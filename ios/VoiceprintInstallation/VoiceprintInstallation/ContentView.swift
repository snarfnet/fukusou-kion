import SwiftUI

struct ContentView: View {
    @StateObject private var recorder = VoiceRecorder()
    @StateObject private var gallery = GalleryStore()
    @State private var currentArtwork: VoiceArtwork?
    @State private var showGallery = false
    @State private var showExportSheet = false
    @State private var showMintPrep = false
    @State private var shareItems: [Any] = []

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    artworkArea
                    controlArea
                }
            }
            .navigationTitle("VoiceprintNFT")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showGallery = true
                    } label: {
                        Image(systemName: "square.grid.2x2")
                            .foregroundStyle(.cyan)
                    }
                }
            }
            .sheet(isPresented: $showGallery) {
                GalleryView(gallery: gallery) { artwork in
                    currentArtwork = artwork
                    showGallery = false
                }
            }
            .sheet(isPresented: $showExportSheet) {
                ShareSheet(items: shareItems)
            }
            .sheet(isPresented: $showMintPrep) {
                if let artwork = currentArtwork {
                    MintPrepView(artwork: artwork) { artwork in
                        gallery.save(artwork)
                    }
                }
            }
            .onChange(of: recorder.isRecording) { wasRecording, isRecording in
                if wasRecording, !isRecording, currentArtwork == nil, recorder.recordingProgress >= 1 {
                    currentArtwork = VoiceArtwork(features: recorder.buildFeatures())
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var artworkArea: some View {
        VoiceArtworkView(
            artwork: currentArtwork,
            liveLevel: recorder.liveLevel,
            livePitch: recorder.livePitch,
            isRecording: recorder.isRecording
        )
        .padding(16)
    }

    private var controlArea: some View {
        VStack(spacing: 16) {
            if recorder.isRecording {
                ProgressView(value: recorder.recordingProgress)
                    .tint(.cyan)
                    .padding(.horizontal, 32)

                Text("Recording... \(Int(recorder.recordingProgress * 5))s / 5s")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            VStack(spacing: 14) {
                Button {
                    if recorder.isRecording {
                        recorder.stopRecording()
                        let features = recorder.buildFeatures()
                        currentArtwork = VoiceArtwork(features: features)
                    } else {
                        currentArtwork = nil
                        recorder.startRecording()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(recorder.isRecording ? Color.red : Color.cyan)
                            .frame(width: 72, height: 72)

                        if recorder.isRecording {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(.white)
                                .frame(width: 24, height: 24)
                        } else {
                            Image(systemName: "mic.fill")
                                .font(.title)
                                .foregroundStyle(.black)
                        }
                    }
                }

                if currentArtwork != nil {
                    HStack(spacing: 10) {
                        Button {
                            if let art = currentArtwork, let url = ArtworkExporter.renderPNG(artwork: art) {
                                shareItems = [url]
                                showExportSheet = true
                            }
                        } label: {
                            Label("Export", systemImage: "square.and.arrow.up")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(.white.opacity(0.1), in: Capsule())
                        }

                        Button {
                            showMintPrep = true
                        } label: {
                            Label("NFT Prep", systemImage: "globe")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(.cyan.opacity(0.18), in: Capsule())
                        }

                        Button {
                            if let art = currentArtwork, let _ = ArtworkExporter.writeMetadata(artwork: art) {
                                gallery.save(art)
                            }
                        } label: {
                            Label("Save", systemImage: "folder.badge.plus")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(.white.opacity(0.1), in: Capsule())
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }

            if currentArtwork != nil {
                Button("New Recording") {
                    currentArtwork = nil
                }
                .font(.caption)
                .foregroundStyle(.gray)
            }
        }
        .padding(.bottom, 32)
        .padding(.top, 16)
    }
}

// MARK: - NFT Prep View

struct MintPrepView: View {
    let artwork: VoiceArtwork
    var onSave: (VoiceArtwork) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var pngURL: URL?
    @State private var metadataURL: URL?
    @State private var isSaved = false
    @State private var showShareSheet = false
    @State private var prepShareItems: [Any] = []

    private var openSeaURL: URL {
        URL(string: "https://opensea.io/studio")!
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        VoiceArtworkView(artwork: artwork)
                            .frame(height: 260)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading, spacing: 14) {
                            Text("NFT Prep")
                                .font(.title2.bold())
                                .foregroundStyle(.white)

                            PrepStepRow(
                                icon: "checkmark.circle.fill",
                                title: "Voice artwork",
                                detail: artwork.nftMetadata.name,
                                isDone: true
                            )

                            PrepStepRow(
                                icon: pngURL == nil ? "circle" : "checkmark.circle.fill",
                                title: "PNG export",
                                detail: pngURL?.lastPathComponent ?? "1024 x 1024 artwork",
                                isDone: pngURL != nil
                            )

                            PrepStepRow(
                                icon: metadataURL == nil ? "circle" : "checkmark.circle.fill",
                                title: "Metadata JSON",
                                detail: metadataURL?.lastPathComponent ?? "OpenSea attributes",
                                isDone: metadataURL != nil
                            )
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))

                        VStack(spacing: 12) {
                            Button {
                                pngURL = ArtworkExporter.renderPNG(artwork: artwork)
                            } label: {
                                Label("Export PNG", systemImage: "photo")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PrepButtonStyle(tint: .cyan))

                            Button {
                                metadataURL = ArtworkExporter.writeMetadata(artwork: artwork)
                            } label: {
                                Label("Export Metadata", systemImage: "doc.text")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PrepButtonStyle(tint: .mint))

                            Button {
                                onSave(artwork)
                                isSaved = true
                            } label: {
                                Label(isSaved ? "Saved" : "Save to Gallery", systemImage: "folder.badge.plus")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PrepButtonStyle(tint: .white))

                            if pngURL != nil || metadataURL != nil {
                                Button {
                                    var items: [Any] = []
                                    if let pngURL { items.append(pngURL) }
                                    if let metadataURL { items.append(metadataURL) }
                                    prepShareItems = items
                                    showShareSheet = true
                                } label: {
                                    Label("Share Files", systemImage: "square.and.arrow.up")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(PrepButtonStyle(tint: .white))
                            }

                            Button {
                                openURL(openSeaURL)
                            } label: {
                                Label("Open OpenSea", systemImage: "globe")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PrepButtonStyle(tint: .blue, foreground: .white))
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("OpenSea Registration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.cyan)
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: prepShareItems)
        }
    }
}

struct PrepStepRow: View {
    var icon: String
    var title: String
    var detail: String
    var isDone: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(isDone ? .mint : .white.opacity(0.35))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(1)
            }

            Spacer()
        }
    }
}

struct PrepButtonStyle: ButtonStyle {
    var tint: Color
    var foreground: Color = .black

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.bold())
            .foregroundStyle(foreground)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(tint.opacity(configuration.isPressed ? 0.7 : 1), in: RoundedRectangle(cornerRadius: 8))
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}

// MARK: - Gallery View

struct GalleryView: View {
    @ObservedObject var gallery: GalleryStore
    var onSelect: (VoiceArtwork) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if gallery.artworks.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "waveform")
                            .font(.largeTitle)
                            .foregroundStyle(.gray)
                        Text("No artworks yet")
                            .foregroundStyle(.gray)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                            ForEach(gallery.artworks) { artwork in
                                VoiceArtworkView(artwork: artwork)
                                    .frame(height: 150)
                                    .onTapGesture { onSelect(artwork) }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Gallery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.cyan)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
