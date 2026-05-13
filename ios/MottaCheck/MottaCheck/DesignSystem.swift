import SwiftUI

enum AppTheme {
    static let background = Color(red: 0.96, green: 0.97, blue: 0.94)
    static let panel = Color.white
    static let ink = Color(red: 0.10, green: 0.13, blue: 0.12)
    static let muted = Color(red: 0.42, green: 0.46, blue: 0.42)
    static let olive = Color(red: 0.15, green: 0.38, blue: 0.30)
    static let blue = Color(red: 0.19, green: 0.35, blue: 0.65)
    static let coral = Color(red: 0.77, green: 0.28, blue: 0.22)
    static let mint = Color(red: 0.10, green: 0.50, blue: 0.40)
    static let rose = Color(red: 0.68, green: 0.20, blue: 0.34)

    static func tint(_ name: String) -> Color {
        switch name {
        case "blue": blue
        case "coral": coral
        case "mint": mint
        case "rose": rose
        default: olive
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppTheme.olive.opacity(configuration.isPressed ? 0.78 : 1), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct Panel<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
    }
}
