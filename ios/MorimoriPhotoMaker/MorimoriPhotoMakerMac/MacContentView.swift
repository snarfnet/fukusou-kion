import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct MacContentView: View {
    @State private var selectedCategory: MoriCategory = .hair
    @State private var basePhoto: NSImage?
    @State private var layers: [MoriLayer] = []
    @State private var selectedLayerID: UUID?
    @State private var dragStart: CGPoint?
    @State private var purchasedPacks: Set<MoriPack> = []
    @State private var hasAllAccessSubscription = false

    private var selectedLayerIndex: Int? {
        layers.firstIndex { $0.id == selectedLayerID }
    }

    private var selectedLayer: MoriLayer? {
        guard let selectedLayerIndex else { return nil }
        return layers[selectedLayerIndex]
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 340)

            VStack(spacing: 12) {
                toolbar
                MacStageView(
                    basePhoto: basePhoto,
                    layers: layers,
                    selectedLayerID: selectedLayerID,
                    onSelect: { selectedLayerID = $0 },
                    onDrag: moveLayer
                )
                .aspectRatio(3 / 4, contentMode: .fit)
                .padding(.horizontal, 24)
                controls
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 1.0, green: 0.93, blue: 0.97))
        }
        .frame(minWidth: 1100, minHeight: 760)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("盛り盛りフォトメーカー")
                .font(.title2.weight(.black))
            Text("iOS版と同じ素材データ")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            Picker("カテゴリー", selection: $selectedCategory) {
                ForEach(MoriCategory.allCases) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .pickerStyle(.menu)

            ScrollView {
                MacAssetGrid(
                    assets: MoriLibrary.assets.filter { $0.category == selectedCategory },
                    isUnlocked: isAssetUnlocked,
                    onSelect: addAsset
                )
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.82))
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            Button {
                openPhoto()
            } label: {
                Label("写真を選ぶ", systemImage: "photo")
            }

            Button {
                autoMori()
            } label: {
                Label("おまかせ盛り", systemImage: "sparkles")
            }

            Button {
                exportImage()
            } label: {
                Label("PNG保存", systemImage: "square.and.arrow.down")
            }

            Spacer()

            Text(hasAllAccessSubscription ? "サブスク: 全解放" : "ロック中")
                .font(.caption.weight(.black))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.white.opacity(0.85), in: Capsule())
        }
        .buttonStyle(.borderedProminent)
        .padding(.horizontal, 24)
        .padding(.top, 18)
    }

    private var controls: some View {
        VStack(spacing: 8) {
            HStack {
                Text(selectedLayer?.asset.name ?? "未選択")
                    .font(.headline.weight(.black))
                Spacer()
                Button("複製", action: duplicateSelected)
                Button("反転") { updateSelected { $0.isFlipped.toggle() } }
                Button("削除", role: .destructive, action: deleteSelected)
            }

            if let selectedLayer {
                SliderRow(title: "大きさ", displayValue: "\(Int(selectedLayer.widthRatio * 100))%", value: Double(selectedLayer.widthRatio), range: 0.08...6.0) { newValue in
                    updateSelected { layer in layer.widthRatio = CGFloat(newValue) }
                }
                SliderRow(title: "回転", displayValue: "\(Int(selectedLayer.rotation.degrees))°", value: selectedLayer.rotation.degrees, range: -180...180) { newValue in
                    updateSelected { layer in layer.rotation.degrees = newValue }
                }
                SliderRow(title: "透明度", displayValue: "\(Int(selectedLayer.opacity * 100))%", value: Double(selectedLayer.opacity), range: 0.2...1.0) { newValue in
                    updateSelected { layer in layer.opacity = CGFloat(newValue) }
                }
            }
        }
        .padding(16)
        .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 24)
        .padding(.bottom, 18)
    }

    private func openPhoto() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        basePhoto = NSImage(contentsOf: url)
    }

    private func exportImage() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "morimori-photo.png"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let image = MacImageExporter.render(basePhoto: basePhoto, layers: layers)
        guard let data = MacImageExporter.pngData(from: image) else { return }
        try? data.write(to: url)
    }

    private func addAsset(_ asset: MoriAsset) {
        guard isAssetUnlocked(asset) else { return }
        let maxZ = layers.map(\.zIndex).max() ?? asset.defaultZ
        if asset.shouldSplitOnAdd {
            let pairZ = max(maxZ + 1, asset.defaultZ)
            let left = MoriLayer(
                asset: asset,
                position: CGPoint(x: max(-0.2, asset.defaultPosition.x - asset.splitOffsetX), y: asset.defaultPosition.y),
                widthRatio: asset.defaultWidth,
                zIndex: pairZ,
                cropSide: .left
            )
            let right = MoriLayer(
                asset: asset,
                position: CGPoint(x: min(1.2, asset.defaultPosition.x + asset.splitOffsetX), y: asset.defaultPosition.y),
                widthRatio: asset.defaultWidth,
                zIndex: pairZ + 0.01,
                cropSide: .right
            )
            layers.append(contentsOf: [left, right])
            selectedLayerID = right.id
            return
        }

        let layer = MoriLayer(
            asset: asset,
            position: asset.defaultPosition,
            widthRatio: asset.defaultWidth,
            zIndex: asset.isBackground ? asset.defaultZ : max(maxZ + 1, asset.defaultZ)
        )
        layers.append(layer)
        selectedLayerID = layer.id
    }

    private func autoMori() {
        let accessibleAssets = MoriLibrary.assets.filter(isAssetUnlocked)
        let categories: [MoriCategory] = [.animatedBackground, .hair, .brows, .shadow, .blush, .lipstick, .glasses, .earrings, .background]
        for category in categories {
            if let asset = accessibleAssets.filter({ $0.category == category }).randomElement() {
                addAsset(asset)
            }
        }
    }

    private func moveLayer(id: UUID, translation: CGSize, stageSize: CGSize, ended: Bool) {
        guard let index = layers.firstIndex(where: { $0.id == id }) else { return }
        if dragStart == nil {
            dragStart = layers[index].position
        }
        guard let dragStart else { return }
        layers[index].position = CGPoint(
            x: dragStart.x + translation.width / max(1, stageSize.width),
            y: dragStart.y + translation.height / max(1, stageSize.height)
        )
        if ended {
            self.dragStart = nil
        }
    }

    private func updateSelected(_ update: (inout MoriLayer) -> Void) {
        guard let selectedLayerIndex else { return }
        update(&layers[selectedLayerIndex])
    }

    private func duplicateSelected() {
        guard let selectedLayer else { return }
        var copy = selectedLayer
        copy.id = UUID()
        copy.position.x += 0.04
        copy.position.y += 0.04
        copy.zIndex = (layers.map(\.zIndex).max() ?? selectedLayer.zIndex) + 1
        layers.append(copy)
        selectedLayerID = copy.id
    }

    private func deleteSelected() {
        guard let selectedLayerID else { return }
        layers.removeAll { $0.id == selectedLayerID }
        self.selectedLayerID = layers.last?.id
    }

    private func isAssetUnlocked(_ asset: MoriAsset) -> Bool {
        MorimoriBuildConfig.unlockPaidPacksForTestFlight
            || asset.pack == .free
            || hasAllAccessSubscription
            || purchasedPacks.contains(asset.pack)
    }
}

