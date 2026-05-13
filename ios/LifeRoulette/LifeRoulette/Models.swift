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

    var promptTitle: String {
        switch self {
        case .today: "日付や今日の気分"
        case .name: "名前"
        case .choice: "迷っていること"
        case .custom: "数字や短い言葉"
        }
    }

    var placeholder: String {
        switch self {
        case .today: "例: 2026/05/14"
        case .name: "例: さくら"
        case .choice: "例: 転職するか迷っている"
        case .custom: "例: 777"
        }
    }

    var tint: Color {
        switch self {
        case .today: Color(red: 0.93, green: 0.62, blue: 0.18)
        case .name: Color(red: 0.20, green: 0.62, blue: 0.72)
        case .choice: Color(red: 0.37, green: 0.58, blue: 0.36)
        case .custom: Color(red: 0.72, green: 0.34, blue: 0.49)
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
