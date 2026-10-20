import SwiftUI
import SceneKit

@MainActor
final class StudioModel: ObservableObject {
    @Published var artwork: Artwork
    @Published var history = EditHistory()
    @Published var error: String?
    @Published var saved = false
    @Published var selection: Set<Int> = []
    let renderer = SculptureRenderer()
    var aspect = 1.0
    var gestureStart: Artwork?
    var loaded = false
    var viewportHeight = 400.0

    init(_ artwork: Artwork) { self.artwork = artwork }
    var selectedSurface: Surface? {
        let indices = artwork.expandedSelection(selection)
        guard !indices.isEmpty else { return artwork.surface }
        let surfaces = indices.map { artwork.adjustment(at: $0).surface ?? artwork.surface }
        guard let first = surfaces.first else { return nil }
        return surfaces.allSatisfy { $0 == first } ? first : nil
    }
    func change<Value: Equatable>(_ key: WritableKeyPath<Artwork, Value>, _ value: Value) {
        guard artwork[keyPath: key] != value else { return }
        history.record(artwork)
        artwork[keyPath: key] = value
        saved = false
        render()
    }
    func binding<Value: Equatable>(_ key: WritableKeyPath<Artwork, Value>) -> Binding<Value> {
        Binding(get: { self.artwork[keyPath: key] }, set: { self.change(key, $0) })
    }
    func render() {
        selection.formIntersection(Set(artwork.editableIndices))
        do {
            try renderer.update(artwork, aspect: aspect)
            renderer.select(artwork.expandedSelection(selection))
        }
        catch { self.error = error.localizedDescription }
    }
    func edit(_ action: (inout Artwork) -> Void) {
        history.record(artwork)
        action(&artwork)
        saved = false
        render()
    }
    func select(_ index: Int, additive: Bool = false) {
        if additive {
            if selection.contains(index) { selection.remove(index) } else { selection.insert(index) }
        } else { selection = [index] }
        renderer.select(artwork.expandedSelection(selection))
        StudioFeedback.shared.selection()
    }
    func applySurface(_ surface: Surface) {
        let indices = artwork.expandedSelection(selection)
        edit { artwork in
            if indices.isEmpty { artwork.surface = surface }
            else { for index in indices { artwork.updateGlyph(at: index) { $0.surface = surface } } }
        }
        StudioFeedback.shared.selection()
    }
    func setGlyphValue(_ key: WritableKeyPath<GlyphAdjustment, Double>, _ value: Double) {
        guard let first = selection.sorted().first else { return }
        let difference = value - artwork.adjustment(at: first)[keyPath: key]
        for index in artwork.expandedSelection(selection) {
            artwork.updateGlyph(at: index) { item in
                item[keyPath: key] += difference
                if key == \GlyphAdjustment.scale { item.scale = max(0.2, min(3, item.scale)) }
            }
        }
        saved = false
        render()
    }
    func moveLayer(_ delta: Int) {
        let indices = artwork.expandedSelection(selection)
        edit { artwork in
            for index in indices { artwork.updateGlyph(at: index) { $0.layer = max(-20, min(20, $0.layer + delta)) } }
        }
    }
    func beginGesture() {
        if gestureStart == nil { gestureStart = artwork; history.record(artwork); saved = false }
    }
    func undo() {
        if let previous = history.undo(artwork) { artwork = previous; saved = false; render() }
    }
    func redo() {
        if let next = history.redo(artwork) { artwork = next; saved = false; render() }
    }
    func save(_ store: ProjectStore, thumbnail: Bool = true) {
        do {
            if let issue = InputCheck.validate(artwork.text) { throw GeometryError.invalid(issue) }
            // Validate even when a thumbnail is not requested.
            _ = try GlyphOutlineBuilder.build(text: artwork.text, spacing: artwork.spacing)
            let preview = thumbnail ? try renderer.image(artwork, size: CGSize(width: 400, height: 400), transparent: false).pngData() : nil
            try store.save(artwork, history: history, thumbnail: preview)
            saved = true
            if thumbnail { StudioFeedback.shared.saved() }
        } catch { self.error = L10n.text("保存できませんでした。") + error.localizedDescription }
    }
}

