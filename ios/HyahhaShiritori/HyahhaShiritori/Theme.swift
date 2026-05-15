import SwiftUI

enum HTheme {
    static let ink = Color(red: 0.05, green: 0.035, blue: 0.028)
    static let soot = Color(red: 0.10, green: 0.075, blue: 0.055)
    static let rust = Color(red: 0.83, green: 0.27, blue: 0.10)
    static let amber = Color(red: 1.00, green: 0.72, blue: 0.18)
    static let paper = Color(red: 0.95, green: 0.86, blue: 0.65)
    static let bone = Color(red: 0.98, green: 0.93, blue: 0.82)
    static let smoke = Color.white.opacity(0.72)
    static let panel = Color(red: 0.12, green: 0.09, blue: 0.07).opacity(0.90)
    static let line = Color(red: 0.95, green: 0.62, blue: 0.25).opacity(0.25)

    static func color(_ name: ThemeColor) -> Color {
        switch name {
        case .rust: rust
        case .cyan: Color(red: 0.15, green: 0.78, blue: 0.82)
        case .yellow: Color(red: 0.96, green: 0.74, blue: 0.15)
        case .red: Color(red: 0.88, green: 0.13, blue: 0.10)
        case .mint: Color(red: 0.35, green: 0.86, blue: 0.55)
        case .violet: Color(red: 0.58, green: 0.38, blue: 0.92)
        case .sand: Color(red: 0.82, green: 0.62, blue: 0.38)
        case .pink: Color(red: 0.96, green: 0.33, blue: 0.50)
        case .steel: Color(red: 0.52, green: 0.60, blue: 0.64)
        case .gold: Color(red: 0.98, green: 0.66, blue: 0.12)
        }
    }
}

struct WastelandBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.16, green: 0.08, blue: 0.03),
                    HTheme.ink,
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [HTheme.rust.opacity(0.40), .clear],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 420
            )

            VStack {
                Spacer()
                UnevenRoundedRectangle(topLeadingRadius: 80, topTrailingRadius: 20)
                    .fill(Color.black.opacity(0.34))
                    .frame(height: 150)
                    .overlay(alignment: .top) {
                        Rectangle()
                            .fill(HTheme.amber.opacity(0.20))
                            .frame(height: 2)
                    }
            }

            ForEach(0..<14, id: \.self) { index in
                Rectangle()
                    .fill(HTheme.amber.opacity(index.isMultiple(of: 3) ? 0.24 : 0.10))
                    .frame(width: CGFloat(14 + index * 4), height: 2)
                    .rotationEffect(.degrees(index.isMultiple(of: 2) ? 12 : -9))
                    .offset(x: CGFloat((index % 5) * 86 - 180), y: CGFloat((index % 7) * 88 - 270))
            }
        }
        .ignoresSafeArea()
    }
}

extension View {
    func wastelandPanel() -> some View {
        self
            .padding(14)
            .background(HTheme.panel, in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(HTheme.line, lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.28), radius: 18, y: 10)
    }
}
