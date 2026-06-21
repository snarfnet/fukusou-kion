import PhotosUI
import SwiftUI
import UIKit

struct ContentView: View {
    @State private var settings = GeneratorSettings()
    @State private var seed = Int.random(in: 10000...99999)
    @State private var design: StitchDesign
    @State private var exportFormat: ExportFormat = .svg
    @State private var exportFile: ExportFile?
    @State private var exportMessage = "Ready"
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var importedVector: VectorTemplate?
    @State private var previewZoom: CGFloat = 1.0
    @State private var previewPan: CGSize = .zero

    init() {
        let initialSeed = Int.random(in: 10000...99999)
        _seed = State(initialValue: initialSeed)
        _design = State(initialValue: FloraGenerator.make(seed: initialSeed, settings: GeneratorSettings()))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        header
                        DesignPreview(design: design, zoom: previewZoom, pan: $previewPan)
                            .frame(height: 270)
                        previewControls
                        stats
                        controls
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Flora Stitch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        randomize()
                    } label: {
                        Label("Random seed", systemImage: "dice")
                    }
                }
            }
            .onChange(of: selectedPhotoItem) { _, item in
                importPhoto(item)
            }
            .sheet(item: $exportFile) { item in
                SaveToFilesSheet(url: item.url) { didSave in
                    exportMessage = didSave
                        ? "Saved as \(item.fileName) in the Files location you selected."
                        : "Save cancelled"
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Random floral borders for embroidery")
                .font(.system(size: 31, weight: .semibold, design: .serif))
                .foregroundStyle(AppTheme.ink)
            Text("Create original vine, leaf, flower, berry, fruit, and curl patterns from a seed. Import an image, turn it into a simple SVG motif, and mix it into the garden.")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(AppTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stats: some View {
        HStack(spacing: 10) {
            StatPill(title: "Seed", value: "\(design.seed)", icon: "number")
            StatPill(title: "Stitches", value: "\(design.stitchPlan.stitchCount)", icon: "point.topleft.down.curvedto.point.bottomright.up")
            StatPill(title: "Colors", value: "\(design.stitchPlan.blocks.count)", icon: "paintpalette")
        }
    }

    private var previewControls: some View {
        HStack(spacing: 10) {
            Button {
                previewZoom = max(0.75, previewZoom - 0.25)
            } label: {
                Image(systemName: "minus.magnifyingglass")
                    .frame(width: 42, height: 34)
            }
            .buttonStyle(.bordered)

            Text("\(Int(previewZoom * 100))%")
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(AppTheme.muted)
                .frame(width: 58)

            Button {
                previewZoom = min(5.0, previewZoom + 0.25)
            } label: {
                Image(systemName: "plus.magnifyingglass")
                    .frame(width: 42, height: 34)
            }
            .buttonStyle(.bordered)

            Button {
                previewZoom = 1.0
                previewPan = .zero
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .frame(width: 42, height: 34)
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var controls: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                HStack {
                    Label("Seed", systemImage: "slider.horizontal.2.square")
                        .font(.headline)
                    Spacer()
                    TextField("Seed", value: $seed, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                }
                Button {
                    randomize()
                } label: {
                    Label("New random seed", systemImage: "dice")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.leaf)

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label(importedVector == nil ? "Import image motif" : "Replace image motif", systemImage: "photo.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                if importedVector != nil {
                    Label("Image motif is active", systemImage: "checkmark.circle")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.leaf)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                if importedVector != nil {
                    Button {
                        importedVector = nil
                        design = FloraGenerator.make(seed: seed, settings: settings, importedVector: nil)
                        exportMessage = "Image motif removed from seed \(seed)"
                    } label: {
                        Label("Remove image motif", systemImage: "xmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }

            SettingsPanel(settings: $settings) {
                regenerate()
            }

            VStack(spacing: 12) {
                Picker("Format", selection: $exportFormat) {
                    ForEach(ExportFormat.allCases) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)

                Button {
                    export()
                } label: {
                    Label("Save \(exportFormat.rawValue)", systemImage: "folder.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.rose)

                Text(exportMessage)
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.line, lineWidth: 1)
        )
    }

    private func randomize() {
        seed = Int.random(in: 10000...99999)
        regenerate()
    }

    private func regenerate() {
        design = FloraGenerator.make(seed: seed, settings: settings, importedVector: importedVector)
        exportMessage = "Generated seed \(seed)"
    }

    private func importPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let template = ImageVectorizer.template(from: data) {
                    await MainActor.run {
                        let newDesign = FloraGenerator.make(seed: seed, settings: settings, importedVector: template)
                        importedVector = template
                        design = newDesign
                        selectedPhotoItem = nil
                        let count = newDesign.elements.filter { element in
                            if case .importedVector = element { return true }
                            return false
                        }.count
                        exportMessage = "Image motif active: \(count) placements in seed \(seed)"
                    }
                } else {
                    await MainActor.run {
                        selectedPhotoItem = nil
                        exportMessage = "Image import could not find a clear shape"
                    }
                }
            } catch {
                await MainActor.run {
                    selectedPhotoItem = nil
                    exportMessage = "Image import failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func export() {
        do {
            let url = try DesignExporter.write(design: design, format: exportFormat)
            exportFile = ExportFile(url: url)
            exportMessage = exportFormat == .pes
                ? "Choose a Files folder for \(url.lastPathComponent). PES is experimental; use DST for machine tests."
                : "Choose a Files folder for \(url.lastPathComponent)"
        } catch {
            exportMessage = "Export failed: \(error.localizedDescription)"
        }
    }
}

private struct DesignPreview: View {
    let design: StitchDesign
    let zoom: CGFloat
    @Binding var pan: CGSize
    @GestureState private var dragOffset: CGSize = .zero

    var body: some View {
        GeometryReader { _ in
            Canvas { context, size in
                let scale = min((size.width - 28) / design.size.width, (size.height - 28) / design.size.height) * zoom
                let activePan = CGSize(width: pan.width + dragOffset.width, height: pan.height + dragOffset.height)
                let offset = CGSize(
                    width: (size.width - design.size.width * scale) / 2 + activePan.width,
                    height: (size.height - design.size.height * scale) / 2 + activePan.height
                )
                context.translateBy(x: offset.width, y: offset.height)
                context.scaleBy(x: scale, y: scale)

                let cloth = Path(CGRect(origin: .zero, size: design.size))
                context.fill(cloth, with: .color(.white))
                context.stroke(cloth, with: .color(AppTheme.line), lineWidth: 1 / scale)

                for element in design.elements {
                    draw(element, in: &context)
                }
            }
            .background(AppTheme.clothShadow, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation
                    }
                    .onEnded { value in
                        pan = CGSize(width: pan.width + value.translation.width, height: pan.height + value.translation.height)
                    }
            )
            .overlay(alignment: .bottomLeading) {
                Text("\(String(format: "%.1f", Double(design.size.width / 240))) x \(String(format: "%.1f", Double(design.size.height / 240))) in")
                    .font(.caption.weight(.medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.86), in: Capsule())
                    .padding(10)
            }
        }
    }

    private func draw(_ element: DesignElement, in context: inout GraphicsContext) {
        switch element {
        case .vine(let vine):
            context.stroke(polyline(vine.points), with: .color(vine.color.color), style: StrokeStyle(lineWidth: vine.width, lineCap: .round, lineJoin: .round))
        case .leaf(let leaf):
            let outline = StitchPlanner.leafOutline(leaf, steps: 34)
            var path = polyline(outline)
            path.closeSubpath()
            context.fill(path, with: .color(leaf.color.color.opacity(0.92)))
            context.stroke(path, with: .color(AppTheme.thread.opacity(0.55)), lineWidth: 0.8)
            context.stroke(polyline([StitchPlanner.leafTip(leaf, direction: -1), StitchPlanner.leafTip(leaf, direction: 1)]), with: .color(leaf.veinColor.color.opacity(0.85)), lineWidth: 0.8)
        case .flower(let flower):
            for outline in StitchPlanner.flowerPetalOutlines(flower) {
                var path = polyline(outline)
                path.closeSubpath()
                context.fill(path, with: .color(flower.fill.color.opacity(0.94)))
                context.stroke(path, with: .color(AppTheme.thread.opacity(0.35)), lineWidth: 0.7)
            }
            for line in StitchPlanner.flowerAccentLines(flower) {
                context.stroke(polyline(line), with: .color(flower.centerColor.color.opacity(0.8)), lineWidth: 0.8)
            }
            let centerRadius = StitchPlanner.flowerCenterRadius(flower)
            if centerRadius > 0 {
                context.fill(Path(ellipseIn: CGRect(x: flower.center.x - centerRadius, y: flower.center.y - centerRadius, width: centerRadius * 2, height: centerRadius * 2)), with: .color(flower.centerColor.color))
            }
        case .berry(let berry):
            for outline in StitchPlanner.berryOutlines(berry) {
                var path = polyline(outline)
                path.closeSubpath()
                context.fill(path, with: .color(berry.color.color.opacity(0.94)))
                context.stroke(path, with: .color(AppTheme.thread.opacity(0.45)), lineWidth: 0.8)
            }
            for line in StitchPlanner.berryAccentLines(berry) {
                context.stroke(polyline(line), with: .color(AppTheme.thread.opacity(0.55)), lineWidth: 0.8)
            }
        case .importedVector(let vector):
            for shape in StitchPlanner.importedVectorColoredShapes(vector) {
                var path = polyline(shape.outline)
                path.closeSubpath()
                context.fill(path, with: .color(Color(hex: shape.fillHex).opacity(0.94)))
            }
            for outline in StitchPlanner.importedVectorOutlines(vector) {
                var path = polyline(outline)
                path.closeSubpath()
                if vector.coloredShapes.isEmpty {
                    context.fill(path, with: .color(vector.color.color.opacity(0.94)))
                }
                context.stroke(path, with: .color(AppTheme.thread.opacity(0.68)), lineWidth: 1.2)
            }
        case .bird(let bird):
            for outline in StitchPlanner.birdBodyOutlines(bird) {
                var path = polyline(outline)
                path.closeSubpath()
                context.fill(path, with: .color(bird.bodyColor.color.opacity(0.94)))
                context.stroke(path, with: .color(AppTheme.thread.opacity(0.45)), lineWidth: 0.75)
            }
            for outline in StitchPlanner.birdWingOutlines(bird) {
                var path = polyline(outline)
                path.closeSubpath()
                context.fill(path, with: .color(bird.wingColor.color.opacity(0.9)))
                context.stroke(path, with: .color(AppTheme.thread.opacity(0.35)), lineWidth: 0.65)
            }
            for line in StitchPlanner.birdAccentLines(bird) {
                context.stroke(polyline(line), with: .color(bird.accentColor.color.opacity(0.95)), style: StrokeStyle(lineWidth: 1.45, lineCap: .round, lineJoin: .round))
            }
        case .curl(let curl):
            context.stroke(polyline(StitchPlanner.curlPoints(curl)), with: .color(curl.color.color), style: StrokeStyle(lineWidth: 1.25, lineCap: .round, lineJoin: .round, dash: [1.8, 2.8]))
        }
    }

    private func polyline(_ points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        return path
    }
}

private struct SettingsPanel: View {
    @Binding var settings: GeneratorSettings
    let onChange: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            control(title: "Width", value: "\(String(format: "%.1f", settings.widthInches)) in", icon: "arrow.left.and.right") {
                Slider(value: binding(\.widthInches), in: 3.0...5.5, step: 0.1)
            }
            control(title: "Density", value: "\(Int(settings.density * 100))%", icon: "circle.grid.3x3") {
                Slider(value: binding(\.density), in: 0.35...1.0, step: 0.01)
            }
            control(title: "Flowers", value: "\(Int(settings.flowerMix * 100))%", icon: "camera.macro") {
                Slider(value: binding(\.flowerMix), in: 0.15...1.0, step: 0.01)
            }
            Toggle(isOn: Binding(get: { settings.curls }, set: { settings.curls = $0; onChange() })) {
                Label("Curl stitches", systemImage: "scribble.variable")
            }
            Toggle(isOn: Binding(get: { settings.birds }, set: { settings.birds = $0; onChange() })) {
                Label("Birds", systemImage: "bird")
            }
            Picker("Palette", selection: Binding(get: { settings.paletteIndex }, set: { settings.paletteIndex = $0; onChange() })) {
                Text("Garden").tag(0)
                Text("Market").tag(1)
                Text("Meadow").tag(2)
            }
            .pickerStyle(.segmented)
        }
    }

    private func binding(_ keyPath: WritableKeyPath<GeneratorSettings, Double>) -> Binding<Double> {
        Binding(
            get: { settings[keyPath: keyPath] },
            set: { settings[keyPath: keyPath] = $0; onChange() }
        )
    }

    private func control<Content: View>(title: String, value: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(title, systemImage: icon)
                Spacer()
                Text(value)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(AppTheme.muted)
            }
            .font(.subheadline.weight(.medium))
            content()
        }
    }
}

private struct StatPill: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(title, systemImage: icon)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(AppTheme.muted)
                .lineLimit(1)
            Text(value)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(AppTheme.line, lineWidth: 1))
    }
}

private struct SaveToFilesSheet: UIViewControllerRepresentable {
    let url: URL
    let onComplete: (Bool) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onComplete: onComplete)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forExporting: [url], asCopy: true)
        picker.delegate = context.coordinator
        picker.shouldShowFileExtensions = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onComplete: (Bool) -> Void

        init(onComplete: @escaping (Bool) -> Void) {
            self.onComplete = onComplete
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            DispatchQueue.main.async {
                self.onComplete(!urls.isEmpty)
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            DispatchQueue.main.async {
                self.onComplete(false)
            }
        }
    }
}

private enum AppTheme {
    static let background = Color(hex: "#F7F4EF")
    static let ink = Color(hex: "#27241E")
    static let muted = Color(hex: "#766F63")
    static let line = Color(hex: "#DDD5C7")
    static let leaf = Color(hex: "#62733A")
    static let rose = Color(hex: "#B95773")
    static let thread = Color(hex: "#3A3328")
    static let clothShadow = Color(hex: "#E9E1D4")
}