struct StudioView: View {
    @EnvironmentObject private var store: ProjectStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("lowPower") private var lowPower = false
    @AppStorage("panelOnRight") private var panelOnRight = false
    @StateObject private var model: StudioModel
    @State private var tab = "素材"
    @State private var exporting = false
    @State private var exhibition = false
    @State private var textDraft = ""
    @State private var changingText = false
    @State private var thermalLimited = false
    @State private var exhibitionControls = true
    @State private var controlsRevealedAt = Date()

    init(artwork: Artwork) { _model = StateObject(wrappedValue: StudioModel(artwork)) }
    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                Group {
                    if exhibition { viewport }
                    else if proxy.size.width > 750 {
                        HStack(spacing: 0) {
                            if !panelOnRight { controls.frame(width: 310); Divider() }
                            viewport
                            if panelOnRight { Divider(); controls.frame(width: 310) }
                        }
                    } else {
                        VStack(spacing: 0) {
                            viewport
                            Divider()
                            controls.frame(height: min(330, proxy.size.height * 0.46))
                        }
                    }
                }
            }
            .background(Theme.background)
            .navigationTitle(exhibition ? "" : model.artwork.text)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !exhibition {
                    ToolbarItem(placement: .cancellationAction) {
                        Button { model.save(store); if model.saved { dismiss() } } label: { Image(systemName: "chevron.down") }
                            .accessibilityLabel("保存して閉じる").accessibilityIdentifier("studio.close")
                    }
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button { model.undo() } label: { Image(systemName: "arrow.uturn.backward") }
                            .disabled(model.history.past.isEmpty).accessibilityLabel("取り消す").accessibilityIdentifier("studio.undo")
                        Button { model.redo() } label: { Image(systemName: "arrow.uturn.forward") }
                            .disabled(model.history.future.isEmpty).accessibilityLabel("やり直す")
                        Button { model.save(store) } label: { Image(systemName: model.saved ? "checkmark" : "square.and.arrow.down") }
                            .accessibilityLabel(LocalizedStringKey(model.saved ? "保存済み" : "作品を保存")).accessibilityIdentifier("studio.save")
                    }
                }
            }
            .toolbar(exhibition ? .hidden : .visible, for: .navigationBar)
            .overlay(alignment: .topTrailing) {
                if exhibition && exhibitionControls {
                    Button("展示を終了", systemImage: "xmark") { exhibition = false }
                        .padding(16).background(.ultraThinMaterial, in: Capsule()).padding()
                }
            }
            .sheet(isPresented: $exporting) { ExportView(model: model) }
            .sheet(isPresented: $changingText) {
                TextEditSheet(text: model.artwork.text) { value in
                    model.edit { $0.replaceText(value) }
                    model.selection = []
                }
            }
            .alert("確認してください", isPresented: Binding(get: { model.error != nil }, set: { if !$0 { model.error = nil } })) {
                Button("閉じる") { model.error = nil }
            } message: { Text(model.error ?? "") }
            .task {
                guard !model.loaded else { return }
                model.loaded = true
                if store.projects.contains(where: { $0.id == model.artwork.id }) {
                    do {
                        let saved = try store.load(model.artwork)
                        model.artwork = saved.artwork
                        model.history = saved.history
                    } catch { model.error = error.localizedDescription }
                }
                model.render()
            }
            .task(id: model.artwork) {
                do { try await Task.sleep(for: .seconds(1.5)) } catch { return }
                guard model.loaded else { return }
                model.save(store, thumbnail: false)
            }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active && model.loaded { model.save(store, thumbnail: false) }
            }
            .task(id: exhibition && !reduceMotion && scenePhase == .active && !thermalLimited) {
                guard exhibition, !reduceMotion, scenePhase == .active, !thermalLimited else { return }
                let start = Date()
                while !Task.isCancelled {
                    model.renderer.exhibition(at: Date().timeIntervalSince(start), artwork: model.artwork)
                    do { try await Task.sleep(for: .milliseconds(33)) } catch { return }
                }
            }
            .task(id: controlsRevealedAt) {
                guard exhibition else { return }
                do { try await Task.sleep(for: .seconds(3)) } catch { return }
                if !UIAccessibility.isVoiceOverRunning { exhibitionControls = false }
            }
            .onChange(of: exhibition) { _, active in
                model.render()
                if active {
                    model.renderer.select([])
                    exhibitionControls = true
                    controlsRevealedAt = Date()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: ProcessInfo.thermalStateDidChangeNotification)) { _ in
                thermalLimited = ProcessInfo.processInfo.thermalState == .serious || ProcessInfo.processInfo.thermalState == .critical
            }
        }
    }

    private var viewport: some View {
        GeometryReader { geometry in
            SculptureView(renderer: model.renderer,
                          lowPower: lowPower || thermalLimited || ProcessInfo.processInfo.isLowPowerModeEnabled,
                          interaction: handleInteraction)
                .accessibilityIdentifier("studio.viewport")
                .overlay(alignment: .bottomLeading) {
                    if !exhibition {
                        Text("ドラッグで回転・2本指で移動・長押しで選択").font(.caption).foregroundStyle(.secondary).padding(20)
                    } else if exhibitionControls {
                        Text("タップで操作を表示・ダブルタップで編集に戻る").font(.caption).foregroundStyle(.secondary).padding(20)
                    }
                }
                .onAppear { resize(geometry.size) }
                .onChange(of: geometry.size) { _, size in resize(size) }
        }
    }

    private var controls: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 22) {
                    ForEach(["素材", "形状", "文字ごと", "光と背景", "構図", "作品"], id: \.self) { title in
                        Button { tab = title } label: {
                            Text(LocalizedStringKey(title)).font(.subheadline).foregroundStyle(tab == title ? Theme.ivory : .gray)
                                .padding(.vertical, 16)
                                .overlay(alignment: .bottom) { if tab == title { Rectangle().fill(Theme.gold).frame(height: 2) } }
                        }
                        .accessibilityIdentifier("studio.tab.\(title)")
                    }
                }.padding(.horizontal, 20)
            }.accessibilityIdentifier("studio.tabs")
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    switch tab {
                    case "素材":
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 85))], spacing: 12) {
                            ForEach(Surface.allCases) { surface in
                                Button { model.applySurface(surface) } label: {
                                    VStack(spacing: 10) {
                                        Circle().fill(LinearGradient(colors: [.white.opacity(0.8), Color(uiColor: surface.color), .black.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .frame(width: 36, height: 36)
                                        Text(surface.title).font(.caption)
                                    }.frame(maxWidth: .infinity).padding(12)
                                        .background(model.selectedSurface == surface ? .white.opacity(0.10) : .clear, in: RoundedRectangle(cornerRadius: 8))
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(model.selectedSurface == surface ? Theme.gold : .white.opacity(0.12)))
                                }.buttonStyle(.plain).accessibilityAddTraits(model.selectedSurface == surface ? .isSelected : [])
                            }
                        }
                        if !model.selection.isEmpty {
                            Text("選択した文字の素材を変更します。").font(.caption).foregroundStyle(.secondary)
                        }
                        slider("粗さ", \.finish.roughness, 0.05...1)
                        slider("金属度", \.finish.metallic, 0...1)
                        slider("クリアコート", \.finish.clearCoat, 0...1)
                        slider("表面の傷", \.finish.scratches, 0...1)
                    case "形状":
                        Button("文字を変更", systemImage: "textformat") { textDraft = model.artwork.text; changingText = true }
                        slider("厚さ", \.depth, 0...100)
                        slider("ベベル", \.bevel, 0...30)
                        slider("字間", \.spacing, -20...100)
                        slider("行間", \.layout.lineHeight, 0.7...2)
                        slider("アーチ", \.layout.arc, -1.5...1.5)
                        Picker("整列", selection: model.binding(\.layout.alignment)) {
                            ForEach(TextAlignmentMode.allCases) { Text(LocalizedStringKey($0.title)).tag($0) }
                        }
                        Picker("曲線の品質", selection: model.binding(\.layout.smoothness)) {
                            Text("標準").tag(0.5); Text("高精細").tag(0.25); Text("最高精細").tag(0.1)
                        }
                    case "文字ごと":
                        GlyphControls(model: model)
                    case "光と背景":
                        Picker("照明", selection: model.binding(\.lighting.style)) {
                            ForEach(LightStyle.allCases) { Text(LocalizedStringKey($0.title)).tag($0) }
                        }
                        slider("光の強さ", \.light, 0.2...2.5)
                        slider("補助光", \.lighting.fill, 0...2)
                        slider("輪郭の光", \.lighting.rim, 0...2)
                        slider("光の暖かさ", \.lighting.temperature, -1...1)
                        Picker("背景", selection: model.binding(\.backdrop)) {
                            ForEach(Backdrop.allCases) { Text(LocalizedStringKey($0.title)).tag($0) }
                        }.pickerStyle(.menu)
                    case "構図":
                        slider("左右の角度", \.yaw, -Double.pi...Double.pi)
                        slider("上下の角度", \.pitch, -1.3...1.3)
                        slider("傾き", \.layout.roll, -Double.pi...Double.pi)
                        slider("拡大率", \.zoom, 0.3...3)
                        slider("左右の位置", \.panX, -100...100)
                        slider("上下の位置", \.panY, -100...100)
                        Button("正面に戻す", systemImage: "viewfinder") { resetCamera() }
                        HStack {
                            Button("45度") { camera(yaw: -.pi / 4, pitch: 0.2) }
                            Button("上方") { camera(yaw: 0, pitch: 0.9) }
                            Button("俯瞰") { camera(yaw: -.pi / 4, pitch: 1.2) }
                        }.buttonStyle(.bordered)
                        Button("アイソメトリック") { camera(yaw: -.pi / 4, pitch: 0.615) }
                    default:
                        Menu("プリセットを適用") {
                            ForEach(ArtworkPreset.allCases) { preset in
                                Button(preset.title) { model.edit { preset.apply(to: &$0) }; model.selection = [] }
                            }
                        }
                        TextField("作品名", text: model.binding(\.title)).textFieldStyle(.roundedBorder)
                        Button("画像を書き出す", systemImage: "square.and.arrow.up") { exporting = true }.accessibilityIdentifier("studio.export")
                        Button("展示する", systemImage: "play.rectangle") { exhibition = true }.accessibilityIdentifier("studio.exhibit")
                        Button("別の作品として保存", systemImage: "doc.on.doc") {
                            model.artwork.id = UUID()
                            model.artwork.createdAt = Date()
                            model.artwork.title += " コピー"
                            model.history = EditHistory()
                            model.save(store)
                        }
                    }
                }.padding(20)
            }.accessibilityIdentifier("studio.controls")
        }.background(Color(white: 0.07))
    }
    private func slider(_ title: String, _ key: WritableKeyPath<Artwork, Double>, _ range: ClosedRange<Double>) -> some View {
        VStack(spacing: 8) {
            HStack { Text(LocalizedStringKey(title)); Spacer(); Text(model.artwork[keyPath: key], format: .number.precision(.fractionLength(1))).foregroundStyle(.secondary).monospacedDigit() }
                .font(.caption)
            Slider(value: Binding(get: { model.artwork[keyPath: key] }, set: {
                model.artwork[keyPath: key] = $0
                model.saved = false
                model.render()
            }), in: range, onEditingChanged: { editing in
                if editing { model.history.record(model.artwork) }
            }).accessibilityLabel(LocalizedStringKey(title))
        }
    }
    private func resize(_ size: CGSize) {
        model.aspect = size.width / max(size.height, 1)
        model.viewportHeight = max(size.height, 1)
        model.render()
    }
    private func camera(yaw: Double, pitch: Double) {
        model.edit { $0.yaw = yaw; $0.pitch = pitch; $0.layout.roll = 0; $0.panX = 0; $0.panY = 0; $0.zoom = 1 }
    }
    private func handleInteraction(_ event: SculptureInteraction) {
        if exhibition {
            if case .reset = event { exhibition = false }
            if case .tap = event { exhibitionControls = true; controlsRevealedAt = Date() }
            return
        }
        switch event {
        case .begin: model.beginGesture()
        case .end: model.gestureStart = nil
        case .rotate(let point):
            guard let start = model.gestureStart else { return }
            model.artwork.yaw = start.yaw + point.x / 150
            model.artwork.pitch = max(-1.3, min(1.3, start.pitch + point.y / 150))
            model.render()
        case .move(let point):
            guard let start = model.gestureStart else { return }
            let factor = (model.renderer.camera.camera?.orthographicScale ?? 85) * 2 / model.viewportHeight
            model.artwork.panX = start.panX + point.x * factor
            model.artwork.panY = start.panY - point.y * factor
            model.render()
        case .zoom(let factor):
            guard let start = model.gestureStart else { return }
            model.artwork.zoom = max(0.3, min(3, start.zoom * factor)); model.render()
        case .select(let index):
            model.select(index)
            tab = "文字ごと"
        case .reset: resetCamera()
        case .tap: break
        }
    }
    private func resetCamera() {
        model.history.record(model.artwork)
        model.saved = false
        model.artwork.yaw = 0; model.artwork.pitch = 0; model.artwork.zoom = 1
        model.artwork.panX = 0; model.artwork.panY = 0
        model.artwork.layout.roll = 0
        model.render()
    }
}

