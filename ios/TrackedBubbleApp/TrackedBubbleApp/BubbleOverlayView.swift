import SwiftUI

struct BubbleOverlayView: View {
    let text: String
    let anchor: CGPoint
    let containerSize: CGSize
    var offset: CGPoint = .zero
    var scale: CGFloat = 1

    var body: some View {
        let point = CGPoint(
            x: (anchor.x + offset.x) * containerSize.width,
            y: (anchor.y + offset.y) * containerSize.height
        )
        ZStack(alignment: .bottomTrailing) {
            MangaSpeechTail()
                .fill(.white)
                .frame(width: containerSize.width * 0.12 * scale, height: containerSize.width * 0.09 * scale)
                .overlay(MangaSpeechTail().stroke(.black, lineWidth: 4.0))
                .offset(x: -containerSize.width * 0.06 * scale, y: containerSize.width * 0.036 * scale)

            Text(text.isEmpty ? "え、まって" : text)
                .font(.system(size: max(16, containerSize.width * 0.047 * scale), weight: .heavy, design: .rounded))
                .foregroundStyle(Color(red: 0.88, green: 0.18, blue: 0.46))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.56)
                .padding(.horizontal, 25 * scale)
                .padding(.vertical, 15 * scale)
                .frame(maxWidth: containerSize.width * 0.61 * scale, minHeight: containerSize.width * 0.18 * scale)
                .background(MangaSpeechBubble().fill(.white))
                .overlay(MangaSpeechBubble().stroke(.black, lineWidth: 4.8))
        }
        .shadow(color: .black.opacity(0.18), radius: 1, x: 2, y: 3)
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
                    .font(.system(size: base * 0.48, weight: .black))
                    .foregroundStyle(shape.color)
                    .position(x: center.x - base * 0.42, y: center.y + CGFloat(sin(t * shape.speed)) * 3)
                Text(shape.glyph)
                    .font(.system(size: base * 0.48, weight: .black))
                    .foregroundStyle(shape.color)
                    .position(x: center.x + base * 0.42, y: center.y + CGFloat(cos(t * shape.speed)) * 3)

                ForEach(0..<shape.particleCount, id: \.self) { index in
                    let angle = Double(index) * .pi * 2 / Double(shape.particleCount) + t * shape.orbitSpeed
                    let radius = base * (0.34 + CGFloat((index + shape.rawValue) % 4) * 0.09)
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
            .shadow(color: .white.opacity(0.85), radius: 5)
        }
        .allowsHitTesting(false)
    }
}

struct MangaSpeechBubble: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.34))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.42, y: rect.minY + rect.height * 0.08), control1: CGPoint(x: rect.minX + rect.width * 0.20, y: rect.minY + rect.height * 0.14), control2: CGPoint(x: rect.minX + rect.width * 0.28, y: rect.minY + rect.height * 0.08))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.78, y: rect.minY + rect.height * 0.16), control1: CGPoint(x: rect.minX + rect.width * 0.58, y: rect.minY - rect.height * 0.02), control2: CGPoint(x: rect.minX + rect.width * 0.73, y: rect.minY + rect.height * 0.04))
        path.addCurve(to: CGPoint(x: rect.maxX - rect.width * 0.04, y: rect.minY + rect.height * 0.50), control1: CGPoint(x: rect.maxX - rect.width * 0.04, y: rect.minY + rect.height * 0.17), control2: CGPoint(x: rect.maxX + rect.width * 0.04, y: rect.minY + rect.height * 0.36))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.78, y: rect.maxY - rect.height * 0.14), control1: CGPoint(x: rect.maxX + rect.width * 0.02, y: rect.maxY - rect.height * 0.26), control2: CGPoint(x: rect.maxX - rect.width * 0.07, y: rect.maxY - rect.height * 0.09))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.34, y: rect.maxY - rect.height * 0.08), control1: CGPoint(x: rect.minX + rect.width * 0.64, y: rect.maxY + rect.height * 0.02), control2: CGPoint(x: rect.minX + rect.width * 0.45, y: rect.maxY + rect.height * 0.00))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.06, y: rect.minY + rect.height * 0.58), control1: CGPoint(x: rect.minX + rect.width * 0.13, y: rect.maxY - rect.height * 0.05), control2: CGPoint(x: rect.minX - rect.width * 0.02, y: rect.maxY - rect.height * 0.29))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.34), control1: CGPoint(x: rect.minX - rect.width * 0.01, y: rect.minY + rect.height * 0.42), control2: CGPoint(x: rect.minX + rect.width * 0.07, y: rect.minY + rect.height * 0.32))
        return path
    }
}

