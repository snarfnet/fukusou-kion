import Foundation

struct NumberReadingEngine {
    func reading(for rawInput: String, theme: NumberTheme) -> NumberReading {
        let input = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let seed = input.isEmpty ? defaultSeed(for: theme) : input
        let number = reduceToSingleDigit(seed)
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
            Date.now.formatted(date: .numeric, time: .omitted)
        case .name:
            "なまえ"
        case .choice:
            "まよう"
        case .custom:
            "数字"
        }
    }

    private func reduceToSingleDigit(_ text: String) -> Int {
        let total = text.unicodeScalars.map { Int($0.value) }.reduce(0, +)
        let reduced = total % 9
        return reduced == 0 ? 9 : reduced
    }
}