struct TextEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State var text: String
    let apply: (String) -> Void
    var body: some View {
        NavigationStack {
            Form {
                TextEditor(text: $text).font(.system(size: 36, design: .serif)).frame(minHeight: 160)
                Text("12文字・3行まで").foregroundStyle(.secondary)
                if let issue = InputCheck.validate(text) { Text(issue).foregroundStyle(.orange) }
                Text("文字を変更すると、文字ごとの配置と素材はリセットされます。").font(.caption).foregroundStyle(.secondary)
            }.navigationTitle("文字を変更")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("適用") { apply(text); dismiss() }.disabled(InputCheck.validate(text) != nil)
                    }
                }
        }
    }
}

struct GlyphControls: View {
    @ObservedObject var model: StudioModel
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("文字をタップして複数選択できます。").font(.caption).foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))]) {
                ForEach(model.artwork.editableIndices, id: \.self) { index in
                    Button { model.select(index, additive: true) } label: {
                        Text(String(Array(model.artwork.text)[index])).font(.title3)
                            .frame(minWidth: 44, minHeight: 44)
                            .background(model.artwork.expandedSelection(model.selection).contains(index) ? Theme.gold.opacity(0.25) : .white.opacity(0.06),
                                        in: RoundedRectangle(cornerRadius: 6))
                    }.accessibilityLabel("\(index + 1)文字目 \(Array(model.artwork.text)[index])")
                }
            }
            if model.selection.isEmpty {
                Text("選択した文字の位置、角度、大きさを調整します。").font(.caption).foregroundStyle(.secondary)
            } else {
                HStack {
                    Button("選択解除") { model.selection = []; model.render() }
                    Spacer()
                    Text("\(model.artwork.expandedSelection(model.selection).count)文字").font(.caption)
                }
                HStack {
                    Button("グループ化") { model.edit { $0.group(model.selection) } }
                        .disabled(model.artwork.expandedSelection(model.selection).count < 2)
                    Button("解除") { model.edit { $0.ungroup(model.selection) } }
                }.buttonStyle(.bordered)
                glyphSlider("左右", \.x, -300...300)
                glyphSlider("上下", \.y, -300...300)
                glyphSlider("奥行き", \.z, -200...200)
                glyphSlider("回転 X", \.rotationX, -.pi...(.pi))
                glyphSlider("回転 Y", \.rotationY, -.pi...(.pi))
                glyphSlider("回転 Z", \.rotationZ, -.pi...(.pi))
                glyphSlider("大きさ", \.scale, 0.2...3)
                HStack {
                    Button("手前へ", systemImage: "square.3.layers.3d.top.filled") { model.moveLayer(1) }
                    Button("奥へ", systemImage: "square.3.layers.3d.bottom.filled") { model.moveLayer(-1) }
                }
                Button("高さを揃える") {
                    let indices = model.artwork.expandedSelection(model.selection)
                    let average = indices.reduce(0.0) { $0 + model.artwork.adjustment(at: $1).y } / Double(indices.count)
                    model.edit { artwork in for index in indices { artwork.updateGlyph(at: index) { $0.y = average } } }
                }
                Button("選択した文字をリセット") {
                    let indices = model.artwork.expandedSelection(model.selection)
                    model.edit { $0.glyphs.removeAll { indices.contains($0.id) } }
                }
            }
        }
    }
    private func glyphSlider(_ title: String, _ key: WritableKeyPath<GlyphAdjustment, Double>, _ range: ClosedRange<Double>) -> some View {
        let index = model.selection.sorted().first ?? 0
        return VStack {
            HStack {
                Text(LocalizedStringKey(title))
                Spacer()
                Text(model.artwork.adjustment(at: index)[keyPath: key], format: .number.precision(.fractionLength(1))).monospacedDigit()
            }.font(.caption)
            Slider(value: Binding(get: { model.artwork.adjustment(at: index)[keyPath: key] },
                                  set: { model.setGlyphValue(key, $0) }),
                   in: range, onEditingChanged: { if $0 { model.history.record(model.artwork) } })
                .accessibilityLabel(LocalizedStringKey(title))
        }
    }
}
