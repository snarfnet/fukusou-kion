import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NotesHomeView()
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }

            CalendarNotesView()
                .tabItem {
                    Label("カレンダー", systemImage: "calendar")
                }

            PrayerListView()
                .tabItem {
                    Label("祈り", systemImage: "hands.sparkles.fill")
                }

            SearchView()
                .tabItem {
                    Label("検索", systemImage: "magnifyingglass")
                }
        }
        .tint(ChurchTheme.navy)
    }
}

private struct NotesHomeView: View {
    @EnvironmentObject private var store: NoteStore
    @State private var selectedFilter: NoteFilter = .all
    @State private var showingEditor = false
    @State private var editingNote: SermonNote?

    private var notes: [SermonNote] {
        store.filteredNotes(query: "", favoritesOnly: false)
            .filter { selectedFilter.matches($0) }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ChurchTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HeaderStatsView(notes: store.notes)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(NoteFilter.allCases) { filter in
                                    FilterChip(
                                        title: filter.title,
                                        isSelected: selectedFilter == filter
                                    ) {
                                        selectedFilter = filter
                                    }
                                }
                            }
                            .padding(.horizontal, 18)
                        }

                        LazyVStack(spacing: 0) {
                            if notes.isEmpty {
                                EmptyStateView()
                                    .padding(.top, 50)
                            } else {
                                ForEach(notes) { note in
                                    Button {
                                        editingNote = note
                                    } label: {
                                        NoteRowView(note: note)
                                    }
                                    .buttonStyle(.plain)

                                    Divider()
                                        .padding(.leading, 76)
                                }
                            }
                        }
                        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal, 18)
                        .padding(.bottom, 96)
                    }
                    .padding(.top, 18)
                }

                Button {
                    showingEditor = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 58, height: 58)
                        .background(ChurchTheme.navy, in: Circle())
                        .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
                }
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
            .navigationTitle("教会ノート")
            .sheet(isPresented: $showingEditor) {
                NoteEditorView(note: SermonNote())
            }
            .sheet(item: $editingNote) { note in
                NoteEditorView(note: note)
            }
        }
    }
}

private struct HeaderStatsView: View {
    let notes: [SermonNote]

    private var prayerCount: Int {
        notes.flatMap(\.prayerRequests).filter { !$0.isAnswered }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(ChurchTheme.navy)
                    Image(systemName: "cross.case.fill")
                        .font(.system(size: 29, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 58, height: 58)

                VStack(alignment: .leading, spacing: 4) {
                    Text("神さまのことばを、心に刻む")
                        .font(.headline)
                        .foregroundStyle(ChurchTheme.ink)
                    Text("礼拝、説教、祈りを一つの場所へ。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 10) {
                StatPill(value: "\(notes.count)", label: "メモ")
                StatPill(value: "\(prayerCount)", label: "祈り")
                StatPill(value: "\(notes.filter(\.isFavorite).count)", label: "お気に入り")
            }
        }
        .padding(18)
        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 18)
    }
}

