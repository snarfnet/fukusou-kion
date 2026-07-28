import AVFoundation
import Accelerate
import Foundation

@MainActor
final class AudioTransformer: NSObject, ObservableObject {
    @Published var sourceURL: URL?
    @Published var outputURL: URL?
    @Published var sourceName = ""
    @Published var duration: TimeInterval = 0
    @Published var waveform: [CGFloat] = Array(repeating: 0.12, count: 72)
    @Published var state: TransformState = .empty
    @Published var isPlaying = false
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0

    private var player: AVAudioPlayer?
    private var recorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var securityScopedURL: URL?

    override init() {
        super.init()
        try? activatePlaybackSession()
    }

    deinit {
        securityScopedURL?.stopAccessingSecurityScopedResource()
        recordingTimer?.invalidate()
    }

    func load(url: URL) async {
        stop()
        securityScopedURL?.stopAccessingSecurityScopedResource()
        securityScopedURL = url.startAccessingSecurityScopedResource() ? url : nil

        do {
            let localURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("CHOP-Source-\(UUID().uuidString)")
                .appendingPathExtension(url.pathExtension.isEmpty ? "m4a" : url.pathExtension)
            try FileManager.default.copyItem(at: url, to: localURL)
            securityScopedURL?.stopAccessingSecurityScopedResource()
            securityScopedURL = nil

            let file = try AVAudioFile(forReading: localURL)
            sourceURL = localURL
            sourceName = url.deletingPathExtension().lastPathComponent
            duration = Double(file.length) / file.fileFormat.sampleRate
            waveform = try await Self.makeWaveform(from: localURL, buckets: 72)
            outputURL = nil
            state = .ready
        } catch {
            securityScopedURL?.stopAccessingSecurityScopedResource()
            securityScopedURL = nil
            state = .failed("この音声ファイルは読み込めませんでした。")
        }
    }

    func transform(bpm: Int, style: DNBStyle) async {
        guard let sourceURL else { return }
        stop()
        state = .rendering(0.08)

        do {
            let destination = FileManager.default.temporaryDirectory
                .appendingPathComponent("CHOP-\(bpm)-\(UUID().uuidString.prefix(6)).wav")
            try? FileManager.default.removeItem(at: destination)

            state = .rendering(0.2)
            let progressTask = Task { @MainActor [weak self] in
                for progress in stride(from: 0.28, through: 0.86, by: 0.08) {
                    try? await Task.sleep(for: .milliseconds(350))
                    guard !Task.isCancelled else { return }
                    self?.state = .rendering(progress)
                }
            }
            defer { progressTask.cancel() }
            do {
                try await Task.detached(priority: .userInitiated) {
                    try Self.render(sourceURL: sourceURL, destination: destination, bpm: bpm, style: style)
                }.value
            } catch {
                state = .failed("音の変換中に失敗しました。短い音で試してください。\n\(error.localizedDescription)")
                return
            }

            state = .rendering(0.95)
            outputURL = destination
            do {
                try activatePlaybackSession()
                player = try AVAudioPlayer(contentsOf: destination)
                player?.volume = 1
                guard player?.prepareToPlay() == true else {
                    throw CocoaError(.fileReadCorruptFile)
                }
                state = .complete
            } catch {
                state = .failed("曲は作成できましたが、再生の準備に失敗しました。\n\(error.localizedDescription)")
            }
        } catch {
            state = .failed("保存先を準備できませんでした。\n\(error.localizedDescription)")
        }
    }

    func togglePlayback() {
        guard let player else { return }
        if player.isPlaying {
            player.pause()
            isPlaying = false
        } else {
            do {
                try activatePlaybackSession()
                if player.currentTime >= player.duration {
                    player.currentTime = 0
                }
                isPlaying = player.play()
                if !isPlaying {
                    state = .failed("再生を開始できませんでした。音量と出力先を確認してください。")
                }
            } catch {
                state = .failed("スピーカーを使えませんでした。もう一度再生してください。")
            }
        }
    }

    func stop() {
        player?.stop()
        player?.currentTime = 0
        isPlaying = false
    }

    func toggleRecording() async {
        if isRecording {
            await finishRecording()
            return
        }

        let permission = await requestRecordPermission()
        guard permission else {
            state = .failed("録音にはマイクの許可が必要です。設定からマイクを許可してください。")
            return
        }

        do {
            stop()
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP]
            )
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let destination = FileManager.default.temporaryDirectory
                .appendingPathComponent("CHOP-Recording-\(UUID().uuidString.prefix(6)).m4a")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44_100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            recorder = try AVAudioRecorder(url: destination, settings: settings)
            recorder?.prepareToRecord()
            guard recorder?.record() == true else {
                throw CocoaError(.fileWriteUnknown)
            }

