import Foundation

struct PianoPhraseGenerator {
    private struct EmotionalChord {
        let name: String
        let root: Int
        let tones: [Int]
        let colorTones: [Int]
        let surprise: Double
    }

    private let keys: [(name: String, root: Int)] = [
        ("C", 60), ("D", 62), ("E", 64), ("F", 65), ("G", 67), ("A", 69)
    ]

    func makePhrase(seconds: Double, mood: PhraseMood) -> PianoPhrase {
        let bpm = tempo(for: mood)
        let key = keys.randomElement() ?? ("C", 60)
        let step = 60.0 / Double(bpm) / 4.0
        let totalSteps = max(16, Int((seconds / step).rounded(.down)))
        let barSteps = 16
        let progression = emotionalProgression(for: mood)
        var notes: [PianoNote] = []

        for cursor in stride(from: 0, to: totalSteps, by: barSteps) {
            let barIndex = cursor / barSteps
            let progress = Double(cursor) / Double(max(1, totalSteps))
            let isPeak = progress > 0.58 && progress < 0.82
            let isResolution = cursor + barSteps >= totalSteps
            let chord = isResolution ? progression[0] : progression[barIndex % progression.count]
            let energy = isPeak ? 1.0 : min(0.9, 0.45 + progress * 0.7)

            addBassAndHarmony(
                chord: chord,
                keyRoot: key.root,
                cursor: cursor,
                step: step,
                energy: energy,
                isResolution: isResolution,
                notes: &notes
            )

            addMelody(
                chord: chord,
                keyRoot: key.root,
                cursor: cursor,
                totalSteps: totalSteps,
                step: step,
                mood: mood,
                energy: energy,
                isPeak: isPeak,
                isResolution: isResolution,
                notes: &notes
            )
        }

        let trimmed = notes
            .filter { $0.start < seconds - 0.05 }
            .map {
                PianoNote(
                    pitch: clampPitch($0.pitch),
                    velocity: max(1, min(127, $0.velocity)),
                    start: $0.start,
                    duration: max(0.05, min($0.duration, seconds - $0.start))
                )
            }
            .sorted {
                if $0.start == $1.start {
                    return $0.pitch < $1.pitch
                }
                return $0.start < $1.start
            }

        let title = "\(key.name) \(mood.rawValue) \(bpm)bpm"
        return PianoPhrase(name: title, bpm: bpm, keyName: key.name, duration: seconds, notes: trimmed)
    }

    private func tempo(for mood: PhraseMood) -> Int {
        switch mood {
        case .mellow:
            return Int.random(in: 68...94)
        case .bright:
            return Int.random(in: 86...116)
        case .midnight:
            return Int.random(in: 64...88)
        }
    }

    private func emotionalProgression(for mood: PhraseMood) -> [EmotionalChord] {
        let minorI = EmotionalChord(name: "i", root: 0, tones: [0, 3, 7], colorTones: [10, 14], surprise: 0.10)
        let minorIV = EmotionalChord(name: "iv", root: 5, tones: [0, 3, 7], colorTones: [10], surprise: 0.18)
        let flatVI = EmotionalChord(name: "bVI", root: 8, tones: [0, 4, 7], colorTones: [11, 14], surprise: 0.42)
        let flatIII = EmotionalChord(name: "bIII", root: 3, tones: [0, 4, 7], colorTones: [11], surprise: 0.28)
        let flatVII = EmotionalChord(name: "bVII", root: 10, tones: [0, 4, 7], colorTones: [9], surprise: 0.36)
        let majorV = EmotionalChord(name: "V", root: 7, tones: [0, 4, 7], colorTones: [10], surprise: 0.56)
        let borrowedIV = EmotionalChord(name: "IV", root: 5, tones: [0, 4, 7], colorTones: [11, 14], surprise: 0.64)
        let majorI = EmotionalChord(name: "I", root: 0, tones: [0, 4, 7], colorTones: [11, 14], surprise: 0.08)
        let majorVPop = EmotionalChord(name: "V", root: 7, tones: [0, 4, 7], colorTones: [9], surprise: 0.18)
        let majorVI = EmotionalChord(name: "vi", root: 9, tones: [0, 3, 7], colorTones: [10], surprise: 0.24)
        let majorIV = EmotionalChord(name: "IV", root: 5, tones: [0, 4, 7], colorTones: [11, 14], surprise: 0.22)
        let flatVIInMajor = EmotionalChord(name: "bVI", root: 8, tones: [0, 4, 7], colorTones: [11], surprise: 0.70)

        switch mood {
        case .mellow:
            return [
                [minorI, flatVI, flatIII, majorV],
                [minorI, minorIV, flatVI, majorV],
                [minorI, flatVII, flatVI, majorV]
            ].randomElement() ?? [minorI, flatVI, flatIII, majorV]
        case .bright:
            return [
                [majorI, majorVPop, majorVI, borrowedIV],
                [majorI, majorVI, majorIV, majorVPop],
                [majorI, flatVIInMajor, majorIV, majorVPop]
            ].randomElement() ?? [majorI, majorVPop, majorVI, borrowedIV]
        case .midnight:
            return [
                [minorI, flatVII, flatVI, majorV],
                [minorI, flatIII, minorIV, majorV],
                [minorI, borrowedIV, flatVI, majorV]
            ].randomElement() ?? [minorI, flatVII, flatVI, majorV]
        }
    }

