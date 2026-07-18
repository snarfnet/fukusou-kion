import SwiftUI

enum AurumTheme {
    static let ink = Color(red: 0.055, green: 0.050, blue: 0.045)
    static let charcoal = Color(red: 0.105, green: 0.095, blue: 0.082)
    static let parchment = Color(red: 0.88, green: 0.81, blue: 0.67)
    static let muted = Color(red: 0.63, green: 0.58, blue: 0.49)
    static let gold = Color(red: 0.78, green: 0.58, blue: 0.22)
    static let ember = Color(red: 0.63, green: 0.20, blue: 0.12)
}

struct ManuscriptBackground: View {
    var body: some View {
        ZStack {
            AurumTheme.ink
            Image("SanctuaryBackground")
                .resizable()
                .scaledToFill()
                .opacity(0.74)
            LinearGradient(
                colors: [AurumTheme.ink.opacity(0.08), AurumTheme.ink.opacity(0.48), AurumTheme.ink.opacity(0.95)],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(colors: [.clear, AurumTheme.ink.opacity(0.64)], center: .center, startRadius: 80, endRadius: 430)
        }
        .ignoresSafeArea()
    }
}

struct MysticCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(22)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 20).fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 20).fill(AurumTheme.charcoal.opacity(0.7))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [AurumTheme.gold.opacity(0.72), AurumTheme.gold.opacity(0.12), AurumTheme.gold.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            }
            .shadow(color: .black.opacity(0.56), radius: 22, y: 12)
    }
}

struct StageSeal: View {
    let stage: Stage

    var body: some View {
        ZStack {
            Circle().stroke(AurumTheme.gold.opacity(0.2), lineWidth: 1).frame(width: 118, height: 118)
            Circle()
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [2, 7]))
                .foregroundStyle(AurumTheme.gold.opacity(0.62))
                .frame(width: 98, height: 98)
            Circle().fill(AurumTheme.ink.opacity(0.78)).frame(width: 72, height: 72)
                .overlay(Circle().stroke(AurumTheme.gold.opacity(0.72), lineWidth: 1))
            Image(systemName: stage.mark)
                .font(.system(size: 27, weight: .light))
                .foregroundStyle(AurumTheme.gold)
        }
        .accessibilityHidden(true)
    }
}

struct GoldCapsule: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(.subheadline, design: .serif, weight: .semibold))
            .foregroundStyle(AurumTheme.ink)
            .padding(.horizontal, 18)
            .padding(.vertical, 13)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(LinearGradient(colors: [Color(red: 0.9, green: 0.72, blue: 0.36), AurumTheme.gold], startPoint: .top, endPoint: .bottom))
                    .shadow(color: AurumTheme.gold.opacity(0.25), radius: 12, y: 5)
            )
    }
}