private struct MacStageView: View {
    let basePhoto: NSImage?
    let layers: [MoriLayer]
    let selectedLayerID: UUID?
    let onSelect: (UUID?) -> Void
    let onDrag: (UUID, CGSize, CGSize, Bool) -> Void

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                Checkerboard()
                if let basePhoto {
                    Image(nsImage: basePhoto)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size.width, height: size.height)
                        .clipped()
                        .zIndex(5)
                }

                ForEach(layers.sorted { $0.zIndex < $1.zIndex }) { layer in
                    MacLayerView(layer: layer, isSelected: layer.id == selectedLayerID, stageSize: size)
                        .zIndex(layer.zIndex)
                        .onTapGesture { onSelect(layer.id) }
                        .gesture(
                            DragGesture()
                                .onChanged { value in onDrag(layer.id, value.translation, size, false) }
                                .onEnded { value in onDrag(layer.id, value.translation, size, true) }
                        )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white, lineWidth: 3))
            .shadow(color: .black.opacity(0.18), radius: 18, y: 8)
            .onTapGesture { onSelect(nil) }
        }
    }
}

private struct MacLayerView: View {
    let layer: MoriLayer
    let isSelected: Bool
    let stageSize: CGSize

    var body: some View {
        Group {
            if let image = MacBundleImage.load(layer.asset.filename, folder: "Overlays", cropSide: layer.cropSide) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: displaySize(imageSize: image.size).width, height: displaySize(imageSize: image.size).height)
            }
        }
        .opacity(layer.opacity)
        .rotationEffect(.degrees(layer.rotation.degrees))
        .scaleEffect(x: layer.isFlipped ? -1 : 1, y: 1)
        .position(x: stageSize.width * layer.position.x, y: stageSize.height * layer.position.y)
        .overlay {
            if isSelected && !layer.isBackground {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white, style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                    .shadow(color: .cyan, radius: 4)
            }
        }
    }

    private func displaySize(imageSize: CGSize) -> CGSize {
        if layer.isBackground {
            return stageSize
        }
        let baseWidth = stageSize.width * layer.widthRatio
        let width = layer.cropSide == nil ? baseWidth : baseWidth * 0.52
        let ratio = imageSize.height / max(1, imageSize.width)
        return CGSize(width: width, height: width * ratio)
    }
}

