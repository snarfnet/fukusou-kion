import PhotosUI
import StoreKit
import SwiftUI
import UIKit

struct ContentView: View {
    @State private var selectedCategory: MoriCategory = .hair
    @State private var activeAdjustment: AdjustmentTool?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var basePhoto: UIImage?
    @State private var layers: [MoriLayer] = []
    @State private var selectedLayerID: UUID?
    @State private var dragStart: CGPoint?
    @State private var sharePayload: SharePayload?
    @State private var showSaveAlert = false
    @State private var purchasePromptPack: MoriPack?
    @State private var showStore = false
    @StateObject private var purchaseStore = PurchaseStore()

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
            let isIPad = proxy.size.width > 700
            let pagePadding: CGFloat = isCompact ? 8 : (isIPad ? 24 : 12)
            let railColumnWidth: CGFloat = isCompact ? 48 : (isIPad ? 64 : 54)
            let railGap: CGFloat = isCompact ? 4 : (isIPad ? 16 : 8)
            let stageWidth = proxy.size.width - pagePadding * 2 - railColumnWidth - railGap
            let compactStageHeight = min(stageWidth * 4 / 3, proxy.size.height * 0.58)
            let compactAssetHeight = max(96, proxy.size.height - compactStageHeight - 88 - (activeAdjustment == nil ? 0 : 42))

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
                        isIPad: isIPad,
                        onAutoMori: autoMori,
                        onStore: { showStore = true },
                        onShare: share,
                        onSave: saveToPhotoLibrary,
                        photoPicker: photoPicker
                    )

                    HStack(alignment: .center, spacing: railGap) {
                        Group {
                            if selectedLayer != nil {
                                AdjustmentRail(
                                    activeTool: $activeAdjustment,
                                    onBack: sendBack,
                                    onFront: bringFront,
                                    onDelete: deleteSelected,
                                    isIPad: isIPad
                                )
                            } else {
                                Color.clear
                            }
                        }
                        .frame(width: railColumnWidth)

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
                    }

                    if isCompact {
                        CompactControlPanel(
                            layer: selectedLayer,
                            activeTool: activeAdjustment,
                            onScale: { value in updateSelected { layer in layer.widthRatio = value } },
                            onRotate: { value in updateSelected { layer in layer.rotation.degrees = value } },
                            onOpacity: { value in updateSelected { layer in layer.opacity = value } }
                        )

                        ScrollView(.vertical, showsIndicators: true) {
                            VStack(spacing: 6) {
                                CategoryStrip(compact: true, selectedCategory: $selectedCategory)
                                AssetGrid(
                                    compact: true,
                                    assets: MoriLibrary.assets.filter { $0.category == selectedCategory },
                                    isUnlocked: isAssetUnlocked,
                                    onLocked: showPurchasePrompt,
                                    onSelect: addAsset
                                )
                            }
                            .padding(.bottom, 8)
                        }
                        .frame(height: compactAssetHeight)
                    } else {
                        ControlPanel(
                            compact: false,
                            isIPad: isIPad,
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

                        CategoryStrip(compact: false, isIPad: isIPad, selectedCategory: $selectedCategory)
                        AssetGrid(
                            compact: false,
                            isIPad: isIPad,
                            assets: MoriLibrary.assets.filter { $0.category == selectedCategory },
                            isUnlocked: isAssetUnlocked,
                            onLocked: showPurchasePrompt,
                            onSelect: addAsset
                        )
                    }
                }
                .padding(pagePadding)
                .padding(.top, isCompact ? 4 : 8)
            }
        }
        .task(id: selectedPhotoItem) {
            await loadPhoto()
        }
        .task {
            await purchaseStore.load()
        }
        .sheet(item: $sharePayload) { payload in
            ActivityView(items: [payload.image])
        }
        .sheet(isPresented: $showStore) {
            StoreSheet(promptPack: purchasePromptPack, purchaseStore: purchaseStore)
        }
        .alert("保存しました。", isPresented: $showSaveAlert) {
            Button("OK", role: .cancel) {}
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
            activeAdjustment = nil
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
        activeAdjustment = nil
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
        if self.selectedLayerID == nil {
            activeAdjustment = nil
        }
    }

    private func autoMori() {
        let accessibleAssets = MoriLibrary.assets.filter(isAssetUnlocked)
        let requiredCategories: [MoriCategory] = [
            .animatedBackground, .hair, .brows, .shadow, .blush, .lipstick, .glasses, .earrings, .background
        ]
        let optionalCategories: [MoriCategory] = [
            .hairAccessory, .lashes, .nosePierce, .parts, .plush, .emotion
        ]

        for category in requiredCategories {
            if let asset = accessibleAssets.filter({ $0.category == category }).randomElement() {
                addAsset(asset)
            }
        }

        let extraCount = Int.random(in: 2...4)
        for category in optionalCategories.shuffled().prefix(extraCount) {
            if let asset = accessibleAssets.filter({ $0.category == category }).randomElement() {
                addAsset(asset)
            }
        }
    }

    private func share() {
        sharePayload = SharePayload(image: MoriImageExporter.render(basePhoto: basePhoto, layers: layers))
    }

    private func isAssetUnlocked(_ asset: MoriAsset) -> Bool {
        MorimoriBuildConfig.unlockPaidPacksForTestFlight
            || asset.pack == .free
            || purchaseStore.hasAllAccessSubscription
            || purchaseStore.purchasedPacks.contains(asset.pack)
    }

    private func showPurchasePrompt(_ asset: MoriAsset) {
        purchasePromptPack = asset.pack
        showStore = true
    }

    private func saveToPhotoLibrary() {
        let image = MoriImageExporter.render(basePhoto: basePhoto, layers: layers)
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        showSaveAlert = true
    }
}

