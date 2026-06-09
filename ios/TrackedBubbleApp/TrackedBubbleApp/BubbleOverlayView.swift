import SwiftUI

struct BubbleOverlayView: View {
    let text: String
    let anchor: CGPoint
    let containerSize: CGSize
    var offset: CGPoint = .zero
    var scale: CGFloat = 1
    var style: BubbleStyle = .cloud

    var body: some View {
        let point = CGPoint(
            x: (anchor.x + offset.x) * containerSize.width,
            y: (anchor.y + offset.y) * containerSize.height
        )
        ZStack(alignment: .bottomTrailing) {
            MangaSpeechTail(style: style)
                .fill(.white)
                .frame(width: containerSize.width * 0.15 * scale, height: containerSize.width * 0.11 * scale)
                .overlay(MangaSpeechTail(style: style).stroke(.black, style: StrokeStyle(lineWidth: 5.0, lineJoin: .round)))
                .offset(x: -containerSize.width * 0.07 * scale, y: containerSize.width * 0.045 * scale)

            Text(text.isEmpty ? "え、まって" : text)
                .font(.system(size: max(16, containerSize.width * 0.049 * scale), weight: .heavy, design: .rounded))
                .foregroundStyle(Color(red: 0.88, green: 0.18, blue: 0.46))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.50)
                .padding(.horizontal, 28 * scale)
                .padding(.vertical, 17 * scale)
                .frame(width: containerSize.width * 0.62 * scale)
                .frame(minHeight: containerSize.width * 0.22 * scale)
                .background(MangaSpeechBubble(style: style).fill(.white))
                .overlay(MangaSpeechBubble(style: style).stroke(.black, style: StrokeStyle(lineWidth: 5.5, lineJoin: .round)))
        }
        .shadow(color: .black.opacity(0.22), radius: 1, x: 3, y: 4)
        .position(point)
        .animation(.spring(response: 0.22, dampingFraction: 0.78), value: anchor)
    }
}

struct EyeSparkleOverlayView: View {
    let point: FaceTrackingPoint
    let shape: EyeSparkleShape
    let containerSize: CGSize

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let center = CGPoint(x: point.eyeCenter.x * containerSize.width, y: point.eyeCenter.y * containerSize.height)
            let base = max(12, point.eyeWidth * containerSize.width)

            ZStack {
                Text(shape.glyph)
                    .font(.system(size: base * shape.mainScale, weight: .black))
                    .foregroundStyle(shape.color)
                    .position(x: center.x - base * 0.42, y: center.y + CGFloat(sin(t * shape.speed)) * 3)
                Text(shape.glyph)
                    .font(.system(size: base * shape.mainScale, weight: .black))
                    .foregroundStyle(shape.color)
                    .position(x: center.x + base * 0.42, y: center.y + CGFloat(cos(t * shape.speed)) * 3)

                ForEach(0..<shape.particleCount, id: \.self) { index in
                    let angle = Double(index) * .pi * 2 / Double(shape.particleCount) + t * shape.orbitSpeed
                    let radius = base * (0.32 + CGFloat((index + shape.rawValue) % 5) * 0.075)
                    Text(shape.particleGlyph(index))
                        .font(.system(size: base * shape.particleScale(index), weight: .bold))
                        .foregroundStyle(shape.particleColor(index))
                        .position(
                            x: center.x + CGFloat(cos(angle)) * radius,
                            y: center.y + CGFloat(sin(angle)) * radius * shape.ySpread
                        )
                        .opacity(shape.particleOpacity(index, time: t))
                }
            }
            .shadow(color: shape.glowColor.opacity(0.85), radius: 5)
        }
        .allowsHitTesting(false)
    }
}

enum BubbleStyle: Int {
    case cloud
    case burst
    case oval
    case soft

    static func style(for index: Int) -> BubbleStyle {
        BubbleStyle(rawValue: index % 4) ?? .cloud
    }
}

struct MangaSpeechBubble: Shape {
    var style: BubbleStyle = .cloud

    func path(in rect: CGRect) -> Path {
        switch style {
        case .burst:
            return burstPath(in: rect)
        case .oval:
            return ovalPath(in: rect)
        case .soft:
            return softPath(in: rect)
        case .cloud:
            return cloudPath(in: rect)
        }
    }

