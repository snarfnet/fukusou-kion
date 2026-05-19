import Foundation

struct ZenLesson: Identifiable, Hashable {
    let id: Int
    let title: String
    let minutes: Int
    let summary: String
    let imageName: String
    let steps: [String]
}

struct ZenVisualGuide: Identifiable, Hashable {
    let id: Int
    let title: String
    let imageName: String
    let body: String
}

struct ZenQuote: Identifiable, Hashable {
    let id: Int
    let phrase: String
    let reading: String
    let meaning: String
}

struct PracticeLog: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    let minutes: Int
    let note: String
}

extension PracticeLog {
    init(minutes: Int, note: String) {
        self.id = UUID()
        self.date = Date()
        self.minutes = minutes
        self.note = note
    }
}

final class ZenProgressStore: ObservableObject {
    @Published var logs: [PracticeLog] = [] {
        didSet { saveLogs() }
    }

    @Published var completedLessonIDs: Set<Int> = [] {
        didSet { saveCompletedLessons() }
    }

    private let logsKey = "zenPower.practiceLogs"
    private let completedKey = "zenPower.completedLessons"

    init() {
        load()
    }

    var totalMinutes: Int {
        logs.reduce(0) { $0 + $1.minutes }
    }

    var todayMinutes: Int {
        let calendar = Calendar.current
        return logs
            .filter { calendar.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.minutes }
    }

    var streakDays: Int {
        let calendar = Calendar.current
        let days = Set(logs.map { calendar.startOfDay(for: $0.date) })
        guard !days.isEmpty else { return 0 }

        var streak = 0
        var day = calendar.startOfDay(for: Date())
        while days.contains(day) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previousDay
        }
        return streak
    }

    func addLog(minutes: Int, note: String) {
        let cleanNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        logs.insert(PracticeLog(minutes: minutes, note: cleanNote), at: 0)
    }

    func completeLesson(_ lesson: ZenLesson) {
        completedLessonIDs.insert(lesson.id)
    }

    private func load() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: logsKey),
           let decoded = try? JSONDecoder().decode([PracticeLog].self, from: data) {
            logs = decoded.sorted { $0.date > $1.date }
        }

        if let ids = defaults.array(forKey: completedKey) as? [Int] {
            completedLessonIDs = Set(ids)
        }
    }

    private func saveLogs() {
        guard let data = try? JSONEncoder().encode(logs) else { return }
        UserDefaults.standard.set(data, forKey: logsKey)
    }

    private func saveCompletedLessons() {
        UserDefaults.standard.set(Array(completedLessonIDs), forKey: completedKey)
    }
}

enum ZenContent {
    static let lessons: [ZenLesson] = [
        ZenLesson(
            id: 1,
            title: "まず座る",
            minutes: 3,
            summary: "姿勢を整え、呼吸を数えるだけで始めます。",
            imageName: "zen-posture",
            steps: [
                "背中をまっすぐにして座る",
                "目線を少し落とす",
                "吐く息を一つずつ数える",
                "考えが出たら、数に戻る"
            ]
        ),
        ZenLesson(
            id: 2,
            title: "雑念を敵にしない",
            minutes: 5,
            summary: "浮かぶ考えを追わず、消そうともせず、ただ戻ります。",
            imageName: "zen-thoughts",
            steps: [
                "考えに気づく",
                "良い悪いを決めない",
                "息の感覚へ戻る",
                "戻れたことを小さな成功にする"
            ]
        ),
        ZenLesson(
            id: 3,
            title: "日常に一息置く",
            minutes: 2,
            summary: "通知、会話、移動の前に、短い間を作ります。",
            imageName: "zen-journal",
            steps: [
                "動く前に一呼吸する",
                "肩の力を抜く",
                "今していることを一つだけ見る",
                "急がず次の動作へ移る"
            ]
        )
    ]

    static let visualGuides: [ZenVisualGuide] = [
        ZenVisualGuide(
            id: 1,
            title: "姿勢を作る",
            imageName: "zen-posture",
            body: "背中を伸ばし、肩をゆるめます。形を完璧にするより、呼吸が通る姿勢を探します。"
        ),
        ZenVisualGuide(
            id: 2,
            title: "呼吸に戻る",
            imageName: "zen-breath",
            body: "息を吸い、吐く。その感覚を目印にします。迷ったら、吐く息を一つ数えます。"
        ),
        ZenVisualGuide(
            id: 3,
            title: "雑念を見る",
            imageName: "zen-thoughts",
            body: "考えは出ます。追わず、責めず、気づいたら呼吸へ戻ります。戻る動きが練習です。"
        ),
        ZenVisualGuide(
            id: 4,
            title: "記録を残す",
            imageName: "zen-journal",
            body: "終わったら一言だけ書きます。長文より、今日の変化を短く残す方が続きます。"
        )
    ]

    static let quotes: [ZenQuote] = [
        ZenQuote(id: 1, phrase: "日日是好日", reading: "にちにちこれこうじつ", meaning: "どの日も、その日として受け取る。良し悪しの前に、まず今日を見る。"),
        ZenQuote(id: 2, phrase: "喫茶去", reading: "きっさこ", meaning: "難しく考えすぎたら、お茶を飲む。目の前の一杯に戻る。"),
        ZenQuote(id: 3, phrase: "初心忘るべからず", reading: "しょしんわするべからず", meaning: "慣れた時ほど、最初の素直さに戻る。"),
        ZenQuote(id: 4, phrase: "平常心是道", reading: "びょうじょうしんこれどう", meaning: "特別な場所だけでなく、普段の心の中に道がある。")
    ]

    static var todayQuote: ZenQuote {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        return quotes[day % quotes.count]
    }
}
