import SwiftUI

extension CharacterPalette {
    var colors: [Color] {
        switch self {
        case .crimson: return [.red, .orange]
        case .ice: return [.cyan, .white]
        case .gold: return [.yellow, .pink]
        case .violet: return [.purple, .indigo]
        case .tiger: return [.orange, .black]
        case .blackRose: return [.black, .pink]
        }
    }
}

extension Sukeban {
    var colors: [Color] {
        palette.colors
    }
}