    private func cloudPath(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.16, y: rect.minY + rect.height * 0.50))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.27, y: rect.minY + rect.height * 0.20), control1: CGPoint(x: rect.minX + rect.width * 0.04, y: rect.minY + rect.height * 0.40), control2: CGPoint(x: rect.minX + rect.width * 0.10, y: rect.minY + rect.height * 0.18))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.48, y: rect.minY + rect.height * 0.10), control1: CGPoint(x: rect.minX + rect.width * 0.30, y: rect.minY + rect.height * 0.01), control2: CGPoint(x: rect.minX + rect.width * 0.45, y: rect.minY - rect.height * 0.02))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.70, y: rect.minY + rect.height * 0.18), control1: CGPoint(x: rect.minX + rect.width * 0.57, y: rect.minY - rect.height * 0.02), control2: CGPoint(x: rect.minX + rect.width * 0.70, y: rect.minY + rect.height * 0.02))
        path.addCurve(to: CGPoint(x: rect.maxX - rect.width * 0.06, y: rect.minY + rect.height * 0.47), control1: CGPoint(x: rect.maxX - rect.width * 0.07, y: rect.minY + rect.height * 0.15), control2: CGPoint(x: rect.maxX + rect.width * 0.04, y: rect.minY + rect.height * 0.30))
        path.addCurve(to: CGPoint(x: rect.maxX - rect.width * 0.19, y: rect.maxY - rect.height * 0.17), control1: CGPoint(x: rect.maxX + rect.width * 0.05, y: rect.maxY - rect.height * 0.34), control2: CGPoint(x: rect.maxX - rect.width * 0.03, y: rect.maxY - rect.height * 0.14))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.48, y: rect.maxY - rect.height * 0.09), control1: CGPoint(x: rect.maxX - rect.width * 0.25, y: rect.maxY + rect.height * 0.05), control2: CGPoint(x: rect.minX + rect.width * 0.62, y: rect.maxY + rect.height * 0.04))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.maxY - rect.height * 0.23), control1: CGPoint(x: rect.minX + rect.width * 0.32, y: rect.maxY + rect.height * 0.02), control2: CGPoint(x: rect.minX + rect.width * 0.17, y: rect.maxY - rect.height * 0.04))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.16, y: rect.minY + rect.height * 0.50), control1: CGPoint(x: rect.minX - rect.width * 0.02, y: rect.maxY - rect.height * 0.30), control2: CGPoint(x: rect.minX + rect.width * 0.00, y: rect.minY + rect.height * 0.58))
        path.closeSubpath()
        return path
    }

    private func burstPath(in rect: CGRect) -> Path {
        let points: [CGPoint] = [
            CGPoint(x: 0.03, y: 0.50), CGPoint(x: 0.13, y: 0.40), CGPoint(x: 0.05, y: 0.23), CGPoint(x: 0.20, y: 0.28),
            CGPoint(x: 0.23, y: 0.08), CGPoint(x: 0.36, y: 0.22), CGPoint(x: 0.47, y: 0.04), CGPoint(x: 0.55, y: 0.21),
            CGPoint(x: 0.72, y: 0.09), CGPoint(x: 0.73, y: 0.28), CGPoint(x: 0.95, y: 0.24), CGPoint(x: 0.84, y: 0.43),
            CGPoint(x: 0.98, y: 0.55), CGPoint(x: 0.81, y: 0.61), CGPoint(x: 0.92, y: 0.80), CGPoint(x: 0.70, y: 0.73),
            CGPoint(x: 0.64, y: 0.94), CGPoint(x: 0.50, y: 0.78), CGPoint(x: 0.32, y: 0.92), CGPoint(x: 0.30, y: 0.72),
            CGPoint(x: 0.10, y: 0.82), CGPoint(x: 0.18, y: 0.62)
        ]
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + points[0].x * rect.width, y: rect.minY + points[0].y * rect.height))
        for point in points.dropFirst() {
            path.addLine(to: CGPoint(x: rect.minX + point.x * rect.width, y: rect.minY + point.y * rect.height))
        }
        path.closeSubpath()
        return path
    }

    private func ovalPath(in rect: CGRect) -> Path {
        Path(ellipseIn: rect.insetBy(dx: rect.width * 0.04, dy: rect.height * 0.06))
    }

    private func softPath(in rect: CGRect) -> Path {
        Path(roundedRect: rect.insetBy(dx: rect.width * 0.04, dy: rect.height * 0.08), cornerRadius: rect.height * 0.28)
    }
}