private enum AdjustmentTool: CaseIterable, Identifiable {
    case scale
    case rotate
    case opacity

    var id: Self { self }

    var title: String {
        switch self {
        case .scale: "大きさ"
        case .rotate: "回転"
        case .opacity: "透明度"
        }
    }

    var iconName: String {
        switch self {
        case .scale: "arrow.up.left.and.arrow.down.right"
        case .rotate: "rotate.right"
        case .opacity: "circle.lefthalf.filled"
        }
    }
}

private struct SharePayload: Identifiable {
    let id = UUID()
    let image: UIImage
}

private struct StoreSheet: View {
    let promptPack: MoriPack?
    @ObservedObject var purchaseStore: PurchaseStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if let product = purchaseStore.subscriptionProduct {
                    Section("サブスク") {
                        productRow(
                            title: "全ロック素材使い放題",
                            detail: "すべての課金パックを月額で解放",
                            price: product.displayPrice,
                            action: { Task { await purchaseStore.purchase(product) } }
                        )
                    }
                }

                Section("単品パック") {
                    ForEach(MoriPack.allCases.filter { $0.productID != nil }) { pack in
                        let product = purchaseStore.product(for: pack)
                        productRow(
                            title: pack.title,
                            detail: pack.itemCount.map { "\($0)点" } ?? "追加素材",
                            price: product?.displayPrice ?? pack.priceYen.map { "\($0)円" } ?? "",
                            highlighted: pack == promptPack,
                            purchased: purchaseStore.purchasedPacks.contains(pack),
                            action: {
                                guard let product else { return }
                                Task { await purchaseStore.purchase(product) }
                            }
                        )
                    }
                }

                Section {
                    Button("購入を復元") {
                        Task { await purchaseStore.restore() }
                    }
                }

                Section("法的情報") {
                    Link("プライバシーポリシー", destination: URL(string: "https://snarfnet.github.io/privacy.html")!)
                    Link("利用規約 (EULA)", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                }
            }
            .navigationTitle("ショップ")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
            .task {
                await purchaseStore.load()
            }
            .alert("お知らせ", isPresented: Binding(get: { purchaseStore.errorMessage != nil }, set: { if !$0 { purchaseStore.errorMessage = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(purchaseStore.errorMessage ?? "")
            }
        }
    }

    private func productRow(
        title: String,
        detail: String,
        price: String,
        highlighted: Bool = false,
        purchased: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if purchased {
                Text("購入済み")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            } else {
                Button(price.isEmpty ? "読み込み中" : price, action: action)
                    .disabled(price.isEmpty)
                    .buttonStyle(.borderedProminent)
            }
        }
        .listRowBackground(highlighted ? Color(red: 1.0, green: 0.90, blue: 0.96) : nil)
    }
}

private struct HeaderView<PhotoPicker: View>: View {
    let compact: Bool
    var isIPad: Bool = false
    let onAutoMori: () -> Void
    let onStore: () -> Void
    let onShare: () -> Void
    let onSave: () -> Void
    let photoPicker: PhotoPicker

