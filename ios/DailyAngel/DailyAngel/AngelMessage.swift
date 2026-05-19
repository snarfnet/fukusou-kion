import Foundation

struct AngelPayload: Decodable {
    let name: String
    let version: Int
    let noteJa: String
    let noteEn: String
    let messages: [AngelMessage]

    enum CodingKeys: String, CodingKey {
        case name
        case version
        case noteJa = "note_ja"
        case noteEn = "note_en"
        case messages
    }
}

struct AngelMessage: Identifiable, Codable, Hashable {
    var id: Int { day }

    let day: Int
    let theme: String
    let themeJa: String
    let themeEn: String
    let angelic: String
    let ja: String
    let en: String
    let actionJa: String
    let actionEn: String
    let tags: [String]

    enum CodingKeys: String, CodingKey {
        case day
        case theme
        case themeJa = "theme_ja"
        case themeEn = "theme_en"
        case angelic
        case ja
        case en
        case actionJa = "action_ja"
        case actionEn = "action_en"
        case tags
    }
}

enum AngelTheme {
    static func colorName(for key: String) -> String {
        switch key {
        case "light":
            return "sun.max"
        case "water":
            return "drop"
        case "air":
            return "wind"
        case "earth":
            return "leaf"
        case "fire":
            return "flame"
        case "moon":
            return "moon"
        case "dream":
            return "sparkles"
        case "gate":
            return "door.left.hand.open"
        case "silence":
            return "bell.slash"
        case "heart":
            return "heart"
        default:
            return "sparkle"
        }
    }
}
