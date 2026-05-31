import PhotosUI
import SwiftUI
import UIKit

struct ContentView: View {
    @State private var productName = "新作アイテム"
    @State private var tone: ReelTone = .trend
    @State private var scenes: [ReelScene] = []
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var activeScene = 0
    @State private var selectedPosition: LayerPosition = .topLeft
    @State private var selectedMotionPosition: LayerPosition = .center
    @State private var activeTool: ToolTab = .text
    @State private var status = "写真を追加すると、TikTokサイズのMP4を作れます。"
    @State private var isExporting = false

    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.height < 760
            let previewHeight = min(proxy.size.width * 1.16, proxy.size.height * (compact ? 0.43 : 0.50))
            let editorHeight = max(compact ? 204 : 230, proxy.size.height - previewHeight - (compact ? 170 : 190))

            ZStack {
                Color(red: 0.97, green: 0.94, blue: 0.86).ignoresSafeArea()
                Image("ReelHeroBackdrop")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.2)
                    .blur(radius: 18)
                    .ignoresSafeArea()
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.72),
                        Color(red: 1.0, green: 0.91, blue: 0.72).opacity(0.52),
                        Color.white.opacity(0.65)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: compact ? 8 : 12) {
                    header(compact: compact)

                    ReelPreview(
                        scene: scenes.indices.contains(activeScene) ? scenes[activeScene] : nil,
                        sceneIndex: activeScene,
                        isExporting: isExporting
                    ) {
                        PhotosPicker(selection: $selectedItems, matching: .images) {
                            VStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.system(size: 30, weight: .black))
                                Text("写真追加")
                                    .font(.caption.bold())
                            }
                        }
                        .buttonStyle(AddPhotoButtonStyle())
                    }
                    .frame(height: previewHeight)
                    .padding(.horizontal, 14)

                    topControls
                        .padding(.horizontal, 14)

                    compactEditor
                        .frame(height: editorHeight, alignment: .top)
                        .padding(.horizontal, 10)
                }
            }
        }
        .task(id: selectedItems) {
            await importPhotos()
        }
    }

    private func header(compact: Bool) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Product Reel Studio")
                    .font(.caption2.bold())
                    .foregroundStyle(.blue)
                    .textCase(.uppercase)
                Text("商品紹介を、すぐ動画っぽく。")
                    .font(.system(size: compact ? 18 : 22, weight: .black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Spacer(minLength: 6)

            Button {
                Task { await exportVideo() }
            } label: {
                Label(isExporting ? "保存中" : "MP4保存", systemImage: "square.and.arrow.down")
            }
            .buttonStyle(PrimaryPillButtonStyle())
            .disabled(isExporting || scenes.isEmpty)
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
    }

    private var topControls: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                TextField("商品名", text: $productName)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: productName) { _, _ in regenerateCaptions() }

                Picker("雰囲気", selection: $tone) {
                    ForEach(ReelTone.allCases) { tone in
                        Text(tone.title).tag(tone)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 128)
                .onChange(of: tone) { _, _ in regenerateCaptions() }
            }

            HStack(spacing: 8) {
                PhotosPicker(selection: $selectedItems, matching: .images) {
                    Label("写真追加", systemImage: "photo.badge.plus")
                }
                .buttonStyle(SecondaryPillButtonStyle())

                Button {
                    regenerateCaptions(random: true)
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(SquareToolButtonStyle())

                sceneStrip
            }
        }
    }

    private var sceneStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(scenes.indices, id: \.self) { index in
                    Button {
                        activeScene = index
                    } label: {
                        Text("\(index + 1)")
                            .frame(width: 34, height: 34)
                    }
                    .buttonStyle(SceneButtonStyle(active: index == activeScene))
                }
            }
        }
    }

    private var compactEditor: some View {
        VStack(spacing: 8) {
            Picker("編集", selection: $activeTool) {
                ForEach(ToolTab.allCases) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 12)
            .padding(.top, 10)

            Group {
                switch activeTool {
                case .caption:
                    captionPanel
                case .text:
                    textStickerPanel
                case .motion:
                    motionPanel
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)

            Text(status)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.black.opacity(0.26), lineWidth: 1.5))
        .shadow(color: .black.opacity(0.12), radius: 0, x: 4, y: 4)
    }

    private var captionPanel: some View {
        VStack(spacing: 8) {
            if scenes.indices.contains(activeScene) {
                TextEditor(text: Binding(
                    get: { scenes[activeScene].caption },
                    set: { scenes[activeScene].caption = $0 }
                ))
                .font(.headline)
                .frame(height: 74)
                .padding(8)
                .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))

                Button("このシーンの写真を削除") {
                    removeActiveScene()
                }
                .buttonStyle(SecondaryPillButtonStyle())
            } else {
                emptyText
            }
        }
        .padding(.horizontal, 14)
    }

    private var textStickerPanel: some View {
        VStack(spacing: 8) {
            positionPicker(selection: $selectedPosition)
            stickerGrid
        }
        .padding(.horizontal, 14)
    }

    private var motionPanel: some View {
        VStack(spacing: 8) {
            positionPicker(selection: $selectedMotionPosition)
            motionGrid
        }
        .padding(.horizontal, 14)
    }

    private var stickerGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], spacing: 8) {
                ForEach(ReelLibrary.textStickers) { sticker in
                    Button {
                        toggle(sticker)
                    } label: {
                        Text(sticker.text)
                            .font(.system(size: 16, weight: .black))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.65)
                            .frame(height: 54)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(StickerChipStyle(active: currentScene?.textStickers.contains { $0.sticker.id == sticker.id } == true, colors: sticker.colors))
                }
            }
            .padding(.bottom, 12)
        }
    }

    private var motionGrid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 106), spacing: 8)], spacing: 8) {
                ForEach(ReelLibrary.motionStickers) { sticker in
                    Button {
                        toggle(sticker)
                    } label: {
                        Label(sticker.name, systemImage: "sparkles")
                            .font(.caption.bold())
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(height: 44)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(MotionChipStyle(active: currentScene?.motionStickers.contains { $0.sticker.id == sticker.id } == true, color: sticker.color))
                }
            }
            .padding(.bottom, 12)
        }
    }

    private func positionPicker(selection: Binding<LayerPosition>) -> some View {
        Picker("配置", selection: selection) {
            ForEach(LayerPosition.allCases) { position in
                Text(position.title).tag(position)
            }
        }
        .pickerStyle(.segmented)
    }

    private var emptyText: some View {
        Text("写真を追加すると編集できます。")
            .font(.headline)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(.white.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }

    private var currentScene: ReelScene? {
        scenes.indices.contains(activeScene) ? scenes[activeScene] : nil
    }

    private func importPhotos() async {
        guard !selectedItems.isEmpty else { return }
        var imported: [UIImage] = []

        for item in selectedItems {
            if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                imported.append(image)
            }
        }

        await MainActor.run {
            let start = scenes.count
            for (offset, image) in imported.enumerated() {
                scenes.append(ReelScene(
                    image: image,
                    caption: caption(for: start + offset),
                    textStickers: [defaultTextSticker(index: start + offset)],
                    motionStickers: [defaultMotionSticker(index: start + offset)]
                ))
            }
            if scenes.count == imported.count {
                activeScene = 0
            }
            selectedItems = []
            status = "\(imported.count)枚追加しました。合計\(scenes.count)枚です。"
        }
    }

    private func caption(for index: Int, random: Bool = false) -> String {
        let pool = tone.captions
        let seed = random ? Int.random(in: 0..<pool.count) : index * 3
        return pool[seed % pool.count].replacingOccurrences(of: "{name}", with: productName.isEmpty ? "このアイテム" : productName)
    }

    private func regenerateCaptions(random: Bool = false) {
        for index in scenes.indices {
            scenes[index].caption = caption(for: index, random: random)
        }
        status = "雰囲気に合わせてキャプションを更新しました。"
    }

    private func defaultTextSticker(index: Int) -> PlacedTextSticker {
        PlacedTextSticker(
            sticker: ReelLibrary.textStickers[index % ReelLibrary.textStickers.count],
            position: LayerPosition.allCases[index % LayerPosition.allCases.count],
            scale: 1
        )
    }

    private func defaultMotionSticker(index: Int) -> PlacedMotionSticker {
        PlacedMotionSticker(
            sticker: ReelLibrary.motionStickers[index % ReelLibrary.motionStickers.count],
            position: LayerPosition.allCases[(index + 2) % LayerPosition.allCases.count],
            scale: 1
        )
    }

    private func toggle(_ sticker: TextSticker) {
        guard scenes.indices.contains(activeScene) else { return }
        if let index = scenes[activeScene].textStickers.firstIndex(where: { $0.sticker.id == sticker.id }) {
            scenes[activeScene].textStickers.remove(at: index)
            status = "文字ステッカーを外しました。"
        } else {
            scenes[activeScene].textStickers.append(PlacedTextSticker(
                sticker: sticker,
                position: nextPosition(used: scenes[activeScene].textStickers.map(\.position), preferred: selectedPosition),
                scale: [1, 1.14, 1.28, 1.42, 1.56].randomElement() ?? 1
            ))
            status = "文字ステッカーを追加しました。"
        }
    }

    private func toggle(_ sticker: MotionSticker) {
        guard scenes.indices.contains(activeScene) else { return }
        if let index = scenes[activeScene].motionStickers.firstIndex(where: { $0.sticker.id == sticker.id }) {
            scenes[activeScene].motionStickers.remove(at: index)
            status = "動くキラキラを外しました。"
        } else {
            scenes[activeScene].motionStickers.append(PlacedMotionSticker(
                sticker: sticker,
                position: nextPosition(used: scenes[activeScene].motionStickers.map(\.position), preferred: selectedMotionPosition),
                scale: [1, 1.08, 1.18, 1.28].randomElement() ?? 1
            ))
            status = "動くキラキラを追加しました。"
        }
    }

    private func nextPosition(used: [LayerPosition], preferred: LayerPosition) -> LayerPosition {
        if !used.contains(preferred) { return preferred }
        return LayerPosition.allCases.filter { !used.contains($0) }.randomElement() ?? LayerPosition.allCases.randomElement() ?? preferred
    }

    private func removeActiveScene() {
        guard scenes.indices.contains(activeScene) else { return }
        scenes.remove(at: activeScene)
        activeScene = min(activeScene, max(0, scenes.count - 1))
        status = scenes.isEmpty ? "写真をすべて削除しました。" : "写真を1枚削除しました。"
    }

    private func exportVideo() async {
        guard !scenes.isEmpty else { return }
        await MainActor.run {
            isExporting = true
            status = "MP4を書き出しています。"
        }

        do {
            let url = try await ProductReelVideoRenderer.render(scenes: scenes)
            try await ProductReelVideoRenderer.saveToPhotos(url: url)
            await MainActor.run {
                isExporting = false
                status = "写真アプリにMP4を保存しました。"
            }
        } catch {
            await MainActor.run {
                isExporting = false
                status = "保存に失敗しました。写真への追加許可を確認してください。"
            }
        }
    }
}

enum ToolTab: String, CaseIterable, Identifiable {
    case caption
    case text
    case motion

    var id: String { rawValue }

    var title: String {
        switch self {
        case .caption: "キャプション"
        case .text: "ステッカー"
        case .motion: "キラキラ"
        }
    }
}
