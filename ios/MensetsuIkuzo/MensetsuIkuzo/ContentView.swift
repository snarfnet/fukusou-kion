import PhotosUI
import SwiftUI
import UIKit

struct ContentView: View {
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var basePhoto: UIImage?
    @State private var layers: [MoriLayer] = []
    @State private var selectedLayerID: UUID?
    @State private var selectedCategory: MoriCategory = .hair
    @State private var genderFilter: GenderFilter = .all
    @State private var sharePayload: SharePayload?
    @State private var showSaveAlert = false

    private var selectedLayerIndex: Int? {
        layers.firstIndex { $0.id == selectedLayerID }
    }

    private var selectedLayer: MoriLayer? {
        guard let selectedLayerIndex else { return nil }
        return layers[selectedLayerIndex]
    }

    private var filteredAssets: [MoriAsset] {
        MoriLibrary.assets.filter {
            $0.category == selectedCategory && $0.audience.matches(genderFilter)
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.height < 730
            let stageWidth = min(proxy.size.width - 20, compact ? 430 : 620)
            let stageHeight = min(stageWidth * 4 / 3, proxy.size.height * (compact ? 0.62 : 0.66))

            ZStack {
                InterviewTheme.background.ignoresSafeArea()

                VStack(spacing: compact ? 6 : 10) {
                    header

                    StageView(
                        basePhoto: basePhoto,
                        layers: $layers,
                        selectedLayerID: $selectedLayerID
                    )
                    .frame(width: stageWidth, height: stageHeight)

                    if let selectedLayer {
                        LayerControls(
                            layer: selectedLayer,
                            onScale: { value in updateSelected { $0.widthRatio = value } },
                            onRotate: { value in updateSelected { $0.rotation.degrees = value } },
                            onOpacity: { value in updateSelected { $0.opacity = value } },
                            onBack: sendBack,
                            onFront: bringFront,
                            onFlip: { updateSelected { $0.isFlipped.toggle() } },
                            onDuplicate: duplicateSelected,
                            onDelete: deleteSelected
                        )
                    }

                    GenderPicker(selection: $genderFilter)
                    CategoryStrip(selection: $selectedCategory)
                    AssetGrid(assets: filteredAssets, compact: compact, onSelect: addAsset)
                }
                .padding(.horizontal, 10)
                .padding(.top, compact ? 6 : 10)
                .padding(.bottom, 8)
            }
        }
        .task(id: selectedPhotoItem) {
            await loadPhoto()
        }
        .sheet(item: $sharePayload) { payload in
            ActivityView(items: [payload.image])
        }
        .alert("保存しました", isPresented: $showSaveAlert) {
            Button("OK", role: .cancel) {}
        }
    }

    private var header: some View {
        VStack(spacing: 9) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("面接行くぞい")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(InterviewTheme.ink)
                    Text("証明写真っぽく、真面目度を盛る")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(InterviewTheme.muted)
                }

                Spacer()

                HStack(spacing: 8) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Image(systemName: "photo")
                    }
                    .buttonStyle(IconButtonStyle())

                    Button(action: autoInterview) {
                        Image(systemName: "wand.and.stars")
                    }
                    .buttonStyle(IconButtonStyle())

                    Button(action: share) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .buttonStyle(IconButtonStyle())

                    Button(action: saveToPhotoLibrary) {
                        Image(systemName: "square.and.arrow.down")
                    }
                    .buttonStyle(IconButtonStyle(filled: true))
                }
            }
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
        updateSelected { $0.zIndex = $0.isBackground ? 4 : 12 }
    }

    private func bringFront() {
        let maxZ = layers.map(\.zIndex).max() ?? 40
        updateSelected { $0.zIndex = maxZ + 1 }
    }

    private func duplicateSelected() {
        guard var layer = selectedLayer else { return }
        layer.id = UUID()
        layer.position.x += 0.04
        layer.position.y += 0.04
        layer.zIndex += 1
        layers.append(layer)
        selectedLayerID = layer.id
    }

    private func deleteSelected() {
        guard let selectedLayerID else { return }
        layers.removeAll { $0.id == selectedLayerID }
        self.selectedLayerID = layers.last?.id
    }

    private func autoInterview() {
        layers.removeAll()
        let preferredAudience: AssetAudience = genderFilter == .men ? .men : (genderFilter == .women ? .women : .all)
        for category in [MoriCategory.background, .hair, .businessTop, .glasses, .accessory] {
            let candidates = MoriLibrary.assets.filter {
                $0.category == category && ($0.audience == preferredAudience || $0.audience == .all || genderFilter == .all)
            }
            if let asset = candidates.randomElement() {
                addAsset(asset)
            }
        }
        selectedLayerID = layers.last?.id
    }

    private func renderImage() -> UIImage {
        MoriImageExporter.render(basePhoto: basePhoto, layers: layers)
    }

    private func share() {
        sharePayload = SharePayload(image: renderImage())
    }

    private func saveToPhotoLibrary() {
        UIImageWriteToSavedPhotosAlbum(renderImage(), nil, nil, nil)
        showSaveAlert = true
    }
}