    private func addBassAndHarmony(
        chord: EmotionalChord,
        keyRoot: Int,
        cursor: Int,
        step: Double,
        energy: Double,
        isResolution: Bool,
        notes: inout [PianoNote]
    ) {
        let root = keyRoot + chord.root
        let bassDuration = step * (isResolution ? 16.0 : 12.5)
        notes.append(PianoNote(pitch: root - 24, velocity: velocity(50, energy), start: Double(cursor) * step, duration: bassDuration))

        let arpeggioOffsets = [2, 5, 8, 11]
        let arpeggioTones = chord.tones + [chord.colorTones.first ?? chord.tones[1]]
        for (index, offset) in arpeggioOffsets.enumerated() {
            let tone = arpeggioTones[index % arpeggioTones.count]
            let start = Double(cursor + offset) * step
            let duration = step * (index == arpeggioOffsets.count - 1 ? 4.5 : 3.2)
            notes.append(PianoNote(pitch: root + tone - 12, velocity: velocity(34 + index * 4, energy), start: start, duration: duration))
        }

        if chord.surprise > 0.55 {
            let color = chord.colorTones.randomElement() ?? chord.tones[1]
            notes.append(PianoNote(pitch: root + color, velocity: velocity(48, energy), start: Double(cursor + 10) * step, duration: step * 3.0))
        }
    }

    private func addMelody(
        chord: EmotionalChord,
        keyRoot: Int,
        cursor: Int,
        totalSteps: Int,
        step: Double,
        mood: PhraseMood,
        energy: Double,
        isPeak: Bool,
        isResolution: Bool,
        notes: inout [PianoNote]
    ) {
        let root = keyRoot + chord.root
        let contour = melodicContour(for: mood, isPeak: isPeak, isResolution: isResolution)
        let motifOffsets = [0, 4, 7, 10, 12]
        let motifLengths = [3, 2, 2, 2, 5]
        let baseOctave = isPeak ? 24 : 12

        for index in motifOffsets.indices {
            let startStep = cursor + motifOffsets[index]
            guard startStep < totalSteps else { continue }

            let targetTone = contour[index % contour.count]
            let chordTone = nearestChordTone(targetTone, in: chord)
            let target = root + chordTone + baseOctave
            let duration = Double(motifLengths[index]) * step * 0.9
            let accent = index == 0 || index == motifOffsets.count - 1 || chord.surprise > 0.55

            if accent && !isResolution && startStep + 1 < totalSteps {
                let lean = [1, -1, 2].randomElement() ?? 1
                notes.append(PianoNote(pitch: target + lean, velocity: velocity(58, energy), start: Double(startStep) * step, duration: step * 0.72))
                notes.append(PianoNote(pitch: target, velocity: velocity(76, energy), start: Double(startStep + 1) * step, duration: max(step * 1.2, duration - step)))
            } else {
                notes.append(PianoNote(pitch: target, velocity: velocity(accent ? 84 : 66, energy), start: Double(startStep) * step, duration: duration))
            }
        }

        if isResolution {
            notes.append(PianoNote(pitch: keyRoot + 12, velocity: velocity(74, 0.55), start: Double(cursor + 13) * step, duration: step * 7.5))
        }
    }

    private func melodicContour(for mood: PhraseMood, isPeak: Bool, isResolution: Bool) -> [Int] {
        if isResolution {
            return [7, 4, 2, 0, 0]
        }
        if isPeak {
            return [3, 7, 10, 12, 11]
        }
        switch mood {
        case .mellow:
            return [[3, 5, 7, 5, 3], [7, 10, 8, 7, 5]].randomElement() ?? [3, 5, 7, 5, 3]
        case .bright:
            return [[4, 7, 9, 7, 12], [7, 9, 11, 12, 9]].randomElement() ?? [4, 7, 9, 7, 12]
        case .midnight:
            return [[3, 7, 8, 7, 3], [10, 8, 7, 5, 3]].randomElement() ?? [3, 7, 8, 7, 3]
        }
    }

    private func nearestChordTone(_ target: Int, in chord: EmotionalChord) -> Int {
        let candidates = chord.tones + chord.colorTones
        return candidates.min { first, second in
            abs(first - target) < abs(second - target)
        } ?? chord.tones[0]
    }

    private func velocity(_ base: Int, _ energy: Double) -> Int {
        let humanized = Int.random(in: -4...5)
        return max(1, min(127, Int(Double(base) * (0.85 + energy * 0.35)) + humanized))
    }

    private func clampPitch(_ pitch: Int) -> Int {
        max(21, min(108, pitch))
    }
}
