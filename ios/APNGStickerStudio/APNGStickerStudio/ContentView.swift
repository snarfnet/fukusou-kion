import PhotosUI
import SwiftUI
import UIKit

struct ContentView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var sourceImage: UIImage?
    @State private var settings = StickerSettings()
    @State private var previewTick = 0
    @State private var exportResult: ExportResult?
    @State private var error: StudioError?
    @State private var isExporting = false
    @State private var showShare = false

    private let previewTimer = Timer.publish(every: 0.12, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    header
                    previewPanel
                    importPanel
                    effectPanel
                    tuningPanel
                    specPanel
                    exportPanel
                }
                .padding(16)
            }
            .background(StudioTheme.canvas.ignoresSafeArea())
            .navigationTitle("APNG Sticker Studio")
            .navigationBarTitleDisplayMode(.inline)
            .onReceive(previewTimer) { _ in
                previewTick += 1
            }
            .onChange(of: selectedItem) { _, item in
                Task { await loadImage(item) }
            }
            .alert(item: $error) { error in
                Alert(title: Text("エラー"), message: Text(error.localizedDescription), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $showShare) {
                if let exportResult {
                    ActivityView(items: [exportResult.url])
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(StudioTheme.ink)

                VStack(alignment: .leading, spacing: 2) {
                    Text("1枚の画像からAPNGへ")
                        .font(.title2.weight(.black))
                    Text("端末内でフレーム生成。書き出し後にFilesや共有で使えます。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var previewPanel: some View {
        VStack(spacing: 14) {
            ZStack {
                Checkerboard()
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                if let sourceImage {
                    Image(uiImage: previewImage(sourceImage))
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(18)
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 42, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Text("PNGまたは写真を選んでください")
                            .font(.headline)
                        Text("透明PNGなら背景も保てます")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .aspectRatio(LineStickerSpec.canvasSize, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.black.opacity(0.08)))

            HStack {
                StatView(title: "Canvas", value: "320 x 270")
                StatView(title: "Frames", value: "\(settings.frameCount)")
                StatView(title: "Time", value: String(format: "%.1fs", APNGStickerRenderer.duration(settings: settings)))
            }
        }
        .panelStyle()
    }

    private var importPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Import", systemImage: "photo.on.rectangle")
                .font(.headline.weight(.bold))

            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label(sourceImage == nil ? "画像を選ぶ" : "画像を変更", systemImage: "plus.circle.fill")
            }
            .buttonStyle(StudioPrimaryButtonStyle())
        }
        .panelStyle()
    }

    private var effectPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Effect", systemImage: "wand.and.stars")
                .font(.headline.weight(.bold))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 10) {
                ForEach(StickerEffect.allCases) { effect in
                    Button {
                        settings.effect = effect
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: effect.systemImage)
                                .font(.title3.weight(.bold))
                            Text(effect.rawValue)
                                .font(.caption.weight(.bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 74)
                    }
                    .buttonStyle(EffectButtonStyle(isSelected: settings.effect == effect))
                    .accessibilityLabel(effect.rawValue)
                }
            }

            Text(settings.effect.shortNote)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .panelStyle()
    }

    private var tuningPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Tune", systemImage: "slider.horizontal.3")
                .font(.headline.weight(.bold))

            SliderRow(title: "強さ", value: $settings.strength, range: 0.2...1.0, display: "\(Int(settings.strength * 100))%")
            SliderRow(title: "速さ", value: $settings.speed, range: 0.5...1.8, display: String(format: "%.1fx", settings.speed))

            Stepper(value: $settings.frameCount, in: 5...20) {
                HStack {
                    Text("フレーム数")
                    Spacer()
                    Text("\(settings.frameCount)")
                        .foregroundStyle(.secondary)
                        .font(.subheadline.monospacedDigit())
                }
            }

            Stepper(value: $settings.loops, in: 1...4) {
                HStack {
                    Text("ループ")
                    Spacer()
                    Text("\(settings.loops)")
                        .foregroundStyle(.secondary)
                        .font(.subheadline.monospacedDigit())
                }
            }

            Picker("背景", selection: $settings.background) {
                ForEach(StickerBackground.allCases) { background in
                    Text(background.rawValue).tag(background)
                }
            }
            .pickerStyle(.segmented)
        }
        .panelStyle()
    }

    private var specPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("LINE向けチェック", systemImage: "checklist")
                .font(.headline.weight(.bold))

            ForEach(LineStickerSpec.report(settings: settings)) { item in
                HStack {
                    Image(systemName: item.isPassing ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(item.isPassing ? .green : .orange)
                    Text(item.title)
                        .font(.subheadline)
                    Spacer()
                }
            }
        }
        .panelStyle()
    }

    private var exportPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Export", systemImage: "square.and.arrow.up")
                .font(.headline.weight(.bold))

            Button {
                Task { await exportAPNG() }
            } label: {
                Label(isExporting ? "書き出し中..." : "APNGを書き出す", systemImage: "arrow.down.doc.fill")
            }
            .buttonStyle(StudioPrimaryButtonStyle())
            .disabled(sourceImage == nil || isExporting)

            if let exportResult {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exportResult.url.lastPathComponent)
                            .font(.subheadline.weight(.bold))
                            .lineLimit(1)
                        Text("\(exportResult.sizeText) / \(exportResult.frameCount) frames / \(String(format: "%.1fs", exportResult.duration))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button {
                        showShare = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.headline.weight(.bold))
                    }
                    .buttonStyle(IconButtonStyle())
                    .accessibilityLabel("共有")
                }
                .padding(12)
                .background(.white, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.black.opacity(0.08)))
            }
        }
        .panelStyle()
    }

    private func previewImage(_ image: UIImage) -> UIImage {
        var previewSettings = settings
        previewSettings.frameCount = 12
        let index = previewTick % previewSettings.frameCount
        let progress = Double(index) / Double(max(1, previewSettings.frameCount - 1))
        return APNGStickerRenderer.frame(from: image, settings: previewSettings, progress: progress, index: index)
    }

    private func loadImage(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                error = .imageLoadFailed
                return
            }
            sourceImage = image.normalized()
            exportResult = nil
        } catch {
            self.error = .imageLoadFailed
        }
    }

    private func exportAPNG() async {
        guard let sourceImage else { return }
        isExporting = true
        defer { isExporting = false }

        do {
            let frames = APNGStickerRenderer.frames(from: sourceImage, settings: settings)
            let data = try APNGEncoder.encode(
                images: frames,
                delay: APNGStickerRenderer.delay(settings: settings),
                loopCount: settings.loops
            )
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("apng-sticker-\(Int(Date().timeIntervalSince1970)).png")
            try data.write(to: url, options: .atomic)
            exportResult = ExportResult(
                url: url,
                byteCount: data.count,
                frameCount: frames.count,
                duration: APNGStickerRenderer.duration(settings: settings)
            )
            showShare = true
        } catch let studioError as StudioError {
            error = studioError
        } catch {
            self.error = .exportFailed(error.localizedDescription)
        }
    }
}

