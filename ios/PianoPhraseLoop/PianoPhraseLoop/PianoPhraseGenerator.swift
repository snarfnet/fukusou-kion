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

    private struct HookMotif {
        let offsets: [Int]
        let lengths: [Double]
        let call: [Int]
        let answer: [Int]
        let echoInterval: Int
    }

    private let keys: [(name: String, root: Int)] = [
        ("C", 60), ("D", 62), ("E", 64), ("F", 65), ("G", 67), ("A", 69)
    ]

    func makePhrase(bars: Int, mood: PhraseMood) -> PianoPhrase {
        let bpm = tempo(for: mood)
        let key = keys.randomElement() ?? ("C", 60)
        let step = 60.0 / Double(bpm) / 4.0
        let barCount = max(1, min(8, bars))
        let barSteps = 16
        let totalSteps = barCount * barSteps
        let seconds = Double(totalSteps) * step
        let progression = emotionalProgression(for: mood)
        let density = Double.random(in: 0.32...0.54)
        let hook = hookMotif(for: mood)
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
                density: density,
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
                hook: hook,
                energy: energy,
                density: density,
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
            return Int.random(in: 58...76)
        case .bright:
            return Int.random(in: 72...94)
        case .midnight:
            return Int.random(in: 52...70)
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
        let minorIVInMajor = EmotionalChord(name: "iv", root: 5, tones: [0, 3, 7], colorTones: [10, 14], surprise: 0.74, bassMotion: 5)
        let flatVIInMajor = EmotionalChord(name: "bVI", root: 8, tones: [0, 4, 7], colorTones: [11], surprise: 0.70, bassMotion: 8)

        let canonMajor = [majorI, majorVPop, majorVI, majorIII, majorIV, majorI, majorIV, majorV]

        switch mood {
        case .mellow:
            return [
                [minorI, flatVI, minorIV, majorV],
                [majorI, majorVI, minorIVInMajor, majorVPop],
                [minorI, flatIII, flatVI, majorV],
                [majorI, flatVIInMajor, minorIVInMajor, majorVPop]
            ].randomElement() ?? [minorI, flatVI, minorIV, majorV]
        case .bright:
            return [
                [majorI, majorVI, minorIVInMajor, majorVPop],
                [majorI, majorVPop, majorVI, minorIVInMajor],
                [majorI, flatVIInMajor, borrowedIV, majorVPop],
                Array(canonMajor.prefix(4))
            ].randomElement() ?? [majorI, majorVI, minorIVInMajor, majorVPop]
        case .midnight:
            return [
                [minorI, flatVII, flatVI, majorV],
                [minorI, flatVI, minorIV, majorV],
                [minorI, flatIII, minorIV, majorV],
                [minorI, minorV, flatVI, majorV]
            ].randomElement() ?? [minorI, flatVII, flatVI, majorV]
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
        density: Double,
        isResolution: Bool,
        notes: inout [PianoNote]
    ) {
        let root = keyRoot + chord.root
        let bassRoot = keyRoot + chord.bassMotion
        let bassDuration = step * (isResolution ? 10.0 : Double.random(in: 5.0...8.5))
        notes.append(PianoNote(pitch: bassRoot - 24, velocity: velocity(42, energy), start: Double(cursor) * step, duration: bassDuration))

        if density > 0.48 && !isResolution && Bool.random() {
            notes.append(PianoNote(pitch: bassRoot - 12, velocity: velocity(24, energy), start: Double(cursor + 9) * step, duration: step * 2.1))
        }

        let arpeggioOffsets = [[4], [3, 10], [6, 12], [2, 11]].randomElement() ?? [4]
        let arpeggioTones = [chord.tones[1], chord.colorTones.first ?? chord.tones[2], chord.tones[2]]
        for (index, offset) in arpeggioOffsets.enumerated() {
            let tone = arpeggioTones[index % arpeggioTones.count]
            let start = Double(cursor + offset) * step
            let duration = step * Double.random(in: 2.0...3.2)
            notes.append(PianoNote(pitch: root + tone - 12, velocity: velocity(24 + index * 3, energy), start: start, duration: duration))
        }

        if chord.surprise > 0.55 && Double.random(in: 0...1) < density {
            let color = chord.colorTones.randomElement() ?? chord.tones[1]
            notes.append(PianoNote(pitch: root + color, velocity: velocity(36, energy), start: Double(cursor + 10) * step, duration: step * 1.8))
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
        hook: HookMotif,
        energy: Double,
        density: Double,
        isPeak: Bool,
        isResolution: Bool,
        notes: inout [PianoNote]
    ) {
        let root = keyRoot + chord.root
        let motifOffsets = hook.offsets
        let motifLengths = hook.lengths
        let baseOctave = isPeak ? 24 : 12

        for index in motifOffsets.indices {
            let startStep = cursor + motifOffsets[index]
            guard startStep < totalSteps else { continue }

            if index > 1 && Double.random(in: 0...1) > density {
                continue
            }

            let targetTone = hookTone(hook: hook, barIndex: barIndex, noteIndex: index, mood: mood, isPeak: isPeak, isResolution: isResolution)
            let target = keyRoot + targetTone + baseOctave
            let duration = motifLengths[index % motifLengths.count] * step * Double.random(in: 0.75...1.08)
            let accent = index == 0 || index == motifOffsets.count - 1 || chord.surprise > 0.55

            if accent && startStep + 1 < totalSteps && Double.random(in: 0...1) < 0.84 {
                let lean = tearfulLean(for: mood, index: index)
                notes.append(PianoNote(pitch: target + lean, velocity: velocity(54, energy), start: Double(startStep) * step, duration: step * 0.85))
                notes.append(PianoNote(pitch: target, velocity: velocity(72, energy), start: Double(startStep + 1) * step, duration: max(step * 1.4, duration - step)))
            } else {
                notes.append(PianoNote(pitch: target, velocity: velocity(accent ? 78 : 60, energy), start: Double(startStep) * step, duration: duration))
            }

            let echoStep = startStep + 4
            if index == 0 && echoStep < totalSteps && !isResolution && Double.random(in: 0...1) < 0.48 {
                notes.append(PianoNote(pitch: target + hook.echoInterval, velocity: velocity(23, energy), start: Double(echoStep) * step, duration: duration * 0.68))
            }
        }

        if !isResolution && cursor + 15 < totalSteps && Double.random(in: 0...1) < 0.42 {
            let suspension = root + (chord.colorTones.first ?? 10) + baseOctave
            let resolution = root + nearestChordTone(7, in: chord) + baseOctave
            notes.append(PianoNote(pitch: suspension, velocity: velocity(40, energy), start: Double(cursor + 13) * step, duration: step * 1.6))
            notes.append(PianoNote(pitch: resolution, velocity: velocity(56, energy), start: Double(cursor + 15) * step, duration: step * 2.4))
        }

        if isResolution && Bool.random() {
            let finalTone = mood == .bright ? 11 : 10
            notes.append(PianoNote(pitch: keyRoot + finalTone + 12, velocity: velocity(48, 0.55), start: Double(cursor + 10) * step, duration: step * 1.5))
            notes.append(PianoNote(pitch: keyRoot + 12, velocity: velocity(68, 0.55), start: Double(cursor + 12) * step, duration: step * 4.8))
        }
    }

    private func hookMotif(for mood: PhraseMood) -> HookMotif {
        switch mood {
        case .bright:
            return [
                HookMotif(offsets: [0, 3, 7, 12], lengths: [2.1, 2.4, 3.2, 4.0], call: [7, 11, 14, 16], answer: [14, 12, 11, 7], echoInterval: -12),
                HookMotif(offsets: [1, 5, 8, 13], lengths: [2.4, 2.2, 3.0, 3.8], call: [9, 12, 16, 14], answer: [16, 14, 12, 11], echoInterval: -5),
                HookMotif(offsets: [0, 4, 6, 11], lengths: [2.8, 1.8, 2.7, 4.2], call: [11, 12, 16, 14], answer: [14, 11, 9, 7], echoInterval: -12)
            ].randomElement() ?? HookMotif(offsets: [0, 3, 7, 12], lengths: [2.1, 2.4, 3.2, 4.0], call: [7, 11, 14, 16], answer: [14, 12, 11, 7], echoInterval: -12)
        case .mellow:
            return [
                HookMotif(offsets: [0, 4, 7, 12], lengths: [2.8, 2.0, 3.0, 4.0], call: [10, 15, 14, 12], answer: [15, 14, 12, 10], echoInterval: -12),
                HookMotif(offsets: [1, 5, 9, 13], lengths: [2.4, 2.4, 2.8, 3.8], call: [7, 12, 15, 14], answer: [14, 12, 10, 7], echoInterval: -5),
                HookMotif(offsets: [0, 3, 8, 12], lengths: [2.2, 2.4, 3.0, 4.2], call: [12, 17, 15, 14], answer: [15, 14, 12, 10], echoInterval: -12)
            ].randomElement() ?? HookMotif(offsets: [0, 4, 7, 12], lengths: [2.8, 2.0, 3.0, 4.0], call: [10, 15, 14, 12], answer: [15, 14, 12, 10], echoInterval: -12)
        case .midnight:
            return [
                HookMotif(offsets: [0, 5, 8, 13], lengths: [3.0, 2.0, 2.8, 4.0], call: [7, 12, 10, 8], answer: [15, 14, 12, 10], echoInterval: -12),
                HookMotif(offsets: [2, 6, 10, 14], lengths: [2.2, 2.5, 2.5, 3.8], call: [10, 15, 17, 15], answer: [14, 12, 10, 7], echoInterval: -5),
                HookMotif(offsets: [0, 4, 9, 12], lengths: [2.6, 2.1, 3.3, 3.6], call: [12, 10, 15, 14], answer: [12, 10, 8, 7], echoInterval: -12)
            ].randomElement() ?? HookMotif(offsets: [0, 5, 8, 13], lengths: [3.0, 2.0, 2.8, 4.0], call: [7, 12, 10, 8], answer: [15, 14, 12, 10], echoInterval: -12)
        }
    }

    private func hookTone(
        hook: HookMotif,
        barIndex: Int,
        noteIndex: Int,
        mood: PhraseMood,
        isPeak: Bool,
        isResolution: Bool
    ) -> Int {
        let source = (barIndex % 2 == 0 && !isResolution) ? hook.call : hook.answer
        let phraseTurn = barIndex % 4
        let variation: Int
        switch phraseTurn {
        case 1:
            variation = mood == .bright ? -2 : -3
        case 2:
            variation = isPeak ? 2 : 0
        case 3:
            variation = isResolution ? 0 : -5
        default:
            variation = 0
        }
        let peakLift = isPeak && noteIndex == 1 ? 12 : 0
        let endingPull = isResolution && noteIndex >= source.count - 2 ? -2 : 0
        return source[noteIndex % source.count] + variation + peakLift + endingPull
    }

    private func tearfulLean(for mood: PhraseMood, index: Int) -> Int {
        if mood == .bright {
            return [1, 2, -1, 1, -2][index % 5]
        }
        return [1, -1, 2, 1, -2][index % 5]
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
