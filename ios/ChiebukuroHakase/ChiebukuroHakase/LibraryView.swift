import SwiftUI

struct LibraryView: View {
    let wisdoms: [WisdomItem]
    let favorites: FavoritesManager
    let tracker: ReadingTracker
    let onSelect: (WisdomItem) -> Void

    @State private var searchText = ""
    @State private var selectedCategory: String?

    private let isEnglish = Locale.preferredLanguages.first?.hasPrefix("en") == true

    private var categories: [String] {
        Array(Set(wisdoms.map(\.category))).sorted()
    }

    private var filteredWisdoms: [WisdomItem] {
        var result = wisdoms
        if let cat = selectedCategory {
            result = result.filter { $0.category == cat }
        }
        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.content.localizedCaseInsensitiveContains(searchText)
            }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            List {
                if selectedCategory == nil && searchText.isEmpty {
                    categorySummary
                }

                Section(sectionTitle) {
                    ForEach(filteredWisdoms) { wisdom in
                        Button { onSelect(wisdom) } label: {
                            wisdomRow(wisdom)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: isEnglish ? "Search wisdoms..." : "知恵を検索...")
            .navigationTitle(isEnglish ? "Library" : "図書館")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if selectedCategory != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(isEnglish ? "All" : "すべて") {
                            selectedCategory = nil
                        }
                    }
                }
            }
        }
    }

    private var sectionTitle: String {
        if let cat = selectedCategory {
            return cat
        }
        if !searchText.isEmpty {
            return isEnglish
                ? "\(filteredWisdoms.count) results"
                : "\(filteredWisdoms.count)件の結果"
        }
        return isEnglish
            ? "All Wisdoms (\(wisdoms.count))"
            : "すべての知恵 (\(wisdoms.count))"
    }

    private var categorySummary: some View {
        Section(isEnglish ? "Categories" : "カテゴリ") {
            ForEach(categories, id: \.self) { cat in
                let count = wisdoms.filter { $0.category == cat }.count
                let readCount = wisdoms.filter { $0.category == cat && tracker.readIds.contains($0.id) }.count
                Button {
                    selectedCategory = cat
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(cat)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(isEnglish ? "\(count) wisdoms" : "\(count)件の知恵")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        ProgressView(value: Double(readCount), total: Double(max(count, 1)))
                            .frame(width: 60)
                        Text("\(readCount)/\(count)")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
    }

    private func wisdomRow(_ wisdom: WisdomItem) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    if tracker.readIds.contains(wisdom.id) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.green)
                    }
                    Text(wisdom.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                Text(wisdom.content)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    Text(wisdom.category)
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.ultraThinMaterial, in: Capsule())
                    if favorites.isFavorite(wisdom.id) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.pink)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}
