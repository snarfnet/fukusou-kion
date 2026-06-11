import AVFoundation
import Accelerate

@MainActor
final class VoiceRecorder: ObservableObject {
    @Published var isRecording = false
    @Published var liveLevel: Double = 0
    @Published var livePitch: Double = 0
    @Published var recordingProgress: Double = 0

    private var audioEngine: AVAudioEngine?
    private var energySamples: [Double] = []
    private var waveformSamples: [Double] = []
    private var pitchSamples: [Double] = []
    private var startTime: Date?
    private let duration: TimeInterval = 5
    private var timer: Timer?

    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement)
            try session.setActive(true)
        } catch { return }

        energySamples = []
        waveformSamples = []
        pitchSamples = []
        recordingProgress = 0

        let engine = AVAudioEngine()
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)

        input.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
            Task { @MainActor [weak self] in
                self?.processBuffer(buffer)
            }
        }

        do {
            try engine.start()
            audioEngine = engine
            isRecording = true
            startTime = Date()

            timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self, let start = self.startTime else { return }
                    let elapsed = Date().timeIntervalSince(start)
                    self.recordingProgress = min(1, elapsed / self.duration)
                    if elapsed >= self.duration {
                        self.stopRecording()
                    }
                }
            }
        } catch {
            isRecording = false
        }
    }

    func stopRecording() {
        timer?.invalidate()
        timer = nil
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        isRecording = false
        recordingProgress = 1
    }

    func buildFeatures() -> VoiceFeatures {
        let energy = energySamples.isEmpty ? Array(repeating: 0.0, count: 64) : resample(energySamples, to: 64)
        let wave = waveformSamples.isEmpty ? Array(repeating: 0.0, count: 64) : resample(waveformSamples, to: 64)
        let pitch = pitchSamples.isEmpty ? Array(repeating: 200.0, count: 64) : resample(pitchSamples, to: 64)

        let avgEnergy = energy.reduce(0, +) / Double(energy.count)
        let pitchMin = pitch.min() ?? 0
        let pitchMax = pitch.max() ?? 0

        var rhythmDensity = 0.0
        for i in 1..<energy.count {
            rhythmDensity += abs(energy[i] - energy[i - 1])
        }
        rhythmDensity = min(1, rhythmDensity / Double(energy.count))

        return VoiceFeatures(
            averageEnergy: min(1, avgEnergy),
            energyCurve: energy,
            waveform: wave,
            pitchCurve: pitch,
            pitchRange: pitchMax - pitchMin,
            rhythmDensity: rhythmDensity
        )
    }

    private func processBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let data = buffer.floatChannelData?[0] else { return }
        let count = Int(buffer.frameLength)

        var rms: Float = 0
        vDSP_rmsqv(data, 1, &rms, vDSP_Length(count))
        let level = Double(min(1, rms * 8))
        liveLevel = level
        energySamples.append(level)

        var peak: Float = 0
        vDSP_maxv(data, 1, &peak, vDSP_Length(count))
        waveformSamples.append(Double(min(1, peak * 4)))

        let pitch = estimatePitch(data: data, count: count, sampleRate: Float(buffer.format.sampleRate))
        livePitch = pitch
        pitchSamples.append(pitch)
    }

    private func estimatePitch(data: UnsafePointer<Float>, count: Int, sampleRate: Float) -> Double {
        guard count > 0 else { return 200 }
        let halfCount = count / 2
        var autocorrelation = [Float](repeating: 0, count: halfCount)

        for lag in 0..<halfCount {
            var sum: Float = 0
            vDSP_dotpr(data, 1, data + lag, 1, &sum, vDSP_Length(count - lag))
            autocorrelation[lag] = sum
        }

        guard let maxVal = autocorrelation.first, maxVal > 0 else { return 200 }

        let minLag = Int(sampleRate / 1000)
        let maxLag = min(halfCount - 1, Int(sampleRate / 60))
        guard minLag < maxLag else { return 200 }

        var bestLag = minLag
        var bestVal: Float = 0
        for lag in minLag...maxLag {
            if autocorrelation[lag] > bestVal {
                bestVal = autocorrelation[lag]
                bestLag = lag
            }
        }

        let frequency = Double(sampleRate) / Double(bestLag)
        return frequency.isFinite ? max(60, min(1000, frequency)) : 200
    }

    private func resample(_ input: [Double], to targetCount: Int) -> [Double] {
        guard !input.isEmpty else { return Array(repeating: 0, count: targetCount) }
        var result = [Double](repeating: 0, count: targetCount)
        for i in 0..<targetCount {
            let t = Double(i) / Double(targetCount - 1)
            let srcIndex = t * Double(input.count - 1)
            let lo = Int(srcIndex)
            let hi = min(lo + 1, input.count - 1)
            let frac = srcIndex - Double(lo)
            result[i] = input[lo] * (1 - frac) + input[hi] * frac
        }
        return result
    }
}
