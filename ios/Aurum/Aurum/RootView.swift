import SwiftUI
import Combine

struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack { TodayView() }
                .tabItem { Label("今日", systemImage: "sun.max.fill") }
            NavigationStack { LibraryView() }
                .tabItem { Label("書庫", systemImage: "books.vertical.fill") }
            NavigationStack { JournalView() }
                .tabItem { Label("錬金帖", systemImage: "book.closed.fill") }
            NavigationStack { AboutView() }
                .tabItem { Label("由来", systemImage: "scroll.fill") }
        }
        .tint(AurumTheme.gold)
        .toolbarBackground(AurumTheme.ink.opacity(0.96), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

struct TodayView: View {
    @EnvironmentObject private var store: PracticeStore
    @State private var selected: Wisdom = Library.wisdom[Calendar.current.ordinality(of: .day, in: .year, for: .now).map { ($0 - 1) % Library.wisdom.count } ?? 0]
    @State private var showPractice = false

    var body: some View {
        ZStack {
            ManuscriptBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("AURUM").font(.system(size: 12, weight: .bold, design: .serif)).tracking(4).foregroundStyle(AurumTheme.gold)
                            Text("今日の変容").font(.system(size: 30, weight: .medium, design: .serif)).foregroundStyle(AurumTheme.parchment)
                        }
                        Spacer()
                        VStack(spacing: 2) {
                            Text("\(store.streak)").font(.system(size: 24, weight: .medium, design: .serif))
                            Text("連続日").font(.caption2)
                        }.foregroundStyle(AurumTheme.gold)
                    }

                    HStack {
                        Spacer()
                        VStack(spacing: 10) {
                            StageSeal(stage: selected.stage)
                            Text("\(selected.stage.displayName)・\(selected.stage.subtitle)")
                                .font(.system(.caption, design: .serif, weight: .bold))
                                .tracking(2.2)
                                .foregroundStyle(AurumTheme.gold)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)

                    VStack(alignment: .leading, spacing: 14) {
                        Text("MEDITATIO").font(.system(size: 10, weight: .bold, design: .serif)).tracking(3).foregroundStyle(AurumTheme.gold.opacity(0.8))
                        Text(selected.title).font(.system(size: 28, weight: .semibold, design: .serif)).foregroundStyle(AurumTheme.parchment)
                        Text(selected.sourceIdea).font(.system(.body, design: .serif)).foregroundStyle(AurumTheme.muted).lineSpacing(5)
                        Divider().overlay(AurumTheme.gold.opacity(0.35))
                        Text(selected.reflection).font(.system(size: 20, weight: .regular, design: .serif)).foregroundStyle(AurumTheme.parchment).lineSpacing(6)
                    }
                    .modifier(MysticCardModifier())

                    Button("三分の実践を始める") { showPractice = true }
                        .modifier(GoldCapsule()).frame(maxWidth: .infinity)
                }
                .padding(20).padding(.bottom, 24)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showPractice) { PracticeView(wisdom: selected) }
    }
}

struct PracticeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: PracticeStore
    let wisdom: Wisdom
    @State private var note = ""
    @State private var seconds = 180
    @State private var running = false
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack {
                ManuscriptBackground()
                VStack(spacing: 24) {
                    StageSeal(stage: wisdom.stage)
                    Text(wisdom.practice).font(.system(size: 23, design: .serif)).multilineTextAlignment(.center).foregroundStyle(AurumTheme.parchment).padding(.horizontal)
                    Text(String(format: "%d:%02d", seconds / 60, seconds % 60)).font(.system(size: 52, weight: .light, design: .monospaced)).foregroundStyle(AurumTheme.gold)
                    Button(running ? "静かに続ける" : "計時を始める") { running = true }.modifier(GoldCapsule())
                    TextField("気づきを一行だけ", text: $note, axis: .vertical)
                        .lineLimit(3...6).padding().background(AurumTheme.charcoal).clipShape(RoundedRectangle(cornerRadius: 16)).foregroundStyle(AurumTheme.parchment)
                    Button("錬金帖に封じる") { store.save(wisdom: wisdom, note: note); dismiss() }
                        .font(.system(.body, design: .serif, weight: .semibold)).foregroundStyle(AurumTheme.gold)
                }.padding(24)
            }
            .navigationTitle(wisdom.stage.displayName).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("閉じる") { dismiss() } } }
            .onReceive(timer) { _ in if running && seconds > 0 { seconds -= 1 } }
        }.presentationDetents([.large])
    }
}

