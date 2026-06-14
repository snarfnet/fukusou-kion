import SwiftUI
import UIKit

struct ContentView: View {
    @State private var sourceImage: UIImage?
    @State private var document: CellArtDocument?
    @State private var settings = CellArtSettings()
    @State private var exportedWorkbook: ExportedWorkbook?
    @State private var isShowingPicker = false
    @State private var isShowingShare = false
    @State private var isProcessing = false
    @State private var message = "画像を選ぶと、Excelセルで描いたアートに変換します。"

    private let generator = ImageArtGenerator()
    private let writer = XLSXWorkbookWriter()

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    imagePanel
                    controlsPanel
                    previewPanel
                    exportPanel
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 28)
            }
            .background(AppStyle.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
        }
        .tint(AppStyle.excelGreen)
        .sheet(isPresented: $isShowingPicker) {
            PhotoPicker { image in
                sourceImage = image
                exportedWorkbook = nil
                generatePreview()
            }
        }
        .sheet(isPresented: $isShowingShare) {
            if let exportedWorkbook {
                ShareSheet(items: [exportedWorkbook.url])
            }
        }
        .onChange(of: settings) { _ in
            guard sourceImage != nil else { return }
            generatePreview()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("CELL ARTISAN")
                        .font(.caption.weight(.black))
                        .foregroundStyle(AppStyle.excelGreen)
                    Text("たまにいる\nエクセル職人")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundStyle(AppStyle.ink)
                        .lineSpacing(0)
                }
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppStyle.ink)
                    Image(systemName: "tablecells.fill")
                        .font(.system(size: 28, weight: .black))
                        .foregroundStyle(.white)
                }
                .frame(width: 58, height: 58)
            }

            Text("写真やイラストを、セル塗りつぶしだけの.xlsxに変換します。")
                .font(.subheadline)
                .foregroundStyle(AppStyle.muted)
                .lineSpacing(4)

            HStack(spacing: 8) {
                MetricPill(title: "\(document?.width ?? settings.width)列", icon: "arrow.left.and.right")
                MetricPill(title: "\(document?.height ?? 0)行", icon: "arrow.up.and.down")
                MetricPill(title: "\(document?.palette.count ?? settings.paletteSize)色", icon: "paintpalette")
            }
        }
        .padding(18)
        .background(AppStyle.panel, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppStyle.line))
    }

    private var imagePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("素材", icon: "photo")
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppStyle.ink)
                if let sourceImage {
                    Image(uiImage: sourceImage)
                        .resizable()
                        .scaledToFit()
                        .padding(10)
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 44, weight: .bold))
                        Text("画像を選択")
                            .font(.headline.weight(.black))
                        Text("写真、ロゴ、キャラ絵に対応")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.72))
                    }
                    .foregroundStyle(.white)
                }
            }
            .frame(height: 230)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(RoundedRectangle(cornerRadius: 8))
            .onTapGesture {
                isShowingPicker = true
            }
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(sourceImage == nil ? "画像を選ぶ" : "画像を変更")

            Text(message)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(message.contains("完了") ? AppStyle.excelGreen : AppStyle.muted)
        }
        .padding(16)
        .background(AppStyle.panel, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppStyle.line))
    }

    private var controlsPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle("職人設定", icon: "slider.horizontal.3")

            HStack(spacing: 8) {
                PresetButton(title: "軽め", icon: "bolt", isActive: settings.width == 96) {
                    applyPreset(width: 96, palette: 40, cell: 14)
                }
                PresetButton(title: "写真", icon: "camera.macro", isActive: settings.width == 160) {
                    applyPreset(width: 160, palette: 72, cell: 10)
                }
                PresetButton(title: "本気", icon: "sparkles", isActive: settings.width == 220) {
                    applyPreset(width: 220, palette: 96, cell: 8)
                }
            }

            SettingSlider(
                title: "横セル数",
                value: Binding(get: { Double(settings.width) }, set: { settings.width = Int($0) }),
                range: 24...240,
                step: 4,
                display: "\(settings.width)"
            )
            SettingSlider(
                title: "色数",
                value: Binding(get: { Double(settings.paletteSize) }, set: { settings.paletteSize = Int($0) }),
                range: 8...96,
                step: 2,
                display: "\(settings.paletteSize)"
            )
            SettingSlider(
                title: "セルサイズ",
                value: $settings.cellSize,
                range: 7...22,
                step: 1,
                display: "\(Int(settings.cellSize))"
            )

            VStack(alignment: .leading, spacing: 10) {
                Toggle(isOn: $settings.trimBackground) {
                    Label("余白カット", systemImage: "crop")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppStyle.ink)
                }
                .toggleStyle(SwitchToggleStyle(tint: AppStyle.excelGreen))

                Toggle(isOn: $settings.dither) {
                    Label("ディザ", systemImage: "circle.grid.cross")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(AppStyle.ink)
                }
                .toggleStyle(SwitchToggleStyle(tint: AppStyle.excelGreen))
            }
        }
        .padding(16)
        .background(AppStyle.panel, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppStyle.line))
    }

    private var previewPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("プレビュー", icon: "checkerboard.rectangle")
            if isProcessing {
                ProgressView("セルに変換中")
                    .frame(maxWidth: .infinity, minHeight: 180)
            } else if let document {
                CellArtPreview(document: document)
                    .frame(height: 280)
                paletteStrip(document.palette)
            } else {
                EmptyPreview()
                    .frame(height: 210)
            }
        }
        .padding(16)
        .background(AppStyle.panel, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppStyle.line))
    }

    private var exportPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle("Excel書き出し", icon: "square.and.arrow.up")
            if let exportedWorkbook {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title2)
                        .foregroundStyle(AppStyle.excelGreen)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(exportedWorkbook.url.lastPathComponent)
                            .font(.subheadline.weight(.black))
                            .lineLimit(1)
                        Text("\(exportedWorkbook.cellCount)セル / \(exportedWorkbook.paletteCount)色")
                            .font(.caption)
                            .foregroundStyle(AppStyle.muted)
                    }
                    Spacer()
                }
                .padding(12)
                .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppStyle.line))
            }

            HStack(spacing: 10) {
                Button {
                    exportWorkbook()
                } label: {
                    Label("XLSX作成", systemImage: "tablecells")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle(color: AppStyle.ink))
                .disabled(document == nil || isProcessing)
                .opacity(document == nil ? 0.48 : 1)

                Button {
                    isShowingShare = true
                } label: {
                    Label("共有", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(exportedWorkbook == nil)
                .opacity(exportedWorkbook == nil ? 0.48 : 1)
            }
        }
        .padding(16)
        .background(AppStyle.panel, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppStyle.line))
    }

    private func paletteStrip(_ palette: [CellColor]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(palette.enumerated()), id: \.offset) { _, color in
                    RoundedRectangle(cornerRadius: 5)
                        .fill(color.swiftUIColor)
                        .frame(width: 24, height: 24)
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(AppStyle.line))
                }
            }
        }
    }

    private func applyPreset(width: Int, palette: Int, cell: Double) {
        settings.width = width
        settings.paletteSize = palette
        settings.cellSize = cell
        settings.trimBackground = true
        settings.dither = true
    }

    private func generatePreview() {
        guard let sourceImage else { return }
        isProcessing = true
        exportedWorkbook = nil
        let activeSettings = settings

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let generated = try generator.generate(from: sourceImage, settings: activeSettings)
                DispatchQueue.main.async {
                    document = generated
                    isProcessing = false
                    message = "\(generated.estimatedCellCount)セルのアートを生成しました。"
                }
            } catch {
                DispatchQueue.main.async {
                    isProcessing = false
                    message = error.localizedDescription
                }
            }
        }
    }

    private func exportWorkbook() {
        guard let document else { return }
        isProcessing = true
        let activeSettings = settings

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let workbook = try writer.write(document: document, settings: activeSettings)
                DispatchQueue.main.async {
                    exportedWorkbook = workbook
                    isProcessing = false
                    message = "Excelファイルの作成が完了しました。"
                }
            } catch {
                DispatchQueue.main.async {
                    isProcessing = false
                    message = error.localizedDescription
                }
            }
        }
    }
}

