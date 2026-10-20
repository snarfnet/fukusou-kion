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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var selection: Artwork?
    @State private var creating = false
    @State private var settings = false
    @State private var gallery = false
    @State private var collection = false
    @State private var pendingArtwork: Artwork?
    @State private var isVisible = false
    @StateObject private var hero = SculptureRenderer()
    @ScaledMetric(relativeTo: .largeTitle) private var headlineSize = 38.0
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    HStack {
                        Text("TYPO").font(.system(.title2, design: .serif).weight(.medium)).tracking(5)
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
                        Text("一文字が、\n美術館になる。").font(.system(size: headlineSize, weight: .regular, design: .serif))
                        Text("文字に、かたちと光を。").foregroundStyle(.secondary)
                    }
                    Button { creating = true } label: {
                        HStack { Text("文字を作る"); Spacer(); Image(systemName: "plus") }
                            .padding(20).foregroundStyle(Theme.background).background(Theme.ivory, in: RoundedRectangle(cornerRadius: 6))
                    }
                    .accessibilityIdentifier("home.create")
                    Button { collection = true } label: {
                        HStack { Text("コレクションから始める"); Spacer(); Image(systemName: "square.stack.3d.up") }
                            .padding(.vertical, 8)
                    }
                    HStack {
                        Text("最近の作品").font(.headline)
                        Spacer()
                        Button("ギャラリー", systemImage: "square.grid.2x2") { gallery = true }.accessibilityIdentifier("home.gallery")
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
            .sheet(isPresented: $creating, onDismiss: openPending) {
                NewArtworkView { pendingArtwork = $0 }
            }
            .sheet(isPresented: $collection, onDismiss: openPending) { CollectionView { pendingArtwork = $0 } }
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
            .onAppear { isVisible = true }
            .onDisappear { isVisible = false }
            .task(id: isVisible && selection == nil && !reduceMotion && scenePhase == .active) {
                guard isVisible, selection == nil, !reduceMotion, scenePhase == .active else { return }
                let start = Date()
                var sample = Artwork()
                sample.text = "T"
                while !Task.isCancelled {
                    hero.exhibition(at: Date().timeIntervalSince(start), artwork: sample)
                    do { try await Task.sleep(for: .milliseconds(33)) } catch { return }
                }
            }
        }
    }
    private func openPending() {
        if let artwork = pendingArtwork { selection = artwork; pendingArtwork = nil }
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
    @State private var preset = ArtworkPreset.chrome
    @State private var latinInput = false
    let create: (Artwork) -> Void
    var body: some View {
        NavigationStack {
            Form {
                Section("彫刻にする文字") {
                    Picker("入力の種類", selection: $latinInput) { Text("日本語").tag(false); Text("英数字").tag(true) }
                        .pickerStyle(.segmented)
                    TextField("永、A、TYPO…", text: $text, axis: .vertical).font(.system(size: 48, design: .serif))
                        .accessibilityIdentifier("new.text")
                        .lineLimit(1...3)
                        .autocorrectionDisabled().textInputAutocapitalization(.never)
                        .keyboardType(latinInput ? .asciiCapable : .default)
                    Text("\(text.filter { $0 != "\n" }.count) / 12文字・3行まで").foregroundStyle(.secondary)
                    HStack {
                        ForEach(["永", "光", "A", "8", "TYPO"], id: \.self) { sample in
                            Button(sample) { text = sample }.buttonStyle(.bordered)
                        }
                    }
                    if let issue = InputCheck.validate(text) { Text(issue).foregroundStyle(.orange) }
                }
                Section("プリセット") {
                    Picker("スタイル", selection: $preset) {
                        ForEach(ArtworkPreset.allCases) { Text(LocalizedStringKey($0.title)).tag($0) }
                    }
                    Text(LocalizedStringKey(preset.caption)).font(.caption).foregroundStyle(.secondary)
                }
                Button("スタジオを開く") {
                    var artwork = Artwork()
                    artwork.text = text
                    artwork.title = "\(text.replacingOccurrences(of: "\n", with: " ")) — \(preset.title)"
                    preset.apply(to: &artwork)
                    dismiss()
                    create(artwork)
                }.disabled(InputCheck.validate(text) != nil).accessibilityIdentifier("new.open")
            }
            .navigationTitle("文字を作る")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } } }
        }
    }
}

struct CollectionView: View {
    @Environment(\.dismiss) private var dismiss
    let create: (Artwork) -> Void
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 155), spacing: 20)], spacing: 28) {
                    ForEach(ArtworkPreset.allCases) { preset in
                        Button {
                            var artwork = Artwork()
                            artwork.text = preset == .architectural ? "A" : "永"
                            artwork.title = "\(artwork.text) — \(preset.title)"
                            preset.apply(to: &artwork)
                            create(artwork)
                            dismiss()
                        } label: { PresetCard(preset: preset) }.buttonStyle(.plain)
                    }
                }.padding(20)
            }.background(Theme.background)
                .navigationTitle("コレクション")
                .toolbar { Button("完了") { dismiss() } }
        }
    }
}

struct PresetCard: View {
    let preset: ArtworkPreset
    @State private var image: UIImage?
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Group {
                if let image { Image(uiImage: image).resizable().scaledToFit() }
                else { ProgressView().frame(maxWidth: .infinity).frame(height: 160) }
            }.aspectRatio(1, contentMode: .fit)
            Text(preset.title).font(.system(.title3, design: .serif))
            Text(LocalizedStringKey(preset.caption)).font(.caption).foregroundStyle(.secondary)
        }.task {
            guard image == nil else { return }
            var artwork = Artwork()
            artwork.text = preset == .architectural ? "A" : "永"
            preset.apply(to: &artwork)
            image = try? SculptureRenderer().image(artwork, size: CGSize(width: 320, height: 320), transparent: false)
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
                    .accessibilityIdentifier("gallery.project.\(artwork.id)")
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
    @AppStorage("haptics") private var haptics = true
    @AppStorage("editingSound") private var editingSound = false
    var body: some View {
        NavigationStack {
            Form {
                Section("スタジオ") {
                    Toggle("省電力描画", isOn: $lowPower)
                    Toggle("広い画面で操作パネルを右に置く", isOn: $panelOnRight)
                    Toggle("触覚フィードバック", isOn: $haptics)
                    Toggle("操作音", isOn: $editingSound)
                    Text("発熱時は自動で描画品質を下げます。").font(.caption).foregroundStyle(.secondary)
                }
                Section("言語") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        Link("iPhoneの設定で言語を変更", destination: url)
                    }
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
