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
        let leanChance: Double
    }

    private let keys: [(name: String, root: Int)] = [
        ("C", 60), ("D", 62), ("E", 52), ("F", 53), ("G", 55), ("A", 57)
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
        let density = Double.random(in: 0.24...0.42)
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

            if Double.random(in: 0...1) < 0.34 {
                addMelody(
                    chord: chord,
                    keyRoot: key.root,
                    cursor: cursor,
                    totalSteps: totalSteps,
                    step: step,
                    mood: mood,
                    barIndex: barIndex,
                    hook: hook,
                    energy: energy * 0.62,
                    density: density * 0.58,
                    isPeak: isPeak,
                    isResolution: isResolution,
                    notes: &notes
                )
            }
        }

        addSingingLeadLine(
            keyRoot: key.root,
            progression: progression,
            barCount: barCount,
            totalSteps: totalSteps,
            barSteps: barSteps,
            step: step,
            mood: mood,
            energy: 0.92,
            notes: &notes
        )

        let expressiveNotes = applyExpressiveFluctuation(to: notes, step: step, seconds: seconds, leadThreshold: key.root + 12)
        let trimmed = expressiveNotes
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
        let majorI7 = EmotionalChord(name: "I7", root: 0, tones: [0, 4, 7], colorTones: [10], surprise: 0.52, bassMotion: 0)
        let majorIAug = EmotionalChord(name: "Iaug", root: 0, tones: [0, 4, 8], colorTones: [11], surprise: 0.66, bassMotion: 0)
        let majorI6 = EmotionalChord(name: "I6", root: 0, tones: [0, 4, 9], colorTones: [11], surprise: 0.38, bassMotion: 0)
        let majorIOverVII = EmotionalChord(name: "I/B", root: 0, tones: [0, 4, 7], colorTones: [11], surprise: 0.30, bassMotion: 11)
        let majorVPop = EmotionalChord(name: "V", root: 7, tones: [0, 4, 7], colorTones: [9, 14], surprise: 0.18, bassMotion: 7)
        let majorVOverVII = EmotionalChord(name: "V/B", root: 7, tones: [0, 4, 7], colorTones: [10], surprise: 0.34, bassMotion: 11)
        let majorII7 = EmotionalChord(name: "II7", root: 2, tones: [0, 4, 7], colorTones: [10], surprise: 0.62, bassMotion: 2)
        let minorII = EmotionalChord(name: "ii", root: 2, tones: [0, 3, 7], colorTones: [10], surprise: 0.24, bassMotion: 2)
        let minorIIHalfDim = EmotionalChord(name: "iiø", root: 2, tones: [0, 3, 6], colorTones: [10], surprise: 0.76, bassMotion: 2)
        let majorIII = EmotionalChord(name: "iii", root: 4, tones: [0, 3, 7], colorTones: [10], surprise: 0.24, bassMotion: 4)
        let majorIII7 = EmotionalChord(name: "III7", root: 4, tones: [0, 4, 7], colorTones: [10], surprise: 0.76, bassMotion: 4)
        let majorVI = EmotionalChord(name: "vi", root: 9, tones: [0, 3, 7], colorTones: [10, 14], surprise: 0.24, bassMotion: 9)
        let majorIV = EmotionalChord(name: "IV", root: 5, tones: [0, 4, 7], colorTones: [11, 14], surprise: 0.22, bassMotion: 5)
        let majorIVM7 = EmotionalChord(name: "IVM7", root: 5, tones: [0, 4, 7], colorTones: [11], surprise: 0.36, bassMotion: 5)
        let majorIVOverVI = EmotionalChord(name: "IV/A", root: 5, tones: [0, 4, 7], colorTones: [11], surprise: 0.28, bassMotion: 9)
        let minorIVInMajor = EmotionalChord(name: "iv", root: 5, tones: [0, 3, 7], colorTones: [10, 14], surprise: 0.74, bassMotion: 5)
        let minorIV7InMajor = EmotionalChord(name: "iv7", root: 5, tones: [0, 3, 7], colorTones: [10], surprise: 0.78, bassMotion: 5)
        let flatVIInMajor = EmotionalChord(name: "bVI", root: 8, tones: [0, 4, 7], colorTones: [11], surprise: 0.70, bassMotion: 8)
        let passingDim = EmotionalChord(name: "#Idim", root: 1, tones: [0, 3, 6], colorTones: [9], surprise: 0.82, bassMotion: 1)
        let royalProgression = [majorIV, majorVPop, majorIII, majorVI]
        let descendingCanonBass = [majorI, majorVOverVII, majorIVOverVI, majorVPop]
        let unresolvedTwoFive = [minorII, majorV, majorIII, majorVI]
        let subdominantMinorClose = [majorI, minorII, minorIVInMajor, majorI]
        let secondaryDominantLift = [majorI, majorIII7, majorVI, majorVPop]
        let betrayedSecondaryDominant = [majorIV, majorVPop, majorI, majorIII7]
        let subdominantMajorSeven = [majorIVM7, majorIII, majorVI, minorII]
        let brightSecondaryPull = [majorI, majorII7, majorVPop, majorVI]
        let fifthCliche = [majorI, majorIAug, majorI6, majorI7]
        let dimBridge = [majorI, passingDim, minorII, minorIIHalfDim]
        let fullTearProgression = [majorI, majorIOverVII, flatVII, majorIV, minorIV7InMajor, majorIII, minorII, majorV]

        let canonMajor = [majorI, majorVPop, majorVI, majorIII, majorIV, majorI, majorIV, majorV]

        switch mood {
        case .mellow:
            return [
                descendingCanonBass,
                unresolvedTwoFive,
                subdominantMinorClose,
                secondaryDominantLift,
                betrayedSecondaryDominant,
                subdominantMajorSeven,
                fifthCliche,
                dimBridge,
                fullTearProgression,
                royalProgression,
                [minorI, flatVI, minorIV, majorV],
                [majorI, majorVI, minorIVInMajor, majorVPop],
                [minorI, flatIII, flatVI, majorV],
                [majorI, flatVIInMajor, minorIVInMajor, majorVPop]
            ].randomElement() ?? [minorI, flatVI, minorIV, majorV]
        case .bright:
            return [
                descendingCanonBass,
                unresolvedTwoFive,
                secondaryDominantLift,
                betrayedSecondaryDominant,
                subdominantMajorSeven,
                brightSecondaryPull,
                fifthCliche,
                royalProgression,
                [majorI, majorVI, minorIVInMajor, majorVPop],
                [majorI, majorVPop, majorVI, minorIVInMajor],
                [majorI, flatVIInMajor, borrowedIV, majorVPop],
                Array(canonMajor.prefix(4))
            ].randomElement() ?? [majorI, majorVI, minorIVInMajor, majorVPop]
        case .midnight:
            return [
                unresolvedTwoFive,
                subdominantMinorClose,
                dimBridge,
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
        let baseOctave: Int
        switch mood {
        case .bright:
            baseOctave = isPeak ? 12 : 7
        case .mellow:
            baseOctave = 12
        case .midnight:
            baseOctave = isPeak ? 7 : 0
        }

        for index in motifOffsets.indices {
            let startStep = cursor + motifOffsets[index]
            guard startStep < totalSteps else { continue }

            let keepChance = hook.offsets.count == 3 ? 0.86 : min(0.74, density + 0.24)
            if index > 2 && Double.random(in: 0...1) > keepChance {
                continue
            }

            let targetTone = hookTone(hook: hook, barIndex: barIndex, noteIndex: index, mood: mood, isPeak: isPeak, isResolution: isResolution)
            let target = keyRoot + targetTone + baseOctave
            let duration = motifLengths[index % motifLengths.count] * step * Double.random(in: 0.75...1.08)
            let accent = index == 0 || index == motifOffsets.count - 1 || chord.surprise > 0.55

            if accent && startStep + 1 < totalSteps && Double.random(in: 0...1) < hook.leanChance {
                let lean = tearfulLean(for: mood, index: index)
                notes.append(PianoNote(pitch: target + lean, velocity: velocity(32, energy), start: Double(startStep) * step, duration: step * 0.85))
                notes.append(PianoNote(pitch: target, velocity: velocity(42, energy), start: Double(startStep + 1) * step, duration: max(step * 1.4, duration - step)))
            } else {
                notes.append(PianoNote(pitch: target, velocity: velocity(accent ? 44 : 34, energy), start: Double(startStep) * step, duration: duration))
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
            notes.append(PianoNote(pitch: keyRoot + finalTone + 12, velocity: velocity(44, 0.55), start: Double(cursor + 8) * step, duration: step * 1.4))
            notes.append(PianoNote(pitch: keyRoot + finalTone + 11, velocity: velocity(50, 0.55), start: Double(cursor + 10) * step, duration: step * 1.5))
            notes.append(PianoNote(pitch: keyRoot + 12, velocity: velocity(68, 0.55), start: Double(cursor + 12) * step, duration: step * 4.8))
        }
    }

    private func hookMotif(for mood: PhraseMood) -> HookMotif {
        switch mood {
        case .bright:
            return [
                HookMotif(offsets: [0, 2, 5, 8, 10, 13], lengths: [1.6, 1.6, 3.4, 1.6, 1.6, 4.4], call: [9, 11, 16, 9, 12, 14], answer: [14, 12, 16, 11, 9, 7], echoInterval: -12, leanChance: 0.70),
                HookMotif(offsets: [0, 6, 11], lengths: [4.8, 2.4, 5.2], call: [11, 19, 16], answer: [18, 16, 11], echoInterval: -12, leanChance: 0.72),
                HookMotif(offsets: [1, 3, 7, 10, 14], lengths: [1.4, 2.2, 2.8, 1.8, 3.8], call: [7, 12, 11, 16, 14], answer: [16, 14, 12, 11, 7], echoInterval: -5, leanChance: 0.62),
                HookMotif(offsets: [0, 4, 9, 13], lengths: [3.4, 2.2, 2.8, 4.6], call: [14, 11, 16, 14], answer: [12, 9, 11, 7], echoInterval: -12, leanChance: 0.80),
                HookMotif(offsets: [2, 8, 12], lengths: [5.0, 2.2, 5.0], call: [16, 14, 12], answer: [11, 7, 9], echoInterval: -7, leanChance: 0.56)
            ].randomElement() ?? HookMotif(offsets: [0, 6, 11], lengths: [4.8, 2.4, 5.2], call: [11, 19, 16], answer: [18, 16, 11], echoInterval: -12, leanChance: 0.72)
        case .mellow:
            return [
                HookMotif(offsets: [0, 2, 5, 8, 10, 13], lengths: [1.7, 1.7, 3.8, 1.7, 1.7, 4.8], call: [10, 12, 15, 10, 12, 14], answer: [15, 14, 12, 10, 8, 7], echoInterval: -12, leanChance: 0.82),
                HookMotif(offsets: [0, 2, 5, 8, 10, 13], lengths: [1.7, 1.7, 3.8, 1.7, 1.7, 4.8], call: [10, 12, 15, 10, 12, 14], answer: [15, 14, 12, 10, 8, 7], echoInterval: -12, leanChance: 0.82),
                HookMotif(offsets: [1, 3, 6, 9, 11, 14], lengths: [1.6, 1.8, 3.6, 1.5, 1.8, 4.6], call: [7, 10, 15, 8, 10, 14], answer: [15, 14, 10, 12, 10, 7], echoInterval: -5, leanChance: 0.78),
                HookMotif(offsets: [1, 3, 6, 9, 11, 14], lengths: [1.6, 1.8, 3.6, 1.5, 1.8, 4.6], call: [7, 10, 15, 8, 10, 14], answer: [15, 14, 10, 12, 10, 7], echoInterval: -5, leanChance: 0.78),
                HookMotif(offsets: [0, 6, 10], lengths: [5.2, 2.0, 5.4], call: [10, 19, 17], answer: [15, 14, 10], echoInterval: -12, leanChance: 0.74),
                HookMotif(offsets: [1, 5, 8, 12, 15], lengths: [2.6, 1.7, 2.4, 2.0, 3.6], call: [15, 14, 12, 10, 7], answer: [12, 10, 8, 7, 3], echoInterval: -5, leanChance: 0.86),
                HookMotif(offsets: [0, 3, 9, 13], lengths: [2.0, 3.4, 2.2, 5.0], call: [7, 15, 14, 12], answer: [17, 15, 14, 10], echoInterval: -12, leanChance: 0.70),
                HookMotif(offsets: [2, 7, 11], lengths: [4.4, 2.6, 5.2], call: [12, 10, 15], answer: [14, 12, 7], echoInterval: -7, leanChance: 0.58)
            ].randomElement() ?? HookMotif(offsets: [0, 6, 10], lengths: [5.2, 2.0, 5.4], call: [10, 19, 17], answer: [15, 14, 10], echoInterval: -12, leanChance: 0.74)
        case .midnight:
            return [
                HookMotif(offsets: [0, 2, 5, 8, 10, 13], lengths: [1.8, 1.6, 4.0, 1.8, 1.6, 5.0], call: [10, 12, 15, 10, 12, 14], answer: [17, 15, 14, 12, 10, 7], echoInterval: -12, leanChance: 0.84),
                HookMotif(offsets: [0, 2, 5, 8, 10, 13], lengths: [1.8, 1.6, 4.0, 1.8, 1.6, 5.0], call: [10, 12, 15, 10, 12, 14], answer: [17, 15, 14, 12, 10, 7], echoInterval: -12, leanChance: 0.84),
                HookMotif(offsets: [1, 4, 6, 10, 12, 15], lengths: [2.0, 1.5, 3.6, 1.8, 1.7, 4.8], call: [7, 10, 14, 8, 10, 12], answer: [15, 14, 12, 10, 8, 7], echoInterval: -5, leanChance: 0.80),
                HookMotif(offsets: [1, 4, 6, 10, 12, 15], lengths: [2.0, 1.5, 3.6, 1.8, 1.7, 4.8], call: [7, 10, 14, 8, 10, 12], answer: [15, 14, 12, 10, 8, 7], echoInterval: -5, leanChance: 0.80),
                HookMotif(offsets: [0, 7, 12], lengths: [5.6, 2.2, 5.4], call: [7, 17, 15], answer: [14, 10, 7], echoInterval: -12, leanChance: 0.72),
                HookMotif(offsets: [2, 5, 9, 13, 15], lengths: [1.8, 2.6, 2.4, 1.7, 3.6], call: [10, 15, 14, 12, 10], answer: [14, 12, 10, 8, 7], echoInterval: -5, leanChance: 0.88),
                HookMotif(offsets: [0, 4, 10], lengths: [3.2, 3.8, 5.2], call: [12, 8, 15], answer: [14, 12, 7], echoInterval: -12, leanChance: 0.64),
                HookMotif(offsets: [1, 6, 8, 14], lengths: [2.8, 1.6, 3.0, 4.2], call: [15, 10, 12, 8], answer: [17, 15, 14, 10], echoInterval: -7, leanChance: 0.78)
            ].randomElement() ?? HookMotif(offsets: [0, 7, 12], lengths: [5.6, 2.2, 5.4], call: [7, 17, 15], answer: [14, 10, 7], echoInterval: -12, leanChance: 0.72)
        }
    }

    private func addSingingLeadLine(
        keyRoot: Int,
        progression: [EmotionalChord],
        barCount: Int,
        totalSteps: Int,
        barSteps: Int,
        step: Double,
        mood: PhraseMood,
        energy: Double,
        notes: inout [PianoNote]
    ) {
        let shape = singingShape(for: mood, totalSteps: totalSteps, barSteps: barSteps)
        let baseOctave: Int
        switch mood {
        case .bright:
            baseOctave = 12
        case .mellow:
            baseOctave = Bool.random() ? 12 : 7
        case .midnight:
            baseOctave = 0
        }

        for index in shape.indices {
            let event = shape[index]
            guard event.step < totalSteps else { continue }

            let chord = chordForLeadEvent(event, progression: progression, barCount: barCount, barSteps: barSteps, mood: mood)
            let tone = chordAwareLeadTone(for: event, chord: chord, mood: mood)
            let pitch = keyRoot + tone + baseOctave
            let start = Double(event.step) * step
            let duration = Double(event.length) * step
            let isPeak = event.role == .peak
            let isRelease = event.role == .release
            let isFinal = index == shape.indices.last

            if event.role == .lean && event.step + 1 < totalSteps {
                notes.append(PianoNote(pitch: pitch + event.lean, velocity: velocity(54, energy), start: start, duration: step * 0.85))
                notes.append(PianoNote(pitch: pitch, velocity: velocity(78, energy), start: Double(event.step + 1) * step, duration: max(step * 1.8, duration - step)))
            } else {
                if isRelease && event.step > 1 {
                    let sighStart = max(0, Double(event.step) * step - step * 0.72)
                    notes.append(PianoNote(pitch: pitch + 1, velocity: velocity(42, energy), start: sighStart, duration: step * 0.62))
                }
                let baseVelocity = isPeak ? 86 : (isRelease || isFinal ? 74 : 66)
                notes.append(PianoNote(pitch: pitch, velocity: velocity(baseVelocity, energy), start: start, duration: duration))
            }

            if isPeak && event.step + 3 < totalSteps {
                notes.append(PianoNote(pitch: pitch - 12, velocity: velocity(26, 0.52), start: Double(event.step + 3) * step, duration: duration * 0.42))
            }
        }
    }

    private func singingShape(for mood: PhraseMood, totalSteps: Int, barSteps: Int) -> [LeadEvent] {
        let bars = max(1, totalSteps / barSteps)
        let lastStep = max(0, totalSteps - 3)
        var events: [LeadEvent] = []
        let sentenceCount = max(1, Int(ceil(Double(bars) / 2.0)))

        for sentence in 0..<sentenceCount {
            let base = sentence * barSteps * 2
            guard base < totalSteps else { continue }
            let isFinalSentence = sentence == sentenceCount - 1
            let isPeakSentence = sentence == min(sentenceCount - 1, max(1, sentenceCount / 2))

            let pattern = singingPattern(for: mood, variant: sentence, isPeak: isPeakSentence, isFinal: isFinalSentence)
            for event in pattern {
                let step = min(lastStep, base + event.step)
                guard step < totalSteps else { continue }
                events.append(LeadEvent(step: step, tone: event.tone, length: event.length, role: event.role, lean: event.lean))
            }
        }

        return events.sorted {
            if $0.step == $1.step {
                return $0.tone < $1.tone
            }
            return $0.step < $1.step
        }
    }

    private func singingPattern(for mood: PhraseMood, variant: Int, isPeak: Bool, isFinal: Bool) -> [LeadEvent] {
        switch mood {
        case .mellow:
            if isFinal {
                return [
                    LeadEvent(step: 0, tone: 12, length: 4, role: .plain, lean: 0),
                    LeadEvent(step: 6, tone: 15, length: 2, role: .lean, lean: -1),
                    LeadEvent(step: 9, tone: 14, length: 3, role: .release, lean: 0),
                    LeadEvent(step: 15, tone: 10, length: 5, role: .release, lean: 0),
                    LeadEvent(step: 24, tone: 7, length: 8, role: .release, lean: 0)
                ]
            }
            if isPeak {
                return [
                    LeadEvent(step: 0, tone: 10, length: 4, role: .plain, lean: 0),
                    LeadEvent(step: 6, tone: 14, length: 2, role: .lean, lean: 1),
                    LeadEvent(step: 9, tone: 17, length: 6, role: .peak, lean: 0),
                    LeadEvent(step: 17, tone: 15, length: 4, role: .release, lean: 0),
                    LeadEvent(step: 25, tone: 12, length: 6, role: .release, lean: 0)
                ]
            }
            return variant.isMultiple(of: 2) ? [
                LeadEvent(step: 0, tone: 7, length: 5, role: .plain, lean: 0),
                LeadEvent(step: 7, tone: 10, length: 2, role: .lean, lean: 1),
                LeadEvent(step: 10, tone: 12, length: 5, role: .plain, lean: 0),
                LeadEvent(step: 18, tone: 10, length: 3, role: .release, lean: 0),
                LeadEvent(step: 25, tone: 8, length: 5, role: .release, lean: 0)
            ] : [
                LeadEvent(step: 1, tone: 10, length: 4, role: .plain, lean: 0),
                LeadEvent(step: 8, tone: 12, length: 3, role: .lean, lean: -1),
                LeadEvent(step: 13, tone: 7, length: 5, role: .release, lean: 0),
                LeadEvent(step: 22, tone: 10, length: 4, role: .plain, lean: 0),
                LeadEvent(step: 27, tone: 7, length: 5, role: .release, lean: 0)
            ]
        case .bright:
            if isFinal {
                return [
                    LeadEvent(step: 0, tone: 11, length: 4, role: .plain, lean: 0),
                    LeadEvent(step: 6, tone: 14, length: 3, role: .plain, lean: 0),
                    LeadEvent(step: 12, tone: 12, length: 4, role: .release, lean: 0),
                    LeadEvent(step: 21, tone: 7, length: 8, role: .release, lean: 0)
                ]
            }
            if isPeak {
                return [
                    LeadEvent(step: 0, tone: 9, length: 3, role: .plain, lean: 0),
                    LeadEvent(step: 5, tone: 12, length: 2, role: .lean, lean: 1),
                    LeadEvent(step: 8, tone: 16, length: 5, role: .peak, lean: 0),
                    LeadEvent(step: 16, tone: 14, length: 4, role: .release, lean: 0),
                    LeadEvent(step: 24, tone: 11, length: 6, role: .release, lean: 0)
                ]
            }
            return variant.isMultiple(of: 2) ? [
                LeadEvent(step: 0, tone: 7, length: 4, role: .plain, lean: 0),
                LeadEvent(step: 6, tone: 11, length: 3, role: .plain, lean: 0),
                LeadEvent(step: 12, tone: 12, length: 4, role: .plain, lean: 0),
                LeadEvent(step: 21, tone: 9, length: 6, role: .release, lean: 0)
            ] : [
                LeadEvent(step: 1, tone: 12, length: 4, role: .plain, lean: 0),
                LeadEvent(step: 8, tone: 16, length: 3, role: .plain, lean: 0),
                LeadEvent(step: 13, tone: 14, length: 3, role: .release, lean: 0),
                LeadEvent(step: 22, tone: 11, length: 6, role: .release, lean: 0)
            ]
        case .midnight:
            if isFinal {
                return [
                    LeadEvent(step: 0, tone: 10, length: 6, role: .plain, lean: 0),
                    LeadEvent(step: 10, tone: 12, length: 2, role: .lean, lean: -1),
                    LeadEvent(step: 15, tone: 8, length: 6, role: .release, lean: 0),
                    LeadEvent(step: 25, tone: 3, length: 8, role: .release, lean: 0)
                ]
            }
            if isPeak {
                return [
                    LeadEvent(step: 0, tone: 7, length: 6, role: .plain, lean: 0),
                    LeadEvent(step: 10, tone: 12, length: 2, role: .lean, lean: 1),
                    LeadEvent(step: 14, tone: 15, length: 6, role: .peak, lean: 0),
                    LeadEvent(step: 24, tone: 11, length: 7, role: .release, lean: 0)
                ]
            }
            return variant.isMultiple(of: 2) ? [
                LeadEvent(step: 0, tone: 5, length: 6, role: .plain, lean: 0),
                LeadEvent(step: 10, tone: 7, length: 5, role: .plain, lean: 0),
                LeadEvent(step: 20, tone: 10, length: 6, role: .plain, lean: 0)
            ] : [
                LeadEvent(step: 2, tone: 10, length: 5, role: .plain, lean: 0),
                LeadEvent(step: 11, tone: 8, length: 5, role: .release, lean: 0),
                LeadEvent(step: 22, tone: 7, length: 7, role: .release, lean: 0)
            ]
        }
    }

    private enum LeadRole {
        case plain
        case lean
        case peak
        case release
    }

    private struct LeadEvent {
        let step: Int
        let tone: Int
        let length: Int
        let role: LeadRole
        let lean: Int
    }

    private func cryingShape(for mood: PhraseMood, totalSteps: Int, barSteps: Int) -> [LeadEvent] {
        let bars = max(1, totalSteps / barSteps)
        let phraseEnd = max(0, totalSteps - 3)

        if bars <= 2 {
            switch mood {
            case .bright:
                let variants: [[LeadEvent]] = [
                    [
                        LeadEvent(step: 0, tone: 7, length: 3, role: .plain, lean: 0),
                        LeadEvent(step: 4, tone: 11, length: 2, role: .lean, lean: 1),
                        LeadEvent(step: 7, tone: 16, length: 5, role: .peak, lean: 0),
                        LeadEvent(step: 13, tone: 14, length: 3, role: .release, lean: 0),
                        LeadEvent(step: 18, tone: 12, length: 2, role: .lean, lean: -1),
                        LeadEvent(step: min(phraseEnd, 25), tone: 9, length: 6, role: .release, lean: 0)
                    ],
                    [
                        LeadEvent(step: 1, tone: 11, length: 3, role: .plain, lean: 0),
                        LeadEvent(step: 5, tone: 14, length: 2, role: .lean, lean: 1),
                        LeadEvent(step: 8, tone: 17, length: 4, role: .peak, lean: 0),
                        LeadEvent(step: 14, tone: 16, length: 2, role: .lean, lean: -1),
                        LeadEvent(step: 17, tone: 12, length: 5, role: .release, lean: 0),
                        LeadEvent(step: min(phraseEnd, 27), tone: 7, length: 5, role: .release, lean: 0)
                    ]
                ]
                return variants.randomElement() ?? variants[0]
            case .mellow:
                let variants: [[LeadEvent]] = [
                    [
                        LeadEvent(step: 0, tone: 10, length: 2, role: .lean, lean: 1),
                        LeadEvent(step: 3, tone: 12, length: 3, role: .plain, lean: 0),
                        LeadEvent(step: 7, tone: 15, length: 6, role: .peak, lean: 0),
                        LeadEvent(step: 14, tone: 14, length: 2, role: .lean, lean: -1),
                        LeadEvent(step: 17, tone: 10, length: 5, role: .release, lean: 0),
                        LeadEvent(step: min(phraseEnd, 27), tone: 7, length: 6, role: .release, lean: 0)
                    ],
                    [
                        LeadEvent(step: 1, tone: 7, length: 4, role: .plain, lean: 0),
                        LeadEvent(step: 6, tone: 12, length: 2, role: .lean, lean: 1),
                        LeadEvent(step: 9, tone: 14, length: 5, role: .peak, lean: 0),
                        LeadEvent(step: 15, tone: 12, length: 4, role: .release, lean: 0),
                        LeadEvent(step: 21, tone: 8, length: 2, role: .lean, lean: -1),
                        LeadEvent(step: min(phraseEnd, 27), tone: 5, length: 6, role: .release, lean: 0)
                    ]
                ]
                return variants.randomElement() ?? variants[0]
            case .midnight:
                let variants: [[LeadEvent]] = [
                    [
                        LeadEvent(step: 0, tone: 5, length: 5, role: .plain, lean: 0),
                        LeadEvent(step: 7, tone: 10, length: 2, role: .lean, lean: 1),
                        LeadEvent(step: 10, tone: 14, length: 6, role: .peak, lean: 0),
                        LeadEvent(step: 18, tone: 12, length: 5, role: .release, lean: 0),
                        LeadEvent(step: min(phraseEnd, 27), tone: 7, length: 7, role: .release, lean: 0)
                    ],
                    [
                        LeadEvent(step: 2, tone: 7, length: 4, role: .plain, lean: 0),
                        LeadEvent(step: 9, tone: 12, length: 6, role: .peak, lean: 0),
                        LeadEvent(step: 16, tone: 11, length: 2, role: .lean, lean: -1),
                        LeadEvent(step: 20, tone: 8, length: 5, role: .release, lean: 0),
                        LeadEvent(step: min(phraseEnd, 28), tone: 3, length: 7, role: .release, lean: 0)
                    ]
                ]
                return variants.randomElement() ?? variants[0]
            }
        }

        let peakStep = min(totalSteps - 12, barSteps * max(1, bars - 2) + 5)
        switch mood {
        case .bright:
            let variants: [[LeadEvent]] = [
                [
                    LeadEvent(step: 0, tone: 7, length: 3, role: .plain, lean: 0),
                    LeadEvent(step: 4, tone: 11, length: 2, role: .lean, lean: 1),
                    LeadEvent(step: 7, tone: 16, length: 5, role: .peak, lean: 0),
                    LeadEvent(step: 14, tone: 14, length: 4, role: .release, lean: 0),
                    LeadEvent(step: barSteps + 3, tone: 12, length: 3, role: .plain, lean: 0),
                    LeadEvent(step: peakStep, tone: 17, length: 6, role: .peak, lean: 0),
                    LeadEvent(step: peakStep + 8, tone: 16, length: 2, role: .lean, lean: -1),
                    LeadEvent(step: peakStep + 12, tone: 12, length: 5, role: .release, lean: 0),
                    LeadEvent(step: phraseEnd, tone: 9, length: 6, role: .release, lean: 0)
                ],
                [
                    LeadEvent(step: 2, tone: 11, length: 4, role: .plain, lean: 0),
                    LeadEvent(step: 8, tone: 14, length: 2, role: .lean, lean: 1),
                    LeadEvent(step: 11, tone: 17, length: 4, role: .peak, lean: 0),
                    LeadEvent(step: barSteps + 2, tone: 16, length: 3, role: .release, lean: 0),
                    LeadEvent(step: barSteps + 8, tone: 12, length: 5, role: .plain, lean: 0),
                    LeadEvent(step: peakStep + 2, tone: 14, length: 5, role: .peak, lean: 0),
                    LeadEvent(step: peakStep + 9, tone: 11, length: 5, role: .release, lean: 0),
                    LeadEvent(step: phraseEnd, tone: 7, length: 6, role: .release, lean: 0)
                ]
            ]
            return variants.randomElement() ?? variants[0]
        case .mellow:
            let variants: [[LeadEvent]] = [
                [
                    LeadEvent(step: 0, tone: 10, length: 2, role: .lean, lean: 1),
                    LeadEvent(step: 3, tone: 12, length: 4, role: .plain, lean: 0),
                    LeadEvent(step: 9, tone: 15, length: 6, role: .peak, lean: 0),
                    LeadEvent(step: barSteps + 1, tone: 14, length: 3, role: .release, lean: 0),
                    LeadEvent(step: barSteps + 7, tone: 10, length: 4, role: .plain, lean: 0),
                    LeadEvent(step: peakStep, tone: 17, length: 6, role: .peak, lean: 0),
                    LeadEvent(step: peakStep + 8, tone: 15, length: 5, role: .release, lean: 0),
                    LeadEvent(step: phraseEnd - 5, tone: 10, length: 2, role: .lean, lean: -1),
                    LeadEvent(step: phraseEnd, tone: 7, length: 7, role: .release, lean: 0)
                ],
                [
                    LeadEvent(step: 1, tone: 7, length: 5, role: .plain, lean: 0),
                    LeadEvent(step: 8, tone: 12, length: 2, role: .lean, lean: 1),
                    LeadEvent(step: 11, tone: 14, length: 5, role: .peak, lean: 0),
                    LeadEvent(step: barSteps + 5, tone: 12, length: 5, role: .release, lean: 0),
                    LeadEvent(step: peakStep - 2, tone: 15, length: 6, role: .peak, lean: 0),
                    LeadEvent(step: peakStep + 6, tone: 14, length: 2, role: .lean, lean: -1),
                    LeadEvent(step: peakStep + 10, tone: 10, length: 6, role: .release, lean: 0),
                    LeadEvent(step: phraseEnd, tone: 5, length: 8, role: .release, lean: 0)
                ],
                [
                    LeadEvent(step: 0, tone: 12, length: 4, role: .plain, lean: 0),
                    LeadEvent(step: 6, tone: 15, length: 2, role: .lean, lean: -1),
                    LeadEvent(step: 10, tone: 10, length: 5, role: .release, lean: 0),
                    LeadEvent(step: barSteps + 4, tone: 8, length: 4, role: .plain, lean: 0),
                    LeadEvent(step: peakStep, tone: 15, length: 7, role: .peak, lean: 0),
                    LeadEvent(step: peakStep + 9, tone: 12, length: 5, role: .release, lean: 0),
                    LeadEvent(step: phraseEnd - 3, tone: 10, length: 2, role: .lean, lean: -1),
                    LeadEvent(step: phraseEnd, tone: 7, length: 7, role: .release, lean: 0)
                ]
            ]
            return variants.randomElement() ?? variants[0]
        case .midnight:
            let variants: [[LeadEvent]] = [
                [
                    LeadEvent(step: 0, tone: 5, length: 6, role: .plain, lean: 0),
                    LeadEvent(step: 9, tone: 10, length: 2, role: .lean, lean: 1),
                    LeadEvent(step: 12, tone: 14, length: 7, role: .peak, lean: 0),
                    LeadEvent(step: barSteps + 8, tone: 12, length: 6, role: .release, lean: 0),
                    LeadEvent(step: peakStep + 1, tone: 15, length: 6, role: .peak, lean: 0),
                    LeadEvent(step: peakStep + 9, tone: 11, length: 6, role: .release, lean: 0),
                    LeadEvent(step: phraseEnd, tone: 7, length: 8, role: .release, lean: 0)
                ],
                [
                    LeadEvent(step: 2, tone: 7, length: 5, role: .plain, lean: 0),
                    LeadEvent(step: barSteps - 2, tone: 12, length: 6, role: .peak, lean: 0),
                    LeadEvent(step: barSteps + 7, tone: 11, length: 2, role: .lean, lean: -1),
                    LeadEvent(step: barSteps + 11, tone: 8, length: 6, role: .release, lean: 0),
                    LeadEvent(step: peakStep + 3, tone: 14, length: 6, role: .peak, lean: 0),
                    LeadEvent(step: peakStep + 11, tone: 10, length: 7, role: .release, lean: 0),
                    LeadEvent(step: phraseEnd, tone: 3, length: 8, role: .release, lean: 0)
                ]
            ]
            return variants.randomElement() ?? variants[0]
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
        let peakLift = isPeak && noteIndex == 1 ? 5 : 0
        let endingPull = isResolution && noteIndex >= source.count - 2 ? -2 : 0
        return source[noteIndex % source.count] + variation + peakLift + endingPull
    }

    private func tearfulLean(for mood: PhraseMood, index: Int) -> Int {
        if mood == .bright {
            return [1, 2, -1, 1, -2][index % 5]
        }
        return [1, -1, 2, 1, -2][index % 5]
    }

    private func chordForLeadEvent(
        _ event: LeadEvent,
        progression: [EmotionalChord],
        barCount: Int,
        barSteps: Int,
        mood: PhraseMood
    ) -> EmotionalChord {
        let barIndex = max(0, min(barCount - 1, event.step / barSteps))
        if barIndex >= barCount - 1 {
            return resolutionChord(for: mood)
        }
        return progression[barIndex % progression.count]
    }

    private func chordAwareLeadTone(for event: LeadEvent, chord: EmotionalChord, mood: PhraseMood) -> Int {
        let chordTones = chord.tones.map { chord.root + $0 }
        let colorTones = chord.colorTones.map { chord.root + $0 }
        let roleTones: [Int]

        switch event.role {
        case .release:
            roleTones = chordTones
        case .peak:
            roleTones = chordTones + colorTones + mood.scale.map { $0 + 12 }
        case .lean, .plain:
            roleTones = chordTones + colorTones
        }

        let candidates = roleTones.flatMap { tone in
            [tone - 12, tone, tone + 12, tone + 24]
        }.filter { tone in
            tone >= 0 && tone <= 24
        }

        return candidates.min { first, second in
            abs(first - event.tone) < abs(second - event.tone)
        } ?? event.tone
    }

    private func applyExpressiveFluctuation(to notes: [PianoNote], step: Double, seconds: Double, leadThreshold: Int) -> [PianoNote] {
        let ordered = notes.sorted {
            if $0.start == $1.start {
                return $0.pitch < $1.pitch
            }
            return $0.start < $1.start
        }
        var timingDrift = 0.0
        var velocityDrift = 0.0

        return ordered.enumerated().map { index, note in
            let isLead = note.pitch >= leadThreshold
            timingDrift = timingDrift * 0.86 + Double.random(in: isLead ? -0.026...0.026 : -0.014...0.014)
            velocityDrift = velocityDrift * 0.82 + Double.random(in: -2.8...2.8)

            let longWave = sin(Double(index) * 0.47) * (isLead ? 0.085 : 0.045)
            let start = max(0, min(seconds - 0.05, note.start + timingDrift))
            let durationScale = max(0.72, min(1.34, 0.98 + longWave + Double.random(in: -0.035...0.055)))
            let velocity = max(1, min(127, note.velocity + Int(velocityDrift.rounded())))

            return PianoNote(
                pitch: note.pitch,
                velocity: velocity,
                start: start,
                duration: max(step * 0.45, min(note.duration * durationScale, seconds - start))
            )
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
