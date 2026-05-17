import SwiftUI

enum AppPhase {
    case title
    case story
    case menu
    case battle
    case result
    case gacha
}

struct Player: Identifiable, Equatable {
    let id: Int
    let name: String
    let symbol: String
    let color: Color
    let line: String
}

struct BoardCell: Identifiable, Equatable {
    let id: Int
    var owner: Int?
    var hasMine: Bool
    var hasGas: Bool
    var contaminatedTurns: Int
}

struct GachaReward: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let rarity: String
}

enum GameTheme {
    static let bg = Color(red: 0.04, green: 0.03, blue: 0.025)
    static let panel = Color(red: 0.12, green: 0.10, blue: 0.085)
    static let rust = Color(red: 0.62, green: 0.16, blue: 0.08)
    static let amber = Color(red: 1.0, green: 0.78, blue: 0.24)
    static let bone = Color(red: 0.96, green: 0.88, blue: 0.72)
    static let smoke = Color(red: 0.70, green: 0.63, blue: 0.55)
    static let poison = Color(red: 0.63, green: 0.20, blue: 0.95)
}
