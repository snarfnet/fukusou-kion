import SwiftUI

struct StatsSettingsView: View {
    let wisdoms: [WisdomItem]
    let favorites: FavoritesManager
    let tracker: ReadingTracker
    let notificationManager: NotificationManager

    @State private var selectedDate = Date()
    private let isEnglish = Locale.preferredLanguages.first?.hasPrefix("en") == true

    var body: some View {
        NavigationStack {
            List {
                statsSection
                notificationSection
                aboutSection
            }
            .navigationTitle(isEnglish ? "More" : "その他")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                var components = DateComponents()
                components.hour = notificationManager.hour
                components.minute = notificationManager.minute
                selectedDate = Calendar.current.date(from: components) ?? Date()
            }
        }
    }

    private var statsSection: some View {
        Section(isEnglish ? "Reading Progress" : "読書の記録") {
            HStack {
                Image(systemName: "book.closed.fill")
                    .foregroundStyle(.orange)
                Text(isEnglish ? "Wisdoms Read" : "読了した知恵")
                Spacer()
                Text("\(tracker.readIds.count) / \(wisdoms.count)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: Double(tracker.readIds.count), total: Double(max(wisdoms.count, 1)))
                .tint(.orange)

            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.red)
                Text(isEnglish ? "Reading Streak" : "連続日数")
                Spacer()
                Text(isEnglish
                     ? "\(tracker.streak) days"
                     : "\(tracker.streak)日")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            HStack {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.pink)
                Text(isEnglish ? "Favorites" : "お気に入り")
                Spacer()
                Text("\(favorites.favoriteIds.count)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            if tracker.quizTotal > 0 {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundStyle(.purple)
                    Text(isEnglish ? "Quiz Accuracy" : "クイズ正答率")
                    Spacer()
                    Text(String(format: "%.0f%% (%d/%d)", tracker.quizAccuracy, tracker.quizCorrect, tracker.quizTotal))
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }

            categoryProgress
        }
    }

    private var categoryProgress: some View {
        let categories = Array(Set(wisdoms.map(\.category))).sorted()
        return ForEach(categories, id: \.self) { cat in
            let total = wisdoms.filter { $0.category == cat }.count
            let read = wisdoms.filter { $0.category == cat && tracker.readIds.contains($0.id) }.count
            HStack {
                Text(cat)
                    .font(.system(size: 14))
                Spacer()
                ProgressView(value: Double(read), total: Double(max(total, 1)))
                    .frame(width: 60)
                    .tint(.orange)
                Text("\(read)/\(total)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, alignment: .trailing)
            }
        }
    }

    private var notificationSection: some View {
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
            }
        }
    }

    private var aboutSection: some View {
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
}