private struct StatPill: View {
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 5) {
            Text(value)
                .font(.headline)
                .foregroundStyle(ChurchTheme.navy)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(ChurchTheme.chip, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct NoteRowView: View {
    let note: SermonNote

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(ChurchTheme.navy)
                .frame(width: 40, height: 48)

            VStack(alignment: .leading, spacing: 6) {
                Text(note.date, format: .dateTime.year().month().day().weekday(.abbreviated))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    Text(note.displayTitle)
                        .font(.headline)
                        .foregroundStyle(ChurchTheme.ink)
                        .lineLimit(1)

                    if note.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(ChurchTheme.gold)
                    }
                }

                HStack(spacing: 12) {
                    if !note.pastorName.isEmpty {
                        Label(note.pastorName, systemImage: "person")
                    }
                    if !note.scripture.isEmpty {
                        Label(note.scripture, systemImage: "book.closed")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer(minLength: 8)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    private var iconName: String {
        if !note.prayerRequests.isEmpty { return "hands.sparkles.fill" }
        if note.scripture.isEmpty { return "note.text" }
        return "book.closed.fill"
    }
}

private struct NoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: NoteStore

    @State private var note: SermonNote
    @State private var tagText: String
    @State private var prayerText: String

    init(note: SermonNote) {
        _note = State(initialValue: note)
        _tagText = State(initialValue: note.tags.joined(separator: ", "))
        _prayerText = State(initialValue: note.prayerRequests.map(\.text).joined(separator: "\n"))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本") {
                    TextField("タイトル", text: $note.title)
                    DatePicker("日付", selection: $note.date, displayedComponents: .date)
                    TextField("牧師名", text: $note.pastorName)
                    TextField("教会名", text: $note.churchName)
                    TextField("聖書箇所 例: John 3:16", text: $note.scripture)
                }

                Section("メモ") {
                    TextEditor(text: $note.body)
                        .frame(minHeight: 180)
                }

                Section("祈りの課題") {
                    TextEditor(text: $prayerText)
                        .frame(minHeight: 110)
                    Text("1行に1つずつ書けます。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("整理") {
                    TextField("タグ 例: 礼拝, 感謝, 家族", text: $tagText)
                    Toggle("お気に入り", isOn: $note.isFavorite)
                }
            }
            .scrollContentBackground(.hidden)
            .background(ChurchTheme.background)
            .navigationTitle(note.title.isEmpty ? "新しいメモ" : "メモ編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        note.tags = tagText
                            .split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }

                        note.prayerRequests = prayerText
                            .split(whereSeparator: \.isNewline)
                            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                            .map { text in
                                note.prayerRequests.first(where: { $0.text == text }) ?? PrayerRequest(text: text)
                            }

                        store.save(note)
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct CalendarNotesView: View {
    @EnvironmentObject private var store: NoteStore

    private var groupedNotes: [(String, [SermonNote])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"

        let groups = Dictionary(grouping: store.filteredNotes(query: "", favoritesOnly: false)) {
            formatter.string(from: $0.date)
        }

        return groups
            .map { ($0.key, $0.value.sorted { $0.date > $1.date }) }
            .sorted {
                ($0.1.first?.date ?? .distantPast) > ($1.1.first?.date ?? .distantPast)
            }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedNotes, id: \.0) { month, notes in
                    Section(month) {
                        ForEach(notes) { note in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(note.displayTitle)
                                    .font(.headline)
                                Text([note.pastorName, note.scripture].filter { !$0.isEmpty }.joined(separator: "  /  "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("カレンダー")
        }
    }
}

private struct PrayerListView: View {
    @EnvironmentObject private var store: NoteStore

    private var prayerItems: [PrayerListItem] {
        store.notes
            .sorted { $0.date > $1.date }
            .flatMap { note in
                note.prayerRequests.map { PrayerListItem(note: note, prayer: $0) }
            }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(prayerItems) { item in
                    Button {
                        store.togglePrayer(noteID: item.note.id, prayerID: item.prayer.id)
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: item.prayer.isAnswered ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(item.prayer.isAnswered ? ChurchTheme.sage : ChurchTheme.navy)
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 5) {
                                Text(item.prayer.text)
                                    .foregroundStyle(ChurchTheme.ink)
                                    .strikethrough(item.prayer.isAnswered)
                                Text(item.note.displayTitle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("祈りの課題")
        }
    }
}

private struct PrayerListItem: Identifiable {
    let note: SermonNote
    let prayer: PrayerRequest

    var id: UUID { prayer.id }
}

private struct SearchView: View {
    @EnvironmentObject private var store: NoteStore
    @State private var query = ""
    @State private var favoritesOnly = false

    private var results: [SermonNote] {
        store.filteredNotes(query: query, favoritesOnly: favoritesOnly)
    }

    var body: some View {
        NavigationStack {
            List {
                Toggle("お気に入りだけ", isOn: $favoritesOnly)

                ForEach(results) { note in
                    NoteSearchResultView(note: note)
                }
            }
            .searchable(text: $query, prompt: "聖書箇所、牧師名、教会名、本文")
            .navigationTitle("検索")
        }
    }
}

private struct NoteSearchResultView: View {
    let note: SermonNote

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(note.displayTitle)
                .font(.headline)
            Text([note.churchName, note.pastorName, note.scripture].filter { !$0.isEmpty }.joined(separator: "  /  "))
                .font(.caption)
                .foregroundStyle(.secondary)
            if !note.body.isEmpty {
                Text(note.body)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 5)
    }
}

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? .white : ChurchTheme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(isSelected ? ChurchTheme.navy : ChurchTheme.chip, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.closed")
                .font(.system(size: 42))
                .foregroundStyle(ChurchTheme.navy)
            Text("最初のメモを作りましょう")
                .font(.headline)
            Text("礼拝の気づき、説教、祈りの課題を残せます。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(30)
    }
}

private enum NoteFilter: String, CaseIterable, Identifiable {
    case all
    case worship
    case sermon
    case prayer
    case favorite

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "すべて"
        case .worship: "礼拝メモ"
        case .sermon: "説教メモ"
        case .prayer: "祈りの課題"
        case .favorite: "お気に入り"
        }
    }

    func matches(_ note: SermonNote) -> Bool {
        switch self {
        case .all:
            return true
        case .worship:
            return note.tags.contains { $0.localizedCaseInsensitiveContains("礼拝") }
        case .sermon:
            return !note.scripture.isEmpty || note.tags.contains { $0.localizedCaseInsensitiveContains("説教") }
        case .prayer:
            return !note.prayerRequests.isEmpty
        case .favorite:
            return note.isFavorite
        }
    }
}

private enum ChurchTheme {
    static let navy = Color(red: 24 / 255, green: 55 / 255, blue: 91 / 255)
    static let ink = Color(red: 22 / 255, green: 34 / 255, blue: 48 / 255)
    static let chip = Color(red: 239 / 255, green: 235 / 255, blue: 225 / 255)
    static let background = Color(red: 250 / 255, green: 247 / 255, blue: 239 / 255)
    static let sage = Color(red: 112 / 255, green: 154 / 255, blue: 128 / 255)
    static let gold = Color(red: 173 / 255, green: 132 / 255, blue: 62 / 255)
}

#Preview {
    ContentView()
        .environmentObject(NoteStore())
}
