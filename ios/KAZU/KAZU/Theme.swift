import SwiftUI

enum KazuTheme {
    static let canvas = Color(red: 0.97, green: 0.96, blue: 0.93)
    static let ink = Color(red: 0.02, green: 0.12, blue: 0.23)
    static let navy = Color(red: 0.01, green: 0.10, blue: 0.20)
    static let cobalt = Color(red: 0.08, green: 0.36, blue: 0.88)
    static let coral = Color(red: 0.95, green: 0.31, blue: 0.20)
    static let paleBlue = Color(red: 0.85, green: 0.89, blue: 0.93)
    static let line = Color(red: 0.79, green: 0.80, blue: 0.79)
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(KazuTheme.line.opacity(0.7)))
    }
}

extension View {
    func kazuCard() -> some View { modifier(CardStyle()) }
}