struct CellArtPreview: View {
    let document: CellArtDocument

    var body: some View {
        GeometryReader { proxy in
            let cell = min(proxy.size.width / CGFloat(document.width), proxy.size.height / CGFloat(document.height))
            let width = CGFloat(document.width) * cell
            let height = CGFloat(document.height) * cell
            let origin = CGPoint(x: (proxy.size.width - width) / 2, y: (proxy.size.height - height) / 2)

            Canvas { context, _ in
                context.fill(Path(CGRect(origin: origin, size: CGSize(width: width, height: height))), with: .color(.white))
                for pixel in document.cells {
                    let rect = CGRect(
                        x: origin.x + CGFloat(pixel.column - 1) * cell,
                        y: origin.y + CGFloat(pixel.row - 1) * cell,
                        width: max(1, cell),
                        height: max(1, cell)
                    )
                    context.fill(Path(rect), with: .color(pixel.color.swiftUIColor))
                }
            }
            .overlay {
                Rectangle()
                    .stroke(AppStyle.line)
                    .frame(width: width, height: height)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }
        }
        .background(AppStyle.ink, in: RoundedRectangle(cornerRadius: 8))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct EmptyPreview: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "tablecells")
                .font(.system(size: 42, weight: .bold))
            Text("ここにセル絵が出ます")
                .font(.headline.weight(.black))
            Text("横セル数を上げるほど細かく、色数を上げるほど写真に近づきます。")
                .font(.subheadline)
                .foregroundStyle(AppStyle.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .foregroundStyle(AppStyle.ink)
        .padding()
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct SettingSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let display: String

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(AppStyle.ink)
                Spacer()
                Text(display)
                    .font(.subheadline.weight(.black))
                    .foregroundStyle(AppStyle.excelGreen)
            }
            Slider(value: $value, in: range, step: step)
        }
    }
}

