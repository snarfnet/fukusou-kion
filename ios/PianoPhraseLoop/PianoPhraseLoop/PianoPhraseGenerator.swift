import Foundation

struct PianoPhraseGenerator {
    private struct EmotionalChord {
        let name: String
        let root: Int
        let tones: [Int]
        let colorTones: [Int]
        let surprise: Double
        let bassMotion: Int
    }

    private let keys: [(name: String, root: Int)] = [
        ("C", 60), ("D", 62), ("E", 64), ("F", 65), ("G", 67), ("A", 69)
    ]

    func makePhrase(bars: Int, mood: PhraseMood) -> PianoPhrase {
        let bpm = tempo(for: mood)
        let key = keys.randomElement() ?? ("C", 60)
        let step = 60.0 / Double(bpm) / 4.0
        let barCount = max(1, min(16, bars))
        let barSteps = 16
        let totalSteps = barCount * barSteps
        let seconds = Double(totalSteps) * step
        let progression = emotionalProgression(for: mood)
        var notes: [PianoNote] = []

        for cursor in stride(from: 0, to: totalSteps, by: barSteps) {
            let barIndex = cursor / barSteps
            let progress = Double(cursor) / Double(max(1, totalSteps))
            let isPeak = progress > 0.58 && progress < 0.82
            let isResolution = cursor + barSteps >= totalSteps
            let chord = isResolution ? resolutionChord(for: mood) : progression[barIndex % progression.count]
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
                barIndex: barIndex,
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
        return PianoPhrase(name: title, bpm: bpm, keyName: key.name, bars: barCount, duration: seconds, notes: trimmed)
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
        let minorI = EmotionalChord(name: "i", root: 0, tones: [0, 3, 7], colorTones: [10, 14], surprise: 0.10, bassMotion: 0)
        let minorV = EmotionalChord(name: "v", root: 7, tones: [0, 3, 7], colorTones: [10], surprise: 0.18, bassMotion: 7)
        let minorIV = EmotionalChord(name: "iv", root: 5, tones: [0, 3, 7], colorTones: [10], surprise: 0.18, bassMotion: 5)
        let flatVI = EmotionalChord(name: "bVI", root: 8, tones: [0, 4, 7], colorTones: [11, 14], surprise: 0.42, bassMotion: 8)
        let flatIII = EmotionalChord(name: "bIII", root: 3, tones: [0, 4, 7], colorTones: [11], surprise: 0.28, bassMotion: 3)
        let flatVII = EmotionalChord(name: "bVII", root: 10, tones: [0, 4, 7], colorTones: [9], surprise: 0.36, bassMotion: 10)
        let majorV = EmotionalChord(name: "V", root: 7, tones: [0, 4, 7], colorTones: [10, 14], surprise: 0.56, bassMotion: 7)
        let borrowedIV = EmotionalChord(name: "IV", root: 5, tones: [0, 4, 7], colorTones: [11, 14], surprise: 0.64, bassMotion: 5)
        let majorI = EmotionalChord(name: "I", root: 0, tones: [0, 4, 7], colorTones: [11, 14], surprise: 0.08, bassMotion: 0)
        let majorVPop = EmotionalChord(name: "V", root: 7, tones: [0, 4, 7], colorTones: [9, 14], surprise: 0.18, bassMotion: 7)
        let majorIII = EmotionalChord(name: "iii", root: 4, tones: [0, 3, 7], colorTones: [10], surprise: 0.24, bassMotion: 4)
        let majorVI = EmotionalChord(name: "vi", root: 9, tones: [0, 3, 7], colorTones: [10, 14], surprise: 0.24, bassMotion: 9)
        let majorIV = EmotionalChord(name: "IV", root: 5, tones: [0, 4, 7], colorTones: [11, 14], surprise: 0.22, bassMotion: 5)
        let flatVIInMajor = EmotionalChord(name: "bVI", root: 8, tones: [0, 4, 7], colorTones: [11], surprise: 0.70, bassMotion: 8)

        let canonMajor = [majorI, majorVPop, majorVI, majorIII, majorIV, majorI, majorIV, majorV]
        let canonMinor = [minorI, minorV, flatVI, flatIII, minorIV, minorI, minorIV, majorV]

        switch mood {
        case .mellow:
            return [
                canonMinor,
                canonMajor,
                [minorI, flatVI, flatIII, majorV, minorI, minorIV, flatVI, majorV]
            ].randomElement() ?? canonMinor
        case .bright:
            return [
                canonMajor,
                [majorI, majorVPop, majorVI, majorIII, majorIV, flatVIInMajor, majorIV, majorVPop],
                [majorI, majorVI, majorIV, majorVPop, majorI, borrowedIV, majorIV, majorVPop]
            ].randomElement() ?? canonMajor
        case .midnight:
            return [
                canonMinor,
                [minorI, flatVII, flatVI, majorV, minorI, flatIII, minorIV, majorV],
                [minorI, borrowedIV, flatVI, majorV, minorI, minorIV, flatVI, majorV]
            ].randomElement() ?? canonMinor
        }
    }

    private func resolutionChord(for mood: PhraseMood) -> EmotionalChord {
        switch mood {
        case .bright:
            return EmotionalChord(name: "I", root: 0, tones: [0, 4, 7], colorTones: [11, 14], surprise: 0.08, bassMotion: 0)
        case .mellow, .midnight:
            return EmotionalChord(name: "i", root: 0, tones: [0, 3, 7], colorTones: [10, 14], surprise: 0.10, bassMotion: 0)
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
        let bassRoot = keyRoot + chord.bassMotion
        let bassDuration = step * (isResolution ? 16.0 : 12.5)
        notes.append(PianoNote(pitch: bassRoot - 24, velocity: velocity(50, energy), start: Double(cursor) * step, duration: bassDuration))
        notes.append(PianoNote(pitch: bassRoot - 12, velocity: velocity(30, energy), start: Double(cursor + 8) * step, duration: step * 4.0))

        let arpeggioOffsets = [2, 5, 8, 11, 14]
        let arpeggioTones = chord.tones + [chord.colorTones.first ?? chord.tones[1], chord.tones[2] + 12]
        for (index, offset) in arpeggioOffsets.enumerated() {
            let tone = arpeggioTones[index % arpeggioTones.count]
            let start = Double(cursor + offset) * step
            let duration = step * (index == arpeggioOffsets.count - 1 ? 3.8 : 3.0)
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
        barIndex: Int,
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

            let targetTone = canonGuideTone(barIndex: barIndex, noteIndex: index, mood: mood) ?? contour[index % contour.count]
            let chordTone = nearestChordTone(targetTone, in: chord)
            let target = root + chordTone + baseOctave
            let duration = Double(motifLengths[index]) * step * 0.9
            let accent = index == 0 || index == motifOffsets.count - 1 || chord.surprise > 0.55

            if accent && !isResolution && startStep + 1 < totalSteps {
                let lean = tearfulLean(for: mood, index: index)
                notes.append(PianoNote(pitch: target + lean, velocity: velocity(58, energy), start: Double(startStep) * step, duration: step * 0.72))
                notes.append(PianoNote(pitch: target, velocity: velocity(76, energy), start: Double(startStep + 1) * step, duration: max(step * 1.2, duration - step)))
            } else {
                notes.append(PianoNote(pitch: target, velocity: velocity(accent ? 84 : 66, energy), start: Double(startStep) * step, duration: duration))
            }

            let echoStep = startStep + 4
            if index < 3 && echoStep < totalSteps && !isResolution {
                notes.append(PianoNote(pitch: target - 12, velocity: velocity(32, energy), start: Double(echoStep) * step, duration: duration * 0.9))
            }
        }

        if !isResolution && cursor + 15 < totalSteps {
            let suspension = root + (chord.colorTones.first ?? 10) + baseOctave
            let resolution = root + nearestChordTone(7, in: chord) + baseOctave
            notes.append(PianoNote(pitch: suspension, velocity: velocity(46, energy), start: Double(cursor + 13) * step, duration: step * 1.5))
            notes.append(PianoNote(pitch: resolution, velocity: velocity(62, energy), start: Double(cursor + 15) * step, duration: step * 2.2))
        }

        if isResolution {
            notes.append(PianoNote(pitch: keyRoot + 12, velocity: velocity(74, 0.55), start: Double(cursor + 13) * step, duration: step * 7.5))
        }
    }

    private func canonGuideTone(barIndex: Int, noteIndex: Int, mood: PhraseMood) -> Int? {
        let majorGuide = [
            [7, 11, 14, 12, 11],
            [7, 9, 11, 9, 7],
            [9, 12, 14, 12, 11],
            [7, 11, 12, 11, 9],
            [5, 9, 12, 11, 9],
            [4, 7, 11, 9, 7],
            [5, 9, 11, 12, 14],
            [7, 11, 14, 16, 14]
        ]
        let minorGuide = [
            [7, 10, 14, 12, 10],
            [7, 10, 12, 10, 7],
            [8, 12, 15, 14, 12],
            [7, 10, 12, 10, 8],
            [5, 8, 10, 12, 10],
            [3, 7, 10, 8, 7],
            [5, 8, 10, 12, 14],
            [7, 11, 14, 15, 14]
        ]
        let guide = mood == .bright ? majorGuide : minorGuide
        return guide[barIndex % guide.count][noteIndex % guide[0].count]
    }

    private func tearfulLean(for mood: PhraseMood, index: Int) -> Int {
        if mood == .bright {
            return [2, 1, -1, 2, 1][index % 5]
        }
        return [1, 2, -1, 1, 2][index % 5]
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
