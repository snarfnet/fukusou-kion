import SwiftUI

enum PhotoCanvas {
    static let aspectRatio: CGFloat = 3.0 / 4.0
}

struct FullBodyGuide: View {
    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            let guides: [(fraction: CGFloat, label: String)] = [
                (0.05, "頭頂"), (0.24, "肩"), (0.49, "腰"), (0.69, "膝"), (0.92, "足元")
            ]
            ZStack {
                Path { path in
                    // Leave room for hair, hats and natural head movement.
                    path.addEllipse(in: CGRect(x: w * 0.40, y: h * 0.045, width: w * 0.20, height: h * 0.145))
                    path.move(to: CGPoint(x: w * 0.40, y: h * 0.24))
                    path.addCurve(to: CGPoint(x: w * 0.36, y: h * 0.56),
                                  control1: CGPoint(x: w * 0.35, y: h * 0.33),
                                  control2: CGPoint(x: w * 0.38, y: h * 0.46))
                    path.move(to: CGPoint(x: w * 0.60, y: h * 0.24))
                    path.addCurve(to: CGPoint(x: w * 0.64, y: h * 0.56),
                                  control1: CGPoint(x: w * 0.65, y: h * 0.33),
                                  control2: CGPoint(x: w * 0.62, y: h * 0.46))
                    path.move(to: CGPoint(x: w * 0.41, y: h * 0.23))
                    path.addLine(to: CGPoint(x: w * 0.40, y: h * 0.92))
                    path.move(to: CGPoint(x: w * 0.59, y: h * 0.23))
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

/// The camera and editor must use this same 3:4 coordinate space.
/// Keeping the guide out of the camera controls prevents the body marks from
/// shifting after a photo is captured.
struct FullBodyGuideCanvas: View {
    var showsBoundary = false

    var body: some View {
        FullBodyGuide()
            .overlay {
                if showsBoundary {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.white.opacity(0.75), lineWidth: 1)
                }
            }
            .aspectRatio(PhotoCanvas.aspectRatio, contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
