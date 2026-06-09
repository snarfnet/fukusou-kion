import AVFoundation
import Foundation

@MainActor
final class VoiceRecorder: ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var elapsed: Double = 0
    @Published private(set) var liveLevel: Double = 0
    @Published private(set) var livePitch: Double = 0
    @Published private(set) var permissionDenied = false
    @Published private(set) var latestFeatures: VoiceFeatures = .empty
    @Published private(set) var completedArtwork: VoiceArtwork?

    private let engine = AVAudioEngine()
    private var startedAt: Date?
    private var energyCurve: [Double] = []
    private var pitchCurve: [Double] = []
    private var waveform: [Double] = []
    private var zeroCrossings: [Double] = []
    private var timer: Timer?

    func start() {
        guard !isRecording else { return }

        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] allowed in
            Task { @MainActor in
                guard let self else { return }
                if allowed {
                    self.beginRecording()
                } else {
                    self.permissionDenied = true
                }
            }
        }
    }

    func stop() -> VoiceArtwork? {
        guard isRecording else { return nil }

        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        timer?.invalidate()
        timer = nil
        isRecording = false

        let features = buildFeatures()
        latestFeatures = features

        let seed = UInt64(Date().timeIntervalSince1970 * 1000) ^ UInt64.random(in: 1...UInt64.max)
        let artwork = VoiceArtwork(
            id: UUID(),
            createdAt: Date(),
            title: title(for: features),
            seed: seed,
            features: features
        )
        completedArtwork = artwork
        return artwork
    }

    func clearPermissionAlert() {
        permissionDenied = false
    }

    private func beginRecording() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .mixWithOthers])
            try session.setActive(true)

            resetBuffers()
            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)

            input.removeTap(onBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                self?.analyze(buffer: buffer, sampleRate: format.sampleRate)
            }

            try engine.start()
            startedAt = Date()
            isRecording = true
            timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    guard let self, let startedAt = self.startedAt else { return }
                    self.elapsed = Date().timeIntervalSince(startedAt)
                    if self.elapsed >= 6 {
                        _ = self.stop()
                    }
                }
            }
        } catch {
            isRecording = false
            permissionDenied = true
        }
    }

    nonisolated private func analyze(buffer: AVAudioPCMBuffer, sampleRate: Double) {
        guard let channel = buffer.floatChannelData?.pointee else { return }
        let count = Int(buffer.frameLength)
        guard count > 0 else { return }

        var sum: Float = 0
        var peak: Float = 0
        var crossings = 0
        var previous = channel[0]
        var compactWave: [Double] = []
        let step = max(1, count / 24)

        for index in 0..<count {
            let sample = channel[index]
            sum += sample * sample
            peak = max(peak, abs(sample))
            if index > 0, (sample >= 0) != (previous >= 0) {
                crossings += 1
            }
            previous = sample
            if index % step == 0 {
                compactWave.append(Double(sample))
            }
        }

        let rms = sqrt(sum / Float(count))
        let pitch = estimatePitch(samples: channel, count: count, sampleRate: sampleRate)
        let zcr = Double(crossings) / Double(count)

        Task { @MainActor [weak self] in
            guard let self else { return }
            self.liveLevel = min(1, Double(rms) * 9)
            self.livePitch = pitch
            self.energyCurve.append(min(1, Double(rms) * 4.5))
            self.pitchCurve.append(pitch)
            self.waveform.append(contentsOf: compactWave)
            self.zeroCrossings.append(zcr)

            self.energyCurve = Array(self.energyCurve.suffix(180))
            self.pitchCurve = Array(self.pitchCurve.suffix(180))
            self.waveform = Array(self.waveform.suffix(720))
            self.zeroCrossings = Array(self.zeroCrossings.suffix(180))
        }
    }

    nonisolated private func estimatePitch(samples: UnsafePointer<Float>, count: Int, sampleRate: Double) -> Double {
        let minFrequency = 75.0
        let maxFrequency = 520.0
        let minLag = max(1, Int(sampleRate / maxFrequency))
        let maxLag = min(count - 1, Int(sampleRate / minFrequency))
        guard maxLag > minLag else { return 0 }

        var bestLag = 0
        var bestCorrelation: Float = 0

        for lag in minLag...maxLag {
            var correlation: Float = 0
            var energy: Float = 0
            for index in 0..<(count - lag) {
                let a = samples[index]
                let b = samples[index + lag]
                correlation += a * b
                energy += a * a + b * b
            }
            let normalized = energy > 0 ? correlation / energy : 0
            if normalized > bestCorrelation {
                bestCorrelation = normalized
                bestLag = lag
            }
        }

        guard bestLag > 0, bestCorrelation > 0.18 else { return 0 }
        return sampleRate / Double(bestLag)
    }

    private func buildFeatures() -> VoiceFeatures {
        let duration = max(elapsed, 0.1)
        let voicedPitches = pitchCurve.filter { $0 > 0 }
        let averageEnergy = energyCurve.average
        let peakEnergy = energyCurve.max() ?? 0
        let averagePitch = voicedPitches.average
        let pitchRange = (voicedPitches.max() ?? 0) - (voicedPitches.min() ?? 0)
        let silenceRatio = energyCurve.isEmpty ? 0 : Double(energyCurve.filter { $0 < 0.08 }.count) / Double(energyCurve.count)
        let rhythmDensity = rhythmPeaks(in: energyCurve) / duration

        return VoiceFeatures(
            duration: duration,
            averageEnergy: averageEnergy,
            peakEnergy: peakEnergy,
            averagePitch: averagePitch,
            pitchRange: pitchRange,
            rhythmDensity: rhythmDensity,
            silenceRatio: silenceRatio,
            zeroCrossingRate: zeroCrossings.average,
            waveform: normalizedSamples(waveform, limit: 220),
            energyCurve: normalizedSamples(energyCurve, limit: 120),
            pitchCurve: normalizedSamples(voicedPitches, limit: 120)
        )
    }

    private func rhythmPeaks(in values: [Double]) -> Double {
        guard values.count > 2 else { return 0 }
        var peaks = 0
        for index in 1..<(values.count - 1) {
            if values[index] > 0.16,
               values[index] > values[index - 1] * 1.25,
               values[index] > values[index + 1] * 1.1 {
                peaks += 1
            }
        }
        return Double(peaks)
    }

    private func normalizedSamples(_ values: [Double], limit: Int) -> [Double] {
        guard !values.isEmpty else { return [] }
        let stride = max(1, values.count / limit)
        let sampled = values.enumerated().compactMap { index, value in
            index % stride == 0 ? value : nil
        }
        let maxValue = max(sampled.map(abs).max() ?? 1, 0.0001)
        return sampled.prefix(limit).map { max(-1, min(1, $0 / maxValue)) }
    }

    private func title(for features: VoiceFeatures) -> String {
        let forms = ["Echo Bloom", "Pulse Glyph", "Tone Drift", "Rhythm Veil", "Signal Halo"]
        let index = Int((features.averageEnergy * 1000).rounded()) % forms.count
        let number = Int(Date().timeIntervalSince1970) % 10_000
        return "\(forms[index]) #\(number)"
    }

    private func resetBuffers() {
        elapsed = 0
        liveLevel = 0
        livePitch = 0
        latestFeatures = .empty
        completedArtwork = nil
        energyCurve = []
        pitchCurve = []
        waveform = []
        zeroCrossings = []
    }
}

private extension Array where Element == Double {
    var average: Double {
        guard !isEmpty else { return 0 }
        return reduce(0, +) / Double(count)
    }
}