private struct StageView: View {
    let basePhoto: UIImage?
    @Binding var layers: [MoriLayer]
    @Binding var selectedLayerID: UUID?

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                RoundedRectangle(cornerRadius: 8)
                    .stroke(InterviewTheme.line, lineWidth: 2)

                VStack(spacing: 12) {
                    if basePhoto == nil {
                        Image(systemName: "person.crop.rectangle")
                            .font(.system(size: 58, weight: .light))
                            .foregroundStyle(InterviewTheme.muted.opacity(0.65))
                        Text("写真を選んで開始")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(InterviewTheme.muted)
                    }
                }

                if let basePhoto {
                    Image(uiImage: basePhoto)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size.width, height: size.height)
                        .clipped()
                }

                ForEach(layers.sorted { $0.zIndex < $1.zIndex }) { layer in
                    LayerView(
                        layer: layer,
                        isSelected: layer.id == selectedLayerID,
                        stageSize: size,
                        onSelect: { selectedLayerID = layer.id },
                        onMove: { translation in
                            guard let index = layers.firstIndex(where: { $0.id == layer.id }) else { return }
                            layers[index].position.x += translation.width / max(1, size.width)
                            layers[index].position.y += translation.height / max(1, size.height)
                            layers[index].position.x = min(1.2, max(-0.2, layers[index].position.x))
                            layers[index].position.y = min(1.2, max(-0.2, layers[index].position.y))
                        }
                    )
                }

                VStack {
                    HStack {
                        Text("ID PHOTO")
                            .font(.caption2.weight(.black))
                            .foregroundStyle(InterviewTheme.muted)
                        Spacer()
                        Text("3:4")
                            .font(.caption2.weight(.black))
                            .foregroundStyle(InterviewTheme.muted)
                    }
                    Spacer()
                }
                .padding(10)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
            .onTapGesture {
                selectedLayerID = nil
            }
        }
        .aspectRatio(3 / 4, contentMode: .fit)
        .shadow(color: .black.opacity(0.12), radius: 20, y: 10)
    }
}

private struct LayerView: View {
    let layer: MoriLayer
    let isSelected: Bool
    let stageSize: CGSize
    let onSelect: () -> Void
    let onMove: (CGSize) -> Void

    @State private var lastTranslation: CGSize = .zero

    var body: some View {
        Group {
            if let image = BundleImage.load(layer.asset.filename, folder: "Overlays", cropSide: layer.cropSide) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(width: stageSize.width * layer.widthRatio)
        .opacity(layer.opacity)
        .scaleEffect(x: layer.isFlipped ? -1 : 1, y: 1)
        .rotationEffect(.degrees(layer.rotation.degrees))
        .position(x: stageSize.width * layer.position.x, y: stageSize.height * layer.position.y)
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(.blue.opacity(0.75), style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .gesture(
            DragGesture()
                .onChanged { value in
                    onSelect()
                    let delta = CGSize(
                        width: value.translation.width - lastTranslation.width,
                        height: value.translation.height - lastTranslation.height
                    )
                    lastTranslation = value.translation
                    onMove(delta)
                }
                .onEnded { _ in
                    lastTranslation = .zero
                }
        )
    }
}

private struct LayerControls: View {
    let layer: MoriLayer
    let onScale: (CGFloat) -> Void
    let onRotate: (Double) -> Void
    let onOpacity: (CGFloat) -> Void
    let onBack: () -> Void
    let onFront: () -> Void
    let onFlip: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(layer.asset.name)
                    .font(.caption.weight(.black))
                    .foregroundStyle(InterviewTheme.ink)
                    .lineLimit(1)
                Spacer()
                Text("\(Int(layer.opacity * 100))%")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(InterviewTheme.muted)
            }

            VStack(spacing: 8) {
                ControlSlider(
                    title: "大きさ",
                    valueText: "\(Int(layer.widthRatio * 100))%",
                    value: Binding(
                        get: { Double(layer.widthRatio) },
                        set: { onScale(CGFloat($0)) }
                    ),
                    range: 0.18...2.40
                )
                ControlSlider(
                    title: "角度",
                    valueText: "\(Int(layer.rotation.degrees))°",
                    value: Binding(get: { layer.rotation.degrees }, set: onRotate),
                    range: -45...45
                )
                ControlSlider(
                    title: "透明度",
                    valueText: "\(Int(layer.opacity * 100))%",
                    value: Binding(
                        get: { Double(layer.opacity) },
                        set: { onOpacity(CGFloat($0)) }
                    ),
                    range: 0.25...1
                )
            }

            HStack(spacing: 8) {
                ControlIcon(systemName: "square.2.layers.3d.bottom.filled", action: onBack)
                ControlIcon(systemName: "square.2.layers.3d.top.filled", action: onFront)
                ControlIcon(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right", action: onFlip)
                ControlIcon(systemName: "plus.square.on.square", action: onDuplicate)
                ControlIcon(systemName: "trash", destructive: true, action: onDelete)
            }
        }
        .padding(10)
        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(InterviewTheme.line))
    }
}

