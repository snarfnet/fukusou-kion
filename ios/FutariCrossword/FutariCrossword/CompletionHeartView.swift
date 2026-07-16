import SwiftUI

struct CompletionHeartView: View {
    let praise: String
    let onFinished: () -> Void
    @State private var appeared = false

    private let hearts: [(x: CGFloat, y: CGFloat, size: CGFloat, delay: Double)] = [
        (-92, -48, 22, 0.05), (88, -62, 27, 0.12), (-112, 34, 18, 0.20),
        (105, 42, 20, 0.28), (-62, 88, 16, 0.34), (70, 94, 19, 0.40)
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(appeared ? 0.36 : 0)
                .ignoresSafeArea()

            ForEach(Array(hearts.enumerated()), id: \.offset) { _, heart in
                Image(systemName: "heart.fill")
                    .font(.system(size: heart.size, weight: .bold))
                    .foregroundStyle(.pink)
                    .offset(x: appeared ? heart.x : 0, y: appeared ? heart.y - 30 : 24)
                    .scaleEffect(appeared ? 1 : 0.15)
                    .opacity(appeared ? 0.9 : 0)
                    .animation(.spring(response: 0.55, dampingFraction: 0.62).delay(heart.delay), value: appeared)
            }

            VStack(spacing: 12) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 92, weight: .bold))
                    .foregroundStyle(.pink.gradient)
                    .shadow(color: .pink.opacity(0.55), radius: 20)
                    .scaleEffect(appeared ? 1 : 0.1)
                    .rotationEffect(.degrees(appeared ? 0 : -14))
                Text(praise)
                    .font(.title2.bold())
                    .foregroundStyle(.cream)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.72)
                    .frame(maxWidth: 310)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.62), in: Capsule())
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
            }
            .animation(.spring(response: 0.52, dampingFraction: 0.64), value: appeared)
        }
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("全部正解。彼女からハート")
        .task {
            appeared = true
            try? await Task.sleep(for: .seconds(2.8))
            withAnimation(.easeOut(duration: 0.35)) { appeared = false }
            try? await Task.sleep(for: .milliseconds(380))
            onFinished()
        }
    }
}
