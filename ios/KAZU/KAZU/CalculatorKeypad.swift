import SwiftUI

struct CalculatorKeypad: View {
    @EnvironmentObject private var store: CalculatorStore
    let scientific: Bool

    private let basicRows = [
        ["AC", "⌫", "±", "÷"],
        ["7", "8", "9", "×"],
        ["4", "5", "6", "−"],
        ["1", "2", "3", "+"],
        ["%", "0", ".", "="]
    ]

    var body: some View {
        VStack(spacing: 10) {
            if scientific {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(["sin", "cos", "tan", "log", "√", "x²", "1/x", "xʸ"], id: \.self) { function in
                        KeyButton(title: function, kind: .function) { handle(function) }
                    }
                }
            }
            ForEach(basicRows, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.self) { title in
                        KeyButton(title: title, kind: kind(for: title)) { handle(title) }
                    }
                }
            }
        }
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
    }

    private func kind(for title: String) -> KeyKind {
        if title == "=" { return .equal }
        if title == "AC" { return .clear }
        if ["÷", "×", "−", "+", "%"].contains(title) { return .operation }
        return .number
    }

    private func handle(_ title: String) {
        switch title {
        case ".":
            store.inputDigit(title)
        case "AC": store.clear()
        case "⌫": store.backspace()
        case "±": store.toggleSign()
        case "=": store.evaluate()
        case "+": store.setOperation(.add)
        case "−": store.setOperation(.subtract)
        case "×": store.setOperation(.multiply)
        case "÷": store.setOperation(.divide)
        case "xʸ": store.setOperation(.power)
        case "sin": store.apply(.sin)
        case "cos": store.apply(.cos)
        case "tan": store.apply(.tan)
        case "log": store.apply(.log)
        case "√": store.apply(.sqrt)
        case "x²": store.apply(.square)
        case "1/x": store.apply(.reciprocal)
        case "%": store.apply(.percent)
        default:
            if title.count == 1, title.first?.isNumber == true {
                store.inputDigit(title)
            }
        }
    }
}

private enum KeyKind {
    case number, operation, function, clear, equal
}

private struct KeyButton: View {
    let title: String
    let kind: KeyKind
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: title.count > 2 ? 19 : 25, weight: .medium, design: .rounded))
                .frame(maxWidth: .infinity, minHeight: kind == .function ? 52 : 62)
                .foregroundStyle(foreground)
                .background(background, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(KazuTheme.line.opacity(0.62)))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(weight: .light), trigger: title)
        .accessibilityLabel(accessibilityName)
    }

    private var background: Color {
        switch kind {
        case .equal: KazuTheme.cobalt
        case .clear: KazuTheme.coral
        case .operation, .function: KazuTheme.paleBlue
        case .number: Color.white.opacity(0.72)
        }
    }

    private var foreground: Color {
        kind == .equal || kind == .clear ? .white : KazuTheme.ink
    }

    private var accessibilityName: String {
        ["÷": "割る", "×": "掛ける", "−": "引く", "+": "足す", "=": "計算",
         "⌫": "一文字削除", "±": "正負を反転", "AC": "すべて消去"][title] ?? title
    }
}