struct LibraryView: View {
    @EnvironmentObject private var store: PracticeStore
    @State private var query = ""
    @State private var favoritesOnly = false

    private var results: [Wisdom] {
        Library.wisdom.filter { wisdom in
            (!favoritesOnly || store.isFavorite(wisdom)) &&
            (query.isEmpty ||
             wisdom.title.localizedCaseInsensitiveContains(query) ||
             wisdom.sourceIdea.localizedCaseInsensitiveContains(query) ||
             wisdom.reflection.localizedCaseInsensitiveContains(query) ||
             wisdom.practice.localizedCaseInsensitiveContains(query))
        }
    }

    var body: some View {
        ZStack {
            ManuscriptBackground()
            List {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(AurumTheme.gold)
                        TextField("知恵を検索", text: $query)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .foregroundStyle(AurumTheme.parchment)
                        if !query.isEmpty {
                            Button { query = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(AurumTheme.muted)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("検索を消去")
                        }
                    }
                    .padding(.vertical, 8)

                    HStack(spacing: 12) {
                        Label("お気に入りだけ", systemImage: favoritesOnly ? "bookmark.fill" : "bookmark")
                            .foregroundStyle(AurumTheme.gold)
                        Spacer()
                        Text("\(results.count)件")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(AurumTheme.muted)
                        Toggle("", isOn: $favoritesOnly)
                            .labelsHidden()
                            .tint(AurumTheme.gold)
                    }
                }

                if results.isEmpty {
                    ContentUnavailableView(
                        favoritesOnly ? "お気に入りはまだありません" : "知恵が見つかりません",
                        systemImage: favoritesOnly ? "bookmark" : "magnifyingglass",
                        description: Text(favoritesOnly ? "書庫の項目を開き、しおりを付けてください。" : "別の言葉で検索してください。")
                    )
                    .listRowBackground(Color.clear)
                }

                ForEach(Stage.allCases, id: \.self) { stage in
                    let stageResults = results.filter { $0.stage == stage }
                    if !stageResults.isEmpty {
                        Section {
                            ForEach(stageResults) { wisdom in
                                NavigationLink { WisdomDetailView(wisdom: wisdom) } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(wisdom.title).font(.system(.headline, design: .serif)).foregroundStyle(AurumTheme.parchment)
                                            Text(wisdom.reflection).font(.caption).foregroundStyle(AurumTheme.muted).lineLimit(2)
                                        }
                                        Spacer()
                                        if store.isFavorite(wisdom) { Image(systemName: "bookmark.fill").foregroundStyle(AurumTheme.gold) }
                                    }
                                    .padding(.vertical, 5)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button { store.toggleFavorite(wisdom) } label: {
                                        Label(
                                            store.isFavorite(wisdom) ? "お気に入りから外す" : "お気に入りに追加",
                                            systemImage: store.isFavorite(wisdom) ? "bookmark.slash" : "bookmark.fill"
                                        )
                                    }
                                    .tint(AurumTheme.gold)
                                }
                            }
                        } header: { Label("\(stage.displayName)・\(stage.subtitle)", systemImage: stage.mark).foregroundStyle(AurumTheme.gold) }
                    }
                }
            }.scrollContentBackground(.hidden)
        }
        .navigationTitle("変容の書庫")
    }
}

