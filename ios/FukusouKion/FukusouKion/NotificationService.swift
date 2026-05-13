import Foundation
import UserNotifications

enum NotificationService {
    static func scheduleMorningReminder(hour: NotificationHour) async throws {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])

        guard granted else { return }

        center.removePendingNotificationRequests(withIdentifiers: ["morning-outfit"])

        var date = DateComponents()
        date.hour = hour.rawValue
        date.minute = 0

        let content = UNMutableNotificationContent()
        content.title = "今日なに着る？"
        content.body = "出かける前に、気温と傘をチェックしよう。"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(identifier: "morning-outfit", content: content, trigger: trigger)
        try await center.add(request)
    }

    static func cancelMorningReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["morning-outfit"])
    }
}
