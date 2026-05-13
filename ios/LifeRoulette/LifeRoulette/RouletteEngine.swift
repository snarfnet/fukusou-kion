import Foundation

struct NumberReadingEngine {
    func reading(for rawInput: String, theme: NumberTheme) -> NumberReading {
        let input = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = input.isEmpty ? defaultSeed(for: theme) : input
        let number = reduceToSingleDigit(base)
        let story = NumberStoryBank.shared.story(for: number, theme: theme)

        return NumberReading(
            number: number,
            title: story.title,
            message: story.message,
            hint: story.hint
        )
    }

    private func defaultSeed(for theme: NumberTheme) -> String {
        switch theme {
        case .today:
            return ISO8601DateFormatter().string(from: Date())
        case .name:
            return "なまえ"
        case .choice:
            return "まよう"
        case .custom:
            return "数字"
        }
    }

    private func reduceToSingleDigit(_ text: String) -> Int {
        let scalars = text.unicodeScalars.map { Int($0.value) }
        let total = scalars.reduce(0, +)
        let reduced = total % 9
        return reduced == 0 ? 9 : reduced
    }
}
