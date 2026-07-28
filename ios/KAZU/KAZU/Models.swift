import Foundation

enum CalculatorMode: String, CaseIterable, Identifiable {
    case standard = "標準"
    case scientific = "関数"
    case finance = "金融"
    case convert = "換算"
    case date = "日付"
    case statistics = "統計"
    case geometry = "図形"
    case compound = "複利"
    case percentage = "割合"
    case health = "健康"
    case electrical = "電気"

    var id: Self { self }

    var symbol: String {
        switch self {
        case .standard: "plus.forwardslash.minus"
        case .scientific: "function"
        case .finance: "banknote"
        case .convert: "arrow.left.arrow.right"
        case .date: "calendar"
        case .statistics: "chart.bar"
        case .geometry: "triangle"
        case .compound: "chart.line.uptrend.xyaxis"
        case .percentage: "percent"
        case .health: "heart.text.square"
        case .electrical: "bolt"
        }
    }
}

struct HistoryEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let expression: String
    let result: String
    let createdAt: Date

    init(expression: String, result: String, createdAt: Date = .now) {
        id = UUID()
        self.expression = expression
        self.result = result
        self.createdAt = createdAt
    }
}

enum RootTab: String {
    case calculator = "電卓"
    case formulas = "公式"
    case history = "履歴"
}
