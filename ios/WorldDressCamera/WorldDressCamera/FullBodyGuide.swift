import SwiftUI

struct FullBodyGuide: View {
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let guides: [(fraction: CGFloat, label: String)] = [
                (0.07, "頭頂"), (0.25, "肩"), (0.49, "腰"), (0.69, "膝"), (0.92, "足元")
            ]
            ZStack {
                Path { path in
                    path.addEllipse(in: CGRect(x: w * 0.43, y: h * 0.07, width: w * 0.14, height: w * 0.18))
                    path.move(to: CGPoint(x: w * 0.42, y: h * 0.25))
                    path.addCurve(to: CGPoint(x: w * 0.36, y: h * 0.56),
                                  control1: CGPoint(x: w * 0.35, y: h * 0.33),
                                  control2: CGPoint(x: w * 0.38, y: h * 0.46))
                    path.move(to: CGPoint(x: w * 0.58, y: h * 0.25))
                    path.addCurve(to: CGPoint(x: w * 0.64, y: h * 0.56),
                                  control1: CGPoint(x: w * 0.65, y: h * 0.33),
                                  control2: CGPoint(x: w * 0.62, y: h * 0.46))
                    path.move(to: CGPoint(x: w * 0.43, y: h * 0.24))
                    path.addLine(to: CGPoint(x: w * 0.40, y: h * 0.92))
                    path.move(to: CGPoint(x: w * 0.57, y: h * 0.24))
                    path.addLine(to: CGPoint(x: w * 0.60, y: h * 0.92))
                }
                .stroke(.white.opacity(0.9), style: StrokeStyle(lineWidth: 2, dash: [8, 6]))

                ForEach(Array(guides.enumerated()), id: \.offset) { _, item in
                    HStack(spacing: 8) {
                        Text(item.label)
                            .font(.caption2.bold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(.black.opacity(0.45), in: Capsule())
                        Rectangle().fill(.white.opacity(0.55)).frame(height: 1)
                    }
                    .position(x: w * 0.54, y: h * item.fraction)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
