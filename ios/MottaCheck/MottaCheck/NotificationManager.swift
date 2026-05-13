import Foundation
import SwiftUI
import UserNotifications

@MainActor
final class NotificationManager: ObservableObject {
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined

    init() {
        Task {
            await refreshStatus()
        }
    }

    func refreshStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    func requestAuthorization() async {
        do {
            _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            await refreshStatus()
        } catch {
            await refreshStatus()
        }
    }

    func scheduleDailyNotifications(
        departureHour: Int,
        departureMinute: Int,
        minutesBeforeDeparture: Int,
        morningHour: Int,
        morningMinute: Int,
        weekdays: Set<Int>
    ) async {
        if authorizationStatus != .authorized {
            await requestAuthorization()
        }

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: Self.notificationIDs)

        for weekday in weekdays {
            await schedule(
                identifier: "motta-morning-\(weekday)",
                title: "今日の持ち物を見よう",
                body: "出かける前に、必要なものを軽くチェックしましょう。",
                hour: morningHour,
                minute: morningMinute,
                weekday: weekday
            )

            let totalMinutes = ((departureHour * 60 + departureMinute - minutesBeforeDeparture) + 24 * 60) % (24 * 60)

            await schedule(
                identifier: "motta-before-\(weekday)",
                title: "持った？",
                body: "財布、鍵、スマホ。最後にもう一度だけ見ておきましょう。",
                hour: totalMinutes / 60,
                minute: totalMinutes % 60,
                weekday: weekday
            )
        }
    }

    private func schedule(identifier: String, title: String, body: String, hour: Int, minute: Int, weekday: Int) async {
        var date = DateComponents()
        date.weekday = weekday
        date.hour = hour
        date.minute = minute

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("通知を登録できませんでした: \(error)")
        }
    }

    static let notificationIDs = (1...7).flatMap { ["motta-morning-\($0)", "motta-before-\($0)"] }
}
