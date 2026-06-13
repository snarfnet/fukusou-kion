import Foundation

enum ClothingCategory: String, CaseIterable, Identifiable {
    case tops = "トップス"
    case pants = "パンツ"
    case skirt = "スカート"
    case onepiece = "ワンピース"
    case outer = "アウター"

    var id: String { rawValue }

    var measurementItems: [MeasurementItem] {
        switch self {
        case .tops:
            return [
                .init(name: "肩幅"),
                .init(name: "身幅"),
                .init(name: "着丈"),
                .init(name: "袖丈")
            ]
        case .pants:
            return [
                .init(name: "ウエスト"),
                .init(name: "股上"),
                .init(name: "股下"),
                .init(name: "わたり幅"),
                .init(name: "裾幅"),
                .init(name: "総丈")
            ]
        case .skirt:
            return [
                .init(name: "ウエスト"),
                .init(name: "総丈"),
                .init(name: "ヒップ")
            ]
        case .onepiece:
            return [
                .init(name: "肩幅"),
                .init(name: "身幅"),
                .init(name: "ウエスト"),
                .init(name: "総丈"),
                .init(name: "袖丈")
            ]
        case .outer:
            return [
                .init(name: "肩幅"),
                .init(name: "身幅"),
                .init(name: "着丈"),
                .init(name: "袖丈")
            ]
        }
    }
}

struct MeasurementItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    var value: String = ""

    var isFilled: Bool {
        !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var label: String {
        "\(name) \(value)cm"
    }
}

struct Annotation: Identifiable {
    let id = UUID()
    var itemName: String
    var valueText: String
    var start: CGPoint
    var end: CGPoint
}
