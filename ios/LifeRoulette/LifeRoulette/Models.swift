import Foundation
import SwiftUI

enum NumberTheme: String, CaseIterable, Identifiable, Codable {
    case today = "今日の数字"
    case name = "名前の数字"
    case choice = "迷った時"
    case custom = "自由入力"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .today: "calendar"
        case .name: "person.text.rectangle"
        case .choice: "signpost.right"
        case .custom: "number"
        }
    }

    var colors: [Color] {
        switch self {
        case .today: [.yellow, .orange, .pink]
        case .name: [.cyan, .blue, .indigo]
        case .choice: [.mint, .green, .yellow]
        case .custom: [.white, .cyan, .pink]
        }
    }
}

struct NumberReading: Identifiable, Hashable {
    let id = UUID()
    let number: Int
    let title: String
    let message: String
    let hint: String
}

struct NumberHistoryItem: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    let theme: NumberTheme
    let input: String
    let number: Int
    let title: String
    let message: String

    var shareText: String {
        """
        数字のお話
        \(theme.rawValue): \(input)
        数字: \(number)
        \(title)
        \(message)
        """
    }
}
