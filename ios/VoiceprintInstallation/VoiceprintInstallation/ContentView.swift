import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject private var recorder: VoiceRecorder
    @EnvironmentObject private var gallery: ArtworkGallery
    @State private var selectedArtwork: VoiceArtwork?
    @State private var exportedPNG: URL?
    @State private var exportedMetadata: URL?
    @State private var showShare = false

    var body: some View {
        ZStack {
            AppBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    HeaderView()
                    StudioPanel(
                        artwork: selectedArtwork,
                        isRecording: recorder.isRecording,
                        elapsed: recorder.elapsed,
                        liveLevel: recorder.liveLevel,
                        livePitch: recorder.livePitch,
                        onRecord: toggleRecording,
                        onRemix: remixCurrent,
                        onExport: exportCurrent
                    )
                    MetricPanel(features: selectedArtwork?.features ?? recorder.latestFeatures, isLive: recorder.isRecording)
                    MintPanel(artwork: selectedArtwork, pngURL: exportedPNG, metadataURL: exportedMetadata)
                    GalleryPanel(artworks: gallery.artworks, selectedArtwork: $selectedArtwork)
                }
                .frame(maxWidth: 860)
                .padding(.horizontal, 18)
                .padding(.top, 18)
                .padding(.bottom, 34)
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $showShare) {
            let urls = [exportedPNG, exportedMetadata].compactMap { $0 }
            ShareSheet(items: urls)
        }
        .alert("Microphone access is needed", isPresented: Binding(get: { recorder.permissionDenied }, set: { _ in recorder.clearPermissionAlert() })) {
            Button("OK", role: .cancel) {
                recorder.clearPermissionAlert()
            }
        } message: {
            Text("Enable microphone access in Settings. VoiceprintNFT does not store your audio, only abstract features for the artwork.")
        }
        .onChange(of: recorder.completedArtwork) { _, artwork in
            guard let artwork, selectedArtwork?.id != artwork.id else { return }
            selectedArtwork = artwork
            gallery.add(artwork)
            exportedPNG = nil
            exportedMetadata = nil
        }
    }

    private func toggleRecording() {
        if recorder.isRecording {
            _ = recorder.stop()
        } else {
            recorder.start()
        }
    }

    private func exportCurrent() {
        guard let selectedArtwork else { return }
        exportedPNG = ArtworkExporter.renderPNG(artwork: selectedArtwork)
        exportedMetadata = ArtworkExporter.writeMetadata(artwork: selectedArtwork)
        showShare = exportedPNG != nil || exportedMetadata != nil
    }

    private func remixCurrent() {
        guard let selectedArtwork else { return }
        let seed = selectedArtwork.seed ^ UInt64(Date().timeIntervalSince1970 * 1000) ^ UInt64.random(in: 1...UInt64.max)
        let artwork = VoiceArtwork(
            id: UUID(),
            createdAt: Date(),
            title: selectedArtwork.title.replacingOccurrences(of: "#", with: "Remix #"),
            seed: seed,
            features: selectedArtwork.features
        )
        self.selectedArtwork = artwork
        gallery.add(artwork)
        exportedPNG = nil
        exportedMetadata = nil
    }
}

private struct HeaderView: View {
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Image("KeyArt")
                .resizable()
                .scaledToFill()
                .frame(width: 58, height: 58)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.16), lineWidth: 1))

            VStack(alignment: .leading, spacing: 3) {
                Text("VoiceprintNFT")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.78)
                Text("Speak. Render. Mint.")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.62))
            }

            Spacer(minLength: 0)
        }
    }
}

private struct StudioPanel: View {
    var artwork: VoiceArtwork?
    var isRecording: Bool
    var elapsed: Double
    var liveLevel: Double
    var livePitch: Double
    var onRecord: () -> Void
    var onRemix: () -> Void
    var onExport: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .topLeading) {
                VoiceArtworkView(artwork: artwork, liveLevel: liveLevel, livePitch: livePitch, isRecording: isRecording)
                    .shadow(color: .cyan.opacity(0.22), radius: 28, y: 12)

                VStack(alignment: .leading, spacing: 6) {
                    Text(artwork?.title ?? "Live Voice Field")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)
                    Text(isRecording ? "Recording \(elapsed, specifier: "%.1f")s" : "Speak for five seconds to generate art")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.68))
                }
                .padding(12)
            }

            HStack(spacing: 10) {
                Button(action: onRecord) {
                    Label(isRecording ? "Generate" : "Record", systemImage: isRecording ? "sparkles" : "record.circle.fill")
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(PrimaryButtonStyle(isHot: isRecording))

                Button(action: onExport) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.headline.weight(.black))
                        .frame(width: 54, height: 52)
                }
                .buttonStyle(IconButtonStyle())
                .disabled(artwork == nil)
                .opacity(artwork == nil ? 0.42 : 1)

                Button(action: onRemix) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.headline.weight(.black))
                        .frame(width: 54, height: 52)
                }
                .buttonStyle(IconButtonStyle())
                .disabled(artwork == nil)
                .opacity(artwork == nil ? 0.42 : 1)
            }
        }
        .panel()
    }
}

