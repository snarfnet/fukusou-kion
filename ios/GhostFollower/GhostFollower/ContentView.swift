import AVFoundation
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var editor: GhostEditorViewModel
    @EnvironmentObject private var store: GhostStore
    @State private var showingPicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.02, green: 0.02, blue: 0.025).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        preview
                        actionBar
                        if editor.videoURL != nil {
                            analysisPanel
                            ghostPicker
                            controls
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Ghost Follower")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showingPicker) {
                VideoPicker { url in
                    editor.loadVideo(url: url)
                }
                .ignoresSafeArea()
            }
            .alert("追加パック", isPresented: Binding(
                get: { store.purchaseMessage != nil },
                set: { if !$0 { store.purchaseMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(store.purchaseMessage ?? "")
            }
        }
    }

    private var preview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black)
                .overlay {
                    if let player = editor.player {
                        VideoPlayerView(player: player)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        GhostOverlayView(point: editor.currentPoint(), settings: editor.settings, time: editor.playbackTime)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        VStack(spacing: 12) {
                            Image(systemName: "video.badge.plus")
                                .font(.system(size: 44, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.85))
                            Text("動画を選んでください")
                                .font(.headline)
                                .foregroundStyle(.white)
                            Text("歩いている人を検出し、選んだ幽霊を追わせます。")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.62))
                                .multilineTextAlignment(.center)
                        }
                        .padding(24)
                    }
                }
        }
        .aspectRatio(9.0 / 16.0, contentMode: .fit)
    }

    private var actionBar: some View {
        HStack(spacing: 10) {
            Button {
                showingPicker = true
            } label: {
                Label("動画", systemImage: "film")
            }
            .buttonStyle(PrimaryButtonStyle())

            Button {
                editor.togglePlayback()
            } label: {
                Label("再生", systemImage: "playpause.fill")
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(editor.player == nil)

            Button {
                editor.analyze()
            } label: {
                Label("検出", systemImage: "scope")
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(editor.videoURL == nil || editor.phase.isBusy)
        }
    }

    private var analysisPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("検出結果", systemImage: "figure.walk")
                    .font(.headline)
                Spacer()
                Text(editor.summary.hitRateText)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.72))
            }

            switch editor.phase {
            case .analyzing(let progress):
                ProgressView(value: progress)
                Text("人物を探しています \(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
            case .exporting(let progress):
                ProgressView(value: progress)
                Text("幽霊入り動画を書き出しています \(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
            case .exported:
                Label("写真ライブラリへ保存しました", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case .failed(let message):
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            default:
                Text("検出フレーム \(editor.summary.detectedFrames) / \(editor.summary.processedFrames)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
            }

            Button {
                editor.exportAndSave()
            } label: {
                Label("保存", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(editor.trackPoints.isEmpty || editor.phase.isBusy)
        }
        .panelStyle()
    }

    private var ghostPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("幽霊")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(GhostStyle.allCases) { style in
                        Button {
                            if store.canUse(style) {
                                editor.settings.style = style
                            } else {
                                Task { await store.purchase(style) }
                            }
                        } label: {
                            VStack(spacing: 8) {
                                ZStack(alignment: .topTrailing) {
                                    Image(style.assetName(for: editor.settings.facing))
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 72, height: 92)
                                        .padding(6)
                                        .background(Color.black.opacity(0.35))
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    if editor.settings.style == style {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.white)
                                            .padding(4)
                                    }
                                }
                                Text(style.displayName)
                                    .font(.caption.weight(.semibold))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(.white)
                            .frame(width: 92)
                            .padding(8)
                            .background(editor.settings.style == style ? Color.white.opacity(0.16) : Color.white.opacity(0.07))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .panelStyle()
    }

    private var controls: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                ForEach(GhostFacing.allCases) { facing in
                    Button {
                        editor.settings.facing = facing
                    } label: {
                        Label(
                            facing.displayName,
                            systemImage: facing == .front ? "face.smiling.inverse" : "figure.walk.motion"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(FacingButtonStyle(isSelected: editor.settings.facing == facing))
                }
            }
            SliderRow(title: "濃さ", value: $editor.settings.opacity, range: 0.2...1.0)
            SliderRow(title: "大きさ", value: $editor.settings.scale, range: 0.75...1.9)
            SliderRow(title: "横位置", value: $editor.settings.horizontalOffset, range: -1.0...1.0)
            SliderRow(title: "縦位置", value: $editor.settings.verticalOffset, range: -0.7...0.7)
            SliderRow(title: "揺れ", value: $editor.settings.jitter, range: 0.0...0.12)
        }
        .panelStyle()
    }
}

private struct SliderRow: View {
    var title: String
    @Binding var value: Double
    var range: ClosedRange<Double>

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text(value, format: .number.precision(.fractionLength(2)))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white.opacity(0.65))
            }
            Slider(value: $value, in: range)
        }
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(.black)
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(configuration.isPressed ? Color.white.opacity(0.72) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(configuration.isPressed ? Color.white.opacity(0.18) : Color.white.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct FacingButtonStyle: ButtonStyle {
    var isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(isSelected ? .black : .white)
            .padding(.horizontal, 10)
            .frame(height: 42)
            .background(isSelected ? Color.white : Color.white.opacity(configuration.isPressed ? 0.18 : 0.09))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private extension View {
    func panelStyle() -> some View {
        self
            .foregroundStyle(.white)
            .padding(14)
            .background(Color.white.opacity(0.075))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    ContentView()
        .environmentObject(GhostEditorViewModel())
        .environmentObject(GhostStore())
}
