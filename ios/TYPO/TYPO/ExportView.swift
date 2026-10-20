import SwiftUI

struct ShareItem: Identifiable { let id = UUID(); let url: URL }

struct ExportView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var model: StudioModel
    @State private var format = "PNG"
    @State private var transparent = false
    @State private var dimension = 0
    @State private var busy = false
    @State private var share: ShareItem?
    @State private var error: String?
    private let sizes = [CGSize(width: 1080, height: 1080), CGSize(width: 2160, height: 2160),
                         CGSize(width: 1080, height: 1920), CGSize(width: 2480, height: 3508),
                         CGSize(width: 3840, height: 2160)]
    private let labels = ["正方形 · 1080", "正方形 · 2160", "ストーリー · 1080 × 1920", "A4比率 · 2480 × 3508", "4K · 3840 × 2160"]
    var body: some View {
        NavigationStack {
            Form {
                Section("画像") {
                    Picker("形式", selection: $format) { Text("PNG").tag("PNG"); Text("JPEG").tag("JPEG") }
                    Picker("サイズ", selection: $dimension) {
                        ForEach(labels.indices, id: \.self) { Text(labels[$0]).tag($0) }
                    }
                    if format == "PNG" { Toggle("背景を透明にする", isOn: $transparent) }
                    Text("操作パネルや透かしは画像に入りません。").font(.caption).foregroundStyle(.secondary)
                }
                Button {
                    busy = true
                    Task { @MainActor in
                        // Allow the progress state to appear before the GPU snapshot.
                        await Task.yield()
                        do {
                            let image = try model.renderer.image(model.artwork, size: sizes[dimension], transparent: transparent && format == "PNG")
                            guard let data = format == "PNG" ? image.pngData() : image.jpegData(compressionQuality: 0.95) else {
                                throw CocoaError(.fileWriteUnknown)
                            }
                            let url = FileManager.default.temporaryDirectory
                                .appendingPathComponent("TYPO-\(UUID().uuidString)").appendingPathExtension(format == "PNG" ? "png" : "jpg")
                            try data.write(to: url, options: .atomic)
                            share = ShareItem(url: url)
                        } catch { self.error = error.localizedDescription }
                        busy = false
                    }
                } label: {
                    HStack { Text("画像を作成して共有"); Spacer(); if busy { ProgressView() } else { Image(systemName: "square.and.arrow.up") } }
                }.disabled(busy)
            }
            .navigationTitle("書き出し")
            .toolbar { Button("完了") { dismiss() }.disabled(busy) }
            .interactiveDismissDisabled(busy)
            .sheet(item: $share, onDismiss: cleanExports) { ShareSheet(url: $0.url) }
            .alert("書き出せませんでした", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("閉じる") { error = nil }
            } message: { Text(error ?? "") }
        }
    }
    private func cleanExports() {
        let temporary = FileManager.default.temporaryDirectory
        if let urls = try? FileManager.default.contentsOfDirectory(at: temporary, includingPropertiesForKeys: nil) {
            for url in urls where url.lastPathComponent.hasPrefix("TYPO-") {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
