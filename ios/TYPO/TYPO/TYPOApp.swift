import SwiftUI

enum Theme {
    static let background = Color(red: 0.043, green: 0.043, blue: 0.051)
    static let ivory = Color(red: 0.95, green: 0.94, blue: 0.92)
    static let gold = Color(red: 0.77, green: 0.65, blue: 0.47)
}

@main
struct TYPOApp: App {
    @StateObject private var store = ProjectStore()
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .tint(Theme.gold)
        }
    }
}

struct HomeView: View {
    @EnvironmentObject private var store: ProjectStore
    @State private var selection: Artwork?
    @State private var creating = false
    @State private var settings = false
    @State private var gallery = false
    @StateObject private var hero = SculptureRenderer()
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    HStack {
                        Text("TYPO").font(.system(size: 26, weight: .medium, design: .serif)).tracking(5)
                        Spacer()
                        Button { settings = true } label: { Image(systemName: "slider.horizontal.3").frame(width: 44, height: 44) }
                            .accessibilityLabel("設定")
                    }
                    ZStack(alignment: .bottomLeading) {
                        SculptureView(renderer: hero, lowPower: true).frame(height: 300)
                            .accessibilityLabel("クロームのTの彫刻")
                        Text("文字の建築家").font(.caption).foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("一文字が、\n美術館になる。").font(.system(size: 38, weight: .regular, design: .serif))
                        Text("文字に、かたちと光を。").foregroundStyle(.secondary)
                    }
                    Button { creating = true } label: {
                        HStack { Text("文字を作る"); Spacer(); Image(systemName: "plus") }
                            .padding(20).foregroundStyle(Theme.background).background(Theme.ivory, in: RoundedRectangle(cornerRadius: 6))
                    }
                    HStack {
                        Text("最近の作品").font(.headline)
                        Spacer()
                        Button("ギャラリー", systemImage: "square.grid.2x2") { gallery = true }
                    }
                    if store.projects.isEmpty {
                        Text("最初の作品を、ここに。保存した彫刻をいつでも編集できます。")
                            .foregroundStyle(.secondary).padding(.vertical, 20)
                    }
                    ForEach(store.projects.prefix(3)) { artwork in
                        Button { selection = artwork } label: { ArtworkRow(artwork: artwork) }
                            .buttonStyle(.plain)
                    }
                }.padding(24).frame(maxWidth: 820).frame(maxWidth: .infinity)
            }
            .background(Theme.background)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $creating) {
                NewArtworkView { selection = $0 }
            }
            .sheet(isPresented: $settings) { SettingsView() }
            .navigationDestination(isPresented: $gallery) { GalleryView() }
            .fullScreenCover(item: $selection) { artwork in StudioView(artwork: artwork) }
            .alert("作品の読み込み", isPresented: Binding(get: { store.issue != nil }, set: { if !$0 { store.issue = nil } })) {
                Button("閉じる") { store.issue = nil }
            } message: { Text(store.issue ?? "") }
            .task {
                var sample = Artwork()
                sample.text = "T"
                sample.depth = 35
                do { try hero.update(sample, aspect: 1.5) } catch { store.issue = error.localizedDescription }
            }
        }
    }
}

struct ArtworkRow: View {
    @EnvironmentObject private var store: ProjectStore
    let artwork: Artwork
    var body: some View {
        HStack(spacing: 20) {
            if let image = UIImage(contentsOfFile: store.thumbnail(artwork.id).path) {
                Image(uiImage: image).resizable().scaledToFit().frame(width: 88, height: 88)
            } else {
                Text(artwork.text).font(.system(size: 32, design: .serif)).frame(width: 88, height: 88).background(.white.opacity(0.04))
            }
            VStack(alignment: .leading, spacing: 8) {
                Text(artwork.title).foregroundStyle(Theme.ivory)
                Text(artwork.surface.title).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.secondary)
        }
    }
}

