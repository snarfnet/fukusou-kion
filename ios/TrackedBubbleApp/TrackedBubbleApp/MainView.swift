import AVFoundation
import PhotosUI
import SwiftUI

struct MainView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var videoURL: URL?
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var bubbleText = "え、まって"
    @State private var trackingPoints: [FaceTrackingPoint] = []
    @State private var currentTime = 0.0
    @State private var sparkleShape: EyeSparkleShape = .material01
    @State private var showsEyeSparkle = false
    @State private var bubbleCount = 1
    @State private var isAnalyzing = false
    @State private var isExporting = false
    @State private var alertMessage: String?

    private let tracker = FaceTrackingService()
    private let exporter = VideoExportService()
    private let timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    VideoPicker(selection: $selectedItem)
                        .buttonStyle(.borderedProminent)

                    preview

                    VStack(alignment: .leading, spacing: 8) {
                        Text("吹き出しテキスト")
                            .font(.headline)
                        TextField("え、まって", text: $bubbleText)
                            .textFieldStyle(.roundedBorder)
                    }

                    Picker("目キラ", selection: $sparkleShape) {
                        ForEach(EyeSparkleShape.allCases) { shape in
                            Text(shape.title).tag(shape)
                        }
                    }
                    .pickerStyle(.menu)

                    Button {
                        bubbleCount = min(4, bubbleCount + 1)
                    } label: {
                        Label("吹き出しを追加", systemImage: "plus.bubble")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(trackingPoints.isEmpty || bubbleCount >= 4)

                    Button {
                        showsEyeSparkle.toggle()
                    } label: {
                        Label(showsEyeSparkle ? "お目目キラキラ ON" : "お目目キラキラ", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(showsEyeSparkle ? .pink : .gray)
                    .disabled(trackingPoints.isEmpty)

                    Button {
                        Task { await analyzeFace() }
                    } label: {
                        Label(isAnalyzing ? "解析中..." : "顔を解析する", systemImage: "face.smiling")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(videoURL == nil || isAnalyzing)

                    Button {
                        Task { await exportVideo() }
                    } label: {
                        Label(isExporting ? "書き出し中..." : "動画を書き出す", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(videoURL == nil || trackingPoints.isEmpty || isExporting)
                }
                .padding()
            }
            .navigationTitle("お目目キラキラ")
        }
        .task(id: selectedItem) {
            await loadSelectedVideo()
        }
        .onReceive(timer) { _ in
            currentTime = player?.currentTime().seconds ?? 0
        }
        .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { notification in
            guard notification.object as? AVPlayerItem === player?.currentItem else { return }
            isPlaying = false
        }
        .alert("お知らせ", isPresented: Binding(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private var preview: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.black.opacity(0.88))

                if let player {
                    VideoPlayerView(player: player)
                        .clipShape(RoundedRectangle(cornerRadius: 18))

                    if let point = trackingPoints.interpolatedPoint(at: currentTime) {
                        ForEach(0..<bubbleCount, id: \.self) { index in
                            BubbleOverlayView(
                                text: bubbleText(for: index),
                                anchor: point.bubbleAnchor,
                                containerSize: size,
                                offset: bubbleOffset(for: index),
                                scale: bubbleScale(for: index)
                            )
                            .allowsHitTesting(false)
                            .zIndex(Double(2 + index))
                        }
                        if showsEyeSparkle {
                            EyeSparkleOverlayView(point: point, shape: sparkleShape, containerSize: size)
                                .zIndex(3)
                        }
                    }
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "video")
                            .font(.system(size: 42))
                        Text("動画を選択")
                            .font(.headline)
                    }
                    .foregroundStyle(.white.opacity(0.9))
                }

                VStack {
                    Spacer()
                    HStack {
                        Button {
                            togglePlayback()
                        } label: {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.title3.bold())
                                .frame(width: 46, height: 46)
                                .background(.white.opacity(0.92), in: Circle())
                        }
                        .disabled(player == nil)
                        .zIndex(10)
                        Spacer()
                    }
                    .padding(12)
                }
            }
        }
        .aspectRatio(9 / 16, contentMode: .fit)
    }

    private func loadSelectedVideo() async {
        guard let selectedItem else { return }
        do {
            if let picked = try await selectedItem.loadTransferable(type: PickedVideo.self) {
                await MainActor.run {
                    videoURL = picked.url
                    player = AVPlayer(url: picked.url)
                    trackingPoints = []
                    showsEyeSparkle = false
                    bubbleCount = 1
                    currentTime = 0
                    isPlaying = false
                }
            }
        } catch {
            alertMessage = "動画を読み込めませんでした。"
        }
    }

    private func analyzeFace() async {
        guard let videoURL else { return }
        isAnalyzing = true
        defer { isAnalyzing = false }
        do {
            let points = try await tracker.analyze(videoURL: videoURL)
            trackingPoints = points
            alertMessage = points.isEmpty ? "顔を見つけられませんでした。" : "顔解析が完了しました。"
        } catch {
            alertMessage = "顔解析に失敗しました。"
        }
    }

    private func exportVideo() async {
        guard let videoURL else { return }
        isExporting = true
        defer { isExporting = false }
        do {
            _ = try await exporter.export(
                videoURL: videoURL,
                trackingPoints: trackingPoints,
                bubbleText: bubbleText,
                bubbleCount: bubbleCount,
                sparkleShape: sparkleShape,
                includeSparkles: showsEyeSparkle
            )
            alertMessage = "動画をカメラロールに保存しました。"
        } catch {
            alertMessage = "動画の書き出しに失敗しました。"
        }
    }

    private func togglePlayback() {
        guard let player else { return }
        if isPlaying {
            player.pause()
        } else {
            if let duration = player.currentItem?.duration.seconds,
               duration.isFinite,
               player.currentTime().seconds >= duration - 0.05 {
                player.seek(to: .zero)
            }
            player.play()
        }
        isPlaying.toggle()
    }

    private func bubbleText(for index: Int) -> String {
        if index == 0 {
            return bubbleText
        }
        let presets = ["すごい!!", "えっ!?", "かわいい", "まって!"]
        return presets[min(index - 1, presets.count - 1)]
    }

    private func bubbleOffset(for index: Int) -> CGPoint {
        let offsets = [
            CGPoint(x: 0.00, y: 0.00),
            CGPoint(x: -0.24, y: 0.14),
            CGPoint(x: 0.18, y: -0.12),
            CGPoint(x: -0.18, y: -0.16)
        ]
        return offsets[min(index, offsets.count - 1)]
    }

    private func bubbleScale(for index: Int) -> CGFloat {
        index == 0 ? 1.0 : 0.78
    }
}