struct WisdomDetailView: View {
    @EnvironmentObject private var store: PracticeStore
    let wisdom: Wisdom
    @State private var showPractice = false
    var body: some View {
        ZStack {
            ManuscriptBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Label(wisdom.stage.displayName, systemImage: wisdom.stage.mark).foregroundStyle(AurumTheme.gold)
                    Text(wisdom.title).font(.system(size: 32, weight: .semibold, design: .serif)).foregroundStyle(AurumTheme.parchment)
                    Text("古典からの着想").font(.caption).tracking(2).foregroundStyle(AurumTheme.gold)
                    Text(wisdom.sourceIdea).foregroundStyle(AurumTheme.muted).lineSpacing(6)
                    Text("問い").font(.caption).tracking(2).foregroundStyle(AurumTheme.gold)
                    Text(wisdom.reflection).font(.system(size: 22, design: .serif)).foregroundStyle(AurumTheme.parchment).lineSpacing(7)
                    Text("小さな実践").font(.caption).tracking(2).foregroundStyle(AurumTheme.gold)
                    Text(wisdom.practice).foregroundStyle(AurumTheme.parchment)
                    Button("この実践を始める") { showPractice = true }
                        .modifier(GoldCapsule()).frame(maxWidth: .infinity)
                }.padding(24)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { store.toggleFavorite(wisdom) } label: {
                    Image(systemName: store.isFavorite(wisdom) ? "bookmark.fill" : "bookmark")
                }
                .accessibilityLabel(Text(LocalizedStringKey(store.isFavorite(wisdom) ? "お気に入りから外す" : "お気に入りに追加")))
            }
        }
        .sheet(isPresented: $showPractice) { PracticeView(wisdom: wisdom) }
    }
}

struct JournalView: View {
    @EnvironmentObject private var store: PracticeStore
    var body: some View {
        ZStack {
            ManuscriptBackground()
            if store.entries.isEmpty {
                ContentUnavailableView("まだ記録がありません", systemImage: "book.closed", description: Text("今日の実践を終えると、ここに変容の跡が残ります。"))
            } else {
                List {
                    ForEach(store.entries) { entry in
                        VStack(alignment: .leading, spacing: 7) {
                            HStack { Text(entry.stage.displayName).foregroundStyle(AurumTheme.gold); Spacer(); Text(entry.date, format: .dateTime.month().day()).foregroundStyle(AurumTheme.muted) }
                            Text(store.wisdom(for: entry)?.title ?? "実践").font(.system(.headline, design: .serif)).foregroundStyle(AurumTheme.parchment)
                            if !entry.note.isEmpty { Text(entry.note).foregroundStyle(AurumTheme.muted) }
                        }.padding(.vertical, 6)
                    }
                    .onDelete(perform: store.delete)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("錬金帖")
        .toolbar {
            if !store.entries.isEmpty {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    HStack(spacing: 2) {
                        Text(store.practicedDays, format: .number)
                        Text("日")
                    }
                    .font(.caption).foregroundStyle(AurumTheme.gold)
                    .accessibilityLabel(Text(String(format: NSLocalizedString("実践日数 %d日", comment: "Days practiced"), store.practicedDays)))
                    ShareLink(item: store.exportText) { Image(systemName: "square.and.arrow.up") }
                        .accessibilityLabel(Text("錬金帖を書き出す"))
                }
            }
        }
    }
}

struct AboutView: View {
    var body: some View {
        ZStack {
            ManuscriptBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Image("AurumArtwork")
                        .resizable().scaledToFit()
                        .clipShape(Circle())
                        .frame(width: 190, height: 190)
                        .frame(maxWidth: .infinity)
                        .overlay(Circle().stroke(AurumTheme.gold.opacity(0.55), lineWidth: 1).frame(width: 190, height: 190))
                    Text("占いではなく、変容のための読書具").font(.system(size: 25, weight: .semibold, design: .serif)).foregroundStyle(AurumTheme.parchment)
                    Text("Aurumは、古い錬金術書やヘルメス思想に見られる『変容』『器』『照応』『象徴』を、短い自己省察へ翻訳したアプリです。未来を予言したり、医学的・宗教的な効能をうたったりしません。").foregroundStyle(AurumTheme.muted).lineSpacing(6)
                    Text("主な参照資料").font(.caption).tracking(2).foregroundStyle(AurumTheme.gold)
                    Text("Alchemy: Ancient and Modern — Herbert Stanley Redgrove\nThe Pictorial Symbols of Alchemy — Arthur Edward Waite\nCorpus Hermetica\nSymbol and the Symbolic\nSeven Hermetic Letters")
                        .font(.system(.callout, design: .serif)).foregroundStyle(AurumTheme.parchment).lineSpacing(6)
                    Text("本文は原典の逐語訳ではなく、歴史的な概念を現代の安全な振り返りへ再構成したものです。収録PDFそのものはアプリに同梱しません。")
                        .font(.footnote).foregroundStyle(AurumTheme.muted)
                }.padding(24)
            }
        }.navigationTitle("このアプリの由来")
    }
}