private struct GenderPicker: View {
    @Binding var selection: GenderFilter

    var body: some View {
        Picker("対象", selection: $selection) {
            ForEach(GenderFilter.allCases) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
    }
}

private struct CategoryStrip: View {
    @Binding var selection: MoriCategory

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MoriCategory.allCases) { category in
                    Button {
                        selection = category
                    } label: {
                        Text(category.rawValue)
                            .font(.caption.weight(.black))
                            .lineLimit(1)
                            .padding(.horizontal, 12)
                            .frame(height: 34)
                            .background(selection == category ? InterviewTheme.ink : .white, in: Capsule())
                            .foregroundStyle(selection == category ? .white : InterviewTheme.ink)
                            .overlay(Capsule().stroke(InterviewTheme.line))
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }
}

private struct ControlSlider: View {
    let title: String
    let valueText: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.caption2.weight(.black))
                .foregroundStyle(InterviewTheme.muted)
                .frame(width: 44, alignment: .leading)
            Slider(value: $value, in: range)
            Text(valueText)
                .font(.caption2.weight(.black))
                .monospacedDigit()
                .foregroundStyle(InterviewTheme.ink)
                .frame(width: 48, alignment: .trailing)
        }
    }
}

private struct AssetGrid: View {
    let assets: [MoriAsset]
    let compact: Bool
    let onSelect: (MoriAsset) -> Void

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: compact ? 4 : 5)
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(assets) { asset in
                    Button {
                        onSelect(asset)
                    } label: {
                        VStack(spacing: 4) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white)
                                if let image = BundleImage.load(asset.filename, folder: "Overlays") {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFit()
                                        .padding(5)
                                }
                            }
                            .frame(height: compact ? 66 : 74)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(InterviewTheme.line))

                            Text(asset.name)
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(InterviewTheme.ink)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .minimumScaleFactor(0.75)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 8)
        }
    }
}

private struct ControlIcon: View {
    let systemName: String
    var destructive = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .black))
                .frame(maxWidth: .infinity)
                .frame(height: 34)
        }
        .buttonStyle(.plain)
        .foregroundStyle(destructive ? Color.red : InterviewTheme.ink)
        .background(.white, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(InterviewTheme.line))
    }
}

private struct IconButtonStyle: ButtonStyle {
    var filled = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .black))
            .frame(width: 38, height: 38)
            .foregroundStyle(filled ? .white : InterviewTheme.ink)
            .background(filled ? InterviewTheme.ink : Color.white, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(InterviewTheme.line))
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
    }
}

private struct SharePayload: Identifiable {
    let id = UUID()
    let image: UIImage
}

private enum InterviewTheme {
    static let ink = Color(red: 0.13, green: 0.20, blue: 0.25)
    static let muted = Color(red: 0.43, green: 0.49, blue: 0.50)
    static let line = Color(red: 0.78, green: 0.82, blue: 0.80)

    static var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.96, green: 0.98, blue: 0.96),
                Color(red: 0.89, green: 0.94, blue: 0.97),
                Color(red: 0.98, green: 0.96, blue: 0.91)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