    var body: some View {
        VStack(spacing: compact ? 6 : 10) {
            if isIPad {
                HStack(spacing: 14) {
                    photoPicker
                    Button("ショップ", action: onStore)
                    Button("おまかせ盛り", action: onAutoMori)
                    Spacer()
                    Button("共有", action: onShare)
                    Button("保存", action: onSave)
                }
                .buttonStyle(CandyButtonStyle(compact: false))
            } else {
                HStack(spacing: compact ? 5 : 8) {
                    photoPicker
                    Button("ショップ", action: onStore)
                    Button("おまかせ盛り", action: onAutoMori)
                    Button("共有", action: onShare)
                    Button("保存", action: onSave)
                }
                .buttonStyle(CandyButtonStyle(compact: compact))
            }
        }
    }
}

private struct AdjustmentRail: View {
    @Binding var activeTool: AdjustmentTool?
    let onBack: () -> Void
    let onFront: () -> Void
    let onDelete: () -> Void
    var isIPad: Bool = false

    var body: some View {
        VStack(spacing: isIPad ? 12 : 7) {
            ForEach(AdjustmentTool.allCases) { tool in
                Button {
                    activeTool = activeTool == tool ? nil : tool
                } label: {
                    RailIconLabel(
                        iconName: tool.iconName,
                        title: tool.title,
                        tint: Color(red: 0.58, green: 0.14, blue: 0.38),
                        isActive: activeTool == tool,
                        isIPad: isIPad
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tool.title)
            }

            Spacer()
                .frame(height: 12)

            RailActionButton(iconName: "arrow.down", title: "背面", tint: Color(red: 0.58, green: 0.14, blue: 0.38), action: onBack, isIPad: isIPad)
            RailActionButton(iconName: "arrow.up", title: "前面", tint: Color(red: 0.58, green: 0.14, blue: 0.38), action: onFront, isIPad: isIPad)
            RailActionButton(iconName: "trash", title: "削除", tint: Color(red: 0.82, green: 0.13, blue: 0.28), action: onDelete, isIPad: isIPad)
        }
    }
}

private struct RailActionButton: View {
    let iconName: String
    let title: String
    let tint: Color
    let action: () -> Void
    var isIPad: Bool = false

    var body: some View {
        Button(action: action) {
            RailIconLabel(iconName: iconName, title: title, tint: tint, isActive: false, isIPad: isIPad)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

private struct RailIconLabel: View {
    let iconName: String
    let title: String
    let tint: Color
    let isActive: Bool

    var isIPad: Bool = false

    var body: some View {
        VStack(spacing: isIPad ? 4 : 2) {
            Image(systemName: iconName)
                .font(.system(size: isIPad ? 22 : 15, weight: .bold))
                .foregroundStyle(isActive ? .white : tint)
                .frame(width: isIPad ? 48 : 34, height: isIPad ? 48 : 34)
                .background(isActive ? Color(red: 0.86, green: 0.18, blue: 0.52) : .white.opacity(0.88), in: Circle())
                .overlay(Circle().stroke(.white.opacity(0.95), lineWidth: 1))
                .shadow(color: Color(red: 0.54, green: 0.18, blue: 0.35).opacity(0.18), radius: 5, y: 2)
            Text(title)
                .font(.system(size: isIPad ? 12 : 9, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(tint)
                .frame(width: isIPad ? 56 : 42)
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
                        .allowsHitTesting(false)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if dragStart == nil {
                            guard let hitLayer = hitTestLayer(at: value.startLocation, in: size),
                                  let index = layers.firstIndex(where: { $0.id == hitLayer.id }) else { return }
                            selectedLayerID = hitLayer.id
                            dragStart = layers[index].position
                        }
                        guard let selectedLayerID,
                              let index = layers.firstIndex(where: { $0.id == selectedLayerID }),
                              let start = dragStart else { return }
                        layers[index].position = CGPoint(
                            x: min(1.2, max(-0.2, start.x + value.translation.width / max(1, size.width))),
                            y: min(1.2, max(-0.2, start.y + value.translation.height / max(1, size.height)))
                        )
                    }
                    .onEnded { _ in dragStart = nil }
            )
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(0.9), lineWidth: 8))
            .shadow(color: Color(red: 0.55, green: 0.18, blue: 0.36).opacity(0.18), radius: 18, y: 8)
        }
        .aspectRatio(3 / 4, contentMode: .fit)
    }

    private func hitTestLayer(at point: CGPoint, in stageSize: CGSize) -> MoriLayer? {
        layers
            .filter { !$0.isBackground }
            .sorted { $0.zIndex > $1.zIndex }
            .first { layer in
                guard let image = BundleImage.load(layer.asset.filename, folder: "Overlays", cropSide: layer.cropSide) else {
                    return false
                }
                let displaySize = layer.displaySize(in: stageSize, imageSize: image.size)
                let center = CGPoint(x: stageSize.width * layer.position.x, y: stageSize.height * layer.position.y)
                let radians = CGFloat(-layer.rotation.degrees * .pi / 180)
                let translated = CGPoint(x: point.x - center.x, y: point.y - center.y)
                let cosR = CoreGraphics.cos(radians)
                let sinR = CoreGraphics.sin(radians)
                var local = CGPoint(
                    x: translated.x * cosR - translated.y * sinR,
                    y: translated.x * sinR + translated.y * cosR
                )
                if layer.isFlipped {
                    local.x *= -1
                }
                let normalized = CGPoint(
                    x: (local.x + displaySize.width / 2) / max(1, displaySize.width),
                    y: (local.y + displaySize.height / 2) / max(1, displaySize.height)
                )
                return image.hasVisiblePixel(at: normalized)
            }
    }
}

private struct LayerView: View {
    let layer: MoriLayer
    let stageSize: CGSize
    let isSelected: Bool

