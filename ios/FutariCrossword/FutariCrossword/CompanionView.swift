import SwiftUI

struct CompanionView: View {
    let line: CompanionLine
    @State private var blink = false

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: [Color(red: 0.18, green: 0.10, blue: 0.06), Color(red: 0.39, green: 0.22, blue: 0.12)], startPoint: .top, endPoint: .bottom)
            cafeDetails
            HStack(alignment: .bottom, spacing: 14) {
                face
                    .frame(width: 122, height: 138)
                Text(line.text)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(red: 0.20, green: 0.12, blue: 0.08))
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.cream, in: RoundedRectangle(cornerRadius: 22))
                    .overlay(alignment: .bottomLeading) { Triangle().fill(.cream).frame(width: 18, height: 14).rotationEffect(.degrees(20)).offset(x: -8, y: -8) }
            }
            .padding(.horizontal, 18).padding(.bottom, 12)
        }
        .frame(height: 210)
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

    private var cafeDetails: some View {
        VStack { HStack { Circle().fill(.orange.opacity(0.28)).frame(width: 70).blur(radius: 12); Spacer(); RoundedRectangle(cornerRadius: 3).fill(.yellow.opacity(0.13)).frame(width: 90, height: 120) }.padding(); Spacer() }
    }

    private var face: some View {
        ZStack {
            Ellipse().fill(Color(red: 0.18, green: 0.09, blue: 0.06)).frame(width: 112, height: 132).offset(y: -5)
            Ellipse().fill(Color(red: 0.95, green: 0.76, blue: 0.64)).frame(width: 86, height: 106)
            hair
            eyes.offset(y: -11)
            mouth.offset(y: 18)
            if [.delighted, .shy, .surprised].contains(line.expression) {
                HStack(spacing: 53) { Circle().fill(.pink.opacity(0.45)); Circle().fill(.pink.opacity(0.45)) }.frame(width: 72, height: 10).offset(y: 9)
            }
            if line.expression == .surprised { Text("!").font(.title.bold()).foregroundStyle(.amber).offset(x: 51, y: -55) }
            if line.expression == .thinking { Circle().fill(.cream.opacity(0.8)).frame(width: 8).offset(x: 46, y: -44) }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: line.expression)
    }

    private var hair: some View {
        ZStack {
            Capsule().fill(Color(red: 0.12, green: 0.06, blue: 0.04)).frame(width: 92, height: 36).offset(y: -46)
            Capsule().fill(Color(red: 0.12, green: 0.06, blue: 0.04)).frame(width: 24, height: 72).rotationEffect(.degrees(13)).offset(x: -38, y: -18)
        }
    }

    private var eyes: some View {
        HStack(spacing: 25) {
            ForEach(0..<2) { _ in
                Group {
                    if blink || [.delighted, .shy].contains(line.expression) { Capsule().fill(.brown).frame(width: 17, height: 3) }
                    else if line.expression == .worried { Capsule().fill(.brown).frame(width: 15, height: 5).rotationEffect(.degrees(-8)) }
                    else { Ellipse().fill(.brown).frame(width: line.expression == .surprised ? 12 : 10, height: line.expression == .surprised ? 16 : 13).overlay(Circle().fill(.white).frame(width: 3).offset(x: -2, y: -3)) }
                }
            }
        }
    }

    @ViewBuilder private var mouth: some View {
        switch line.expression {
        case .delighted, .cheering, .proud: Capsule().fill(.red.opacity(0.72)).frame(width: 27, height: 10)
        case .surprised: Circle().stroke(.red.opacity(0.7), lineWidth: 3).frame(width: 11)
        case .worried: Capsule().stroke(.red.opacity(0.65), lineWidth: 2).frame(width: 18, height: 7).rotationEffect(.degrees(180))
        case .shy: Capsule().fill(.red.opacity(0.6)).frame(width: 19, height: 6).rotationEffect(.degrees(-4))
        default: Capsule().fill(.red.opacity(0.6)).frame(width: 20, height: 6)
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path { Path { $0.move(to: .init(x: 0, y: 0)); $0.addLine(to: .init(x: rect.maxX, y: rect.midY)); $0.addLine(to: .init(x: 0, y: rect.maxY)); $0.closeSubpath() } }
}