struct MangaSpeechTail: Shape {
    var style: BubbleStyle = .cloud

    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch style {
        case .burst:
            path.move(to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.minY + rect.height * 0.02))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.60, y: rect.minY + rect.height * 0.20))
        case .oval, .soft, .cloud:
            path.move(to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.04))
            path.addCurve(to: CGPoint(x: rect.maxX - rect.width * 0.04, y: rect.maxY - rect.height * 0.02), control1: CGPoint(x: rect.minX + rect.width * 0.25, y: rect.minY + rect.height * 0.48), control2: CGPoint(x: rect.minX + rect.width * 0.61, y: rect.maxY))
            path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.70, y: rect.minY + rect.height * 0.18), control1: CGPoint(x: rect.maxX - rect.width * 0.20, y: rect.maxY - rect.height * 0.50), control2: CGPoint(x: rect.maxX - rect.width * 0.22, y: rect.minY + rect.height * 0.28))
        }
        path.closeSubpath()
        return path
    }
}

struct EyeSparkleShape: Identifiable, Hashable, CaseIterable {
    let rawValue: Int

    static let material01 = EyeSparkleShape(rawValue: 1)
    static let allCases: [EyeSparkleShape] = (1...100).map(EyeSparkleShape.init(rawValue:))

    var id: Int { rawValue }

    var title: String {
        "\(String(format: "%03d", rawValue)) \(name)"
    }

    var name: String {
        let names = [
            "星", "ハート", "ダイヤ", "月", "花", "涙", "音符", "炎", "しずく", "ネオン",
            "泡", "リボン", "キラ粉", "流れ星", "天使", "小悪魔", "宝石", "雪", "電撃", "虹",
            "チェリー", "キャンディ", "クラウン", "コスメ", "瞳光", "ミラー", "ふわ丸", "ポップ", "ラブ", "涙目"
        ]
        let base = names[(rawValue - 1) % names.count]
        return "\(base)\((rawValue - 1) / names.count + 1)"
    }

    var glyph: String {
        let glyphs = ["✦", "♥", "◆", "✧", "✿", "💧", "♪", "✹", "💦", "✚", "●", "♡", "✩", "☄", "໒꒱", "✞", "◇", "❄", "⚡", "☆"]
        return glyphs[(rawValue - 1) % glyphs.count]
    }

    func particleGlyph(_ index: Int) -> String {
        let sets = [
            ["✦", "•", "✧"], ["♥", "♡", "•"], ["◆", "◇", "✦"], ["✧", "✦", "•"], ["✿", "❀", "•"],
            ["💧", "💦", "•"], ["♪", "♫", "✦"], ["✹", "•", "✦"], ["💦", "💧", "•"], ["✚", "✦", "•"]
        ]
        let set = sets[(rawValue - 1) % sets.count]
        return set[index % set.count]
    }

    var color: Color { palette[rawValue % palette.count] }
    var glowColor: Color { palette[(rawValue + 3) % palette.count] }
    var mainScale: CGFloat { rawValue % 6 == 0 ? 0.42 : 0.48 }
    var speed: Double { 4.2 + Double(rawValue % 11) * 0.20 }
    var orbitSpeed: Double { 0.7 + Double(rawValue % 13) * 0.11 }
    var particleCount: Int { 8 + rawValue % 8 }
    var ySpread: CGFloat { 0.34 + CGFloat(rawValue % 6) * 0.045 }

    func particleColor(_ index: Int) -> Color {
        palette[(rawValue + index) % palette.count]
    }

    func particleScale(_ index: Int) -> CGFloat {
        0.09 + CGFloat((index + rawValue) % 5) * 0.026
    }

    func particleOpacity(_ index: Int, time: Double) -> Double {
        0.46 + 0.40 * (0.5 + 0.5 * sin(time * speed + Double(index)))
    }

    private var palette: [Color] {
        [
            .yellow, .pink, .cyan, .orange, .purple, .mint,
            .red, .blue, .green, Color(red: 1.0, green: 0.76, blue: 0.18),
            Color(red: 0.55, green: 0.95, blue: 1.0), Color(red: 1.0, green: 0.45, blue: 0.72)
        ]
    }
}