    var body: some View {
        if layer.asset.isAnimated,
           let url = BundleImage.url(layer.asset.filename, folder: "Overlays"),
           let image = BundleImage.load(layer.asset.filename, folder: "Overlays", cropSide: layer.cropSide) {
            LayerImageContainer(layer: layer, stageSize: stageSize, isSelected: isSelected, imageSize: image.size) {
                AnimatedImage(url: url)
            }
        } else if let image = BundleImage.load(layer.asset.filename, folder: "Overlays", cropSide: layer.cropSide) {
            LayerImageContainer(layer: layer, stageSize: stageSize, isSelected: isSelected, imageSize: image.size) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
        }
    }
}

private struct LayerImageContainer<Content: View>: View {
    let layer: MoriLayer
    let stageSize: CGSize
    let isSelected: Bool
    let imageSize: CGSize
    let content: () -> Content

    var body: some View {
        let displaySize = layer.displaySize(in: stageSize, imageSize: imageSize)
        content()
            .frame(width: displaySize.width, height: displaySize.height)
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

private struct AnimatedImage: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = false
        imageView.image = BundleImage.animatedImage(url: url)
        imageView.startAnimating()
        return imageView
    }

    func updateUIView(_ imageView: UIImageView, context: Context) {
        imageView.image = BundleImage.animatedImage(url: url)
        imageView.startAnimating()
    }
}

private extension MoriAsset {
    var isAnimated: Bool {
        filename.lowercased().hasSuffix(".gif")
    }

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

private extension MoriLayer {
    func displaySize(in stageSize: CGSize, imageSize: CGSize) -> CGSize {
        if isBackground {
            return stageSize
        }
        let baseWidth = stageSize.width * widthRatio
        let width = cropSide == nil ? baseWidth : baseWidth * 0.52
        let ratio = imageSize.height / max(1, imageSize.width)
        return CGSize(width: width, height: width * ratio)
    }
}

private struct ControlPanel: View {
    let compact: Bool
    var isIPad: Bool = false
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
                SliderRow(title: "大きさ", displayValue: "\(Int(layer.widthRatio * 100))%", value: Double(layer.widthRatio), range: 0.08...6.0) { onScale(CGFloat($0)) }
                SliderRow(title: "回転", displayValue: "\(Int(layer.rotation.degrees))°", value: layer.rotation.degrees, range: -180...180, onChange: onRotate)
                SliderRow(title: "透明度", displayValue: "\(Int(layer.opacity * 100))%", value: Double(layer.opacity), range: 0.2...1.0) { onOpacity(CGFloat($0)) }
            }

            HStack {
                Button("背面", action: onBack)
                Button("前面", action: onFront)
                Button("削除", action: onDelete)
            }
            .disabled(layer == nil)
        }
        .padding(compact ? 8 : 12)
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 18))
        .buttonStyle(CandyButtonStyle(compact: compact))
    }
}

