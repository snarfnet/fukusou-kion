import SwiftUI

struct VoiceArtworkView: View {
    var artwork: VoiceArtwork?
    var liveLevel: Double = 0
    var livePitch: Double = 0
    var isRecording: Bool = false

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let rect = CGRect(origin: .zero, size: size)
                let phase = timeline.date.timeIntervalSinceReferenceDate
                drawBackground(in: &context, rect: rect)

                if let artwork {
                    drawArtwork(artwork, in: &context, size: size)
                } else {
                    drawIdle(level: liveLevel, pitch: livePitch, phase: phase, isRecording: isRecording, in: &context, size: size)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(.white.opacity(0.12), lineWidth: 1)
        }
    }

    private func drawBackground(in context: inout GraphicsContext, rect: CGRect) {
        let gradient = Gradient(colors: [
            Color(red: 0.018, green: 0.018, blue: 0.026),
            Color(red: 0.016, green: 0.06, blue: 0.072),
            Color(red: 0.06, green: 0.025, blue: 0.055)
        ])
        context.fill(Path(rect), with: .linearGradient(gradient, startPoint: rect.origin, endPoint: CGPoint(x: rect.maxX, y: rect.maxY)))
    }

    private func drawIdle(level: Double, pitch: Double, phase: Double, isRecording: Bool, in context: inout GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) * CGFloat(0.18 + level * 0.18)

        if isRecording {
            drawTremblingWaveform(level: level, pitch: pitch, phase: phase, center: center, in: &context, size: size)
        }

        for ring in 0..<5 {
            var path = Path()
            let steps = 160
            let ringRadius = radius + CGFloat(ring) * 24
            for step in 0...steps {
                let t = Double(step) / Double(steps)
                let angle = t * .pi * 2
                let tremor = isRecording ? sin(phase * 8 + angle * 17) * level * 12 : 0
                let wobble = CGFloat(sin(angle * 5 + level * 8 + Double(ring)) * 10 + tremor)
                let point = CGPoint(
                    x: center.x + CGFloat(cos(angle)) * (ringRadius + wobble),
                    y: center.y + CGFloat(sin(angle)) * (ringRadius + wobble)
                )
                step == 0 ? path.move(to: point) : path.addLine(to: point)
            }
            context.stroke(path, with: .color(ringColor(ring).opacity(0.28 + level * 0.35)), lineWidth: 1.5)
        }

        let dotCount = 38
        for index in 0..<dotCount {
            let angle = Double(index) / Double(dotCount) * .pi * 2
            let distance = radius * 0.7 + CGFloat(index % 7) * 14 + CGFloat(pitch / 38)
            let dot = CGRect(
                x: center.x + CGFloat(cos(angle)) * distance - 2,
                y: center.y + CGFloat(sin(angle)) * distance - 2,
                width: CGFloat(4 + level * 6),
                height: CGFloat(4 + level * 6)
            )
            context.fill(Path(ellipseIn: dot), with: .color(Color.white.opacity(0.16 + level * 0.32)))
        }
    }

    private func drawTremblingWaveform(level: Double, pitch: Double, phase: Double, center: CGPoint, in context: inout GraphicsContext, size: CGSize) {
        let width = size.width * 0.82
        let startX = center.x - width / 2
        let baseAmplitude = size.height * CGFloat(0.045 + level * 0.16)
        let lines = 3

        for line in 0..<lines {
            var path = Path()
            let steps = 180
            let yOffset = CGFloat(line - 1) * size.height * 0.045
            let frequency = 2.5 + Double(line) * 1.7 + min(5, pitch / 180)
            for step in 0...steps {
                let t = Double(step) / Double(steps)
                let x = startX + width * CGFloat(t)
                let tremble = sin(t * .pi * 2 * frequency + phase * 10)
                let micro = sin(t * .pi * 2 * 31 + phase * 23 + Double(line)) * 0.32
                let pulse = sin(phase * 5 + t * .pi * 4) * level
                let y = center.y + yOffset + CGFloat(tremble + micro + pulse) * baseAmplitude
                step == 0 ? path.move(to: CGPoint(x: x, y: y)) : path.addLine(to: CGPoint(x: x, y: y))
            }
            let color: Color = line == 0 ? .cyan : (line == 1 ? .white : .pink)
            context.stroke(path, with: .color(color.opacity(0.26 + level * 0.42)), lineWidth: CGFloat(1.8 + level * 5))
        }

        let glow = CGRect(x: center.x - size.width * 0.18, y: center.y - size.height * 0.18, width: size.width * 0.36, height: size.height * 0.36)
        context.fill(Path(ellipseIn: glow), with: .radialGradient(Gradient(colors: [.white.opacity(0.12 + level * 0.22), .cyan.opacity(0.08), .clear]), center: center, startRadius: 0, endRadius: size.width * 0.2))
    }

    private func drawArtwork(_ artwork: VoiceArtwork, in context: inout GraphicsContext, size: CGSize) {
        let features = artwork.features
        let palette = artwork.palette
        let style = artwork.style
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let short = min(size.width, size.height)
        var rng = SeededRandomNumberGenerator(seed: artwork.seed)

        let backgroundRect = CGRect(origin: .zero, size: size)
        context.fill(
            Path(backgroundRect),
            with: .radialGradient(
                Gradient(colors: [palette.backgroundA.opacity(0.92), palette.backgroundB.opacity(0.78), .black.opacity(0.95)]),
                center: center,
                startRadius: 10,
                endRadius: short * 0.82
            )
        )

        drawModernGround(features, palette: palette, size: size, in: &context, rng: &rng)

        switch style.family {
        case .bloom:
            drawBloomArtwork(features, palette: palette, style: style, center: center, short: short, in: &context, rng: &rng)
        case .aurora:
            drawAuroraArtwork(features, palette: palette, style: style, size: size, in: &context, rng: &rng)
        case .topography:
            drawTopographyArtwork(features, palette: palette, style: style, size: size, in: &context, rng: &rng)
        case .calligraphy:
            drawCalligraphyArtwork(features, palette: palette, style: style, center: center, short: short, in: &context, rng: &rng)
        case .mist:
            drawMistArtwork(features, palette: palette, style: style, size: size, in: &context, rng: &rng)
        case .nebula:
            drawNebulaArtwork(features, palette: palette, style: style, center: center, short: short, in: &context, rng: &rng)
        case .figure:
            drawFigureArtwork(features, palette: palette, style: style, center: center, short: short, in: &context, rng: &rng)
        case .organism:
            drawOrganismArtwork(features, palette: palette, style: style, center: center, short: short, in: &context, rng: &rng)
        case .spirit:
            drawSpiritArtwork(features, palette: palette, style: style, center: center, short: short, in: &context, rng: &rng)
        }

        drawCreatureMotif(features, palette: palette, style: style, center: center, short: short, in: &context, rng: &rng)
        drawCreatureParts(features, palette: palette, style: style, center: center, short: short, in: &context, rng: &rng)
        drawGrain(palette: palette, size: size, in: &context, rng: &rng)
    }

    private func drawCreatureMotif(_ features: VoiceFeatures, palette: ArtworkPalette, style: ArtworkStyle, center: CGPoint, short: CGFloat, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        switch style.biomorphIndex % 10 {
        case 0:
            drawFigureArtwork(features, palette: palette, style: style, center: center, short: short, in: &context, rng: &rng)
        case 1:
            drawOrganismArtwork(features, palette: palette, style: style, center: center, short: short, in: &context, rng: &rng)
        case 2:
            drawSpiritArtwork(features, palette: palette, style: style, center: center, short: short, in: &context, rng: &rng)
        case 3:
            drawWingedCreature(features, palette: palette, style: style, center: center, short: short, in: &context, rng: &rng)
        case 4:
            drawAquaticCreature(features, palette: palette, style: style, center: center, short: short, in: &context, rng: &rng)
        case 5:
            drawInsectCreature(features, palette: palette, style: style, center: center, short: short, in: &context, rng: &rng)
        case 6:
            drawBotanicalCreature(features, palette: palette, style: style, center: center, short: short, in: &context, rng: &rng)
        case 7:
            drawMicrobeCreature(features, palette: palette, style: style, center: center, short: short, in: &context, rng: &rng)
        case 8:
            drawMaskedCreature(features, palette: palette, style: style, center: center, short: short, in: &context, rng: &rng)
        default:
            drawSerpentineCreature(features, palette: palette, style: style, center: center, short: short, in: &context, rng: &rng)
        }
    }

    private func drawCreatureParts(_ features: VoiceFeatures, palette: ArtworkPalette, style: ArtworkStyle, center: CGPoint, short: CGFloat, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        let partMode = style.biomorphIndex % 12
        let faceCenter = CGPoint(
            x: center.x + short * CGFloat(rng.double(in: -0.12...0.12)),
            y: center.y + short * CGFloat(rng.double(in: -0.11...0.1))
        )

        switch partMode {
        case 0, 1:
            drawHumanLikeEyes(palette: palette, center: faceCenter, short: short, in: &context, rng: &rng)
            drawSoftMouth(features, palette: palette, center: faceCenter, short: short, in: &context, rng: &rng)
        case 2, 3:
            drawCompoundEyes(palette: palette, center: faceCenter, short: short, in: &context, rng: &rng)
            drawAntennae(features, palette: palette, center: faceCenter, short: short, in: &context, rng: &rng)
        case 4, 5:
            drawMammalMuzzle(palette: palette, center: faceCenter, short: short, in: &context, rng: &rng)
            drawEarMarks(palette: palette, center: faceCenter, short: short, in: &context, rng: &rng)
        case 6:
            drawBeakMouth(palette: palette, center: faceCenter, short: short, in: &context, rng: &rng)
            drawHumanLikeEyes(palette: palette, center: faceCenter, short: short, in: &context, rng: &rng)
        case 7:
            drawFangMouth(palette: palette, center: faceCenter, short: short, in: &context, rng: &rng)
            drawHumanLikeEyes(palette: palette, center: faceCenter, short: short, in: &context, rng: &rng)
        case 8:
            drawManyTinyEyes(palette: palette, center: faceCenter, short: short, in: &context, rng: &rng)
        case 9:
            drawSnoutAndWhiskers(features, palette: palette, center: faceCenter, short: short, in: &context, rng: &rng)
        case 10:
            drawSegmentedMandibles(palette: palette, center: faceCenter, short: short, in: &context, rng: &rng)
            drawCompoundEyes(palette: palette, center: faceCenter, short: short, in: &context, rng: &rng)
        default:
            drawFloatingMouthAndEye(features, palette: palette, center: faceCenter, short: short, in: &context, rng: &rng)
        }
    }

    private func drawHumanLikeEyes(palette: ArtworkPalette, center: CGPoint, short: CGFloat, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        for side in [-1.0, 1.0] {
            let w = short * CGFloat(rng.double(in: 0.038...0.075))
            let h = w * CGFloat(rng.double(in: 0.42...0.7))
            let rect = CGRect(x: center.x + CGFloat(side) * short * 0.055 - w / 2, y: center.y - short * 0.045 - h / 2, width: w, height: h)
            context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.55)))
            context.fill(Path(ellipseIn: rect.insetBy(dx: w * 0.34, dy: h * 0.18)), with: .color(palette.spark.opacity(0.82)))
        }
    }

    private func drawSoftMouth(_ features: VoiceFeatures, palette: ArtworkPalette, center: CGPoint, short: CGFloat, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        var path = Path()
        let width = short * CGFloat(rng.double(in: 0.07...0.16))
        let y = center.y + short * CGFloat(rng.double(in: 0.045...0.105))
        path.move(to: CGPoint(x: center.x - width / 2, y: y))
        path.addQuadCurve(to: CGPoint(x: center.x + width / 2, y: y), control: CGPoint(x: center.x, y: y + short * CGFloat(0.02 + features.averageEnergy * 0.09)))
        context.stroke(path, with: .color(palette.lineB.opacity(0.62)), lineWidth: CGFloat(rng.double(in: 2...5)))
    }

    private func drawCompoundEyes(palette: ArtworkPalette, center: CGPoint, short: CGFloat, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        for side in [-1.0, 1.0] {
            let base = CGPoint(x: center.x + CGFloat(side) * short * 0.075, y: center.y - short * 0.04)
            let cells = 7 + Int(rng.next() % 8)
            for cell in 0..<cells {
                let angle = Double(cell) / Double(cells) * .pi * 2
                let distance = short * CGFloat(rng.double(in: 0.006...0.028))
                let s = short * CGFloat(rng.double(in: 0.008...0.018))
                let p = CGPoint(x: base.x + CGFloat(cos(angle)) * distance, y: base.y + CGFloat(sin(angle)) * distance)
                context.fill(Path(ellipseIn: CGRect(x: p.x - s / 2, y: p.y - s / 2, width: s, height: s)), with: .color(palette.spark.opacity(0.62)))
            }
        }
    }

    private func drawAntennae(_ features: VoiceFeatures, palette: ArtworkPalette, center: CGPoint, short: CGFloat, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        for side in [-1.0, 1.0] {
            var path = Path()
            let start = CGPoint(x: center.x + CGFloat(side) * short * 0.04, y: center.y - short * 0.09)
            let end = CGPoint(x: center.x + CGFloat(side) * short * CGFloat(rng.double(in: 0.18...0.32)), y: center.y - short * CGFloat(rng.double(in: 0.22...0.38)))
            path.move(to: start)
            path.addQuadCurve(to: end, control: CGPoint(x: center.x + CGFloat(side) * short * 0.14, y: center.y - short * CGFloat(0.18 + features.averageEnergy * 0.14)))
            context.stroke(path, with: .color(palette.lineA.opacity(0.5)), lineWidth: CGFloat(rng.double(in: 1.5...4)))
            let s = short * CGFloat(rng.double(in: 0.012...0.028))
            context.fill(Path(ellipseIn: CGRect(x: end.x - s / 2, y: end.y - s / 2, width: s, height: s)), with: .color(palette.spark.opacity(0.65)))
        }
    }

    private func drawMammalMuzzle(palette: ArtworkPalette, center: CGPoint, short: CGFloat, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        let w = short * CGFloat(rng.double(in: 0.09...0.16))
        let h = short * CGFloat(rng.double(in: 0.055...0.105))
        let rect = CGRect(x: center.x - w / 2, y: center.y + short * 0.02, width: w, height: h)
        context.fill(Path(ellipseIn: rect), with: .color(palette.lineB.opacity(0.3)))
        let nose = CGRect(x: center.x - w * 0.16, y: center.y + short * 0.028, width: w * 0.32, height: h * 0.38)
        context.fill(Path(ellipseIn: nose), with: .color(.white.opacity(0.46)))
    }

    private func drawEarMarks(palette: ArtworkPalette, center: CGPoint, short: CGFloat, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        for side in [-1.0, 1.0] {
            var ear = Path()
            let base = CGPoint(x: center.x + CGFloat(side) * short * 0.11, y: center.y - short * 0.09)
            ear.move(to: base)
            ear.addLine(to: CGPoint(x: base.x + CGFloat(side) * short * CGFloat(rng.double(in: 0.055...0.11)), y: base.y - short * CGFloat(rng.double(in: 0.08...0.16))))
            ear.addLine(to: CGPoint(x: base.x + CGFloat(side) * short * CGFloat(rng.double(in: 0.01...0.05)), y: base.y + short * 0.04))
            ear.closeSubpath()
            context.fill(ear, with: .color(palette.spark.opacity(0.24)))
            context.stroke(ear, with: .color(palette.spark.opacity(0.5)), lineWidth: 1.1)
        }
    }

    private func drawBeakMouth(palette: ArtworkPalette, center: CGPoint, short: CGFloat, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        var beak = Path()
        let y = center.y + short * 0.035
        beak.move(to: CGPoint(x: center.x - short * 0.015, y: y))
        beak.addLine(to: CGPoint(x: center.x + short * CGFloat(rng.double(in: 0.08...0.18)), y: y + short * CGFloat(rng.double(in: -0.025...0.03))))
        beak.addLine(to: CGPoint(x: center.x - short * 0.015, y: y + short * 0.04))
        beak.closeSubpath()
        context.fill(beak, with: .color(palette.lineA.opacity(0.46)))
    }

    private func drawFangMouth(palette: ArtworkPalette, center: CGPoint, short: CGFloat, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        drawSoftMouth(.empty, palette: palette, center: center, short: short, in: &context, rng: &rng)
        for side in [-1.0, 1.0] {
            var fang = Path()
            let x = center.x + CGFloat(side) * short * 0.035
            let y = center.y + short * 0.07
            fang.move(to: CGPoint(x: x, y: y))
            fang.addLine(to: CGPoint(x: x + CGFloat(side) * short * 0.018, y: y + short * 0.075))
            fang.addLine(to: CGPoint(x: x + CGFloat(side) * short * 0.034, y: y))
            fang.closeSubpath()
            context.fill(fang, with: .color(.white.opacity(0.48)))
        }
    }

    private func drawManyTinyEyes(palette: ArtworkPalette, center: CGPoint, short: CGFloat, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        let count = 5 + Int(rng.next() % 10)
        for eye in 0..<count {
            let angle = Double(eye) / Double(count) * .pi * 2 + rng.double(in: -0.2...0.2)
            let d = short * CGFloat(rng.double(in: 0.025...0.14))
            let s = short * CGFloat(rng.double(in: 0.012...0.032))
            let p = CGPoint(x: center.x + CGFloat(cos(angle)) * d, y: center.y + CGFloat(sin(angle)) * d)
            context.fill(Path(ellipseIn: CGRect(x: p.x - s / 2, y: p.y - s / 2, width: s, height: s)), with: .color(.white.opacity(0.5)))
            context.fill(Path(ellipseIn: CGRect(x: p.x - s * 0.18, y: p.y - s * 0.18, width: s * 0.36, height: s * 0.36)), with: .color(palette.spark.opacity(0.85)))
        }
    }

    private func drawSnoutAndWhiskers(_ features: VoiceFeatures, palette: ArtworkPalette, center: CGPoint, short: CGFloat, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        drawMammalMuzzle(palette: palette, center: center, short: short, in: &context, rng: &rng)
        for side in [-1.0, 1.0] {
            for whisker in 0..<3 {
                var path = Path()
                let y = center.y + short * CGFloat(0.055 + Double(whisker - 1) * 0.025)
                path.move(to: CGPoint(x: center.x + CGFloat(side) * short * 0.035, y: y))
                path.addQuadCurve(to: CGPoint(x: center.x + CGFloat(side) * short * 0.24, y: y + short * CGFloat(rng.double(in: -0.035...0.035))), control: CGPoint(x: center.x + CGFloat(side) * short * 0.12, y: y - short * CGFloat(features.averageEnergy * 0.08)))
                context.stroke(path, with: .color(palette.spark.opacity(0.36)), lineWidth: 1.2)
            }
        }
    }

    private func drawSegmentedMandibles(palette: ArtworkPalette, center: CGPoint, short: CGFloat, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        for side in [-1.0, 1.0] {
            var path = Path()
            path.move(to: CGPoint(x: center.x + CGFloat(side) * short * 0.025, y: center.y + short * 0.05))
            path.addQuadCurve(to: CGPoint(x: center.x + CGFloat(side) * short * CGFloat(rng.double(in: 0.11...0.22)), y: center.y + short * CGFloat(rng.double(in: 0.07...0.17))), control: CGPoint(x: center.x + CGFloat(side) * short * 0.1, y: center.y + short * 0.01))
            context.stroke(path, with: .color(palette.lineB.opacity(0.54)), lineWidth: CGFloat(rng.double(in: 2.2...5)))
        }
    }

    private func drawFloatingMouthAndEye(_ features: VoiceFeatures, palette: ArtworkPalette, center: CGPoint, short: CGFloat, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        drawHumanLikeEyes(palette: palette, center: center, short: short, in: &context, rng: &rng)
        drawSoftMouth(features, palette: palette, center: CGPoint(x: center.x + short * CGFloat(rng.double(in: -0.08...0.08)), y: center.y + short * CGFloat(rng.double(in: 0.02...0.1))), short: short, in: &context, rng: &rng)
    }

    private func drawModernGround(_ features: VoiceFeatures, palette: ArtworkPalette, size: CGSize, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        let planes = 4 + Int(rng.next() % 4)
        for index in 0..<planes {
            let energy = sample(features.energyCurve, at: Double(index) / Double(max(1, planes - 1)))
            let width = size.width * CGFloat(rng.double(in: 0.34...0.78))
            let height = size.height * CGFloat(rng.double(in: 0.22...0.58) * (0.75 + energy))
            let x = size.width * CGFloat(rng.double(in: -0.12...0.82))
            let y = size.height * CGFloat(rng.double(in: -0.08...0.84))
            let rect = CGRect(x: x, y: y, width: width, height: height)
            let color = index.isMultiple(of: 3) ? palette.lineB : (index.isMultiple(of: 2) ? palette.backgroundB : palette.lineA)
            context.fill(Path(ellipseIn: rect), with: .color(color.opacity(rng.double(in: 0.045...0.16))))
        }

        let slashCount = 2 + Int(rng.next() % 3)
        for index in 0..<slashCount {
            var path = Path()
            let start = CGPoint(x: size.width * CGFloat(rng.double(in: -0.1...0.42)), y: size.height * CGFloat(rng.double(in: 0.12...0.95)))
            let end = CGPoint(x: size.width * CGFloat(rng.double(in: 0.48...1.12)), y: size.height * CGFloat(rng.double(in: -0.05...0.84)))
            let voice = sample(features.waveform, at: Double(index) / Double(max(1, slashCount - 1)))
            path.move(to: start)
            path.addQuadCurve(
                to: end,
                control: CGPoint(x: size.width * CGFloat(rng.double(in: 0.25...0.75)), y: size.height * CGFloat(0.5 + voice * 0.28))
            )
            let color = index.isMultiple(of: 2) ? palette.spark : palette.lineA
            context.stroke(path, with: .color(color.opacity(rng.double(in: 0.09...0.24))), lineWidth: CGFloat(rng.double(in: 10...28)))
        }
    }

    private func drawBloomArtwork(_ features: VoiceFeatures, palette: ArtworkPalette, style: ArtworkStyle, center: CGPoint, short: CGFloat, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        let petals = 18 + style.symmetry * 3
        for petal in 0..<petals {
            let t = Double(petal) / Double(petals)
            let voice = abs(sample(features.waveform, at: t))
            let energy = sample(features.energyCurve, at: (t + 0.19).truncatingRemainder(dividingBy: 1))
            let angle = t * .pi * 2 + rng.double(in: -0.22...0.22)
            let length = short * CGFloat(0.22 + voice * 0.22 + energy * 0.14)
            let width = short * CGFloat(rng.double(in: 0.035...0.085) * style.strokeBias)
            let tip = CGPoint(x: center.x + CGFloat(cos(angle)) * length, y: center.y + CGFloat(sin(angle)) * length)
            let left = CGPoint(x: center.x + CGFloat(cos(angle - .pi / 2)) * width, y: center.y + CGFloat(sin(angle - .pi / 2)) * width)
            let right = CGPoint(x: center.x + CGFloat(cos(angle + .pi / 2)) * width, y: center.y + CGFloat(sin(angle + .pi / 2)) * width)

            var path = Path()
            path.move(to: left)
            path.addQuadCurve(to: tip, control: CGPoint(x: center.x + CGFloat(cos(angle - 0.35)) * length * 0.52, y: center.y + CGFloat(sin(angle - 0.35)) * length * 0.52))
            path.addQuadCurve(to: right, control: CGPoint(x: center.x + CGFloat(cos(angle + 0.35)) * length * 0.52, y: center.y + CGFloat(sin(angle + 0.35)) * length * 0.52))
            path.addQuadCurve(to: left, control: center)

            let color = petal.isMultiple(of: 3) ? palette.spark : (petal.isMultiple(of: 2) ? palette.lineA : palette.lineB)
            context.fill(path, with: .color(color.opacity(rng.double(in: 0.07...0.28))))
            context.stroke(path, with: .color(color.opacity(rng.double(in: 0.12...0.38))), lineWidth: CGFloat(rng.double(in: 0.5...1.8)))
        }
    }

    private func drawAuroraArtwork(_ features: VoiceFeatures, palette: ArtworkPalette, style: ArtworkStyle, size: CGSize, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        let bands = 7 + style.symmetry
        for band in 0..<bands {
            var path = Path()
            let steps = 110
            let baseY = size.height * CGFloat(rng.double(in: 0.18...0.82))
            let amplitude = size.height * CGFloat(rng.double(in: 0.05...0.18) * style.turbulence)
            for step in 0...steps {
                let t = Double(step) / Double(steps)
                let pitch = sample(features.pitchCurve, at: (t + Double(band) * 0.047).truncatingRemainder(dividingBy: 1))
                let wave = sample(features.waveform, at: t)
                let x = size.width * CGFloat(t)
                let y = baseY + CGFloat(sin(t * .pi * Double(2 + band % 4) + pitch * 4) + wave * 0.55) * amplitude
                step == 0 ? path.move(to: CGPoint(x: x, y: y)) : path.addLine(to: CGPoint(x: x, y: y))
            }
            let color = band.isMultiple(of: 2) ? palette.lineA : palette.spark
            context.stroke(path, with: .color(color.opacity(rng.double(in: 0.18...0.48))), lineWidth: CGFloat(rng.double(in: 6...18)))
            context.stroke(path, with: .color(.white.opacity(rng.double(in: 0.04...0.16))), lineWidth: CGFloat(rng.double(in: 1...3)))
        }
    }

    private func drawTopographyArtwork(_ features: VoiceFeatures, palette: ArtworkPalette, style: ArtworkStyle, size: CGSize, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        let rows = 10 + style.symmetry
        for row in 0..<rows {
            var path = Path()
            let yBase = size.height * CGFloat(row + 1) / CGFloat(rows + 1)
            let steps = 95
            for step in 0...steps {
                let t = Double(step) / Double(steps)
                let voice = sample(features.waveform, at: (t + Double(row) * 0.061).truncatingRemainder(dividingBy: 1))
                let energy = sample(features.energyCurve, at: (t * 0.6 + Double(row) * 0.083).truncatingRemainder(dividingBy: 1))
                let drift = sin(t * .pi * rng.double(in: 1.4...4.5) + Double(row)) * 0.55
                let x = size.width * CGFloat(t)
                let y = yBase + CGFloat(voice * 0.42 + energy * 0.38 + drift * 0.2) * size.height * 0.12
                step == 0 ? path.move(to: CGPoint(x: x, y: y)) : path.addLine(to: CGPoint(x: x, y: y))
            }
            let color = row.isMultiple(of: 2) ? palette.lineB : palette.lineA
            context.stroke(path, with: .color(color.opacity(0.18 + rng.double(in: 0...0.28))), lineWidth: CGFloat(rng.double(in: 1.4...5.5)))
        }
    }

    private func drawCalligraphyArtwork(_ features: VoiceFeatures, palette: ArtworkPalette, style: ArtworkStyle, center: CGPoint, short: CGFloat, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        let strokes = 9 + style.symmetry
        for stroke in 0..<strokes {
            var path = Path()
            let phase = rng.double(in: 0...(.pi * 2))
            let sweep = rng.double(in: 0.7...2.5)
            let steps = 80
            for step in 0...steps {
                let t = Double(step) / Double(steps)
                let voice = sample(features.waveform, at: (t + Double(stroke) * 0.077).truncatingRemainder(dividingBy: 1))
                let radius = short * CGFloat(0.04 + t * rng.double(in: 0.26...0.48) + abs(voice) * 0.1)
                let angle = phase + t * .pi * 2 * sweep + voice * 0.7
                let point = CGPoint(x: center.x + CGFloat(cos(angle)) * radius, y: center.y + CGFloat(sin(angle)) * radius)
                step == 0 ? path.move(to: point) : path.addQuadCurve(to: point, control: CGPoint(x: center.x + CGFloat(voice) * short * 0.24, y: center.y - CGFloat(voice) * short * 0.18))
            }
            let color = stroke.isMultiple(of: 2) ? palette.spark : palette.lineA
            context.stroke(path, with: .color(color.opacity(rng.double(in: 0.16...0.5))), lineWidth: CGFloat(rng.double(in: 3.0...12.0)))
        }
    }

    private func drawMistArtwork(_ features: VoiceFeatures, palette: ArtworkPalette, style: ArtworkStyle, size: CGSize, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        let clouds = 70 + Int(features.averageEnergy * 80)
        for index in 0..<clouds {
            let t = Double(index) / Double(clouds)
            let wave = sample(features.waveform, at: t)
            let energy = sample(features.energyCurve, at: (t + 0.31).truncatingRemainder(dividingBy: 1))
            let x = size.width * CGFloat(rng.double(in: 0.05...0.95))
            let y = size.height * CGFloat(0.18 + rng.double(in: 0...0.68) + wave * 0.08)
            let side = size.width * CGFloat(rng.double(in: 0.05...0.16) * (0.7 + energy))
            let rect = CGRect(x: x - side / 2, y: y - side / 2, width: side, height: side * CGFloat(rng.double(in: 0.55...1.25)))
            let color = index.isMultiple(of: 3) ? palette.lineB : (index.isMultiple(of: 2) ? palette.lineA : palette.spark)
            context.fill(Path(ellipseIn: rect), with: .color(color.opacity(rng.double(in: 0.025...0.14))))
        }
    }

    private func drawNebulaArtwork(_ features: VoiceFeatures, palette: ArtworkPalette, style: ArtworkStyle, center: CGPoint, short: CGFloat, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        let arms = 3 + style.symmetry % 5
        for arm in 0..<arms {
            var path = Path()
            let phase = Double(arm) / Double(arms) * .pi * 2 + rng.double(in: -0.4...0.4)
            let steps = 130
            for step in 0...steps {
                let t = Double(step) / Double(steps)
                let wave = sample(features.waveform, at: (t + Double(arm) * 0.11).truncatingRemainder(dividingBy: 1))
                let radius = short * CGFloat(0.04 + t * 0.46 + wave * 0.07)
                let angle = phase + t * .pi * rng.double(in: 1.6...3.2)
                let point = CGPoint(x: center.x + CGFloat(cos(angle)) * radius, y: center.y + CGFloat(sin(angle)) * radius)
                step == 0 ? path.move(to: point) : path.addLine(to: point)
            }
            let color = arm.isMultiple(of: 2) ? palette.lineA : palette.lineB
            context.stroke(path, with: .color(color.opacity(rng.double(in: 0.16...0.42))), lineWidth: CGFloat(rng.double(in: 8...20)))
        }

        for _ in 0..<(80 + Int(features.rhythmDensity * 15)) {
            let angle = rng.double(in: 0...(.pi * 2))
            let distance = short * CGFloat(rng.double(in: 0.04...0.47))
            let side = CGFloat(rng.double(in: 1.5...8.5))
            let point = CGPoint(x: center.x + CGFloat(cos(angle)) * distance, y: center.y + CGFloat(sin(angle)) * distance)
            context.fill(Path(ellipseIn: CGRect(x: point.x - side / 2, y: point.y - side / 2, width: side, height: side)), with: .color(palette.spark.opacity(rng.double(in: 0.18...0.72))))
        }
    }

    private func drawWingedCreature(_ features: VoiceFeatures, palette: ArtworkPalette, style: ArtworkStyle, center: CGPoint, short: CGFloat, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        let span = short * CGFloat(0.34 + Double(style.biomorphIndex % 17) / 70)
        let bodyHeight = short * CGFloat(0.2 + features.averageEnergy * 0.18)
        let wingPairs = 1 + (style.biomorphIndex / 17) % 3

        for pair in 0..<wingPairs {
            for side in [-1.0, 1.0] {
                var wing = Path()
                let lift = CGFloat(pair) * short * 0.035
                wing.move(to: center)
                wing.addCurve(
                    to: CGPoint(x: center.x + CGFloat(side) * span, y: center.y - short * CGFloat(rng.double(in: 0.05...0.22)) - lift),
                    control1: CGPoint(x: center.x + CGFloat(side) * span * 0.22, y: center.y - short * CGFloat(rng.double(in: 0.28...0.46))),
                    control2: CGPoint(x: center.x + CGFloat(side) * span * 0.75, y: center.y - short * CGFloat(rng.double(in: 0.34...0.5)))
                )
                wing.addCurve(
                    to: center,
                    control1: CGPoint(x: center.x + CGFloat(side) * span * 0.74, y: center.y + short * CGFloat(rng.double(in: 0.08...0.24))),
                    control2: CGPoint(x: center.x + CGFloat(side) * span * 0.18, y: center.y + short * CGFloat(rng.double(in: 0.06...0.2)))
                )
                let color = pair.isMultiple(of: 2) ? palette.spark : palette.lineA
                context.fill(wing, with: .color(color.opacity(0.18)))
                context.stroke(wing, with: .color(.white.opacity(0.18)), lineWidth: 1.2)
            }
        }

        let body = CGRect(x: center.x - short * 0.035, y: center.y - bodyHeight / 2, width: short * 0.07, height: bodyHeight)
        context.fill(Path(ellipseIn: body), with: .color(palette.lineB.opacity(0.5)))
    }

    private func drawAquaticCreature(_ features: VoiceFeatures, palette: ArtworkPalette, style: ArtworkStyle, center: CGPoint, short: CGFloat, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        let length = short * CGFloat(0.36 + Double(style.biomorphIndex % 23) / 80)
        let height = short * CGFloat(0.12 + features.averageEnergy * 0.14)
        var body = Path()
        body.move(to: CGPoint(x: center.x - length * 0.46, y: center.y))
        body.addCurve(to: CGPoint(x: center.x + length * 0.34, y: center.y - height * 0.15), control1: CGPoint(x: center.x - length * 0.2, y: center.y - height), control2: CGPoint(x: center.x + length * 0.18, y: center.y - height * 0.82))
        body.addCurve(to: CGPoint(x: center.x - length * 0.46, y: center.y), control1: CGPoint(x: center.x + length * 0.1, y: center.y + height * 0.85), control2: CGPoint(x: center.x - length * 0.2, y: center.y + height))
        context.fill(body, with: .color(palette.lineA.opacity(0.24)))
        context.stroke(body, with: .color(palette.spark.opacity(0.5)), lineWidth: CGFloat(rng.double(in: 1.6...4.2)))

        var tail = Path()
        tail.move(to: CGPoint(x: center.x + length * 0.32, y: center.y))
        tail.addLine(to: CGPoint(x: center.x + length * 0.52, y: center.y - height * 0.8))
        tail.addLine(to: CGPoint(x: center.x + length * 0.52, y: center.y + height * 0.8))
        tail.closeSubpath()
        context.fill(tail, with: .color(palette.lineB.opacity(0.28)))

        for fin in 0..<(2 + style.biomorphIndex % 4) {
            var path = Path()
            let t = Double(fin) / Double(4)
            let x = center.x - length * CGFloat(0.18 - t * 0.28)
            path.move(to: CGPoint(x: x, y: center.y))
            path.addQuadCurve(to: CGPoint(x: x + short * CGFloat(rng.double(in: -0.04...0.06)), y: center.y + height * CGFloat(rng.double(in: 0.8...1.7))), control: CGPoint(x: x - short * 0.04, y: center.y + height))
            context.stroke(path, with: .color(palette.spark.opacity(0.34)), lineWidth: CGFloat(rng.double(in: 3...7)))
        }
    }

    private func drawInsectCreature(_ features: VoiceFeatures, palette: ArtworkPalette, style: ArtworkStyle, center: CGPoint, short: CGFloat, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        let segments = 4 + style.biomorphIndex % 8
        let axis = short * CGFloat(0.26 + features.rhythmDensity * 0.02)

        for segment in 0..<segments {
            let t = CGFloat(segment) / CGFloat(max(1, segments - 1))
            let y = center.y - axis / 2 + axis * t
            let w = short * CGFloat(rng.double(in: 0.055...0.13)) * CGFloat(1.2 - abs(Double(t - 0.5)))
            let h = short * CGFloat(rng.double(in: 0.055...0.12))
            context.fill(Path(ellipseIn: CGRect(x: center.x - w / 2, y: y - h / 2, width: w, height: h)), with: .color((segment.isMultiple(of: 2) ? palette.lineA : palette.lineB).opacity(0.36)))
        }

        let legs = 6 + (style.biomorphIndex / 11) % 8
        for leg in 0..<legs {
            let side: CGFloat = leg.isMultiple(of: 2) ? -1 : 1
            let y = center.y - axis * 0.42 + axis * CGFloat(leg) / CGFloat(max(1, legs - 1))
            var path = Path()
            path.move(to: CGPoint(x: center.x, y: y))
            path.addQuadCurve(to: CGPoint(x: center.x + side * short * CGFloat(rng.double(in: 0.18...0.34)), y: y + short * CGFloat(rng.double(in: -0.12...0.12))), control: CGPoint(x: center.x + side * short * 0.12, y: y + short * CGFloat(rng.double(in: -0.18...0.18))))
            context.stroke(path, with: .color(palette.spark.opacity(0.38)), lineWidth: CGFloat(rng.double(in: 1.5...4.8)))
        }
    }

    private func drawBotanicalCreature(_ features: VoiceFeatures, palette: ArtworkPalette, style: ArtworkStyle, center: CGPoint, short: CGFloat, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        let stems = 3 + style.biomorphIndex % 7
        for stem in 0..<stems {
            var path = Path()
            let base = CGPoint(x: center.x + short * CGFloat(rng.double(in: -0.14...0.14)), y: center.y + short * 0.28)
            let tip = CGPoint(x: center.x + short * CGFloat(rng.double(in: -0.26...0.26)), y: center.y - short * CGFloat(rng.double(in: 0.16...0.36)))
            path.move(to: base)
            path.addCurve(to: tip, control1: CGPoint(x: base.x + short * CGFloat(rng.double(in: -0.18...0.18)), y: center.y + short * 0.04), control2: CGPoint(x: tip.x + short * CGFloat(rng.double(in: -0.15...0.15)), y: center.y - short * 0.02))
            context.stroke(path, with: .color(palette.lineA.opacity(0.36)), lineWidth: CGFloat(rng.double(in: 3...9)))

            let leafs = 2 + (style.biomorphIndex / 7 + stem) % 5
            for leaf in 0..<leafs {
                let angle = rng.double(in: 0...(.pi * 2))
                let side = short * CGFloat(rng.double(in: 0.045...0.12))
                let p = CGPoint(x: tip.x + CGFloat(cos(angle)) * side, y: tip.y + CGFloat(sin(angle)) * side)
                context.fill(Path(ellipseIn: CGRect(x: p.x - side / 2, y: p.y - side / 3, width: side, height: side * 0.66)), with: .color((leaf.isMultiple(of: 2) ? palette.spark : palette.lineB).opacity(0.24)))
            }
        }
    }

    private func drawMicrobeCreature(_ features: VoiceFeatures, palette: ArtworkPalette, style: ArtworkStyle, center: CGPoint, short: CGFloat, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        let colonies = 12 + style.biomorphIndex % 18
        for colony in 0..<colonies {
            let angle = rng.double(in: 0...(.pi * 2))
            let distance = short * CGFloat(rng.double(in: 0.02...0.32))
            let point = CGPoint(x: center.x + CGFloat(cos(angle)) * distance, y: center.y + CGFloat(sin(angle)) * distance)
            let side = short * CGFloat(rng.double(in: 0.025...0.09))
            context.fill(Path(ellipseIn: CGRect(x: point.x - side / 2, y: point.y - side / 2, width: side, height: side)), with: .color((colony.isMultiple(of: 2) ? palette.lineA : palette.spark).opacity(0.26)))

            for spike in 0..<(3 + colony % 5) {
                let a = Double(spike) / Double(3 + colony % 5) * .pi * 2
                var path = Path()
                path.move(to: point)
                path.addLine(to: CGPoint(x: point.x + CGFloat(cos(a)) * side * 0.9, y: point.y + CGFloat(sin(a)) * side * 0.9))
                context.stroke(path, with: .color(palette.spark.opacity(0.22)), lineWidth: 1)
            }
        }
    }

    private func drawMaskedCreature(_ features: VoiceFeatures, palette: ArtworkPalette, style: ArtworkStyle, center: CGPoint, short: CGFloat, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        let width = short * CGFloat(0.18 + Double(style.biomorphIndex % 19) / 80)
        let height = short * CGFloat(0.26 + features.averageEnergy * 0.18)
        var mask = Path()
        mask.move(to: CGPoint(x: center.x, y: center.y - height * 0.58))
        mask.addCurve(to: CGPoint(x: center.x - width * 0.55, y: center.y), control1: CGPoint(x: center.x - width * 0.55, y: center.y - height * 0.48), control2: CGPoint(x: center.x - width * 0.78, y: center.y - height * 0.08))
        mask.addCurve(to: CGPoint(x: center.x, y: center.y + height * 0.56), control1: CGPoint(x: center.x - width * 0.5, y: center.y + height * 0.35), control2: CGPoint(x: center.x - width * 0.18, y: center.y + height * 0.62))
        mask.addCurve(to: CGPoint(x: center.x + width * 0.55, y: center.y), control1: CGPoint(x: center.x + width * 0.18, y: center.y + height * 0.62), control2: CGPoint(x: center.x + width * 0.5, y: center.y + height * 0.35))
        mask.addCurve(to: CGPoint(x: center.x, y: center.y - height * 0.58), control1: CGPoint(x: center.x + width * 0.78, y: center.y - height * 0.08), control2: CGPoint(x: center.x + width * 0.55, y: center.y - height * 0.48))
        context.fill(mask, with: .color(palette.lineB.opacity(0.32)))
        context.stroke(mask, with: .color(palette.spark.opacity(0.58)), lineWidth: CGFloat(rng.double(in: 1.5...4.5)))

        for eye in [-1.0, 1.0] {
            let side = short * CGFloat(rng.double(in: 0.018...0.04))
            let rect = CGRect(x: center.x + CGFloat(eye) * width * 0.2 - side / 2, y: center.y - height * 0.1 - side / 2, width: side, height: side * 0.58)
            context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.5)))
        }
    }

    private func drawSerpentineCreature(_ features: VoiceFeatures, palette: ArtworkPalette, style: ArtworkStyle, center: CGPoint, short: CGFloat, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        var spine = Path()
        let steps = 120
        let length = short * CGFloat(0.34 + Double(style.biomorphIndex % 31) / 100)
        for step in 0...steps {
            let t = Double(step) / Double(steps)
            let wave = sample(features.waveform, at: t)
            let x = center.x - length / 2 + length * CGFloat(t)
            let y = center.y + CGFloat(sin(t * .pi * Double(2 + style.biomorphIndex % 5)) + wave) * short * CGFloat(rng.double(in: 0.035...0.085))
            step == 0 ? spine.move(to: CGPoint(x: x, y: y)) : spine.addLine(to: CGPoint(x: x, y: y))
        }
        context.stroke(spine, with: .color(palette.lineA.opacity(0.48)), lineWidth: CGFloat(rng.double(in: 8...18)))
        context.stroke(spine, with: .color(palette.spark.opacity(0.5)), lineWidth: CGFloat(rng.double(in: 1.5...4)))
    }

    private func drawFigureArtwork(_ features: VoiceFeatures, palette: ArtworkPalette, style: ArtworkStyle, center: CGPoint, short: CGFloat, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        let tilt = CGFloat(rng.double(in: -0.22...0.22))
        let bodyHeight = short * CGFloat(0.38 + features.averageEnergy * 0.18)
        let bodyWidth = short * CGFloat(0.12 + features.pitchRange / 2_800)
        let headSize = short * CGFloat(rng.double(in: 0.055...0.105))
        let bodyCenter = CGPoint(x: center.x + short * tilt, y: center.y + short * CGFloat(rng.double(in: -0.02...0.08)))

        var torso = Path()
        torso.move(to: CGPoint(x: bodyCenter.x, y: bodyCenter.y - bodyHeight * 0.45))
        torso.addCurve(
            to: CGPoint(x: bodyCenter.x - bodyWidth * 0.55, y: bodyCenter.y + bodyHeight * 0.42),
            control1: CGPoint(x: bodyCenter.x - bodyWidth * 1.25, y: bodyCenter.y - bodyHeight * 0.25),
            control2: CGPoint(x: bodyCenter.x - bodyWidth * 0.95, y: bodyCenter.y + bodyHeight * 0.2)
        )
        torso.addCurve(
            to: CGPoint(x: bodyCenter.x + bodyWidth * 0.6, y: bodyCenter.y + bodyHeight * 0.34),
            control1: CGPoint(x: bodyCenter.x - bodyWidth * 0.1, y: bodyCenter.y + bodyHeight * 0.58),
            control2: CGPoint(x: bodyCenter.x + bodyWidth * 1.25, y: bodyCenter.y + bodyHeight * 0.54)
        )
        torso.addCurve(
            to: CGPoint(x: bodyCenter.x, y: bodyCenter.y - bodyHeight * 0.45),
            control1: CGPoint(x: bodyCenter.x + bodyWidth * 0.95, y: bodyCenter.y),
            control2: CGPoint(x: bodyCenter.x + bodyWidth * 0.74, y: bodyCenter.y - bodyHeight * 0.3)
        )

        context.fill(torso, with: .color(palette.lineA.opacity(0.32)))
        context.stroke(torso, with: .color(palette.spark.opacity(0.58)), lineWidth: CGFloat(rng.double(in: 1.8...5.6)))

        let headRect = CGRect(x: bodyCenter.x - headSize / 2, y: bodyCenter.y - bodyHeight * 0.58 - headSize / 2, width: headSize, height: headSize * CGFloat(rng.double(in: 1.05...1.45)))
        context.fill(Path(ellipseIn: headRect), with: .color(palette.spark.opacity(0.42)))
        context.stroke(Path(ellipseIn: headRect), with: .color(.white.opacity(0.36)), lineWidth: 1.4)

        let limbs = 4 + style.symmetry % 4
        for limb in 0..<limbs {
            var path = Path()
            let side: CGFloat = limb.isMultiple(of: 2) ? -1 : 1
            let startY = bodyCenter.y + bodyHeight * CGFloat(rng.double(in: -0.22...0.24))
            let start = CGPoint(x: bodyCenter.x + side * bodyWidth * CGFloat(rng.double(in: 0.24...0.7)), y: startY)
            let end = CGPoint(x: bodyCenter.x + side * short * CGFloat(rng.double(in: 0.18...0.38)), y: startY + short * CGFloat(rng.double(in: -0.16...0.22)))
            let wave = sample(features.waveform, at: Double(limb) / Double(max(1, limbs - 1)))
            path.move(to: start)
            path.addQuadCurve(to: end, control: CGPoint(x: center.x + side * short * CGFloat(0.16 + abs(wave) * 0.18), y: startY - short * CGFloat(wave * 0.18)))
            context.stroke(path, with: .color((limb.isMultiple(of: 2) ? palette.lineB : palette.spark).opacity(0.42)), lineWidth: CGFloat(rng.double(in: 5...14)))
        }
    }

    private func drawOrganismArtwork(_ features: VoiceFeatures, palette: ArtworkPalette, style: ArtworkStyle, center: CGPoint, short: CGFloat, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        let archetype = style.biomorphIndex
        let lobes = 5 + archetype % 13
        let tendrils = 3 + (archetype / 13) % 9
        let shellBias = Double((archetype / 117) % 7) / 7
        let rotation = rng.double(in: 0...(.pi * 2))
        let bodyScale = short * CGFloat(0.18 + features.averageEnergy * 0.22 + shellBias * 0.06)

        var body = Path()
        let steps = 180
        for step in 0...steps {
            let t = Double(step) / Double(steps)
            let angle = t * .pi * 2 + rotation
            let voice = sample(features.waveform, at: t)
            let pitch = sample(features.pitchCurve, at: (t + shellBias).truncatingRemainder(dividingBy: 1))
            let breathing = sin(angle * Double(lobes)) * 0.14 + cos(angle * Double(2 + archetype % 5)) * 0.08
            let radius = bodyScale * CGFloat(0.76 + breathing + abs(voice) * 0.22 + pitch * 0.16)
            let x = center.x + CGFloat(cos(angle)) * radius * CGFloat(1.0 + shellBias * 0.46)
            let y = center.y + CGFloat(sin(angle)) * radius * CGFloat(0.72 + Double(archetype % 11) / 26)
            step == 0 ? body.move(to: CGPoint(x: x, y: y)) : body.addLine(to: CGPoint(x: x, y: y))
        }
        body.closeSubpath()

        context.fill(body, with: .radialGradient(Gradient(colors: [palette.spark.opacity(0.44), palette.lineA.opacity(0.24), .clear]), center: center, startRadius: 0, endRadius: bodyScale * 1.8))
        context.stroke(body, with: .color(palette.lineB.opacity(0.56)), lineWidth: CGFloat(rng.double(in: 1.8...5.8)))

        for tendril in 0..<tendrils {
            var path = Path()
            let t = Double(tendril) / Double(tendrils)
            let angle = t * .pi * 2 + rotation + rng.double(in: -0.4...0.4)
            let start = CGPoint(x: center.x + CGFloat(cos(angle)) * bodyScale * 0.78, y: center.y + CGFloat(sin(angle)) * bodyScale * 0.64)
            let length = short * CGFloat(rng.double(in: 0.12...0.34) * (0.8 + features.rhythmDensity * 0.06))
            let end = CGPoint(x: start.x + CGFloat(cos(angle + rng.double(in: -0.8...0.8))) * length, y: start.y + CGFloat(sin(angle + rng.double(in: -0.8...0.8))) * length)
            let voice = sample(features.waveform, at: t)
            path.move(to: start)
            path.addCurve(
                to: end,
                control1: CGPoint(x: start.x + CGFloat(cos(angle + 0.8)) * length * 0.38, y: start.y + CGFloat(sin(angle + 0.8)) * length * 0.38),
                control2: CGPoint(x: end.x - CGFloat(voice) * short * 0.08, y: end.y + CGFloat(voice) * short * 0.12)
            )
            context.stroke(path, with: .color((tendril.isMultiple(of: 2) ? palette.spark : palette.lineA).opacity(0.45)), lineWidth: CGFloat(rng.double(in: 2.8...9.5)))
        }

        let eyeCount = archetype % 4 == 0 ? 0 : 1 + archetype % 3
        for eye in 0..<eyeCount {
            let angle = rotation + Double(eye) / Double(max(1, eyeCount)) * .pi * 0.55 - 0.28
            let point = CGPoint(x: center.x + CGFloat(cos(angle)) * bodyScale * 0.28, y: center.y + CGFloat(sin(angle)) * bodyScale * 0.18)
            let side = short * CGFloat(rng.double(in: 0.012...0.026))
            context.fill(Path(ellipseIn: CGRect(x: point.x - side / 2, y: point.y - side / 2, width: side, height: side)), with: .color(.white.opacity(0.36)))
        }
    }

    private func drawSpiritArtwork(_ features: VoiceFeatures, palette: ArtworkPalette, style: ArtworkStyle, center: CGPoint, short: CGFloat, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        let silhouettes = 2 + style.biomorphIndex % 4
        for silhouette in 0..<silhouettes {
            let offset = CGPoint(x: center.x + short * CGFloat(rng.double(in: -0.18...0.18)), y: center.y + short * CGFloat(rng.double(in: -0.12...0.18)))
            var path = Path()
            path.move(to: CGPoint(x: offset.x, y: offset.y - short * CGFloat(rng.double(in: 0.22...0.34))))
            path.addCurve(
                to: CGPoint(x: offset.x - short * CGFloat(rng.double(in: 0.12...0.24)), y: offset.y + short * CGFloat(rng.double(in: 0.18...0.34))),
                control1: CGPoint(x: offset.x - short * CGFloat(rng.double(in: 0.18...0.34)), y: offset.y - short * 0.14),
                control2: CGPoint(x: offset.x - short * CGFloat(rng.double(in: 0.22...0.35)), y: offset.y + short * 0.12)
            )
            path.addCurve(
                to: CGPoint(x: offset.x + short * CGFloat(rng.double(in: 0.12...0.24)), y: offset.y + short * CGFloat(rng.double(in: 0.16...0.32))),
                control1: CGPoint(x: offset.x - short * 0.06, y: offset.y + short * CGFloat(rng.double(in: 0.4...0.5))),
                control2: CGPoint(x: offset.x + short * CGFloat(rng.double(in: 0.18...0.32)), y: offset.y + short * 0.34)
            )
            path.addCurve(
                to: CGPoint(x: offset.x, y: offset.y - short * CGFloat(rng.double(in: 0.22...0.34))),
                control1: CGPoint(x: offset.x + short * CGFloat(rng.double(in: 0.2...0.34)), y: offset.y + short * 0.02),
                control2: CGPoint(x: offset.x + short * CGFloat(rng.double(in: 0.14...0.26)), y: offset.y - short * 0.16)
            )
            let color = silhouette.isMultiple(of: 2) ? palette.spark : palette.lineB
            context.fill(path, with: .color(color.opacity(rng.double(in: 0.16...0.34))))
            context.stroke(path, with: .color(color.opacity(rng.double(in: 0.34...0.62))), lineWidth: CGFloat(rng.double(in: 1.8...4.8)))

            drawVoiceRibbon(features.energyCurve, color: color, center: offset, radius: short * CGFloat(rng.double(in: 0.12...0.21)), in: &context, phase: rng.double(in: 0...(.pi * 2)))
        }
    }

    private func drawOrbitArtwork(_ features: VoiceFeatures, palette: ArtworkPalette, style: ArtworkStyle, center: CGPoint, short: CGFloat, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        drawVoiceRibbon(features.waveform, color: palette.lineA, center: center, radius: short * CGFloat(rng.double(in: 0.15...0.24)), in: &context, phase: rng.double(in: 0...(.pi * 2)))
        drawVoiceRibbon(features.energyCurve, color: palette.lineB, center: center, radius: short * CGFloat(rng.double(in: 0.27...0.39)), in: &context, phase: rng.double(in: 0...(.pi * 2)))
        drawPitchGlyph(features.pitchCurve, color: palette.spark, center: center, in: &context, size: CGSize(width: short, height: short))

        let particleCount = 70 + Int(features.rhythmDensity * 18)
        for index in 0..<particleCount {
            let angle = rng.double(in: 0...(Double.pi * 2))
            let distance = CGFloat(rng.double(in: 0.12...0.49)) * short
            let scale = CGFloat(rng.double(in: 1.8...7.5) * (0.8 + features.averageEnergy))
            let alpha = rng.double(in: 0.18...0.72)
            let point = CGPoint(x: center.x + CGFloat(cos(angle)) * distance, y: center.y + CGFloat(sin(angle)) * distance)
            let rect = CGRect(x: point.x - scale / 2, y: point.y - scale / 2, width: scale, height: scale)
            let color = index.isMultiple(of: 3) ? palette.spark : (index.isMultiple(of: 2) ? palette.lineA : palette.lineB)
            context.fill(Path(ellipseIn: rect), with: .color(color.opacity(alpha)))
        }

        let coreSize = short * CGFloat(0.13 + min(0.08, features.averageEnergy * 0.08))
        context.fill(
            Path(ellipseIn: CGRect(x: center.x - coreSize / 2, y: center.y - coreSize / 2, width: coreSize, height: coreSize)),
            with: .radialGradient(Gradient(colors: [.white.opacity(0.92), palette.spark.opacity(0.42), .clear]), center: center, startRadius: 0, endRadius: coreSize * 0.72)
        )
    }

    private func drawCrystallineArtwork(_ features: VoiceFeatures, palette: ArtworkPalette, style: ArtworkStyle, center: CGPoint, short: CGFloat, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        let nodes = 18 + Int(features.rhythmDensity * 5) + style.symmetry
        var points: [CGPoint] = []

        for index in 0..<nodes {
            let t = Double(index) / Double(nodes)
            let sample = sample(features.energyCurve, at: t)
            let angle = t * .pi * 2 * Double(style.symmetry % 5 + 1) + rng.double(in: -0.28...0.28)
            let distance = short * CGFloat(0.11 + sample * 0.34 + rng.double(in: 0...0.08))
            points.append(CGPoint(x: center.x + CGFloat(cos(angle)) * distance, y: center.y + CGFloat(sin(angle)) * distance))
        }

        for a in points.indices {
            for b in (a + 1)..<points.count where (b - a).isMultiple(of: style.symmetry % 4 + 2) {
                var path = Path()
                path.move(to: points[a])
                path.addLine(to: points[b])
                let alpha = 0.08 + abs(sample(features.waveform, at: Double(a + b) / Double(points.count * 2))) * 0.28
                context.stroke(path, with: .color(palette.lineA.opacity(alpha)), lineWidth: CGFloat(rng.double(in: 0.45...1.8)))
            }
        }

        for point in points {
            let size = CGFloat(rng.double(in: 6...18)) * CGFloat(0.7 + features.averageEnergy)
            let rect = CGRect(x: point.x - size / 2, y: point.y - size / 2, width: size, height: size)
            context.fill(Path(ellipseIn: rect), with: .color(palette.spark.opacity(rng.double(in: 0.35...0.9))))
        }
    }

    private func drawTerrainArtwork(_ features: VoiceFeatures, palette: ArtworkPalette, style: ArtworkStyle, size: CGSize, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        let rows = 12 + style.symmetry
        let width = size.width
        let height = size.height

        for row in 0..<rows {
            var path = Path()
            let yBase = height * CGFloat(row + 1) / CGFloat(rows + 1)
            let steps = 90
            for step in 0...steps {
                let t = Double(step) / Double(steps)
                let voice = sample(features.waveform, at: t)
                let energy = sample(features.energyCurve, at: (t + Double(row) * 0.071).truncatingRemainder(dividingBy: 1))
                let ridge = sin(t * .pi * Double(style.symmetry) + Double(row) * 0.55) * style.turbulence
                let y = yBase + CGFloat((voice * 0.55 + energy * 0.45 + ridge * 0.18) * Double(height) * 0.11)
                let point = CGPoint(x: width * CGFloat(t), y: y)
                step == 0 ? path.move(to: point) : path.addLine(to: point)
            }
            let color = row.isMultiple(of: 2) ? palette.lineA : palette.lineB
            context.stroke(path, with: .color(color.opacity(0.38 + Double(row % 4) * 0.08)), lineWidth: CGFloat(1.2 + style.strokeBias))
        }

        drawPitchGlyph(features.pitchCurve, color: palette.spark, center: CGPoint(x: width / 2, y: height / 2), in: &context, size: size)
    }

    private func drawInkArtwork(_ features: VoiceFeatures, palette: ArtworkPalette, style: ArtworkStyle, center: CGPoint, short: CGFloat, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        let strokes = 7 + style.symmetry

        for stroke in 0..<strokes {
            var path = Path()
            let turns = rng.double(in: 0.65...2.2)
            let phase = rng.double(in: 0...(.pi * 2))
            let steps = 120
            for step in 0...steps {
                let t = Double(step) / Double(steps)
                let voice = sample(features.waveform, at: (t + Double(stroke) * 0.09).truncatingRemainder(dividingBy: 1))
                let angle = phase + t * .pi * 2 * turns
                let radius = short * CGFloat(0.05 + t * 0.44 + voice * 0.08 * style.turbulence)
                let point = CGPoint(x: center.x + CGFloat(cos(angle)) * radius, y: center.y + CGFloat(sin(angle)) * radius)
                step == 0 ? path.move(to: point) : path.addCurve(to: point, control1: CGPoint(x: center.x, y: point.y), control2: CGPoint(x: point.x, y: center.y))
            }
            let color = stroke.isMultiple(of: 2) ? palette.lineA : palette.spark
            context.stroke(path, with: .color(color.opacity(rng.double(in: 0.18...0.54))), lineWidth: CGFloat(rng.double(in: 2.5...9.5) * style.strokeBias))
        }
    }

    private func drawSignalArtwork(_ features: VoiceFeatures, palette: ArtworkPalette, style: ArtworkStyle, size: CGSize, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        let columns = 20 + style.symmetry * 2
        let rows = 18 + Int(features.rhythmDensity * 4)
        let cellW = size.width / CGFloat(columns)
        let cellH = size.height / CGFloat(rows)

        for row in 0..<rows {
            for column in 0..<columns {
                let t = Double(column) / Double(max(1, columns - 1))
                let wave = abs(sample(features.waveform, at: (t + Double(row) * 0.037).truncatingRemainder(dividingBy: 1)))
                let energy = sample(features.energyCurve, at: Double(row) / Double(max(1, rows - 1)))
                guard rng.double(in: 0...1) < 0.18 + wave * 0.52 + energy * 0.26 else { continue }
                let inset = CGFloat(rng.double(in: 1.2...5.8))
                let rect = CGRect(x: CGFloat(column) * cellW + inset, y: CGFloat(row) * cellH + inset, width: max(1, cellW - inset * 2), height: max(1, cellH - inset * 2))
                let color = column.isMultiple(of: 3) ? palette.spark : (row.isMultiple(of: 2) ? palette.lineA : palette.lineB)
                context.fill(Path(roundedRect: rect, cornerRadius: 1.5), with: .color(color.opacity(rng.double(in: 0.15...0.72))))
            }
        }
    }

    private func drawVeilArtwork(_ features: VoiceFeatures, palette: ArtworkPalette, style: ArtworkStyle, center: CGPoint, short: CGFloat, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        let layers = 8 + style.symmetry
        for layer in 0..<layers {
            var path = Path()
            let steps = 180
            let phase = rng.double(in: 0...(.pi * 2))
            for step in 0...steps {
                let t = Double(step) / Double(steps)
                let pitch = sample(features.pitchCurve, at: t)
                let wave = sample(features.waveform, at: (t + Double(layer) * 0.053).truncatingRemainder(dividingBy: 1))
                let angle = t * .pi * 2 + phase
                let radius = short * CGFloat(0.12 + Double(layer) * 0.026 + pitch * 0.16 + wave * 0.05)
                let point = CGPoint(x: center.x + CGFloat(cos(angle)) * radius, y: center.y + CGFloat(sin(angle * Double(style.symmetry % 5 + 1))) * radius)
                step == 0 ? path.move(to: point) : path.addLine(to: point)
            }
            let color = layer.isMultiple(of: 2) ? palette.lineB : palette.lineA
            context.stroke(path, with: .color(color.opacity(0.15 + rng.double(in: 0...0.32))), lineWidth: CGFloat(rng.double(in: 0.8...3.4)))
        }
    }

    private func drawVoiceRibbon(_ values: [Double], color: Color, center: CGPoint, radius: CGFloat, in context: inout GraphicsContext, phase: Double = 0) {
        guard values.count > 4 else { return }
        var path = Path()
        for index in values.indices {
            let t = Double(index) / Double(values.count - 1)
            let angle = t * .pi * 2 + phase
            let value = values[index]
            let r = radius + CGFloat(value) * radius * 0.58
            let point = CGPoint(x: center.x + CGFloat(cos(angle)) * r, y: center.y + CGFloat(sin(angle)) * r)
            index == values.startIndex ? path.move(to: point) : path.addLine(to: point)
        }
        path.closeSubpath()
        context.stroke(path, with: .color(color.opacity(0.9)), lineWidth: 2.4)
        context.stroke(path, with: .color(.white.opacity(0.18)), lineWidth: 7)
    }

    private func drawPitchGlyph(_ values: [Double], color: Color, center: CGPoint, in context: inout GraphicsContext, size: CGSize) {
        guard values.count > 3 else { return }
        var path = Path()
        let width = size.width * 0.72
        let startX = center.x - width / 2
        for index in values.indices {
            let x = startX + width * CGFloat(index) / CGFloat(max(1, values.count - 1))
            let y = center.y + CGFloat(values[index] - 0.5) * size.height * 0.38
            index == values.startIndex ? path.move(to: CGPoint(x: x, y: y)) : path.addLine(to: CGPoint(x: x, y: y))
        }
        context.stroke(path, with: .color(color.opacity(0.78)), lineWidth: 1.8)
    }

    private func drawGrain(palette: ArtworkPalette, size: CGSize, in context: inout GraphicsContext, rng: inout SeededRandomNumberGenerator) {
        let count = 90
        for _ in 0..<count {
            let point = CGPoint(x: CGFloat(rng.double(in: 0...Double(size.width))), y: CGFloat(rng.double(in: 0...Double(size.height))))
            let side = CGFloat(rng.double(in: 0.8...2.8))
            let rect = CGRect(x: point.x, y: point.y, width: side, height: side)
            context.fill(Path(ellipseIn: rect), with: .color(palette.spark.opacity(rng.double(in: 0.04...0.16))))
        }
    }

    private func sample(_ values: [Double], at t: Double) -> Double {
        guard !values.isEmpty else { return 0 }
        let clamped = max(0, min(1, t))
        let index = min(values.count - 1, Int((Double(values.count - 1) * clamped).rounded()))
        return values[index]
    }

    private func ringColor(_ index: Int) -> Color {
        [.cyan, .mint, .pink, .orange, .white][index % 5]
    }
}

@MainActor
enum ArtworkExporter {
    static func renderPNG(artwork: VoiceArtwork, size: CGSize = CGSize(width: 1024, height: 1024)) -> URL? {
        let renderer = ImageRenderer(content: VoiceArtworkView(artwork: artwork).frame(width: size.width, height: size.height))
        renderer.scale = 1
        guard let data = renderer.uiImage?.pngData() else { return nil }
        let url = documentsDirectory.appendingPathComponent("\(artwork.id.uuidString)-voiceprint.png")
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }

    static func writeMetadata(artwork: VoiceArtwork) -> URL? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(artwork.nftMetadata) else { return nil }
        let url = documentsDirectory.appendingPathComponent("\(artwork.id.uuidString)-metadata.json")
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }

    private static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
