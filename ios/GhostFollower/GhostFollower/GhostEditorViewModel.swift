import AVFoundation
import Foundation

@MainActor
final class GhostEditorViewModel: ObservableObject {
    @Published var phase: EditorPhase = .empty
    @Published var videoURL: URL?
    @Published var player: AVPlayer?
    @Published var trackPoints: [PersonTrackPoint] = []
    @Published var summary = AnalysisSummary()
    @Published var settings = GhostSettings()
    @Published var playbackTime: Double = 0

    private let detector = PersonDetector()
    private let exporter = GhostVideoExporter()
    private var timeObserver: Any?

    func loadVideo(url: URL) {
        cleanupPlayer()
        videoURL = url
        trackPoints = []
        summary = AnalysisSummary()
        let player = AVPlayer(url: url)
        self.player = player
        addTimeObserver(to: player)
        phase = .ready
    }

    func analyze() {
        guard let videoURL else { return }
        phase = .analyzing(0)
        Task {
            do {
                let result = try await detector.analyze(url: videoURL) { [weak self] value in
                    Task { @MainActor in
                        self?.phase = .analyzing(value)
                    }
                }
                trackPoints = result.points
                summary = result.summary
                phase = .analyzed
            } catch {
                phase = .failed(error.localizedDescription)
            }
        }
    }

    func togglePlayback() {
        guard let player else { return }

        if player.timeControlStatus == .playing {
            player.pause()
            return
        }

        if shouldRestartPlayback(player: player) {
            player.seek(to: .zero, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
                player.play()
            }
        } else {
            player.play()
        }
    }

    func exportAndSave() {
        guard let videoURL else { return }
        phase = .exporting(0)
        let points = trackPoints
        let settings = settings

        Task {
            do {
                let outputURL = try await exporter.export(sourceURL: videoURL, points: points, settings: settings) { [weak self] value in
                    Task { @MainActor in
                        self?.phase = .exporting(value)
                    }
                }
                try await exporter.saveToPhotoLibrary(url: outputURL)
                phase = .exported(outputURL)
            } catch {
                phase = .failed(error.localizedDescription)
            }
        }
    }

    func currentPoint() -> PersonTrackPoint? {
        GhostRenderer.nearestPoint(at: playbackTime, in: trackPoints)
    }

    private func addTimeObserver(to player: AVPlayer) {
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(value: 1, timescale: 30),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor in
                self?.playbackTime = time.seconds
            }
        }
    }

    private func cleanupPlayer() {
        if let timeObserver, let player {
            player.removeTimeObserver(timeObserver)
        }
        timeObserver = nil
        player = nil
    }

    private func shouldRestartPlayback(player: AVPlayer) -> Bool {
        guard let duration = player.currentItem?.duration.seconds, duration.isFinite else {
            return false
        }

        return player.currentTime().seconds >= max(0, duration - 0.15)
    }

    deinit {}
}
