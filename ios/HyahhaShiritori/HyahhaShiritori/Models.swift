import Foundation

enum Difficulty: Int, CaseIterable, Identifiable {
    case beginner
    case middle
    case hard

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .beginner: "初級"
        case .middle: "中級"
        case .hard: "上級"
        }
    }

    var subtitle: String {
        switch self {
        case .beginner: "正解多め"
        case .middle: "罠カードあり"
        case .hard: "一発勝負"
        }
    }

    var targetCombo: Int {
        switch self {
        case .beginner: 6
        case .middle: 8
        case .hard: 10
        }
    }

    var timeLimit: Int {
        switch self {
        case .beginner: 24
        case .middle: 18
        case .hard: 13
        }
    }

    var correctCardCount: Int {
        switch self {
        case .beginner: 2
        case .middle: 1
        case .hard: 1
        }
    }
}

enum BattleState: Equatable {
    case title
    case playing
    case roundWon
    case roundLost
    case cleared
}

enum CardKind: Equatable {
    case correct
    case wrong
    case trap
}

struct WordCard: Identifiable, Equatable {
    let id = UUID()
    let word: String
    let kind: CardKind
    let bonus: String?
}

struct Opponent: Identifiable, Equatable {
    let id: Int
    let name: String
    let title: String
    let colony: String
    let quote: String
    let firstWords: [String]
    let mark: String
    let colorName: ThemeColor
}

enum ThemeColor: String, Equatable {
    case rust
    case cyan
    case yellow
    case red
    case mint
    case violet
    case sand
    case pink
    case steel
    case gold
}

struct BattleLog: Identifiable, Equatable {
    let id = UUID()
    let text: String
}