private struct SliderRow: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let display: String

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(title)
                Spacer()
                Text(display)
                    .foregroundStyle(.secondary)
                    .font(.subheadline.monospacedDigit())
            }
            Slider(value: $value, in: range)
        }
    }
}

private struct StatView: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.bold).monospacedDigit())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct Checkerboard: View {
    var body: some View {
        Canvas { context, size in
            let square: CGFloat = 14
            for y in stride(from: CGFloat(0), to: size.height, by: square) {
                for x in stride(from: CGFloat(0), to: size.width, by: square) {
                    let isDark = (Int(x / square) + Int(y / square)).isMultiple(of: 2)
                    let rect = CGRect(x: x, y: y, width: square, height: square)
                    context.fill(Path(rect), with: .color(isDark ? Color.black.opacity(0.05) : Color.white))
                }
            }
        }
        .background(Color.white)
    }
}

private enum StudioTheme {
    static let canvas = Color(red: 0.94, green: 0.95, blue: 0.93)
    static let ink = Color(red: 0.07, green: 0.09, blue: 0.10)
    static let accent = Color(red: 0.12, green: 0.46, blue: 0.78)
}

private extension View {
    func panelStyle() -> some View {
        padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.94), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.black.opacity(0.07)))
    }
}

private struct StudioPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .foregroundStyle(.white)
            .background(StudioTheme.ink.opacity(configuration.isPressed ? 0.70 : 1), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct EffectButtonStyle: ButtonStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isSelected ? .white : StudioTheme.ink)
            .background(isSelected ? StudioTheme.accent : Color.white, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? StudioTheme.accent : .black.opacity(0.10)))
            .opacity(configuration.isPressed ? 0.78 : 1)
    }
}

private struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 42, height: 42)
            .foregroundStyle(StudioTheme.ink)
            .background(Color.black.opacity(configuration.isPressed ? 0.10 : 0.05), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
    }
}

private extension UIImage {
    func normalized() -> UIImage {
        guard imageOrientation != .up else { return self }
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
