import SwiftUI

struct VoiceArtworkView: View {
    var artwork: VoiceArtwork?
    var liveLevel: Double = 0
    var livePitch: Double = 0

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            drawBackground(in: &context, rect: rect)

            if let artwork {
                drawArtwork(artwork, in: &context, size: size)
            } else {
                drawIdle(level: liveLevel, pitch: livePitch, in: &context, size: size)
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

    private func drawIdle(level: Double, pitch: Double, in context: inout GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) * CGFloat(0.18 + level * 0.18)

        for ring in 0..<5 {
            var path = Path()
            let steps = 160
            let ringRadius = radius + CGFloat(ring) * 24
            for step in 0...steps {
                let t = Double(step) / Double(steps)
                let angle = t * .pi * 2
                let wobble = CGFloat(sin(angle * 5 + level * 8 + Double(ring)) * 10)
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
        }

        drawGrain(palette: palette, size: size, in: &context, rng: &rng)
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