struct MangaSpeechTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.28, y: rect.minY + rect.height * 0.12))
        path.addCurve(to: CGPoint(x: rect.maxX - rect.width * 0.10, y: rect.maxY - rect.height * 0.12), control1: CGPoint(x: rect.minX + rect.width * 0.35, y: rect.minY + rect.height * 0.50), control2: CGPoint(x: rect.minX + rect.width * 0.62, y: rect.maxY - rect.height * 0.02))
        path.addCurve(to: CGPoint(x: rect.minX + rect.width * 0.74, y: rect.minY + rect.height * 0.24), control1: CGPoint(x: rect.maxX - rect.width * 0.28, y: rect.maxY - rect.height * 0.48), control2: CGPoint(x: rect.maxX - rect.width * 0.16, y: rect.minY + rect.height * 0.34))
        path.closeSubpath()
        return path
    }
}

enum EyeSparkleShape: Int, CaseIterable, Identifiable {
    case material01 = 1, material02, material03, material04, material05, material06, material07, material08, material09, material10
    case material11, material12, material13, material14, material15, material16, material17, material18, material19, material20
    case material21, material22, material23, material24, material25, material26, material27, material28, material29, material30

    var id: Int { rawValue }

    var title: String {
        "\(String(format: "%02d", rawValue)) \(name)"
    }

    var name: String {
        switch rawValue {
        case 1: "星"
        case 2: "ハート"
        case 3: "ダイヤ"
        case 4: "月"
        case 5: "花"
        case 6: "王冠"
        case 7: "音符"
        case 8: "涙"
        case 9: "炎"
        case 10: "ネオン"
        case 11: "泡"
        case 12: "リボン"
        case 13: "キラ粒"
        case 14: "流星"
        case 15: "天使"
        case 16: "小悪魔"
        case 17: "宝石"
        case 18: "雪"
        case 19: "電撃"
        case 20: "虹"
        case 21: "チェリー"
        case 22: "キャンディ"
        case 23: "クラウン"
        case 24: "コスメ"
        case 25: "真珠"
        case 26: "ミラー"
        case 27: "ふわ光"
        case 28: "ポップ"
        case 29: "ラブ"
        default: "爆キラ"
        }
    }

    var glyph: String {
        ["★", "♥", "◆", "☾", "✿", "♛", "♪", "✧", "🔥", "✦"][(rawValue - 1) % 10]
    }

    func particleGlyph(_ index: Int) -> String {
        let sets = [
            ["✦", "•", "✧"], ["♥", "♡", "•"], ["◆", "◇", "✦"], ["☾", "✦", "•"],
            ["✿", "❀", "•"], ["♛", "✦", "•"], ["♪", "♫", "✦"], ["✧", "•", "✦"],
            ["✦", "🔥", "•"], ["✦", "◇", "•"]
        ]
        let set = sets[(rawValue - 1) % sets.count]
        return set[index % set.count]
    }

    var color: Color { palette[rawValue % palette.count] }

    func particleColor(_ index: Int) -> Color {
        palette[(rawValue + index) % palette.count]
    }

    var speed: Double { 4.2 + Double(rawValue % 7) * 0.28 }
    var orbitSpeed: Double { 0.8 + Double(rawValue % 9) * 0.16 }
    var particleCount: Int { 8 + rawValue % 5 }
    var ySpread: CGFloat { 0.38 + CGFloat(rawValue % 4) * 0.06 }

    func particleScale(_ index: Int) -> CGFloat {
        0.10 + CGFloat((index + rawValue) % 4) * 0.035
    }

    func particleOpacity(_ index: Int, time: Double) -> Double {
        0.50 + 0.35 * (0.5 + 0.5 * sin(time * speed + Double(index)))
    }

    private var palette: [Color] {
        [
            .yellow, .pink, .cyan, .orange, .purple, .mint,
            .red, .blue, .green, Color(red: 1.0, green: 0.76, blue: 0.18)
        ]
    }
}