private struct MetricPanel: View {
    var features: VoiceFeatures
    var isLive: Bool

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
            MetricTile(title: "Energy", value: "\(Int(features.averageEnergy * 100))", icon: "bolt.fill", tint: .yellow)
            MetricTile(title: "Pitch", value: "\(Int(features.averagePitch))Hz", icon: "waveform", tint: .cyan)
            MetricTile(title: "Rhythm", value: "\(Int(features.rhythmDensity * 10))", icon: "metronome.fill", tint: .orange)
            MetricTile(title: "Silence", value: "\(Int(features.silenceRatio * 100))%", icon: "moon.fill", tint: .mint)
        }
        .overlay(alignment: .topTrailing) {
            if isLive {
                Text("LIVE")
                    .font(.caption2.weight(.black))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.red.opacity(0.9), in: Capsule())
                    .foregroundStyle(.white)
                    .padding(8)
            }
        }
    }
}

private struct MetricTile: View {
    var title: String
    var value: String
    var icon: String
    var tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.headline.weight(.black))
                .frame(width: 32, height: 32)
                .background(tint.opacity(0.2), in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.52))
                Text(value)
                    .font(.title3.monospacedDigit().weight(.black))
                    .foregroundStyle(.white)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.white.opacity(0.075), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct MintPanel: View {
    var artwork: VoiceArtwork?
    var pngURL: URL?
    var metadataURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PanelTitle(title: "NFT Prep", subtitle: "Export PNG and metadata, upload to IPFS, then mint for OpenSea")

            VStack(spacing: 8) {
                MintStep(isDone: artwork != nil, title: "Voice artwork", detail: artwork?.title ?? "No artwork yet")
                MintStep(isDone: pngURL != nil, title: "PNG export", detail: pngURL?.lastPathComponent ?? "Use the share button to export")
                MintStep(isDone: metadataURL != nil, title: "Metadata JSON", detail: metadataURL?.lastPathComponent ?? "Template before replacing the image CID")
            }

            Link(destination: URL(string: "https://opensea.io/account?tab=created")!) {
                Label("Open OpenSea", systemImage: "safari.fill")
                    .frame(maxWidth: .infinity, minHeight: 46)
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .panel()
    }
}

private struct MintStep: View {
    var isDone: Bool
    var title: String
    var detail: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isDone ? "checkmark.seal.fill" : "circle")
                .foregroundStyle(isDone ? .mint : .white.opacity(0.35))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
    }
}

private struct GalleryPanel: View {
    var artworks: [VoiceArtwork]
    @Binding var selectedArtwork: VoiceArtwork?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PanelTitle(title: "Gallery", subtitle: artworks.isEmpty ? "Generated works appear here" : "\(artworks.count) voiceprints")

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 10) {
                ForEach(artworks) { artwork in
                    Button {
                        selectedArtwork = artwork
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            VoiceArtworkView(artwork: artwork)
                            Text(artwork.title)
                                .font(.caption2.weight(.black))
                                .foregroundStyle(.white.opacity(0.8))
                                .lineLimit(1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .panel()
    }
}

private struct PanelTitle: View {
    var title: String
    var subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.headline.weight(.black))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.55))
        }
    }
}

private struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.012, green: 0.014, blue: 0.02),
                Color(red: 0.02, green: 0.065, blue: 0.075),
                Color(red: 0.095, green: 0.034, blue: 0.07),
                Color(red: 0.02, green: 0.018, blue: 0.026)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    var isHot: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.black))
            .foregroundStyle(.black)
            .background(
                LinearGradient(
                    colors: isHot ? [.orange, .pink] : [.cyan, .mint],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 8)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

private struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.black))
            .foregroundStyle(.white)
            .background(.white.opacity(configuration.isPressed ? 0.18 : 0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(.white.opacity(configuration.isPressed ? 0.18 : 0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}

private extension View {
    func panel() -> some View {
        padding(12)
            .background(.ultraThinMaterial.opacity(0.78), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.1), lineWidth: 1))
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
