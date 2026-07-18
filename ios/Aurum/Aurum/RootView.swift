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
    @FocusState private var noteIsFocused: Bool
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var currentStepTitle: LocalizedStringKey {
        if !running { return "始める前に" }
        if seconds > 150 { return "一、呼吸を整える" }
        if seconds > 30 { return "二、今日の実践" }
        return "三、気づきを記す"
    }

    private var currentStepBody: String {
        if !running { return String(localized: "静かに座り、下の三つの段階を確認してください。") }
        if seconds > 150 { return String(localized: "肩の力を抜き、ゆっくり三回呼吸します。答えを急がなくて大丈夫です。") }
        if seconds > 30 { return wisdom.practice }
        return String(localized: "いま気づいたことを、正解を探さず一行だけ書いてください。")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ManuscriptBackground()
                ScrollView {
                    VStack(spacing: 24) {
                        StageSeal(stage: wisdom.stage)
                        Text(wisdom.practice).font(.system(size: 23, design: .serif)).multilineTextAlignment(.center).foregroundStyle(AurumTheme.parchment).padding(.horizontal)
                        Text(String(format: "%d:%02d", seconds / 60, seconds % 60)).font(.system(size: 52, weight: .light, design: .monospaced)).foregroundStyle(AurumTheme.gold)

                        VStack(alignment: .leading, spacing: 10) {
                            Text(currentStepTitle)
                                .font(.system(.headline, design: .serif, weight: .semibold))
                                .foregroundStyle(AurumTheme.gold)
                            Text(currentStepBody)
                                .foregroundStyle(AurumTheme.parchment)
                                .lineSpacing(5)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .modifier(MysticCardModifier())

                        if !running {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("最初の30秒　呼吸を整える", systemImage: "wind")
                                Label("次の2分　示された実践を行う", systemImage: "hourglass")
                                Label("最後の30秒　気づきを一行書く", systemImage: "pencil.line")
                            }
                            .font(.subheadline)
                            .foregroundStyle(AurumTheme.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button(running ? "実践中" : "三分の実践を始める") { running = true }
                            .modifier(GoldCapsule())
                            .disabled(running)
                        TextField("気づきを一行だけ", text: $note, axis: .vertical)
                            .focused($noteIsFocused)
                            .submitLabel(.done)
                            .onSubmit { noteIsFocused = false }
                            .lineLimit(3...6)
                            .padding()
                            .background(AurumTheme.charcoal)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .foregroundStyle(AurumTheme.parchment)
                    }
                    .padding(24)
                    .padding(.bottom, 72)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .safeAreaInset(edge: .bottom) {
                Button("錬金帖に封じる") {
                    noteIsFocused = false
                    store.save(wisdom: wisdom, note: note)
                    dismiss()
                }
                .modifier(GoldCapsule())
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(AurumTheme.ink.opacity(0.96))
            }
            .navigationTitle(wisdom.stage.displayName).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("閉じる") { dismiss() } }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完了") { noteIsFocused = false }
                }
            }
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

                    AboutChapter(
                        mark: "sparkles",
                        title: "Aurumという名",
                        body: "Aurumはラテン語で『金』を意味します。ここでの金は、富や運勢ではありません。ありふれた経験を見つめ直し、そこから自分にとって確かな意味を取り出す営みの象徴です。答えを授けるアプリではなく、自分の言葉を見つけるための静かな器として設計しました。"
                    )

                    AboutChapter(
                        mark: "circle.hexagongrid.fill",
                        title: "四つの色をめぐる道",
                        body: "書庫は、黒化・白化・黄化・赤化という錬金術の色彩的な流れを手がかりにしています。黒化で混乱をほどき、白化で事実と感情を澄ませ、黄化で小さな兆しを見いだし、赤化で気づきを日常の行いへ結び直します。これは性格診断や運命の段階ではなく、考えを整理するための往復可能な地図です。"
                    )

                    AboutChapter(
                        mark: "hourglass",
                        title: "三分で終わる小さな実践",
                        body: "知恵を読むだけで終わらせず、30秒の呼吸、2分の具体的な行動、30秒の一行記録へつなげます。短さは簡略化のためではなく、忙しい日にも実行できる大きさへ知恵を戻すためです。続けることより、今日一度だけ丁寧に試すことを大切にしています。"
                    )

                    AboutChapter(
                        mark: "book.closed.fill",
                        title: "原典との距離",
                        body: "収録文は古典の逐語訳ではありません。歴史的な象徴や操作を、現代の日常で安全に使える問いと行動へ再構成しています。異なる時代の宗教観や自然観を事実として押しつけず、出典への敬意と、現代の利用者が自分で考える余白の両方を守ります。"
                    )

                    AboutChapter(
                        mark: "hand.raised.fill",
                        title: "このアプリがしないこと",
                        body: "未来の予言、吉凶の判定、診断、治療、宗教的な救済は行いません。表示される問いに唯一の正解はなく、実践を途中でやめても失敗にはなりません。強い苦痛を感じるときは使用を止め、必要に応じて身近な人や専門家へ相談してください。"
                    )

                    AboutChapter(
                        mark: "lock.fill",
                        title: "静かに使える設計",
                        body: "お気に入りと錬金帖の記録は端末内に保存され、アカウント登録は不要です。記録は共有操作を選んだときだけ書き出されます。通知や連続日数に追い立てられるのではなく、自分の速度で書庫へ戻れる道具を目指しています。"
                    )

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

private struct AboutChapter: View {
    let mark: String
    let title: LocalizedStringKey
    let content: LocalizedStringKey

    init(mark: String, title: LocalizedStringKey, body: LocalizedStringKey) {
        self.mark = mark
        self.title = title
        self.content = body
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: mark)
                .font(.system(.headline, design: .serif, weight: .semibold))
                .foregroundStyle(AurumTheme.gold)
            Text(content)
                .foregroundStyle(AurumTheme.muted)
                .lineSpacing(6)
        }
        .modifier(MysticCardModifier())
    }
}