            recordingDuration = 0
            isRecording = true
            recordingTimer?.invalidate()
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.recordingDuration = self?.recorder?.currentTime ?? 0
                }
            }
        } catch {
            isRecording = false
            recordingTimer?.invalidate()
            state = .failed("録音を開始できませんでした。マイクの接続を確認してください。")
            try? activatePlaybackSession()
        }
    }

    private func finishRecording() async {
        guard let url = recorder?.url else { return }
        recorder?.stop()
        recorder = nil
        recordingTimer?.invalidate()
        recordingTimer = nil
        isRecording = false
        try? activatePlaybackSession()
        await load(url: url)
    }

    private func requestRecordPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                continuation.resume(returning: allowed)
            }
        }
    }

    private func activatePlaybackSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetoothA2DP])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }

    private nonisolated static func render(
        sourceURL: URL,
        destination: URL,
        bpm: Int,
        style: DNBStyle
    ) throws {
        let input = try AVAudioFile(forReading: sourceURL)
        let sourceFormat = input.processingFormat
        let maximumInputFrames = AVAudioFrameCount(
            min(Double(input.length), sourceFormat.sampleRate * 60)
        )
        guard let source = AVAudioPCMBuffer(
            pcmFormat: sourceFormat,
            frameCapacity: maximumInputFrames
        ) else { throw CocoaError(.fileReadCorruptFile) }
        try input.read(into: source, frameCount: maximumInputFrames)

        let sampleRate = 44_100.0
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        let bars = 8
        let secondsPerBeat = 60.0 / Double(bpm)
        let outputFrames = AVAudioFrameCount(Double(bars * 4) * secondsPerBeat * sampleRate)
        guard let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: outputFrames),
              let out = output.floatChannelData,
              let inputData = source.floatChannelData else {
            throw CocoaError(.fileWriteUnknown)
        }
        output.frameLength = outputFrames
        vDSP_vclr(out[0], 1, vDSP_Length(outputFrames))
        vDSP_vclr(out[1], 1, vDSP_Length(outputFrames))

        let sourceFrames = Int(source.frameLength)
        let sourceChannels = Int(sourceFormat.channelCount)
        let stepFrames = Int(secondsPerBeat * sampleRate / 4.0)
        let seed = abs(sourceURL.lastPathComponent.hashValue)
        let analysis = analyzeSource(
            input: inputData[0],
            frames: sourceFrames,
            sampleRate: sourceFormat.sampleRate
        )
        let materialGain = Float(min(1.15, max(0.52, 0.32 / max(analysis.rms, 0.01))))

        for step in 0..<(bars * 16) {
            let local = step % 16
            let bar = step / 16
            let destinationStart = step * stepFrames
            let shouldPlay: Bool
            switch style {
            case .liquid:
                shouldPlay = [0, 3, 6, 8, 11, 14].contains(local)
            case .jungle:
                shouldPlay = ![5, 13].contains(local)
            case .dark:
                shouldPlay = local.isMultiple(of: 2) || [7, 15].contains(local)
            }
            guard shouldPlay else { continue }

            let rates: [Double]
            switch style {
            case .liquid: rates = [1.0, 0.84, 1.0, 1.19]
            case .jungle: rates = [1.0, 1.34, 0.72, 1.0, 1.5]
            case .dark: rates = [0.62, 0.75, 1.0, 0.5]
            }
            let rate = rates[(step + seed) % rates.count]
            let reversed = style == .jungle
                ? [3, 10, 15].contains(local)
                : (style == .dark && [7, 15].contains(local))
            let sourceStart = (seed + bar * 9_973 + local * 4_091)
                % max(1, sourceFrames)

            mixSlice(
                input: inputData,
                sourceChannels: sourceChannels,
                sourceFrames: sourceFrames,
                sourceSampleRate: sourceFormat.sampleRate,
                output: out,
                outputFrames: Int(outputFrames),
                outputSampleRate: sampleRate,
                sourceStart: sourceStart,
                destinationStart: destinationStart,
                length: stepFrames,
                rate: rate,
                reversed: reversed,
                gain: materialGain * (style == .jungle ? 0.72 : 0.64)
            )

            let shouldStutter = (style == .jungle && [14, 15].contains(local))
                || (style == .dark && local == 7)
                || (style == .liquid && local == 14)
            if shouldStutter {
                let repeatLength = max(1, stepFrames / 4)
                for repeatIndex in 1..<4 {
                    mixSlice(
                        input: inputData,
                        sourceChannels: sourceChannels,
                        sourceFrames: sourceFrames,
                        sourceSampleRate: sourceFormat.sampleRate,
                        output: out,
                        outputFrames: Int(outputFrames),
                        outputSampleRate: sampleRate,
                        sourceStart: sourceStart,
                        destinationStart: destinationStart + repeatIndex * repeatLength,
                        length: repeatLength,
                        rate: rate * (1 + Double(repeatIndex) * 0.08),
                        reversed: repeatIndex.isMultiple(of: 2) ? !reversed : reversed,
                        gain: materialGain * 0.54
                    )
                }
            }
        }

        let kickPattern = [0, 7, 10]
        let snarePattern = [4, 12]
        for step in 0..<(bars * 16) {
            let local = step % 16
            let start = step * stepFrames
            if kickPattern.contains(local) {
                synthKick(out: out, start: start, total: Int(outputFrames), sampleRate: sampleRate, gain: 0.9)
            }
            if snarePattern.contains(local) {
                synthSnare(out: out, start: start, total: Int(outputFrames), sampleRate: sampleRate, gain: 0.58)
            }
            if local % 2 == 0 || style == .jungle {
                synthHat(out: out, start: start, total: Int(outputFrames), sampleRate: sampleRate, gain: 0.16)
            }
        }

        let detectedRoot = bassFrequency(from: analysis.pitch)
        let bassNotes: [Double]
        switch style {
        case .liquid:
            bassNotes = [detectedRoot, detectedRoot, detectedRoot * 1.1892, detectedRoot * 0.8909]
        case .jungle:
            bassNotes = [detectedRoot, detectedRoot * 1.3348, detectedRoot, detectedRoot * 0.8909]
        case .dark:
            bassNotes = [detectedRoot * 0.8409, detectedRoot * 0.8409, detectedRoot, detectedRoot * 0.7492]
        }
        for bar in 0..<bars {
            synthBass(
                out: out,
                start: bar * 4 * Int(secondsPerBeat * sampleRate),
                frames: Int(3.5 * secondsPerBeat * sampleRate),
                total: Int(outputFrames),
                sampleRate: sampleRate,
                frequency: bassNotes[bar % bassNotes.count],
                gain: style == .dark ? 0.48 : 0.38
            )
        }

        var peak: Float = 0
        vDSP_maxmgv(out[0], 1, &peak, vDSP_Length(outputFrames))
        if peak > 0.96 {
            var scale = 0.96 / peak
            vDSP_vsmul(out[0], 1, &scale, out[0], 1, vDSP_Length(outputFrames))
            vDSP_vsmul(out[1], 1, &scale, out[1], 1, vDSP_Length(outputFrames))
        }

        let waveSettings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: 2,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]
        let file = try AVAudioFile(
            forWriting: destination,
            settings: waveSettings,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )
        try file.write(from: output)
    }

    private nonisolated static func mixSlice(
        input: UnsafePointer<UnsafeMutablePointer<Float>>,
        sourceChannels: Int,
        sourceFrames: Int,
        sourceSampleRate: Double,
        output: UnsafePointer<UnsafeMutablePointer<Float>>,
        outputFrames: Int,
        outputSampleRate: Double,
        sourceStart: Int,
        destinationStart: Int,
        length: Int,
        rate: Double,
        reversed: Bool,
        gain: Float
    ) {
        guard sourceFrames > 1, length > 0, destinationStart < outputFrames else { return }
        let readStep = sourceSampleRate / outputSampleRate * rate
        let availableOutputFrames = min(length, outputFrames - destinationStart)
        let sourceSpan = max(1, Int(Double(availableOutputFrames) * readStep))
        let safeStart = min(max(0, sourceStart), max(0, sourceFrames - 2))

        for frame in 0..<availableOutputFrames {
            let offset = Int(Double(frame) * readStep) % sourceSpan
            let rawIndex = reversed ? safeStart - offset : safeStart + offset
            let wrappedIndex = ((rawIndex % sourceFrames) + sourceFrames) % sourceFrames
            let nextIndex = (wrappedIndex + 1) % sourceFrames
            let fraction = Float(Double(frame) * readStep - floor(Double(frame) * readStep))
            let fadeIn = min(1, Float(frame) / 120)
            let fadeOut = min(1, Float(availableOutputFrames - frame) / 180)
            let envelope = min(fadeIn, fadeOut) * gain

            for channel in 0..<2 {
                let sourceChannel = min(channel, sourceChannels - 1)
                let first = input[sourceChannel][wrappedIndex]
                let second = input[sourceChannel][nextIndex]
                let sample = first + (second - first) * fraction
                output[channel][destinationStart + frame] += sample * envelope
            }
        }
    }

    private nonisolated static func analyzeSource(
        input: UnsafeMutablePointer<Float>,
        frames: Int,
        sampleRate: Double
    ) -> (rms: Double, pitch: Double?) {
        guard frames > 128 else { return (0.1, nil) }
        let analysisFrames = min(frames, 16_384)
        let start = max(0, (frames - analysisFrames) / 2)
        let samples = input.advanced(by: start)

        var rms: Float = 0
        vDSP_rmsqv(samples, 1, &rms, vDSP_Length(analysisFrames))

        let threshold = max(0.008, Double(rms) * 0.18)
        var crossings = 0
        var previous = Double(samples[0])
        var index = 1
        while index < analysisFrames {
            let current = Double(samples[index])
            if abs(previous) > threshold,
               abs(current) > threshold,
               (previous < 0) != (current < 0) {
                crossings += 1
            }
            previous = current
            index += 1
        }

        let seconds = Double(analysisFrames) / sampleRate
        let estimatedPitch = seconds > 0 ? Double(crossings) / (2 * seconds) : 0
        let pitch = (75...650).contains(estimatedPitch) ? estimatedPitch : nil
        return (Double(rms), pitch)
    }

    private nonisolated static func bassFrequency(from detectedPitch: Double?) -> Double {
        var frequency = detectedPitch ?? 43.65
        while frequency > 65 { frequency /= 2 }
        while frequency < 32 { frequency *= 2 }
        return min(65, max(32, frequency))
    }

    private nonisolated static func synthKick(
        out: UnsafePointer<UnsafeMutablePointer<Float>>,
        start: Int, total: Int, sampleRate: Double, gain: Float
    ) {
        let length = min(Int(sampleRate * 0.24), total - start)
        guard length > 0 else { return }
        var phase = 0.0
        for i in 0..<length {
            let t = Double(i) / sampleRate
            let frequency = 48 + 105 * exp(-t * 30)
            phase += 2 * .pi * frequency / sampleRate
            let value = Float(sin(phase) * exp(-t * 18)) * gain
            out[0][start + i] += value
            out[1][start + i] += value
        }
    }

    private nonisolated static func synthSnare(
        out: UnsafePointer<UnsafeMutablePointer<Float>>,
        start: Int, total: Int, sampleRate: Double, gain: Float
    ) {
        let length = min(Int(sampleRate * 0.18), total - start)
        guard length > 0 else { return }
        var noiseSeed = UInt64(start + 1)
        for i in 0..<length {
            noiseSeed = noiseSeed &* 6_364_136_223_846_793_005 &+ 1
            let noise = Float(Int32(truncatingIfNeeded: noiseSeed >> 32)) / Float(Int32.max)
            let t = Double(i) / sampleRate
            let body = Float(sin(2 * .pi * 185 * t)) * 0.35
            let value = (noise * 0.72 + body) * Float(exp(-t * 22)) * gain
            out[0][start + i] += value
            out[1][start + i] += value
        }
    }

    private nonisolated static func synthHat(
        out: UnsafePointer<UnsafeMutablePointer<Float>>,
        start: Int, total: Int, sampleRate: Double, gain: Float
    ) {
        let length = min(Int(sampleRate * 0.045), total - start)
        guard length > 0 else { return }
        var noiseSeed = UInt64(start + 97)
        for i in 0..<length {
            noiseSeed = noiseSeed &* 2_862_933_555_777_941_757 &+ 3_037_000_493
            let noise = Float(Int32(truncatingIfNeeded: noiseSeed >> 32)) / Float(Int32.max)
            let value = noise * Float(exp(-Double(i) / sampleRate * 75)) * gain
            out[0][start + i] += value
            out[1][start + i] += value
        }
    }

    private nonisolated static func synthBass(
        out: UnsafePointer<UnsafeMutablePointer<Float>>,
        start: Int, frames: Int, total: Int, sampleRate: Double, frequency: Double, gain: Float
    ) {
        let length = min(frames, total - start)
        guard length > 0 else { return }
        for i in 0..<length {
            let t = Double(i) / sampleRate
            let attack = min(1, t * 35)
            let release = min(1, Double(length - i) / (sampleRate * 0.16))
            let fundamental = sin(2 * .pi * frequency * t)
            let harmonic = sin(2 * .pi * frequency * 2 * t) * 0.18
            let value = Float((fundamental + harmonic) * attack * release) * gain
            out[0][start + i] += value
            out[1][start + i] += value
        }
    }

    private nonisolated static func makeWaveform(from url: URL, buckets: Int) async throws -> [CGFloat] {
        let file = try AVAudioFile(forReading: url)
        guard let buffer = AVAudioPCMBuffer(
            pcmFormat: file.processingFormat,
            frameCapacity: AVAudioFrameCount(file.length)
        ) else { return [] }
        try file.read(into: buffer)
        guard let channel = buffer.floatChannelData?[0] else { return [] }

        let count = Int(buffer.frameLength)
        let stride = max(1, count / buckets)
        return (0..<buckets).map { bucket in
            let start = bucket * stride
            let end = min(count, start + stride)
            guard start < end else { return 0.08 }
            var peak: Float = 0
            vDSP_maxmgv(channel.advanced(by: start), 1, &peak, vDSP_Length(end - start))
            return CGFloat(max(0.08, min(1, peak * 2.4)))
        }
    }
}
