import SwiftUI

enum AppPhase {
    case title
    case story
    case menu
    case battle
    case result
    case gacha
}

enum CharacterRarity: String, CaseIterable, Comparable {
    case n = "N"
    case r = "R"
    case sr = "SR"
    case ssr = "SSR"
    case ur = "UR"

    var rank: Int {
        switch self {
        case .n: 0
        case .r: 1
        case .sr: 2
        case .ssr: 3
        case .ur: 4
        }
    }

    var color: Color {
        switch self {
        case .n: GameTheme.smoke
        case .r: .cyan
        case .sr: GameTheme.amber
        case .ssr: GameTheme.poison
        case .ur: .red
        }
    }

    static func < (lhs: CharacterRarity, rhs: CharacterRarity) -> Bool {
        lhs.rank < rhs.rank
    }
}

enum CharacterAbilityKind: String {
    case mineScatter
    case bikeCharge
    case flameThrower
    case empBomb
    case overdrive
}

struct BattleCharacter: Identifiable, Equatable {
    let id: String
    let name: String
    let title: String
    let rarity: CharacterRarity
    let imageName: String
    let abilityName: String
    let abilityKind: CharacterAbilityKind
    let maxUses: Int
    let line: String
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
    var hasScrapTrap: Bool
    var hasShield: Bool
    var shieldOwner: Int?
    var contaminatedTurns: Int
}

struct GachaReward: Identifiable, Equatable {
    let id = UUID()
    let character: BattleCharacter
    let isNew: Bool
}

struct AIHandMove: Identifiable, Equatable {
    let id = UUID()
    let playerID: Int
    let targetCell: Int
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
