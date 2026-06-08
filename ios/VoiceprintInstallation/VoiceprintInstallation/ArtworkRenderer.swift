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

        drawVoiceRibbon(features.waveform, color: palette.lineA, center: center, radius: short * 0.19, in: &context)
        drawVoiceRibbon(features.energyCurve, color: palette.lineB, center: center, radius: short * 0.30, in: &context, phase: .pi / 2)
        drawPitchGlyph(features.pitchCurve, color: palette.spark, center: center, in: &context, size: size)

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