struct PresetButton: View {
    let title: String
    let icon: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.black))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .foregroundStyle(isActive ? .white : AppStyle.ink)
                .background(isActive ? AppStyle.excelGreen : .white.opacity(0.82), in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppStyle.line))
        }
    }
}

struct SectionTitle: View {
    let title: String
    let icon: String

    init(_ title: String, icon: String) {
        self.title = title
        self.icon = icon
    }

    var body: some View {
        Label(title, systemImage: icon)
            .font(.headline.weight(.black))
            .foregroundStyle(AppStyle.ink)
    }
}

struct MetricPill: View {
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.bold))
            .foregroundStyle(AppStyle.ink)
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .background(.white.opacity(0.78), in: Capsule())
            .overlay(Capsule().stroke(AppStyle.line))
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .padding(.vertical, 13)
            .background(color.opacity(configuration.isPressed ? 0.72 : 1), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(AppStyle.ink)
            .padding(.vertical, 13)
            .background(.white.opacity(configuration.isPressed ? 0.58 : 0.86), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppStyle.line))
    }
}

enum AppStyle {
    static let ink = Color(red: 0.08, green: 0.12, blue: 0.10)
    static let muted = Color(red: 0.39, green: 0.43, blue: 0.40)
    static let excelGreen = Color(red: 0.05, green: 0.48, blue: 0.27)
    static let line = Color.black.opacity(0.12)
    static let panel = Color(red: 0.98, green: 0.985, blue: 0.94).opacity(0.95)
    static let background = LinearGradient(
        colors: [
            Color(red: 0.92, green: 0.97, blue: 0.91),
            Color(red: 0.98, green: 0.96, blue: 0.88),
            Color(red: 0.93, green: 0.96, blue: 0.98)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