private struct MacAssetGrid: View {
    let assets: [MoriAsset]
    let isUnlocked: (MoriAsset) -> Bool
    let onSelect: (MoriAsset) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 88), spacing: 8)], spacing: 8) {
            ForEach(assets) { asset in
                let unlocked = isUnlocked(asset)
                Button {
                    guard unlocked else { return }
                    onSelect(asset)
                } label: {
                    VStack(spacing: 5) {
                        if let image = MacBundleImage.load(asset.filename, folder: "Overlays") {
                            Image(nsImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 54)
                        }
                        Text(asset.name)
                            .font(.caption2.weight(.black))
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                        if asset.pack != .free {
                            Text(unlocked ? asset.pack.title : "LOCK")
                                .font(.system(size: 9, weight: .black, design: .rounded))
                                .lineLimit(1)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(red: 0.86, green: 0.18, blue: 0.52), in: Capsule())
                        }
                    }
                    .frame(width: 88, height: 110)
                    .padding(6)
                    .opacity(unlocked ? 1 : 0.55)
                    .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(unlocked ? Color(red: 0.96, green: 0.72, blue: 0.84) : .gray.opacity(0.45), lineWidth: 1))
                }
                .disabled(!unlocked)
                .buttonStyle(.plain)
            }
        }
    }
}

private struct SliderRow: View {
    let title: String
    let displayValue: String
    let value: Double
    let range: ClosedRange<Double>
    let onChange: (Double) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(title)
                Spacer()
                Text(displayValue)
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.white.opacity(0.9), in: Capsule())
            }
            Slider(value: Binding(get: { value }, set: onChange), in: range)
        }
    }
}

private struct Checkerboard: View {
    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(red: 1, green: 0.92, blue: 0.97)))
            let tile: CGFloat = 22
            for row in 0...Int(size.height / tile) {
                for col in 0...Int(size.width / tile) where (row + col).isMultiple(of: 2) {
                    let rect = CGRect(x: CGFloat(col) * tile, y: CGFloat(row) * tile, width: tile, height: tile)
                    context.fill(Path(rect), with: .color(.white.opacity(0.55)))
                }
            }
        }
    }
}

private extension MoriAsset {
    var shouldSplitOnAdd: Bool {
        switch category {
        case .earrings, .blush, .brows, .shadow, .lashes:
            true
        default:
            false
        }
    }

    var splitOffsetX: CGFloat {
        switch category {
        case .earrings: 0.20
        case .blush: 0.15
        case .brows, .shadow, .lashes: 0.11
        default: 0
        }
    }
}
