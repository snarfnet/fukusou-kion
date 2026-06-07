import SwiftUI

struct BubbleOverlayView: View {
    let text: String
    let anchor: CGPoint
    let containerSize: CGSize

    var body: some View {
        let point = CGPoint(x: anchor.x * containerSize.width, y: anchor.y * containerSize.height)
        ZStack(alignment: .bottomLeading) {
            MangaBubbleTail()
                .fill(.white)
                .frame(width: containerSize.width * 0.12, height: containerSize.width * 0.10)
                .overlay(MangaBubbleTail().stroke(.black, lineWidth: 3.5))
                .offset(x: containerSize.width * 0.07, y: containerSize.width * 0.055)
                .rotationEffect(.degrees(-12))

            Text(text.isEmpty ? "え、まって" : text)
                .font(.system(size: max(17, containerSize.width * 0.052), weight: .heavy, design: .rounded))
                .foregroundStyle(Color(red: 0.93, green: 0.26, blue: 0.52))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.58)
                .padding(.horizontal, 24)
                .padding(.vertical, 18)
                .frame(maxWidth: containerSize.width * 0.60, minHeight: containerSize.width * 0.18)
                .background(MangaBubbleShape().fill(.white))
                .overlay(MangaBubbleShape().stroke(.black, lineWidth: 4.5))
                .overlay(alignment: .topTrailing) {
                    MangaEmphasisMarks()
                        .stroke(.black, style: StrokeStyle(lineWidth: 3.6, lineCap: .round))
                        .frame(width: 42, height: 34)
                        .offset(x: 14, y: -15)
                }
        }
        .shadow(color: .black.opacity(0.24), radius: 2, x: 3, y: 4)
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

struct MangaBubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.22, y: rect.minY + rect.height * 0.21))
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.47, y: rect.minY + rect.height * 0.08),
            control1: CGPoint(x: rect.minX + rect.width * 0.25, y: rect.minY + rect.height * 0.02),
            control2: CGPoint(x: rect.minX + rect.width * 0.40, y: rect.minY - rect.height * 0.02)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.73, y: rect.minY + rect.height * 0.18),
            control1: CGPoint(x: rect.minX + rect.width * 0.55, y: rect.minY - rect.height * 0.05),
            control2: CGPoint(x: rect.minX + rect.width * 0.70, y: rect.minY + rect.height * 0.02)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX - rect.width * 0.05, y: rect.minY + rect.height * 0.45),
            control1: CGPoint(x: rect.minX + rect.width * 0.91, y: rect.minY + rect.height * 0.14),
            control2: CGPoint(x: rect.maxX + rect.width * 0.02, y: rect.minY + rect.height * 0.28)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX - rect.width * 0.18, y: rect.maxY - rect.height * 0.13),
            control1: CGPoint(x: rect.maxX + rect.width * 0.05, y: rect.minY + rect.height * 0.66),
            control2: CGPoint(x: rect.maxX - rect.width * 0.05, y: rect.maxY - rect.height * 0.10)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.45, y: rect.maxY - rect.height * 0.04),
            control1: CGPoint(x: rect.maxX - rect.width * 0.22, y: rect.maxY + rect.height * 0.06),
            control2: CGPoint(x: rect.minX + rect.width * 0.60, y: rect.maxY + rect.height * 0.08)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.maxY - rect.height * 0.22),
            control1: CGPoint(x: rect.minX + rect.width * 0.32, y: rect.maxY + rect.height * 0.06),
            control2: CGPoint(x: rect.minX + rect.width * 0.14, y: rect.maxY - rect.height * 0.02)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.22, y: rect.minY + rect.height * 0.21),
            control1: CGPoint(x: rect.minX - rect.width * 0.03, y: rect.maxY - rect.height * 0.37),
            control2: CGPoint(x: rect.minX + rect.width * 0.02, y: rect.minY + rect.height * 0.25)
        )
        return path
    }
}

struct MangaBubbleTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.05))
        path.addCurve(
            to: CGPoint(x: rect.maxX - rect.width * 0.03, y: rect.maxY - rect.height * 0.03),
            control1: CGPoint(x: rect.minX + rect.width * 0.23, y: rect.minY + rect.height * 0.47),
            control2: CGPoint(x: rect.minX + rect.width * 0.58, y: rect.maxY)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.70, y: rect.minY + rect.height * 0.18),
            control1: CGPoint(x: rect.maxX - rect.width * 0.18, y: rect.maxY - rect.height * 0.52),
            control2: CGPoint(x: rect.maxX - rect.width * 0.24, y: rect.minY + rect.height * 0.28)
        )
        path.closeSubpath()
        return path
    }
}

struct MangaEmphasisMarks: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.15, y: rect.maxY * 0.72))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.move(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.22))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        path.move(to: CGPoint(x: rect.maxX - rect.width * 0.16, y: rect.maxY * 0.72))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
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