private struct CompactControlPanel: View {
    let layer: MoriLayer?
    let activeTool: AdjustmentTool?
    let onScale: (CGFloat) -> Void
    let onRotate: (Double) -> Void
    let onOpacity: (CGFloat) -> Void

    var body: some View {
        VStack(spacing: 5) {
            if let layer, let activeTool {
                switch activeTool {
                case .scale:
                    SliderRow(title: activeTool.title, displayValue: "\(Int(layer.widthRatio * 100))%", value: Double(layer.widthRatio), range: 0.08...6.0) { onScale(CGFloat($0)) }
                case .rotate:
                    SliderRow(title: activeTool.title, displayValue: "\(Int(layer.rotation.degrees))°", value: layer.rotation.degrees, range: -180...180, onChange: onRotate)
                case .opacity:
                    SliderRow(title: activeTool.title, displayValue: "\(Int(layer.opacity * 100))%", value: Double(layer.opacity), range: 0.2...1.0) { onOpacity(CGFloat($0)) }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(.white.opacity(0.74), in: RoundedRectangle(cornerRadius: 14))
        .buttonStyle(CandyButtonStyle(compact: true))
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
    let compact: Bool
    var isIPad: Bool = false
    @Binding var selectedCategory: MoriCategory

    var body: some View {
        let minWidth: CGFloat = compact ? 62 : (isIPad ? 90 : 72)
        let gridSpacing: CGFloat = compact ? 4 : (isIPad ? 10 : 6)
        let columns = [
            GridItem(.adaptive(minimum: minWidth), spacing: gridSpacing)
        ]

        LazyVGrid(columns: columns, alignment: .leading, spacing: gridSpacing) {
            ForEach(MoriCategory.allCases) { category in
                Button {
                    selectedCategory = category
                } label: {
                    Text(category.rawValue)
                        .font((compact ? Font.caption2 : (isIPad ? Font.body : Font.caption)).weight(.black))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, compact ? 6 : (isIPad ? 14 : 10))
                        .padding(.vertical, compact ? 6 : (isIPad ? 12 : 8))
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
    var isIPad: Bool = false
    let assets: [MoriAsset]
    let isUnlocked: (MoriAsset) -> Bool
    let onLocked: (MoriAsset) -> Void
    let onSelect: (MoriAsset) -> Void

    var body: some View {
        let minWidth: CGFloat = compact ? 64 : (isIPad ? 100 : 78)
        let gridSpacing: CGFloat = compact ? 6 : (isIPad ? 12 : 8)
        let columns = [
            GridItem(.adaptive(minimum: minWidth), spacing: gridSpacing)
        ]

        LazyVGrid(columns: columns, spacing: gridSpacing) {
                ForEach(assets) { asset in
                    let unlocked = isUnlocked(asset)
                    Button {
                        guard unlocked else {
                            onLocked(asset)
                            return
                        }
                        onSelect(asset)
                    } label: {
                        VStack(spacing: isIPad ? 6 : 4) {
                            if let image = BundleImage.load(asset.filename, folder: "Overlays") {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: compact ? 34 : (isIPad ? 72 : 54))
                            }
                            Text(asset.name)
                                .font((isIPad ? Font.caption : Font.caption2).weight(.black))
                                .lineLimit(2)
                                .minimumScaleFactor(0.7)
                            if asset.pack != .free {
                                Text(unlocked ? asset.pack.title : "LOCK")
                                    .font(.system(size: isIPad ? 11 : 9, weight: .black, design: .rounded))
                                    .lineLimit(1)
                                    .padding(.horizontal, isIPad ? 7 : 5)
                                    .padding(.vertical, isIPad ? 2 : 1)
                                    .foregroundStyle(.white)
                                    .background(Color(red: 0.86, green: 0.18, blue: 0.52), in: Capsule())
                            }
                        }
                        .frame(width: compact ? 64 : (isIPad ? 100 : 78), height: compact ? 70 : (isIPad ? 120 : 92))
                        .padding(isIPad ? 6 : 4)
                        .opacity(unlocked ? 1 : 0.55)
                        .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(unlocked ? Color(red: 0.96, green: 0.72, blue: 0.84) : .gray.opacity(0.45), lineWidth: 1))
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
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .foregroundStyle(Color(red: 0.28, green: 0.13, blue: 0.21))
            .padding(.horizontal, compact ? 5 : 12)
            .padding(.vertical, compact ? 4 : 6)
            .frame(minHeight: compact ? 28 : 38)
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
