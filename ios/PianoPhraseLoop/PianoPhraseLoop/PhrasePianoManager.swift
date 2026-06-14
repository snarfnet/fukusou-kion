import Foundation
import SwiftUI

@MainActor
final class PhrasePianoManager: ObservableObject {
    @Published var seconds: Double = 8
    @Published var mood: PhraseMood = .mellow
    @Published var phrase: PianoPhrase
    @Published var isPlaying = false
    @Published var isLooping = false
    @Published var savedMIDIURL: URL?
    @Published var lastError: String?

    private let generator = PianoPhraseGenerator()
    private let synth = PianoSynthesizer()
    private var playToken = UUID()

    init() {
        let initialMood: PhraseMood = .mellow
        self.phrase = PianoPhraseGenerator().makePhrase(seconds: 8, mood: initialMood)
    }

    func generate() {
        stop()
        phrase = generator.makePhrase(seconds: seconds, mood: mood)
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
        synth.stopAll()

        do {
            try synth.start()
        } catch {
            lastError = "音声の開始に失敗しました"
            isPlaying = false
            return
        }

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

                if shouldLoop, self.isLooping {
                    self.playCurrent(shouldLoop: true)
                }
            }
        }
    }
}
