import SwiftUI

struct MainTabView: View {
    private let wisdoms = WisdomStore.load()
    private let isEnglish = Locale.preferredLanguages.first?.hasPrefix("en") == true

    @State private var favorites = FavoritesManager()
    @State private var tracker = ReadingTracker()
    @State private var notificationManager = NotificationManager()
    @State private var selectedTab = 0
    @State private var selectedWisdom: WisdomItem?

    var body: some View {
        TabView(selection: $selectedTab) {
            ContentView(
                wisdoms: wisdoms,
                favorites: favorites,
                tracker: tracker,
                notificationManager: notificationManager
            )
            .tabItem {
                Label(isEnglish ? "Home" : "ホーム", systemImage: "house.fill")
            }
            .tag(0)

            LibraryView(
                wisdoms: wisdoms,
                favorites: favorites,
                tracker: tracker,
                onSelect: { wisdom in
                    selectedWisdom = wisdom
                }
            )
            .tabItem {
                Label(isEnglish ? "Library" : "図書館", systemImage: "books.vertical.fill")
            }
            .tag(1)

            QuizView(wisdoms: wisdoms, tracker: tracker)
                .tabItem {
                    Label(isEnglish ? "Quiz" : "クイズ", systemImage: "brain.head.profile")
                }
                .tag(2)

            StatsSettingsView(
                wisdoms: wisdoms,
                favorites: favorites,
                tracker: tracker,
                notificationManager: notificationManager
            )
            .tabItem {
                Label(isEnglish ? "More" : "その他", systemImage: "ellipsis.circle.fill")
            }
            .tag(3)
        }
        .tint(.orange)
        .sheet(item: $selectedWisdom) { wisdom in
            WisdomDetailSheet(
                wisdom: wisdom,
                favorites: favorites,
                tracker: tracker,
                isEnglish: isEnglish
            )
        }
    }
}

struct WisdomDetailSheet: View {
    let wisdom: WisdomItem
    let favorites: FavoritesManager
    let tracker: ReadingTracker
    let isEnglish: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text(wisdom.category)
                            .font(.system(size: 13, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.orange.opacity(0.15), in: Capsule())
                            .foregroundStyle(.orange)
                        Spacer()
                        Text("#\(wisdom.id)")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }

                    Text(wisdom.title)
                        .font(.system(size: 28, weight: .bold, design: .serif))

                    Text(wisdom.content)
                        .font(.system(size: 18, weight: .medium))
                        .lineSpacing(8)
                        .foregroundStyle(.secondary)

                    Divider()

                    HStack(spacing: 16) {
                        Button {
                            favorites.toggle(wisdom.id)
                        } label: {
                            Label(
                                favorites.isFavorite(wisdom.id)
                                    ? (isEnglish ? "Saved" : "保存済み")
                                    : (isEnglish ? "Save" : "保存"),
                                systemImage: favorites.isFavorite(wisdom.id) ? "heart.fill" : "heart"
                            )
                            .font(.system(size: 15, weight: .bold))
                            .frame(maxWidth: .infinity, minHeight: 48)
                        }
                        .buttonStyle(.bordered)
                        .tint(favorites.isFavorite(wisdom.id) ? .pink : .secondary)

                        let sep = isEnglish ? ". " : "。"
                        ShareLink(item: "\(wisdom.title)\(sep)\(wisdom.content)") {
                            Label(isEnglish ? "Share" : "共有", systemImage: "square.and.arrow.up")
                                .font(.system(size: 15, weight: .bold))
                                .frame(maxWidth: .infinity, minHeight: 48)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(24)
            }
            .navigationTitle(isEnglish ? "Wisdom" : "知恵")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEnglish ? "Close" : "閉じる") { dismiss() }
                }
            }
            .onAppear {
                tracker.markRead(wisdom.id)
            }
        }
    }
}
