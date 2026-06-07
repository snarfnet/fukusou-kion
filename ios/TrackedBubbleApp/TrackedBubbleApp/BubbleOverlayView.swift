import SwiftUI

struct BubbleOverlayView: View {
    let text: String
    let anchor: CGPoint
    let containerSize: CGSize

    var body: some View {
        let point = CGPoint(x: anchor.x * containerSize.width, y: anchor.y * containerSize.height)
        Text(text.isEmpty ? "え、まって" : text)
            .font(.system(size: max(15, containerSize.width * 0.045), weight: .black, design: .rounded))
            .foregroundStyle(Color(red: 0.20, green: 0.10, blue: 0.18))
            .multilineTextAlignment(.center)
            .lineLimit(3)
            .minimumScaleFactor(0.65)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: containerSize.width * 0.54)
            .background(.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 18))
            .overlay(alignment: .bottomLeading) {
                BubbleTail()
                    .fill(.white.opacity(0.96))
                    .frame(width: 26, height: 20)
                    .offset(x: 24, y: 13)
            }
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(red: 0.18, green: 0.08, blue: 0.16), lineWidth: 2))
            .shadow(color: .black.opacity(0.20), radius: 8, y: 4)
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
                sparkleGlyph
                    .font(.system(size: base * 0.48, weight: .black))
                    .position(x: center.x - base * 0.42, y: center.y + CGFloat(sin(t * 5.0)) * 3)
                sparkleGlyph
                    .font(.system(size: base * 0.48, weight: .black))
                    .position(x: center.x + base * 0.42, y: center.y + CGFloat(cos(t * 5.0)) * 3)

                ForEach(0..<8, id: \.self) { index in
                    let angle = Double(index) * .pi / 4 + t * 1.4
                    let radius = base * (0.42 + CGFloat(index % 3) * 0.10)
                    Text(index.isMultiple(of: 2) ? "✦" : "•")
                        .font(.system(size: base * (index.isMultiple(of: 2) ? 0.18 : 0.10), weight: .bold))
                        .foregroundStyle(index.isMultiple(of: 2) ? Color.yellow : Color.pink)
                        .position(
                            x: center.x + CGFloat(cos(angle)) * radius,
                            y: center.y + CGFloat(sin(angle)) * radius * 0.46
                        )
                        .opacity(0.72)
                }
            }
            .shadow(color: .white.opacity(0.85), radius: 5)
        }
        .allowsHitTesting(false)
    }

    private var sparkleGlyph: some View {
        Text(shape.glyph)
            .foregroundStyle(shape.color)
    }
}

struct BubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY), control: CGPoint(x: rect.midX, y: rect.midY))
        path.addQuadCurve(to: CGPoint(x: rect.minX + 4, y: rect.minY + 3), control: CGPoint(x: rect.minX + 9, y: rect.maxY - 2))
        return path
    }
}

enum EyeSparkleShape: String, CaseIterable, Identifiable {
    case star
    case heart
    case diamond

    var id: String { rawValue }

    var title: String {
        switch self {
        case .star: "星"
        case .heart: "ハート"
        case .diamond: "ダイヤ"
        }
    }

    var glyph: String {
        switch self {
        case .star: "★"
        case .heart: "♥"
        case .diamond: "◆"
        }
    }

    var color: Color {
        switch self {
        case .star: .yellow
        case .heart: .pink
        case .diamond: .cyan
        }
    }
}
