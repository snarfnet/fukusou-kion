import SwiftUI

struct CompanionView: View {
    let line: CompanionLine
    var height: CGFloat = 224
    var compact = false
    @State private var blink = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Image("CompanionCafe")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(y: compact ? 22 : 0)
                .clipped()
                .saturation(line.expression == .worried ? 0.72 : 1)
                .brightness(line.expression == .delighted ? 0.06 : 0)
                .scaleEffect([.surprised, .delighted].contains(line.expression) ? 1.025 : 1)
            LinearGradient(colors: [.clear, .black.opacity(0.7)], startPoint: .center, endPoint: .bottom)
            HStack(alignment: .bottom, spacing: 10) {
                expressionBadge
                Text(line.text)
                    .font(.system(size: compact ? 13 : 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 0.20, green: 0.12, blue: 0.08))
                    .lineLimit(compact ? 2 : 3)
                    .minimumScaleFactor(0.78)
                    .padding(compact ? 9 : 16)
                    .frame(minHeight: compact ? 48 : nil)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.cream, in: RoundedRectangle(cornerRadius: 22))
                    .overlay(alignment: .bottomLeading) { Triangle().fill(.cream).frame(width: 18, height: 14).rotationEffect(.degrees(20)).offset(x: -8, y: -8) }
            }
            .padding(.horizontal, compact ? 10 : 18)
            .padding(.bottom, compact ? 9 : 12)
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("彼女は\(line.expression.label)の表情。\(line.text)")
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Double.random(in: 2.5...5)))
                withAnimation(.easeInOut(duration: 0.09)) { blink = true }
                try? await Task.sleep(for: .milliseconds(120))
                withAnimation(.easeInOut(duration: 0.09)) { blink = false }
            }
        }
    }

    @ViewBuilder private var expressionBadge: some View {
        switch line.expression {
        case .thinking: badge("ellipsis.bubble.fill", .amber)
        case .delighted: badge("heart.fill", .pink)
        case .surprised: badge("exclamationmark", .amber)
        case .worried: badge("drop.fill", .cyan)
        case .cheering: badge("sparkles", .amber)
        case .proud: badge("lightbulb.fill", .yellow)
        case .shy: badge("heart.circle.fill", .pink)
        case .gentle: badge("cup.and.saucer.fill", .cream)
        }
    }

    private func badge(_ symbol: String, _ color: Color) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(color)
            .frame(width: compact ? 30 : 38, height: compact ? 30 : 38)
            .background(.black.opacity(0.58), in: Circle())
            .scaleEffect(blink ? 0.92 : 1)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path { Path { $0.move(to: .init(x: 0, y: 0)); $0.addLine(to: .init(x: rect.maxX, y: rect.midY)); $0.addLine(to: .init(x: 0, y: rect.maxY)); $0.closeSubpath() } }
}
