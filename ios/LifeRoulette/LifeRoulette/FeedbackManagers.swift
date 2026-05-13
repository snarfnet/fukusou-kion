import AVFoundation
import AudioToolbox
import CoreHaptics
import UIKit

final class DrumrollSoundPlayer {
    private var player: AVAudioPlayer?

    func play() {
        do {
            let url = try makeDrumrollFile()
            player = try AVAudioPlayer(contentsOf: url)
            player?.volume = 0.85
            player?.play()
        } catch {
            AudioServicesPlaySystemSound(1104)
        }
    }

    func stop() {
        player?.stop()
        player = nil
    }

    private func makeDrumrollFile() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("life-roulette-drumroll.wav")
        if FileManager.default.fileExists(atPath: url.path) {
            return url
        }

        let sampleRate = 44_100.0
        let duration = 1.8
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        buffer.frameLength = frameCount

        let channel = buffer.floatChannelData![0]
        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let hitRate = 18.0 + t * 18.0
            let pulse = max(0, sin(t * hitRate * .pi))
            let noise = Float.random(in: -1...1)
            let ramp = Float(min(1, t / 0.3) * min(1, (duration - t) / 0.2))
            channel[frame] = noise * Float(pow(pulse, 10)) * ramp * 0.9
        }

        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        try file.write(from: buffer)
        return url
    }
}

final class HapticPerformer {
    private var engine: CHHapticEngine?

    init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        engine = try? CHHapticEngine()
        try? engine?.start()
    }

    func spinTick() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func explosion() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            return
        }

        let events = [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 1)
                ],
                relativeTime: 0
            ),
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.75),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.45)
                ],
                relativeTime: 0.04,
                duration: 0.45
            )
        ]

        do {
            try engine?.start()
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}
