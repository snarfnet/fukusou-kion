import SwiftUI
import SceneKit

@MainActor
final class StudioModel: ObservableObject {
    @Published var artwork: Artwork
    @Published var history = EditHistory()
    @Published var error: String?
    @Published var saved = false
    let renderer = SculptureRenderer()
    var aspect = 1.0
    var gestureStart: Artwork?
    var loaded = false

    init(_ artwork: Artwork) { self.artwork = artwork }
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
        do { try renderer.update(artwork, aspect: aspect) }
        catch { self.error = error.localizedDescription }
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
        } catch { self.error = "保存できませんでした。\(error.localizedDescription)" }
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
    private let timer = Timer.publish(every: 1.0 / 30, on: .main, in: .common).autoconnect()

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
                            .accessibilityLabel("保存して閉じる")
                    }
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button { model.undo() } label: { Image(systemName: "arrow.uturn.backward") }
                            .disabled(model.history.past.isEmpty).accessibilityLabel("取り消す")
                        Button { model.redo() } label: { Image(systemName: "arrow.uturn.forward") }
                            .disabled(model.history.future.isEmpty).accessibilityLabel("やり直す")
                        Button { model.save(store) } label: { Image(systemName: model.saved ? "checkmark" : "square.and.arrow.down") }
                            .accessibilityLabel(model.saved ? "保存済み" : "作品を保存")
                    }
                }
            }
            .toolbar(exhibition ? .hidden : .visible, for: .navigationBar)
            .overlay(alignment: .topTrailing) {
                if exhibition {
                    Button("展示を終了", systemImage: "xmark") { exhibition = false }
                        .padding(16).background(.ultraThinMaterial, in: Capsule()).padding()
                }
            }
            .sheet(isPresented: $exporting) { ExportView(model: model) }
            .alert("文字を変更", isPresented: $changingText) {
                TextField("12文字まで", text: $textDraft)
                Button("適用") {
                    if let error = InputCheck.validate(textDraft) { model.error = error }
                    else { model.change(\.text, textDraft) }
                }
                Button("キャンセル", role: .cancel) {}
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
            .onReceive(timer) { _ in
                guard exhibition, !reduceMotion, scenePhase == .active, !thermalLimited else { return }
                // Exhibition rotates the scene only, leaving the editable camera and history intact.
                model.renderer.scene.rootNode.childNodes.first(where: { !$0.childNodes.isEmpty })?.eulerAngles.y += 0.002
            }
            .onChange(of: exhibition) { _, _ in model.render() }
            .onReceive(NotificationCenter.default.publisher(for: ProcessInfo.thermalStateDidChangeNotification)) { _ in
                thermalLimited = ProcessInfo.processInfo.thermalState == .serious || ProcessInfo.processInfo.thermalState == .critical
            }
        }
    }

    private var viewport: some View {
        GeometryReader { geometry in
            SculptureView(renderer: model.renderer, lowPower: lowPower || thermalLimited || ProcessInfo.processInfo.isLowPowerModeEnabled)
                .overlay(alignment: .bottomLeading) {
                    if !exhibition {
                        Text("ドラッグで回転・ピンチで拡大").font(.caption).foregroundStyle(.secondary).padding(20)
                    }
                }
                .gesture(DragGesture().onChanged { value in
                    model.beginGesture()
                    guard let start = model.gestureStart else { return }
                    model.artwork.yaw = start.yaw + value.translation.width / 150
                    model.artwork.pitch = max(-1.3, min(1.3, start.pitch + value.translation.height / 150))
                    model.render()
                }.onEnded { _ in model.gestureStart = nil })
                .simultaneousGesture(MagnifyGesture().onChanged { value in
                    model.beginGesture()
                    model.artwork.zoom = max(0.3, min(3, (model.gestureStart?.zoom ?? 1) * value.magnification))
                    model.render()
                }.onEnded { _ in model.gestureStart = nil })
                .onTapGesture(count: 2) { resetCamera() }
                .onAppear { resize(geometry.size) }
                .onChange(of: geometry.size) { _, size in resize(size) }
        }
    }

    private var controls: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 22) {
                    ForEach(["素材", "形状", "光と背景", "構図", "作品"], id: \.self) { title in
                        Button { tab = title } label: {
                            Text(title).font(.subheadline).foregroundStyle(tab == title ? Theme.ivory : .gray)
                                .padding(.vertical, 16)
                                .overlay(alignment: .bottom) { if tab == title { Rectangle().fill(Theme.gold).frame(height: 2) } }
                        }
                    }
                }.padding(.horizontal, 20)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    switch tab {
                    case "素材":
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 85))], spacing: 12) {
                            ForEach(Surface.allCases) { surface in
                                Button { model.change(\.surface, surface) } label: {
                                    VStack(spacing: 10) {
                                        Circle().fill(LinearGradient(colors: [.white.opacity(0.8), Color(uiColor: surface.color), .black.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .frame(width: 36, height: 36)
                                        Text(surface.title).font(.caption)
                                    }.frame(maxWidth: .infinity).padding(12)
                                        .background(model.artwork.surface == surface ? .white.opacity(0.10) : .clear, in: RoundedRectangle(cornerRadius: 8))
                                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(model.artwork.surface == surface ? Theme.gold : .white.opacity(0.12)))
                                }.buttonStyle(.plain).accessibilityAddTraits(model.artwork.surface == surface ? .isSelected : [])
                            }
                        }
                    case "形状":
                        Button("文字を変更", systemImage: "textformat") { textDraft = model.artwork.text; changingText = true }
                        slider("厚さ", \.depth, 0...100)
                        slider("ベベル", \.bevel, 0...5)
                        slider("字間", \.spacing, -20...100)
                    case "光と背景":
                        slider("光の強さ", \.light, 0.2...2.5)
                        Picker("背景", selection: model.binding(\.backdrop)) {
                            ForEach(Backdrop.allCases) { Text($0.title).tag($0) }
                        }.pickerStyle(.menu)
                    case "構図":
                        slider("左右の角度", \.yaw, -Double.pi...Double.pi)
                        slider("上下の角度", \.pitch, -1.3...1.3)
                        slider("拡大率", \.zoom, 0.3...3)
                        slider("左右の位置", \.panX, -100...100)
                        slider("上下の位置", \.panY, -100...100)
                        Button("正面に戻す", systemImage: "viewfinder") { resetCamera() }
                    default:
                        TextField("作品名", text: model.binding(\.title)).textFieldStyle(.roundedBorder)
                        Button("画像を書き出す", systemImage: "square.and.arrow.up") { exporting = true }
                        Button("展示する", systemImage: "play.rectangle") { exhibition = true }
                        Button("別の作品として保存", systemImage: "doc.on.doc") {
                            model.artwork.id = UUID()
                            model.artwork.createdAt = Date()
                            model.artwork.title += " コピー"
                            model.history = EditHistory()
                            model.save(store)
                        }
                    }
                }.padding(20)
            }
        }.background(Color(white: 0.07))
    }
    private func slider(_ title: String, _ key: WritableKeyPath<Artwork, Double>, _ range: ClosedRange<Double>) -> some View {
        VStack(spacing: 8) {
            HStack { Text(title); Spacer(); Text(model.artwork[keyPath: key], format: .number.precision(.fractionLength(1))).foregroundStyle(.secondary).monospacedDigit() }
                .font(.caption)
            Slider(value: Binding(get: { model.artwork[keyPath: key] }, set: {
                model.artwork[keyPath: key] = $0
                model.saved = false
                model.render()
            }), in: range, onEditingChanged: { editing in
                if editing { model.history.record(model.artwork) }
            }).accessibilityLabel(title)
        }
    }
    private func resize(_ size: CGSize) { model.aspect = size.width / max(size.height, 1); model.render() }
    private func resetCamera() {
        model.history.record(model.artwork)
        model.saved = false
        model.artwork.yaw = 0; model.artwork.pitch = 0; model.artwork.zoom = 1
        model.artwork.panX = 0; model.artwork.panY = 0
        model.render()
    }
}
