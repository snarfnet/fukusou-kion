import Foundation

enum BinaryOperation: String {
    case add = "+"
    case subtract = "−"
    case multiply = "×"
    case divide = "÷"
    case power = "xʸ"

    func apply(_ lhs: Double, _ rhs: Double) -> Double? {
        return switch self {
        case .add: lhs + rhs
        case .subtract: lhs - rhs
        case .multiply: lhs * rhs
        case .divide: rhs == 0 ? nil : lhs / rhs
        case .power: Foundation.pow(lhs, rhs)
        }
    }
}

enum UnaryOperation: String {
    case sin, cos, tan, log, sqrt = "√", square = "x²", reciprocal = "1/x", percent = "%"

    func apply(_ value: Double, degrees: Bool = true) -> Double? {
        let angle = degrees ? value * .pi / 180 : value
        return switch self {
        case .sin: Foundation.sin(angle)
        case .cos: Foundation.cos(angle)
        case .tan: Foundation.tan(angle)
        case .log: value > 0 ? Foundation.log10(value) : nil
        case .sqrt: value >= 0 ? Foundation.sqrt(value) : nil
        case .square: value * value
        case .reciprocal: value == 0 ? nil : 1 / value
        case .percent: value / 100
        }
    }
}

enum NumberFormatter {
    static func display(_ value: Double) -> String {
        guard value.isFinite else { return "エラー" }
        if abs(value) >= 1e12 || (abs(value) > 0 && abs(value) < 1e-8) {
            return value.formatted(.number.notation(.scientific).precision(.significantDigits(10)))
        }
        return value.formatted(.number.grouping(.automatic).precision(.fractionLength(0...10)))
    }
}
