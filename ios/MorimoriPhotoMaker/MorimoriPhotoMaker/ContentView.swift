import PhotosUI
import SwiftUI
import UIKit

enum MorimoriBuildConfig {
    static let unlockPaidPacksForTestFlight = true
}

struct ContentView: View {
    @State private var selectedCategory: MoriCategory = .hair
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var basePhoto: UIImage?
    @State private var layers: [MoriLayer] = []
    @State private var selectedLayerID: UUID?
    @State private var dragStart: CGPoint?
    @State private var sharePayload: SharePayload?

    private var selectedLayerIndex: Int? {
        layers.firstIndex { $0.id == selectedLayerID }
    }

    private var selectedLayer: MoriLayer? {
        guard let selectedLayerIndex else { return nil }
        return layers[selectedLayerIndex]
    }

    var body: some View {
        GeometryReader { proxy in
            let isCompact = proxy.size.height < 720
            let pagePadding: CGFloat = isCompact ? 8 : 12
            let stageWidth = proxy.size.width - pagePadding * 2
            let compactStageHeight = min(stageWidth * 4 / 3, proxy.size.height * 0.52)
            let compactAssetHeight = max(72, proxy.size.height - compactStageHeight - 246)

            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.98, blue: 0.99),
                        Color(red: 1.0, green: 0.90, blue: 0.96)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: isCompact ? 6 : 10) {
                    HeaderView(
                        compact: isCompact,
                        onAutoMori: autoMori,
                        onShare: share,
                        photoPicker: photoPicker
                    )

                    StageView(
                        basePhoto: basePhoto,
                        layers: $layers,
                        selectedLayerID: $selectedLayerID,
                        dragStart: $dragStart,
                        photoPicker: photoPicker
                    )
                    .frame(height: isCompact ? compactStageHeight : nil)
                    .frame(maxHeight: isCompact ? nil : .infinity)
                    .layoutPriority(1)

                    if isCompact {
                        ControlPanel(
                            compact: true,
                            layer: selectedLayer,
                            onScale: { value in updateSelected { layer in layer.widthRatio = value } },
                            onRotate: { value in updateSelected { layer in layer.rotation.degrees = value } },
                            onOpacity: { value in updateSelected { layer in layer.opacity = value } },
                            onBack: sendBack,
                            onFront: bringFront,
                            onFlip: { updateSelected { $0.isFlipped.toggle() } },
                            onDuplicate: duplicateSelected,
                            onDelete: deleteSelected
                        )

                        ScrollView(.vertical, showsIndicators: true) {
                            VStack(spacing: 6) {
                                CategoryStrip(selectedCategory: $selectedCategory)
                                AssetGrid(
                                    compact: true,
                                    assets: MoriLibrary.assets.filter { $0.category == selectedCategory },
                                    onSelect: addAsset
                                )
                            }
                            .padding(.bottom, 8)
                        }
                        .frame(height: compactAssetHeight)
                    } else {
                        ControlPanel(
                            compact: false,
                            layer: selectedLayer,
                            onScale: { value in updateSelected { layer in layer.widthRatio = value } },
                            onRotate: { value in updateSelected { layer in layer.rotation.degrees = value } },
                            onOpacity: { value in updateSelected { layer in layer.opacity = value } },
                            onBack: sendBack,
                            onFront: bringFront,
                            onFlip: { updateSelected { $0.isFlipped.toggle() } },
                            onDuplicate: duplicateSelected,
                            onDelete: deleteSelected
                        )

                        CategoryStrip(selectedCategory: $selectedCategory)
                        AssetGrid(
                            compact: false,
                            assets: MoriLibrary.assets.filter { $0.category == selectedCategory },
                            onSelect: addAsset
                        )
                    }
                }
                .padding(pagePadding)
            }
        }
        .task(id: selectedPhotoItem) {
            await loadPhoto()
        }
        .sheet(item: $sharePayload) { payload in
            ActivityView(items: [payload.image])
        }
    }

    private var photoPicker: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            Label("写真", systemImage: "photo")
        }
    }

    private func loadPhoto() async {
        guard let selectedPhotoItem else { return }
        do {
            if let data = try await selectedPhotoItem.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    basePhoto = image
                }
            }
        } catch {
            print("Photo load failed: \(error)")
        }
    }

    private func addAsset(_ asset: MoriAsset) {
        guard MorimoriBuildConfig.unlockPaidPacksForTestFlight || asset.pack == .free else { return }
        let maxZ = layers.map(\.zIndex).max() ?? asset.defaultZ
        let layer = MoriLayer(
            asset: asset,
            position: asset.defaultPosition,
            widthRatio: asset.defaultWidth,
            zIndex: asset.isBackground ? asset.defaultZ : max(maxZ + 1, asset.defaultZ)
        )
        layers.append(layer)
        selectedLayerID = layer.id
    }

    private func updateSelected(_ update: (inout MoriLayer) -> Void) {
        guard let selectedLayerIndex else { return }
        update(&layers[selectedLayerIndex])
    }

    private func sendBack() {
        updateSelected { $0.zIndex = 10 }
    }

    private func bringFront() {
        let maxZ = layers.map(\.zIndex).max() ?? 40
        updateSelected { $0.zIndex = maxZ + 1 }
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

    private func autoMori() {
        ["kirakira-max-bg", "hair-glam", "brows-arch", "eyes-cat-glitter", "blush-candy-sparkle", "lips-gloss", "glasses-heart-rhinestone", "earrings-heart-chandelier", "halo-sparkle"]
            .compactMap { id in MoriLibrary.assets.first { $0.id == id } }
            .forEach(addAsset)
    }

    private func share() {
        sharePayload = SharePayload(image: MoriImageExporter.render(basePhoto: basePhoto, layers: layers))
    }
}

