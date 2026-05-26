import Foundation
import UserNotifications

@Observable
final class NotificationManager {
    var isEnabled: Bool = false {
        didSet { save() }
    }
    var hour: Int = 8 {
        didSet { save() }
    }
    var minute: Int = 0 {
        didSet { save() }
    }

    private let enabledKey = "notificationEnabled"
    private let hourKey = "notificationHour"
    private let minuteKey = "notificationMinute"

    init() {
        isEnabled = UserDefaults.standard.bool(forKey: enabledKey)
        hour = UserDefaults.standard.object(forKey: hourKey) as? Int ?? 8
        minute = UserDefaults.standard.object(forKey: minuteKey) as? Int ?? 0
    }

    func requestPermissionAndSchedule(wisdoms: [WisdomItem]) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                if granted {
                    self.isEnabled = true
                    self.scheduleDaily(wisdoms: wisdoms)
                } else {
                    self.isEnabled = false
                }
            }
        }
    }

    func scheduleDaily(wisdoms: [WisdomItem]) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["dailyWisdom"])

        guard isEnabled, !wisdoms.isEmpty else { return }

        let day = Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
        let wisdom = wisdoms[day % wisdoms.count]

        let content = UNMutableNotificationContent()
        content.title = wisdom.title
        content.body = wisdom.content
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyWisdom", content: content, trigger: trigger)
        center.add(request)
    }

    func cancel() {
        isEnabled = false
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyWisdom"])
    }

    private func save() {
        UserDefaults.standard.set(isEnabled, forKey: enabledKey)
        UserDefaults.standard.set(hour, forKey: hourKey)
        UserDefaults.standard.set(minute, forKey: minuteKey)
    }
}
