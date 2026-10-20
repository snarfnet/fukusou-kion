import SwiftUI

struct ShareItem: Identifiable { let id = UUID(); let url: URL }

struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var model: StudioModel
    @State private var format = ImageFormat.png
    @State private var transparent = false
    @State private var dimension = 0
    @State private var movie = false
    @State private var seconds = 5
    @State private var progress = 0.0
    @State private var exportTask: Task<Void, Never>?
    @State private var busy = false
    @State private var share: ShareItem?
    @State private var generatedURL: URL?
    @State private var error: String?
    private let sizes = [CGSize(width: 1080, height: 1080), CGSize(width: 2160, height: 2160),
                         CGSize(width: 1080, height: 1920), CGSize(width: 2480, height: 3508),
                         CGSize(width: 3840, height: 2160)]
    private let labels = ["正方形 · 1080", "正方形 · 2160", "ストーリー · 1080 × 1920", "A4比率 · 2480 × 3508", "4K · 3840 × 2160"]
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("書き出すもの", selection: $movie) { Text("画像").tag(false); Text("回転動画").tag(true) }
                        .pickerStyle(.segmented)
                }.disabled(busy)
                Section(LocalizedStringKey(movie ? "MP4動画" : "画像")) {
                    if !movie {
                        Picker("形式", selection: $format) {
                            ForEach(ImageFormat.allCases.filter(\.supported)) { Text($0.rawValue).tag($0) }
                        }
                    }
                    Picker("サイズ", selection: $dimension) {
                        ForEach(labels.indices.filter { !movie || $0 != 3 }, id: \.self) { Text(LocalizedStringKey(labels[$0])).tag($0) }
                    }
                    if movie {
                        Picker("長さ", selection: $seconds) { ForEach([5, 10, 15], id: \.self) { Text("\($0)秒").tag($0) } }
                        Text("30fpsで1回転する動画を作ります。処理中はこの画面を開いたままにしてください。")
                            .font(.caption).foregroundStyle(.secondary)
                    } else if format == .png { Toggle("背景を透明にする", isOn: $transparent) }
                    Text("操作パネルや透かしは入りません。").font(.caption).foregroundStyle(.secondary)
                }.disabled(busy)
                Section {
                    if busy {
                        if movie { ProgressView(value: progress) }
                        else { ProgressView("画像を作成中") }
                        Button("中止", role: .cancel) { exportTask?.cancel() }
                    } else {
                        Button(LocalizedStringKey(movie ? "動画を作成して共有" : "画像を作成して共有"), systemImage: "square.and.arrow.up") { start() }
                    }
                }
            }
            .navigationTitle("書き出し")
            .toolbar { Button("完了") { dismiss() }.disabled(busy) }
            .interactiveDismissDisabled(busy)
            .onChange(of: movie) { _, isMovie in if isMovie && dimension == 3 { dimension = 0 } }
            .onChange(of: scenePhase) { _, phase in
                if phase == .background && busy {
                    exportTask?.cancel()
                    error = "書き出しを中止しました。この画面を開いたまま再試行してください。"
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didReceiveMemoryWarningNotification)) { _ in
                if busy { exportTask?.cancel(); error = "メモリが不足しています。サイズを下げて再試行してください。" }
            }
            .onDisappear { exportTask?.cancel() }
            .sheet(item: $share, onDismiss: cleanExport) { ShareSheet(url: $0.url) }
            .alert("書き出し", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("閉じる") { error = nil }
            } message: { Text(error ?? "") }
        }
    }
    private func start() {
        busy = true
        progress = 0
        let artwork = model.artwork
        exportTask = Task { @MainActor in
            defer { busy = false; exportTask = nil }
            do {
                let url: URL
                if movie {
                    url = try await ExportService.movie(artwork, size: sizes[dimension], seconds: seconds) { progress = $0 }
                } else {
                    url = try await ExportService.image(artwork, size: sizes[dimension], format: format, transparent: transparent)
                }
                generatedURL = url
                share = ShareItem(url: url)
            } catch is CancellationError {
                // Cancellation is an expected user action.
            } catch { self.error = error.localizedDescription }
        }
    }
    private func cleanExport() {
        if let generatedURL { try? FileManager.default.removeItem(at: generatedURL) }
        generatedURL = nil
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
