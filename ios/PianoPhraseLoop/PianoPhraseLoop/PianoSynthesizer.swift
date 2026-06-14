import AVFoundation
import AudioToolbox
import Foundation
import QuartzCore

final class PianoSynthesizer {
    private final class Voice {
        let note: Int
        let frequency: Double
        let velocity: Float
        let startedAt: Double
        var releasedAt: Double?
        var phase: Double = 0

        init(note: Int, velocity: Int, startedAt: Double) {
            self.note = note
            self.frequency = 440.0 * pow(2.0, Double(note - 69) / 12.0)
            self.velocity = Float(velocity) / 127.0
            self.startedAt = startedAt
        }
    }

    private let engine = AVAudioEngine()
    private let sampler = AVAudioUnitSampler()
    private let reverb = AVAudioUnitReverb()
    private let lock = NSLock()
    private var voices: [Voice] = []
    private let sampleRate = 44_100.0
    private var isConfigured = false
    private var usesSampler = false

    private lazy var sourceNode = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList in
        guard let self else { return noErr }
        let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
        let twoPi = Double.pi * 2
        let releaseSeconds = 0.34
        let now = CACurrentMediaTime()

        self.lock.lock()
        defer { self.lock.unlock() }

        for frame in 0..<Int(frameCount) {
            let frameTime = now + Double(frame) / self.sampleRate
            var sample: Float = 0

            for voice in self.voices {
                let age = max(0, frameTime - voice.startedAt)
                var envelope = min(1.0, age / 0.012)
                if age > 0.05 {
                    envelope = 0.62 + (0.38 * exp(-3.5 * (age - 0.05)))
                }
                if let releasedAt = voice.releasedAt {
                    let releaseAge = max(0, frameTime - releasedAt)
                    envelope *= max(0, 1.0 - releaseAge / releaseSeconds)
                }

                let fundamental = sin(voice.phase)
                let bell = 0.35 * sin(voice.phase * 2.01)
                let air = 0.12 * sin(voice.phase * 3.02)
                sample += Float((fundamental + bell + air) * envelope) * voice.velocity * 0.13
                voice.phase += twoPi * voice.frequency / self.sampleRate
                if voice.phase > twoPi {
                    voice.phase -= twoPi
                }
            }

            for buffer in buffers {
                let pointer = buffer.mData?.assumingMemoryBound(to: Float.self)
                pointer?[frame] = sample
            }
        }

        self.voices.removeAll { voice in
            guard let releasedAt = voice.releasedAt else { return false }
            return now - releasedAt > releaseSeconds
        }

        return noErr
    }

    func start() throws {
        guard !engine.isRunning else { return }

        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)
        #endif

        if !isConfigured {
            let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
            engine.attach(reverb)
            reverb.loadFactoryPreset(.mediumHall)
            reverb.wetDryMix = 18

            if configureSampler() {
                engine.attach(sampler)
                engine.connect(sampler, to: reverb, format: nil)
                usesSampler = true
            } else {
                engine.attach(sourceNode)
                engine.connect(sourceNode, to: reverb, format: format)
                usesSampler = false
            }

            engine.connect(reverb, to: engine.mainMixerNode, format: nil)
            isConfigured = true
        }
        try engine.start()
    }

    func noteOn(_ note: Int, velocity: Int) {
        if usesSampler {
            sampler.startNote(UInt8(max(0, min(127, note))), withVelocity: UInt8(max(1, min(127, velocity))), onChannel: 0)
            return
        }

        lock.lock()
        voices.append(Voice(note: note, velocity: velocity, startedAt: CACurrentMediaTime()))
        lock.unlock()
    }

    func noteOff(_ note: Int) {
        if usesSampler {
            sampler.stopNote(UInt8(max(0, min(127, note))), onChannel: 0)
            return
        }

        lock.lock()
        for voice in voices where voice.note == note && voice.releasedAt == nil {
            voice.releasedAt = CACurrentMediaTime()
        }
        lock.unlock()
    }

    func stopAll() {
        if usesSampler {
            for note in 0...127 {
                sampler.stopNote(UInt8(note), onChannel: 0)
            }
        }

        lock.lock()
        voices.removeAll()
        lock.unlock()
    }

    private func configureSampler() -> Bool {
        let soundBankURL = URL(fileURLWithPath: "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls")

        do {
            try sampler.loadSoundBankInstrument(
                at: soundBankURL,
                program: 0,
                bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                bankLSB: UInt8(kAUSampler_DefaultBankLSB)
            )
            sampler.globalTuning = 0
            sampler.masterGain = -3
            return true
        } catch {
            return false
        }
    }
}
