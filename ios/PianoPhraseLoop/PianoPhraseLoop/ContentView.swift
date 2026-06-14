import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var manager = PhrasePianoManager()
    @State private var isSharing = false

    var body: some View {
        NavigationStack {
            ZStack {
                GeometryReader { proxy in
                    Image("PianoForestBackground")
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.56),
                                    Color.black.opacity(0.38),
                                    Color.black.opacity(0.68)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        header
                        phrasePanel
                        controls
                        keyboardPreview
                    }
                    .padding(20)
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Phrase Piano")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $isSharing) {
                if let url = manager.savedMIDIURL {
                    ActivityView(activityItems: [url])
                }
            }
            .alert("エラー", isPresented: Binding(
                get: { manager.lastError != nil },
                set: { if !$0 { manager.lastError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(manager.lastError ?? "")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "pianokeys")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(Int(manager.bars))小節")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }

            Text("感情の起伏が出やすいモチーフ、低音、解決感をランダムに組み合わせます。")
                .font(.callout)
                .foregroundStyle(.white.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var phrasePanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(manager.phrase.name)
                        .font(.headline)
                    Text("\(manager.phrase.noteCount) notes")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if manager.isLooping {
                        Text("Bar \(manager.currentBarNumber)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                            .monospacedDigit()
                    }
                }
                Spacer()
                Image(systemName: manager.isPlaying ? "waveform" : "sparkles")
                    .font(.title2)
                    .foregroundStyle(.orange)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("長さ")
                    Spacer()
                    Text("\(Int(manager.bars))小節")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                Slider(value: $manager.bars, in: 1...8, step: 1) {
                    Text("長さ")
                }
            }

            Picker("Mood", selection: $manager.mood) {
                ForEach(PhraseMood.allCases) { mood in
                    Text(mood.rawValue).tag(mood)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var controls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    manager.generate()
                } label: {
                    Label("作成", systemImage: "sparkles")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())

                Button {
                    manager.togglePlayback()
                } label: {
                    Label(manager.isPlaying && !manager.isLooping ? "停止" : "再生", systemImage: manager.isPlaying && !manager.isLooping ? "stop.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
            }

            HStack(spacing: 12) {
                Button {
                    manager.toggleLoop()
                } label: {
                    Label(manager.isLooping ? "ループ停止" : "ループ", systemImage: manager.isLooping ? "stop.circle" : "repeat")
                        .frame(maxWidth: .infinity)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }
                .buttonStyle(SecondaryButtonStyle(isActive: manager.isLooping))

                Button {
                    manager.saveMIDI()
                    isSharing = manager.savedMIDIURL != nil
                } label: {
                    Label("MIDI保存", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }

    private var keyboardPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("現在のフレーズ")
                .font(.headline)
                .foregroundStyle(.white)

            GeometryReader { proxy in
                let width = proxy.size.width
                let height = proxy.size.height
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.white.opacity(0.08))

                    ForEach(manager.phrase.notes.prefix(48)) { note in
                        let x = max(0, min(width - 6, CGFloat(note.start / manager.phrase.duration) * width))
                        let normalizedPitch = CGFloat(note.pitch - 36) / 48.0
                        let y = max(6, min(height - 10, height - normalizedPitch * height))
                        let noteWidth = max(6, CGFloat(note.duration / manager.phrase.duration) * width)

                        Capsule()
                            .fill(note.pitch > 72 ? Color.orange : Color.cyan)
                            .frame(width: noteWidth, height: 6)
                            .position(x: x + noteWidth / 2, y: y)
                            .opacity(0.88)
                    }

                    if manager.isPlaying {
                        let playheadX = max(4, min(width - 4, CGFloat(manager.playbackProgress) * width))
                        Rectangle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 3, height: height - 16)
                            .position(x: playheadX, y: height / 2)
                            .shadow(color: .orange.opacity(0.55), radius: 8)
                    }
                }
            }
            .frame(height: 190)
        }
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.black)
            .padding(.vertical, 15)
            .background(configuration.isPressed ? Color.white.opacity(0.72) : Color.white, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct SecondaryButtonStyle: ButtonStyle {
    var isActive = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 14)
            .background(backgroundColor(isPressed: configuration.isPressed), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        if isActive {
            return Color.orange.opacity(isPressed ? 0.62 : 0.78)
        }
        return Color.white.opacity(isPressed ? 0.12 : 0.18)
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
