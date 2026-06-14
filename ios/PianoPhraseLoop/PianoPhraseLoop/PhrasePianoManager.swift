import Foundation
import SwiftUI

@MainActor
final class PhrasePianoManager: ObservableObject {
    @Published var bars: Double = 2
    @Published var mood: PhraseMood = .mellow
    @Published var phrase: PianoPhrase
    @Published var isPlaying = false
    @Published var isLooping = false
    @Published var playbackProgress: Double = 0
    @Published var loopCycle = 0
    @Published var currentBarNumber = 1
    @Published var savedMIDIURL: URL?
    @Published var lastError: String?

    private let generator = PianoPhraseGenerator()
    private let synth = PianoSynthesizer()
    private var playToken = UUID()

    init() {
        let initialMood: PhraseMood = .mellow
        self.phrase = PianoPhraseGenerator().makePhrase(bars: 2, mood: initialMood)
    }

    func generate() {
        stop()
        phrase = generator.makePhrase(bars: Int(bars), mood: mood)
        savedMIDIURL = nil
    }

    func togglePlayback() {
        if isPlaying && !isLooping {
            stop()
        } else {
            isLooping = false
            playCurrent(shouldLoop: false)
        }
    }

    func toggleLoop() {
        if isLooping {
            stop()
        } else {
            isLooping = true
            playCurrent(shouldLoop: true)
        }
    }

    func stop() {
        playToken = UUID()
        isPlaying = false
        isLooping = false
        playbackProgress = 0
        loopCycle = 0
        currentBarNumber = 1
        synth.stopAll()
    }

    func saveMIDI() {
        do {
            savedMIDIURL = try MIDIFileWriter.write(phrase: phrase)
            lastError = nil
        } catch {
            lastError = "MIDI保存に失敗しました"
        }
    }

    private func playCurrent(shouldLoop: Bool, cycle: Int = 0) {
        let token = UUID()
        playToken = token
        isPlaying = true
        loopCycle = cycle
        playbackProgress = 0
        currentBarNumber = cycle * max(1, phrase.bars) + 1
        if cycle == 0 {
            synth.stopAll()
        }

        do {
            try synth.start()
        } catch {
            lastError = "音声の開始に失敗しました"
            isPlaying = false
            return
        }

        updateProgress(token: token, startedAt: Date(), cycle: cycle)

        for note in phrase.notes {
            DispatchQueue.main.asyncAfter(deadline: .now() + note.start) { [weak self] in
                Task { @MainActor in
                    guard let self, self.playToken == token else { return }
                    self.synth.noteOn(note.pitch, velocity: note.velocity)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + note.start + note.duration) { [weak self] in
                Task { @MainActor in
                    guard let self, self.playToken == token else { return }
                    self.synth.noteOff(note.pitch)
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + phrase.duration + 0.02) { [weak self] in
            Task { @MainActor in
                guard let self, self.playToken == token else { return }
                self.synth.stopAll()

                if shouldLoop, self.isLooping {
                    self.playCurrent(shouldLoop: true, cycle: cycle + 1)
                } else {
                    self.isPlaying = false
                    self.playbackProgress = 1
                    self.currentBarNumber = max(1, self.phrase.bars)
                }
            }
        }
    }

    private func updateProgress(token: UUID, startedAt: Date, cycle: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            Task { @MainActor in
                guard let self, self.playToken == token, self.isPlaying else { return }
                let elapsed = Date().timeIntervalSince(startedAt)
                self.playbackProgress = min(1, max(0, elapsed / self.phrase.duration))
                let barCount = max(1, self.phrase.bars)
                let barInPhrase = min(barCount - 1, Int(self.playbackProgress * Double(barCount)))
                self.currentBarNumber = cycle * barCount + barInPhrase + 1
                if self.playbackProgress < 1 {
                    self.updateProgress(token: token, startedAt: startedAt, cycle: cycle)
                }
            }
        }
    }
}
