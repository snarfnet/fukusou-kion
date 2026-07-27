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
            let file = try AVAudioFile(forReading: url)
            sourceURL = url
            sourceName = url.deletingPathExtension().lastPathComponent
            duration = Double(file.length) / file.fileFormat.sampleRate
            waveform = try await Self.makeWaveform(from: url, buckets: 72)
            outputURL = nil
            state = .ready
        } catch {
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
            try await Task.detached(priority: .userInitiated) {
                try Self.render(sourceURL: sourceURL, destination: destination, bpm: bpm, style: style)
            }.value

            state = .rendering(0.95)
            outputURL = destination
            try activatePlaybackSession()
            player = try AVAudioPlayer(contentsOf: destination)
            player?.volume = 1
            player?.prepareToPlay()
            state = .complete
        } catch {
            state = .failed("変換に失敗しました。別の音で試してください。")
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
        guard let source = AVAudioPCMBuffer(
            pcmFormat: sourceFormat,
            frameCapacity: AVAudioFrameCount(input.length)
        ) else { throw CocoaError(.fileReadCorruptFile) }
        try input.read(into: source)

        let sampleRate = 44_100.0
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        let bars = 16
        let secondsPerBeat = 60.0 / Double(bpm)
        let outputFrames = AVAudioFrameCount(Double(bars * 4) * secondsPerBeat * sampleRate)
        guard let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: outputFrames),
              let out = output.floatChannelData,
              let inputData = source.floatChannelData else {
            throw CocoaError(.fileWriteUnknown)
        }
        output.frameLength = outputFrames

        let sourceFrames = Int(source.frameLength)
        let sourceChannels = Int(sourceFormat.channelCount)
        let stepFrames = Int(secondsPerBeat * sampleRate / 4.0)
        let sliceFrames = max(1, min(stepFrames, sourceFrames / 6))
        let seed = abs(sourceURL.lastPathComponent.hashValue)

        for step in 0..<(bars * 16) {
            let destinationStart = step * stepFrames
            let sliceIndex = (step * 7 + seed) % max(1, sourceFrames - sliceFrames)
            let gate: Float = style == .jungle ? (step % 4 == 3 ? 0.55 : 0.82) : 0.72

            for frame in 0..<sliceFrames where destinationStart + frame < Int(outputFrames) {
                let fade = min(Float(frame) / 180, Float(sliceFrames - frame) / 220, 1)
                for channel in 0..<2 {
                    let sourceChannel = min(channel, sourceChannels - 1)
                    out[channel][destinationStart + frame] += inputData[sourceChannel][sliceIndex + frame] * fade * gate
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

        let bassNotes: [Double]
        switch style {
        case .liquid: bassNotes = [43.65, 43.65, 51.91, 38.89]
        case .jungle: bassNotes = [43.65, 58.27, 43.65, 38.89]
        case .dark: bassNotes = [36.71, 36.71, 43.65, 34.65]
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

        let file = try AVAudioFile(forWriting: destination, settings: format.settings)
        try file.write(from: output)
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
