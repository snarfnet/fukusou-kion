import Foundation

struct PianoPhraseGenerator {
    private let keys: [(name: String, root: Int)] = [
        ("C", 60), ("D", 62), ("E", 64), ("F", 65), ("G", 67), ("A", 69)
    ]

    func makePhrase(seconds: Double, mood: PhraseMood) -> PianoPhrase {
        let bpm = Int.random(in: 72...112)
        let key = keys.randomElement() ?? ("C", 60)
        let step = 60.0 / Double(bpm) / 4.0
        let totalSteps = max(8, Int((seconds / step).rounded(.down)))
        var notes: [PianoNote] = []
        let progressions = [
            [0, 5, 3, 4],
            [0, 3, 5, 4],
            [0, 4, 5, 3],
            [0, 2, 5, 4]
        ]
        let chordDegrees = progressions.randomElement() ?? [0, 5, 3, 4]
        let motif = makeMotif(for: mood)
        let phraseStepCount = 16

        for cursor in stride(from: 0, to: totalSteps, by: phraseStepCount) {
            let chordIndex = (cursor / phraseStepCount) % chordDegrees.count
            let chordDegree = chordDegrees[chordIndex]
            let isLastChord = cursor + phraseStepCount >= totalSteps
            let bassPitch = pitch(for: chordDegree, keyRoot: key.root, mood: mood, octaveOffset: -24)
            let chordTone = pitch(for: chordDegree + 2, keyRoot: key.root, mood: mood, octaveOffset: -12)
            let fifth = pitch(for: chordDegree + 4, keyRoot: key.root, mood: mood, octaveOffset: -12)

            notes.append(PianoNote(pitch: bassPitch, velocity: 58, start: Double(cursor) * step, duration: step * 12.0))
            notes.append(PianoNote(pitch: chordTone, velocity: 42, start: Double(cursor + 2) * step, duration: step * 8.0))
            notes.append(PianoNote(pitch: fifth, velocity: 38, start: Double(cursor + 6) * step, duration: step * 5.0))

            if isLastChord {
                notes.append(PianoNote(pitch: pitch(for: 0, keyRoot: key.root, mood: mood, octaveOffset: 0), velocity: 66, start: Double(cursor + 12) * step, duration: step * 8.0))
            }
        }

        for cursor in stride(from: 0, to: totalSteps, by: phraseStepCount) {
            let phraseIndex = cursor / phraseStepCount
            let rise = phraseIndex % 4 == 2
            let resolve = cursor + phraseStepCount >= totalSteps

            for item in motif {
                let startStep = cursor + item.offset
                guard startStep < totalSteps else { continue }
                let variation = emotionalVariation(phraseIndex: phraseIndex, rise: rise, resolve: resolve)
                let degree = resolve && item.offset >= 12 ? 0 : item.degree + variation
                let octave = rise ? 12 : 0
                let pitch = pitch(for: degree, keyRoot: key.root, mood: mood, octaveOffset: octave)
                let duration = min(Double(item.length) * step * 0.96, seconds - Double(startStep) * step)

                if duration > 0.05 {
                    notes.append(
                        PianoNote(
                            pitch: pitch,
                            velocity: item.accent ? Int.random(in: 86...112) : Int.random(in: 60...84),
                            start: Double(startStep) * step,
                            duration: duration
                        )
                    )
                }
            }
        }

        let trimmed = notes
            .filter { $0.start < seconds - 0.05 }
            .map {
                PianoNote(
                    pitch: max(21, min(108, $0.pitch)),
                    velocity: $0.velocity,
                    start: $0.start,
                    duration: max(0.05, min($0.duration, seconds - $0.start))
                )
            }
            .sorted { $0.start < $1.start }

        let title = "\(key.name) \(mood.rawValue) \(bpm)bpm"
        return PianoPhrase(name: title, bpm: bpm, keyName: key.name, duration: seconds, notes: trimmed)
    }

    private func makeMotif(for mood: PhraseMood) -> [(offset: Int, degree: Int, length: Int, accent: Bool)] {
        let candidates: [[(offset: Int, degree: Int, length: Int, accent: Bool)]] = [
            [(0, 2, 2, true), (3, 4, 1, false), (4, 5, 3, true), (8, 4, 2, false), (11, 2, 1, false), (12, 1, 4, true)],
            [(0, 4, 2, true), (2, 5, 2, false), (5, 3, 3, true), (9, 2, 2, false), (12, 0, 4, true)],
            [(0, 0, 3, true), (4, 2, 2, false), (6, 3, 2, true), (10, 5, 1, false), (12, 4, 4, true)]
        ]
        return candidates.randomElement() ?? candidates[0]
    }

    private func emotionalVariation(phraseIndex: Int, rise: Bool, resolve: Bool) -> Int {
        if resolve { return 0 }
        if rise { return [1, 1, 2, 3].randomElement() ?? 1 }
        if phraseIndex % 2 == 1 { return [-1, 0, 1].randomElement() ?? 0 }
        return [0, 0, 1].randomElement() ?? 0
    }

    private func pitch(for degree: Int, keyRoot: Int, mood: PhraseMood, octaveOffset: Int) -> Int {
        let scale = mood.scale
        let octave = Int(floor(Double(degree) / Double(scale.count))) * 12
        let index = ((degree % scale.count) + scale.count) % scale.count
        return keyRoot + octaveOffset + octave + scale[index]
    }
}
