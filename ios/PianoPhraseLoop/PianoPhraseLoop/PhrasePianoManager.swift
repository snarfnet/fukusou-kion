import Foundation
import SwiftUI

@MainActor
final class PhrasePianoManager: ObservableObject {
    @Published var bars: Double = 4
    @Published var mood: PhraseMood = .mellow
    @Published var phrase: PianoPhrase
    @Published var isPlaying = false
    @Published var isLooping = false
    @Published var playbackProgress: Double = 0
    @Published var savedMIDIURL: URL?
    @Published var lastError: String?

    private let generator = PianoPhraseGenerator()
    private let synth = PianoSynthesizer()
    private var playToken = UUID()

    init() {
        let initialMood: PhraseMood = .mellow
        self.phrase = PianoPhraseGenerator().makePhrase(bars: 4, mood: initialMood)
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

    private func playCurrent(shouldLoop: Bool) {
        let token = UUID()
        playToken = token
        isPlaying = true
        playbackProgress = 0
        synth.stopAll()

        do {
            try synth.start()
        } catch {
            lastError = "音声の開始に失敗しました"
            isPlaying = false
            return
        }

        updateProgress(token: token, startedAt: Date())

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

        DispatchQueue.main.asyncAfter(deadline: .now() + phrase.duration + 0.15) { [weak self] in
            Task { @MainActor in
                guard let self, self.playToken == token else { return }
                self.synth.stopAll()
                self.isPlaying = false
                self.playbackProgress = 1

                if shouldLoop, self.isLooping {
                    self.playCurrent(shouldLoop: true)
                }
            }
        }
    }

    private func updateProgress(token: UUID, startedAt: Date) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            Task { @MainActor in
                guard let self, self.playToken == token, self.isPlaying else { return }
                let elapsed = Date().timeIntervalSince(startedAt)
                self.playbackProgress = min(1, max(0, elapsed / self.phrase.duration))
                if self.playbackProgress < 1 {
                    self.updateProgress(token: token, startedAt: startedAt)
                }
            }
        }
    }
}
