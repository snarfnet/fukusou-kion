import SwiftUI

@Observable
final class ReadingTracker {
    private(set) var readIds: Set<Int> = []
    private(set) var quizCorrect: Int = 0
    private(set) var quizTotal: Int = 0
    private(set) var streak: Int = 0
    private(set) var lastReadDate: String = ""

    private let readKey = "readWisdomIds"
    private let quizCorrectKey = "quizCorrectCount"
    private let quizTotalKey = "quizTotalCount"
    private let streakKey = "readingStreak"
    private let lastDateKey = "lastReadDate"

    init() {
        let ids = UserDefaults.standard.array(forKey: readKey) as? [Int] ?? []
        readIds = Set(ids)
        quizCorrect = UserDefaults.standard.integer(forKey: quizCorrectKey)
        quizTotal = UserDefaults.standard.integer(forKey: quizTotalKey)
        streak = UserDefaults.standard.integer(forKey: streakKey)
        lastReadDate = UserDefaults.standard.string(forKey: lastDateKey) ?? ""
        updateStreak()
    }

    func markRead(_ id: Int) {
        readIds.insert(id)
        UserDefaults.standard.set(Array(readIds), forKey: readKey)
        updateStreak()
    }

    func recordQuiz(correct: Bool) {
        quizTotal += 1
        if correct { quizCorrect += 1 }
        UserDefaults.standard.set(quizCorrect, forKey: quizCorrectKey)
        UserDefaults.standard.set(quizTotal, forKey: quizTotalKey)
    }

    var quizAccuracy: Double {
        guard quizTotal > 0 else { return 0 }
        return Double(quizCorrect) / Double(quizTotal) * 100
    }

    private func updateStreak() {
        let today = Self.dateString(Date())
        if lastReadDate == today { return }

        let yesterday = Self.dateString(Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        if lastReadDate == yesterday {
            streak += 1
        } else if lastReadDate != today {
            streak = 1
        }
        lastReadDate = today
        UserDefaults.standard.set(streak, forKey: streakKey)
        UserDefaults.standard.set(lastReadDate, forKey: lastDateKey)
    }

    private static func dateString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
