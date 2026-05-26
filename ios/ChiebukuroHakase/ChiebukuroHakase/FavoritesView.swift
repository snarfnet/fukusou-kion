import SwiftUI

struct FavoritesView: View {
    let wisdoms: [WisdomItem]
    let favorites: FavoritesManager
    let onSelect: (Int) -> Void
    @Environment(\.dismiss) private var dismiss

    private let isEnglish = Locale.preferredLanguages.first?.hasPrefix("en") == true

    private var favoriteWisdoms: [WisdomItem] {
        favorites.favoriteWisdoms(from: wisdoms)
    }

    var body: some View {
        NavigationStack {
            Group {
                if favoriteWisdoms.isEmpty {
                    ContentUnavailableView(
                        isEnglish ? "No Favorites" : "お気に入りなし",
                        systemImage: "heart.slash",
                        description: Text(isEnglish ? "Tap the heart icon to save wisdoms." : "ハートを押して知恵を保存しましょう。")
                    )
                } else {
                    List(favoriteWisdoms) { wisdom in
                        Button {
                            if let idx = wisdoms.firstIndex(where: { $0.id == wisdom.id }) {
                                onSelect(idx)
                                dismiss()
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(wisdom.category)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(wisdom.title)
                                    .font(.headline)
                                Text(wisdom.content)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 4)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                favorites.toggle(wisdom.id)
                            } label: {
                                Label(isEnglish ? "Remove" : "削除", systemImage: "heart.slash")
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEnglish ? "Favorites" : "お気に入り")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isEnglish ? "Close" : "閉じる") { dismiss() }
                }
            }
        }
    }
}
