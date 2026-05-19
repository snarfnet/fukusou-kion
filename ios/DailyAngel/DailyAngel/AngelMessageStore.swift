import Foundation
import UserNotifications

@MainActor
final class AngelMessageStore: ObservableObject {
    @Published private(set) var messages: [AngelMessage] = []
    @Published var savedDays: Set<Int> = []
    @Published var reminderEnabled = false

    private let savedKey = "dailyAngel.savedDays"
    private let reminderKey = "dailyAngel.reminderEnabled"

    init() {
        loadMessages()
        loadSavedDays()
        reminderEnabled = UserDefaults.standard.bool(forKey: reminderKey)
    }

    var todayMessage: AngelMessage {
        if messages.isEmpty {
            return AngelMessage(
                day: 1,
                theme: "light",
                themeJa: "光",
                themeEn: "Light",
                angelic: "IAIDA ZACAR CA",
                ja: "天使は静かに告げます。今日の光は、あなたの近くにあります。",
                en: "The angel speaks softly. Today's light is near you.",
                actionJa: "朝の光を一分だけ見る。",
                actionEn: "Look at the morning light for one minute.",
                tags: ["light"]
            )
        }

        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return messages[(day - 1) % messages.count]
    }

    var savedMessages: [AngelMessage] {
        messages.filter { savedDays.contains($0.day) }
    }

    func isSaved(_ message: AngelMessage) -> Bool {
        savedDays.contains(message.day)
    }

    func toggleSaved(_ message: AngelMessage) {
        if savedDays.contains(message.day) {
            savedDays.remove(message.day)
        } else {
            savedDays.insert(message.day)
        }
        persistSavedDays()
    }

    func message(for day: Int) -> AngelMessage? {
        messages.first { $0.day == day }
    }

    func scheduleDailyReminder() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else {
                reminderEnabled = false
                UserDefaults.standard.set(false, forKey: reminderKey)
                return
            }

            center.removePendingNotificationRequests(withIdentifiers: ["daily-angel-morning"])

            let content = UNMutableNotificationContent()
            content.title = "天使の手紙"
            content.body = "今日のメッセージが届いています。"
            content.sound = .default

            var components = DateComponents()
            components.hour = 7
            components.minute = 30

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: "daily-angel-morning", content: content, trigger: trigger)
            try await center.add(request)

            reminderEnabled = true
            UserDefaults.standard.set(true, forKey: reminderKey)
        } catch {
            reminderEnabled = false
            UserDefaults.standard.set(false, forKey: reminderKey)
        }
    }

    func cancelDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-angel-morning"])
        reminderEnabled = false
        UserDefaults.standard.set(false, forKey: reminderKey)
    }

    private func loadMessages() {
        guard let url = Bundle.main.url(forResource: "angel_messages_365", withExtension: "json") else {
            messages = []
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let payload = try JSONDecoder().decode(AngelPayload.self, from: data)
            messages = payload.messages.sorted { $0.day < $1.day }
        } catch {
            messages = []
        }
    }

    private func loadSavedDays() {
        let days = UserDefaults.standard.array(forKey: savedKey) as? [Int] ?? []
        savedDays = Set(days)
    }

    private func persistSavedDays() {
        UserDefaults.standard.set(Array(savedDays).sorted(), forKey: savedKey)
    }
}
