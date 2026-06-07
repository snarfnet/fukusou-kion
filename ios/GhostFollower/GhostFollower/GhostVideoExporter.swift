import AVFoundation
import CoreImage
import CoreImage.CIFilterBuiltins
import Photos
import UIKit

final class GhostVideoExporter {
    private let context = CIContext()

    func export(
        sourceURL: URL,
        points: [PersonTrackPoint],
        settings: GhostSettings,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        guard !points.isEmpty else { throw EditorError.missingAnalysis }

        let asset = AVURLAsset(url: sourceURL)
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw EditorError.noVideoTrack
        }

        let renderSize = try await naturalRenderSize(for: videoTrack)
        let composition = AVMutableVideoComposition(asset: asset, applyingCIFiltersWithHandler: { [context] request in
            autoreleasepool {
                let seconds = request.compositionTime.seconds
                let source = request.sourceImage.clampedToExtent()
                let point = GhostRenderer.nearestPoint(at: seconds, in: points)
                guard let image = GhostRenderer.makeOverlayImage(size: renderSize, point: point, settings: settings, time: seconds),
                      let ciOverlay = CIImage(image: image) else {
                    request.finish(with: request.sourceImage, context: context)
                    return
                }

                let overlay = ciOverlay
                    .transformed(by: CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -renderSize.height))
                    .cropped(to: CGRect(origin: .zero, size: renderSize))
                let filter = CIFilter.sourceOverCompositing()
                filter.inputImage = overlay
                filter.backgroundImage = source
                let output = (filter.outputImage ?? request.sourceImage).cropped(to: request.sourceImage.extent)
                request.finish(with: output, context: context)
            }
        })
        composition.renderSize = renderSize
        composition.frameDuration = CMTime(value: 1, timescale: 30)

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("ghost-follower-\(UUID().uuidString)")
            .appendingPathExtension("mp4")
        try? FileManager.default.removeItem(at: outputURL)

        guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            throw EditorError.exportSessionFailed
        }
        session.outputURL = outputURL
        session.outputFileType = .mp4
        session.videoComposition = composition
        session.shouldOptimizeForNetworkUse = true

        let progressTask = Task {
            while !Task.isCancelled {
                progress(Double(session.progress))
                try? await Task.sleep(nanoseconds: 180_000_000)
            }
        }
        await session.export()
        progressTask.cancel()

        guard session.status == .completed else {
            throw session.error ?? EditorError.exportSessionFailed
        }
        progress(1)
        return outputURL
    }

    func saveToPhotoLibrary(url: URL) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }
    }

    private func naturalRenderSize(for track: AVAssetTrack) async throws -> CGSize {
        let naturalSize = try await track.load(.naturalSize)
        let transform = try await track.load(.preferredTransform)
        let rect = CGRect(origin: .zero, size: naturalSize).applying(transform)
        return CGSize(width: abs(rect.width), height: abs(rect.height))
    }
}
