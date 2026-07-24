import Foundation

enum TileSuit: String, CaseIterable, Hashable, Codable {
    case man = "萬"
    case pin = "筒"
    case sou = "索"
    case honor = "字"
}

struct MahjongTile: Identifiable, Hashable, Codable {
    let id: UUID
    let suit: TileSuit
    let value: Int

    init(id: UUID = UUID(), suit: TileSuit, value: Int) {
        self.id = id
        self.suit = suit
        self.value = value
    }

    var label: String {
        if suit == .honor {
            return ["東", "南", "西", "北", "白", "發", "中"][value - 1]
        }
        return "\(value)\(suit.rawValue)"
    }

    var spokenLabel: String {
        if suit == .honor {
            return ["東", "南", "西", "北", "白", "發", "中"][value - 1]
        }
        let suitName: String
        switch suit {
        case .man: suitName = "ワンズ"
        case .pin: suitName = "ピンズ"
        case .sou: suitName = "ソウズ"
        case .honor: suitName = ""
        }
        return "\(value)\(suitName)"
    }
}
