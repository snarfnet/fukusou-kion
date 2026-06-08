import Foundation
import SwiftUI

enum WasteCategory: String, CaseIterable, Codable, Identifiable {
    case burnable = "燃やすごみ"
    case nonBurnable = "燃やさないごみ"
    case recyclable = "資源"
    case plastic = "プラスチック"
    case bulky = "粗大ごみ"

    var id: String { rawValue }

    var tint: Color {
        switch self {
        case .burnable: .red
        case .nonBurnable: .gray
        case .recyclable: .green
        case .plastic: .blue
        case .bulky: .orange
        }
    }
}

struct CollectionRule: Codable, Identifiable, Equatable {
    var id = UUID()
    var municipality: String
    var townKeyword: String
    var category: WasteCategory
    var weekday: Int
    var memo: String

    func matches(address: AddressResult) -> Bool {
        let municipalityMatches = municipality.isEmpty || address.municipality.contains(municipality)
        let townMatches = townKeyword.isEmpty || address.town.contains(townKeyword)
        return municipalityMatches && townMatches
    }
}

struct CollectionDay: Identifiable, Equatable {
    var id: String { "\(date.timeIntervalSince1970)-\(rule.id)" }
    var date: Date
    var rule: CollectionRule

    var dayText: String {
        Self.dayFormatter.string(from: date)
    }

    var weekdayText: String {
        Self.weekdayFormatter.string(from: date)
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d"
        return formatter
    }()

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "E"
        return formatter
    }()
}
