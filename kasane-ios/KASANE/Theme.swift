import SwiftUI

enum KasaneTheme {
    static let indigo = Color(red: 23/255, green: 43/255, blue: 77/255)
    static let deep = Color(red: 12/255, green: 28/255, blue: 52/255)
    static let paper = Color(red: 250/255, green: 248/255, blue: 242/255)
    static let vermilion = Color(red: 219/255, green: 75/255, blue: 50/255)
    static let mist = Color(red: 238/255, green: 241/255, blue: 237/255)
    static let muted = Color(red: 105/255, green: 113/255, blue: 122/255)
}

extension Font {
    static func kasaneSerif(_ size: CGFloat, weight: Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}