private struct SharePayload: Identifiable {
    let id = UUID()
    let image: UIImage
}

private struct HeaderView<PhotoPicker: View>: View {
    let compact: Bool
    let onAutoMori: () -> Void
    let onShare: () -> Void
    let photoPicker: PhotoPicker

    var body: some View {
        VStack(spacing: compact ? 6 : 10) {
            VStack(spacing: 2) {
                Text("MORIMORI PHOTO")
                    .font((compact ? Font.caption2 : Font.caption).weight(.black))
                    .foregroundStyle(Color(red: 0.58, green: 0.14, blue: 0.38))
                Text("盛り盛りフォトメーカー")
                    .font(.system(size: compact ? 22 : 34, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 0.84, green: 0.16, blue: 0.50))
                    .shadow(color: .white, radius: 0, x: 0, y: 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, compact ? 8 : 18)
            .background(.white.opacity(0.62), in: RoundedRectangle(cornerRadius: compact ? 14 : 22))
            .overlay(RoundedRectangle(cornerRadius: compact ? 14 : 22).stroke(.white.opacity(0.9), lineWidth: 1))

            HStack(spacing: 8) {
                photoPicker
                Button("おまかせ盛り", action: onAutoMori)
                Button("共有", action: onShare)
            }
            .buttonStyle(CandyButtonStyle(compact: compact))
        }
    }
}

private struct StageView<PhotoPicker: View>: View {
    let basePhoto: UIImage?
    @Binding var layers: [MoriLayer]
    @Binding var selectedLayerID: UUID?
    @Binding var dragStart: CGPoint?
    let photoPicker: PhotoPicker

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                Checkerboard()
                if let basePhoto {
                    Image(uiImage: basePhoto)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size.width, height: size.height)
                        .clipped()
                        .zIndex(5)
                } else if layers.isEmpty {
                    VStack(spacing: 12) {
                        Text("写真を入れて、盛る")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                        photoPicker
                            .buttonStyle(MainPhotoButtonStyle())
                        Text("髪・まゆげ・メイク・唇・キラキラ背景を重ねられます。")
                            .font(.footnote.weight(.bold))
                    }
                    .padding(24)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color(red: 0.31, green: 0.15, blue: 0.22))
                    .zIndex(90)
                }

                ForEach(layers.sorted { $0.zIndex < $1.zIndex }) { layer in
                    LayerView(layer: layer, stageSize: size, isSelected: layer.id == selectedLayerID)
                        .zIndex(layer.zIndex)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    guard let index = layers.firstIndex(where: { $0.id == layer.id }) else { return }
                                    if selectedLayerID != layer.id {
                                        selectedLayerID = layer.id
                                        dragStart = layers[index].position
                                    }
                                    if dragStart == nil {
                                        dragStart = layers[index].position
                                    }
                                    let start = dragStart ?? layers[index].position
                                    layers[index].position = CGPoint(
                                        x: min(1.2, max(-0.2, start.x + value.translation.width / max(1, size.width))),
                                        y: min(1.2, max(-0.2, start.y + value.translation.height / max(1, size.height)))
                                    )
                                }
                                .onEnded { _ in dragStart = nil }
                        )
                        .onTapGesture {
                            selectedLayerID = layer.id
                        }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.9), lineWidth: 8))
            .shadow(color: Color(red: 0.55, green: 0.18, blue: 0.36).opacity(0.18), radius: 18, y: 8)
        }
        .aspectRatio(3 / 4, contentMode: .fit)
    }
}

private struct LayerView: View {
    let layer: MoriLayer
    let stageSize: CGSize
    let isSelected: Bool

    var body: some View {
        if let image = BundleImage.load(layer.asset.filename, folder: "Overlays") {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: layer.isBackground ? stageSize.width : stageSize.width * layer.widthRatio)
                .frame(width: layer.isBackground ? stageSize.width : nil, height: layer.isBackground ? stageSize.height : nil)
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
    }
}

