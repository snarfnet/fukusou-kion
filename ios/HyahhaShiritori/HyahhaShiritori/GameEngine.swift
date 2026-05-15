import Foundation

enum ShiritoriEngine {
    static func firstKana(of word: String) -> String {
        guard let first = word.first else { return "" }
        return normalizeKana(String(first))
    }

    static func lastKana(of word: String) -> String {
        let chars = Array(word)
        guard !chars.isEmpty else { return "" }

        var index = chars.count - 1
        if chars[index] == "ー", index > 0 {
            index -= 1
        }

        return normalizeKana(String(chars[index]))
    }

    static func isNTrap(_ word: String) -> Bool {
        lastKana(of: word) == "ん"
    }

    static func connects(_ card: String, after prompt: String) -> Bool {
        firstKana(of: card) == lastKana(of: prompt)
    }

    private static func normalizeKana(_ kana: String) -> String {
        switch kana {
        case "ぁ": "あ"
        case "ぃ": "い"
        case "ぅ": "う"
        case "ぇ": "え"
        case "ぉ": "お"
        case "ゃ": "や"
        case "ゅ": "ゆ"
        case "ょ": "よ"
        case "っ": "つ"
        case "ゎ": "わ"
        default: kana
        }
    }
}

struct CardFactory {
    private let allWords: [String]
    private let bank: [String: [String]]

    init(bank: [String: [String]] = GameData.wordBank) {
        self.bank = bank
        self.allWords = Array(Set(bank.values.flatMap { $0 })).sorted()
    }

    func cards(after prompt: String, difficulty: Difficulty, combo: Int) -> [WordCard] {
        let required = ShiritoriEngine.lastKana(of: prompt)
        let candidates = (bank[required] ?? fallbackWords(for: required))
            .filter { !ShiritoriEngine.isNTrap($0) }
            .shuffled()

        let corrects = Array(candidates.prefix(difficulty.correctCardCount))
        let traps = trapWords(for: required, difficulty: difficulty)
        let wrongCount = max(0, 6 - corrects.count - traps.count)
        let wrongs = wrongWords(excluding: required, count: wrongCount)

        var result = corrects.map {
            WordCard(word: $0, kind: .correct, bonus: bonusText(for: $0, combo: combo))
        }
        result += traps.map {
            WordCard(word: $0, kind: .trap, bonus: "終末の「ん」")
        }
        result += wrongs.map {
            WordCard(word: $0, kind: .wrong, bonus: nil)
        }

        return result.shuffled()
    }

    private func fallbackWords(for required: String) -> [String] {
        allWords.filter { ShiritoriEngine.firstKana(of: $0) == required }
    }

    private func trapWords(for required: String, difficulty: Difficulty) -> [String] {
        guard difficulty != .beginner else { return [] }

        let traps = (bank[required] ?? [])
            .filter { ShiritoriEngine.isNTrap($0) }
            .shuffled()

        if difficulty == .middle {
            return Array(traps.prefix(1))
        }

        return Array(traps.prefix(2))
    }

    private func wrongWords(excluding required: String, count: Int) -> [String] {
        guard count > 0 else { return [] }

        return allWords
            .filter { ShiritoriEngine.firstKana(of: $0) != required }
            .filter { !ShiritoriEngine.isNTrap($0) }
            .shuffled()
            .prefix(count)
            .map { $0 }
    }

    private func bonusText(for word: String, combo: Int) -> String? {
        if word.count >= 6 {
            return "長語尾ボーナス"
        }
        if combo >= 4 {
            return "連結ボーナス"
        }
        return nil
    }
}