struct NewArtworkView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text = "永"
    @State private var surface = Surface.chrome
    let create: (Artwork) -> Void
    var body: some View {
        NavigationStack {
            Form {
                Section("彫刻にする文字") {
                    TextField("永、A、TYPO…", text: $text).font(.system(size: 48, design: .serif))
                        .autocorrectionDisabled().textInputAutocapitalization(.never)
                    Text("\(text.count) / 12文字").foregroundStyle(.secondary)
                    HStack {
                        ForEach(["永", "光", "A", "8", "TYPO"], id: \.self) { sample in
                            Button(sample) { text = sample }.buttonStyle(.bordered)
                        }
                    }
                    if let issue = InputCheck.validate(text) { Text(issue).foregroundStyle(.orange) }
                }
                Section("最初の素材") {
                    Picker("素材", selection: $surface) {
                        ForEach(Surface.allCases) { Text($0.title).tag($0) }
                    }
                }
                Button("スタジオを開く") {
                    var artwork = Artwork()
                    artwork.text = text
                    artwork.title = "\(text) — \(surface.title)"
                    artwork.surface = surface
                    dismiss()
                    create(artwork)
                }.disabled(InputCheck.validate(text) != nil)
            }
            .navigationTitle("文字を作る")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } } }
        }
    }
}

struct GalleryView: View {
    @EnvironmentObject private var store: ProjectStore
    @State private var selected: Artwork?
    @State private var pendingDelete: Artwork?
    @State private var hideTitles = false
    @State private var error: String?
    var body: some View {
        ScrollView {
            if store.projects.isEmpty {
                ContentUnavailableView("まだ作品がありません", systemImage: "square.grid.2x2", description: Text("ホームの「文字を作る」から始めましょう。"))
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 24)], spacing: 32) {
                ForEach(store.projects) { artwork in
                    Button { selected = artwork } label: {
                        VStack(alignment: .leading, spacing: 12) {
                            if let image = UIImage(contentsOfFile: store.thumbnail(artwork.id).path) {
                                Image(uiImage: image).resizable().scaledToFit().aspectRatio(1, contentMode: .fit)
                            } else {
                                Text(artwork.text).font(.system(size: 48, design: .serif)).frame(maxWidth: .infinity).frame(height: 150)
                            }
                            if !hideTitles {
                                Text(artwork.title).foregroundStyle(Theme.ivory).lineLimit(1)
                                Text(artwork.updatedAt, style: .date).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    .accessibilityLabel(artwork.title)
                    .contextMenu { Button("作品を削除", role: .destructive) { pendingDelete = artwork } }
                }
            }.padding(24)
        }
        .background(Theme.background)
        .navigationTitle("ギャラリー")
        .toolbar { Toggle("タイトルを隠す", isOn: $hideTitles).toggleStyle(.button) }
        .fullScreenCover(item: $selected) { StudioView(artwork: $0) }
        .confirmationDialog("作品を削除しますか？", isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })) {
            Button("削除", role: .destructive) {
                if let artwork = pendingDelete {
                    do { try store.delete(artwork) } catch { self.error = error.localizedDescription }
                }
                pendingDelete = nil
            }
        }
        .alert("削除できませんでした", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("閉じる") { error = nil }
        } message: { Text(error ?? "") }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("lowPower") private var lowPower = false
    @AppStorage("panelOnRight") private var panelOnRight = false
    var body: some View {
        NavigationStack {
            Form {
                Section("スタジオ") {
                    Toggle("省電力描画", isOn: $lowPower)
                    Toggle("広い画面で操作パネルを右に置く", isOn: $panelOnRight)
                    Text("発熱時は自動で描画品質を下げます。").font(.caption).foregroundStyle(.secondary)
                }
                Section("プライバシー") {
                    Text("作品はこの端末に保存します。アカウント、広告、アプリ内課金はありません。共有したときだけ、選んだアプリに画像を渡します。")
                }
                Section("フォント") {
                    Text("Noto Serif CJK JP — SIL Open Font License 1.1")
                    NavigationLink("ライセンス全文") {
                        ScrollView {
                            Text(license).font(.caption.monospaced()).padding()
                        }.navigationTitle("フォントライセンス")
                    }
                }
                Section("作品の利用") {
                    Text("作成した画像は個人・商用の作品に利用できます。入力した文字や商標など、第三者の権利は利用者が確認してください。")
                }
            }.navigationTitle("設定")
                .toolbar { Button("完了") { dismiss() } }
        }
    }
    private var license: String {
        guard let url = Bundle.main.url(forResource: "OFL", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else { return "同梱のOFL.txtをご確認ください。" }
        return text
    }
}