private struct ControlPanel: View {
    let compact: Bool
    let layer: MoriLayer?
    let onScale: (CGFloat) -> Void
    let onRotate: (Double) -> Void
    let onOpacity: (CGFloat) -> Void
    let onBack: () -> Void
    let onFront: () -> Void
    let onFlip: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: compact ? 4 : 8) {
            HStack {
                Text(layer?.asset.name ?? "未選択")
                    .font((compact ? Font.subheadline : Font.headline).weight(.black))
                Spacer()
            }

            if let layer {
                SliderRow(title: "大きさ", displayValue: "\(Int(layer.widthRatio * 100))%", value: Double(layer.widthRatio), range: 0.08...2.6) { onScale(CGFloat($0)) }
                SliderRow(title: "回転", displayValue: "\(Int(layer.rotation.degrees))%", value: layer.rotation.degrees, range: -180...180, onChange: onRotate)
                SliderRow(title: "透明度", displayValue: "\(Int(layer.opacity * 100))%", value: Double(layer.opacity), range: 0.2...1.0) { onOpacity(CGFloat($0)) }
            }

            HStack {
                Button("背面", action: onBack)
                Button("前面", action: onFront)
                Button("反転", action: onFlip)
            }
            HStack {
                Button("複製", action: onDuplicate)
                Button("削除", action: onDelete)
            }
            .disabled(layer == nil)
        }
        .padding(compact ? 8 : 12)
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 18))
        .buttonStyle(CandyButtonStyle(compact: compact))
    }
}

private struct SliderRow: View {
    let title: String
    let displayValue: String
    let value: Double
    let range: ClosedRange<Double>
    let onChange: (Double) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title)
                Spacer()
                Text(displayValue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.white.opacity(0.9), in: Capsule())
            }
            .font(.caption.weight(.bold))
            Slider(value: Binding(get: { value }, set: onChange), in: range)
                .tint(Color(red: 0.88, green: 0.18, blue: 0.52))
        }
    }
}

private struct CategoryStrip: View {
    @Binding var selectedCategory: MoriCategory

    var body: some View {
        let columns = [
            GridItem(.adaptive(minimum: 72), spacing: 6)
        ]

        LazyVGrid(columns: columns, alignment: .leading, spacing: 6) {
            ForEach(MoriCategory.allCases) { category in
                Button {
                    selectedCategory = category
                } label: {
                    Text(category.rawValue)
                        .font(.caption.weight(.black))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .foregroundStyle(selectedCategory == category ? .white : Color(red: 0.33, green: 0.18, blue: 0.25))
                        .background(selectedCategory == category ? Color(red: 0.86, green: 0.18, blue: 0.52) : .white.opacity(0.74), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 2)
    }
}

private struct AssetGrid: View {
    let compact: Bool
    let assets: [MoriAsset]
    let onSelect: (MoriAsset) -> Void

    var body: some View {
        let columns = [
            GridItem(.adaptive(minimum: compact ? 70 : 78), spacing: 8)
        ]

        LazyVGrid(columns: columns, spacing: 8) {
                ForEach(assets) { asset in
                    Button {
                        onSelect(asset)
                    } label: {
                        VStack(spacing: 4) {
                            if let image = BundleImage.load(asset.filename, folder: "Overlays") {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: compact ? 42 : 54)
                            }
                            Text(asset.name)
                                .font(.caption2.weight(.black))
                                .lineLimit(2)
                                .minimumScaleFactor(0.7)
                            if asset.pack != .free {
                                Text(asset.pack.title)
                                    .font(.system(size: 9, weight: .black, design: .rounded))
                                    .lineLimit(1)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .foregroundStyle(.white)
                                    .background(Color(red: 0.86, green: 0.18, blue: 0.52), in: Capsule())
                            }
                        }
                        .frame(width: compact ? 70 : 78, height: compact ? 78 : 92)
                        .padding(4)
                        .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(red: 0.96, green: 0.72, blue: 0.84), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
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

private struct CandyButtonStyle: ButtonStyle {
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.black))
            .foregroundStyle(Color(red: 0.28, green: 0.13, blue: 0.21))
            .padding(.horizontal, compact ? 8 : 12)
            .frame(minHeight: compact ? 32 : 38)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(colors: [.white.opacity(0.95), Color(red: 1.0, green: 0.77, blue: 0.88).opacity(0.92)], startPoint: .top, endPoint: .bottom),
                in: Capsule()
            )
            .overlay(Capsule().stroke(.white.opacity(0.9), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}

private struct MainPhotoButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2.weight(.black))
            .foregroundStyle(.white)
            .padding(.horizontal, 38)
            .padding(.vertical, 18)
            .background(
                LinearGradient(colors: [Color(red: 0.97, green: 0.46, blue: 0.72), Color(red: 0.95, green: 0.66, blue: 0.84)], startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: 24)
            )
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.85), lineWidth: 2))
            .shadow(color: Color(red: 0.72, green: 0.22, blue: 0.46).opacity(0.24), radius: 12, y: 6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
    }
}
