import SwiftUI

struct SettingsView: View {
    let notificationManager: NotificationManager
    let wisdoms: [WisdomItem]
    @Environment(\.dismiss) private var dismiss

    private let isEnglish = Locale.preferredLanguages.first?.hasPrefix("en") == true

    @State private var selectedDate: Date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section(isEnglish ? "Daily Notification" : "毎日の通知") {
                    Toggle(
                        isEnglish ? "Enable Notification" : "通知を有効にする",
                        isOn: Binding(
                            get: { notificationManager.isEnabled },
                            set: { newValue in
                                if newValue {
                                    notificationManager.requestPermissionAndSchedule(wisdoms: wisdoms)
                                } else {
                                    notificationManager.cancel()
                                }
                            }
                        )
                    )

                    if notificationManager.isEnabled {
                        DatePicker(
                            isEnglish ? "Time" : "通知時刻",
                            selection: $selectedDate,
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: selectedDate) { _, newDate in
                            let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                            notificationManager.hour = components.hour ?? 8
                            notificationManager.minute = components.minute ?? 0
                            notificationManager.scheduleDaily(wisdoms: wisdoms)
                        }

                        Text(isEnglish
                             ? "A new wisdom will arrive every day at the selected time."
                             : "選んだ時刻に毎日新しい知恵が届きます。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section(isEnglish ? "About" : "アプリについて") {
                    HStack {
                        Text(isEnglish ? "Wisdoms" : "知恵袋数")
                        Spacer()
                        Text("\(wisdoms.count.formatted())")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text(isEnglish ? "Version" : "バージョン")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(isEnglish ? "Settings" : "設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEnglish ? "Close" : "閉じる") { dismiss() }
                }
            }
            .onAppear {
                var components = DateComponents()
                components.hour = notificationManager.hour
                components.minute = notificationManager.minute
                selectedDate = Calendar.current.date(from: components) ?? Date()
            }
        }
    }
}
