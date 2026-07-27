import SwiftUI

@MainActor
final class CalculatorStore: ObservableObject {
    @Published var display = "0"
    @Published var expression = ""
    @Published var mode: CalculatorMode = .scientific
    @Published var history: [HistoryEntry] = []
    @Published var isDegrees = true

    private var accumulator: Double?
    private var pendingOperation: BinaryOperation?
    private var startsNewNumber = true
    private let historyKey = "kazu.history"

    init() {
        if let data = UserDefaults.standard.data(forKey: historyKey),
           let decoded = try? JSONDecoder().decode([HistoryEntry].self, from: data) {
            history = decoded
        }
    }

    var value: Double { Double(display.replacingOccurrences(of: ",", with: "")) ?? 0 }

    func inputDigit(_ digit: String) {
        if startsNewNumber || display == "エラー" {
            display = digit == "." ? "0." : digit
            startsNewNumber = false
        } else if digit == "." {
            if !display.contains(".") { display += "." }
        } else if display.replacingOccurrences(of: "-", with: "").count < 14 {
            display = display == "0" ? digit : display + digit
        }
    }

    func setOperation(_ operation: BinaryOperation) {
        if pendingOperation != nil, !startsNewNumber { evaluate() }
        accumulator = value
        pendingOperation = operation
        expression = "\(display) \(operation.rawValue)"
        startsNewNumber = true
    }

    func evaluate() {
        guard let lhs = accumulator, let operation = pendingOperation else { return }
        let rhs = value
        let fullExpression = "\(NumberFormatter.display(lhs)) \(operation.rawValue) \(NumberFormatter.display(rhs))"
        guard let result = operation.apply(lhs, rhs) else {
            display = "エラー"
            resetPending()
            return
        }
        display = NumberFormatter.display(result)
        expression = fullExpression
        appendHistory(expression: fullExpression, result: display)
        accumulator = result
        pendingOperation = nil
        startsNewNumber = true
    }

    func apply(_ operation: UnaryOperation) {
        let input = value
        guard let result = operation.apply(input, degrees: isDegrees) else {
            display = "エラー"
            startsNewNumber = true
            return
        }
        let fullExpression = "\(operation.rawValue)(\(NumberFormatter.display(input)))"
        display = NumberFormatter.display(result)
        expression = fullExpression
        appendHistory(expression: fullExpression, result: display)
        startsNewNumber = true
    }

    func clear() {
        display = "0"
        expression = ""
        accumulator = nil
        pendingOperation = nil
        startsNewNumber = true
    }

    func backspace() {
        guard !startsNewNumber, display != "エラー" else { return }
        display.removeLast()
        if display.isEmpty || display == "-" { display = "0"; startsNewNumber = true }
    }

    func toggleSign() {
        guard display != "0", display != "エラー" else { return }
        display = display.hasPrefix("-") ? String(display.dropFirst()) : "-" + display
    }

    func useHistory(_ entry: HistoryEntry) {
        display = entry.result
        expression = entry.expression
        startsNewNumber = true
    }

    func clearHistory() {
        history = []
        saveHistory()
    }

    func deleteHistory(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            history.remove(at: index)
        }
        saveHistory()
    }

    func recordSpecial(_ expression: String, result: Double) {
        let formatted = NumberFormatter.display(result)
        appendHistory(expression: expression, result: formatted)
    }

    private func resetPending() {
        accumulator = nil
        pendingOperation = nil
        startsNewNumber = true
    }

    private func appendHistory(expression: String, result: String) {
        history.insert(HistoryEntry(expression: expression, result: result), at: 0)
        history = Array(history.prefix(100))
        saveHistory()
    }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }
}
