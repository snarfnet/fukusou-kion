import AVFoundation
import Photos
import UIKit

final class VideoExportService {
    func export(
        videoURL: URL,
        trackingPoints: [FaceTrackingPoint],
        bubbleText: String,
        bubbleCount: Int,
        sparkleShape: EyeSparkleShape,
        includeSparkles: Bool
    ) async throws -> URL {
        let asset = AVURLAsset(url: videoURL)
        let composition = AVMutableComposition()

        guard let sourceVideoTrack = try await asset.loadTracks(withMediaType: .video).first,
              let compositionVideoTrack = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid
              ) else {
            throw ExportError.missingVideoTrack
        }

        let duration = try await asset.load(.duration)
        try compositionVideoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: sourceVideoTrack, at: .zero)
        compositionVideoTrack.preferredTransform = try await sourceVideoTrack.load(.preferredTransform)

        if let sourceAudioTrack = try await asset.loadTracks(withMediaType: .audio).first,
           let compositionAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            try compositionAudioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: sourceAudioTrack, at: .zero)
        }

        let renderSize = try await renderSize(for: sourceVideoTrack)
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(origin: .zero, size: renderSize)

        let overlayLayer = CALayer()
        overlayLayer.frame = CGRect(origin: .zero, size: renderSize)
        overlayLayer.masksToBounds = true
        for index in 0..<max(1, min(4, bubbleCount)) {
            overlayLayer.addSublayer(
                makeBubbleLayer(
                    text: exportBubbleText(for: index, primaryText: bubbleText),
                    renderSize: renderSize,
                    trackingPoints: trackingPoints,
                    index: index
                )
            )
        }
        if includeSparkles {
            overlayLayer.addSublayer(makeSparkleLayer(shape: sparkleShape, renderSize: renderSize, trackingPoints: trackingPoints))
        }

        let parentLayer = CALayer()
        parentLayer.frame = CGRect(origin: .zero, size: renderSize)
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(overlayLayer)

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: duration)

        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionVideoTrack)
        instruction.layerInstructions = [layerInstruction]

        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = renderSize
        videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
        videoComposition.instructions = [instruction]
        videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
            postProcessingAsVideoLayer: videoLayer,
            in: parentLayer
        )

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("tracked-bubble-\(UUID().uuidString)")
            .appendingPathExtension("mov")
        try? FileManager.default.removeItem(at: outputURL)

        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw ExportError.cannotCreateExportSession
        }
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.videoComposition = videoComposition
        exportSession.shouldOptimizeForNetworkUse = true

        try await runExport(exportSession)
        guard exportSession.status == .completed else {
            throw ExportError.exportFailed
        }

        try await saveToPhotoLibrary(outputURL)
        return outputURL
    }

    private func renderSize(for track: AVAssetTrack) async throws -> CGSize {
        let naturalSize = try await track.load(.naturalSize)
        let transform = try await track.load(.preferredTransform)
        let rect = CGRect(origin: .zero, size: naturalSize).applying(transform)
        return CGSize(width: abs(rect.width), height: abs(rect.height))
    }

    private func makeBubbleLayer(text: String, renderSize: CGSize, trackingPoints: [FaceTrackingPoint], index: Int) -> CALayer {
        let scale = bubbleScale(for: index)
        let bubbleSize = CGSize(width: renderSize.width * 0.54 * scale, height: renderSize.height * 0.14 * scale)
        let root = CALayer()
        root.bounds = CGRect(origin: .zero, size: bubbleSize)
        root.position = CGPoint(x: renderSize.width * 0.5, y: renderSize.height * 0.18)

        let tailFrame = CGRect(
            x: bubbleSize.width * 0.66,
            y: bubbleSize.height * 0.74,
            width: bubbleSize.width * 0.20,
            height: bubbleSize.height * 0.48
        )
        let tail = CAShapeLayer()
        tail.path = mangaTailPath(in: tailFrame).cgPath
        tail.fillColor = UIColor.white.cgColor
        tail.strokeColor = UIColor.black.cgColor
        tail.lineWidth = max(3, renderSize.width * 0.006)
        tail.lineJoin = .round
        root.addSublayer(tail)

        let bubble = CAShapeLayer()
        bubble.path = mangaBubblePath(in: CGRect(origin: .zero, size: bubbleSize)).cgPath
        bubble.fillColor = UIColor.white.cgColor
        bubble.strokeColor = UIColor.black.cgColor
        bubble.lineWidth = max(4, renderSize.width * 0.008)
        bubble.lineJoin = .round
        root.addSublayer(bubble)

        let textLayer = BubbleTextLayer()
        textLayer.string = text.isEmpty ? "え、まって" : text
        textLayer.fontSize = max(22, renderSize.width * 0.052 * scale)
        textLayer.alignmentMode = .center
        textLayer.foregroundColor = UIColor(red: 0.88, green: 0.18, blue: 0.46, alpha: 1).cgColor
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.bounds = CGRect(x: 0, y: 0, width: bubbleSize.width * 0.78, height: bubbleSize.height * 0.66)
        textLayer.position = CGPoint(x: bubbleSize.width * 0.50, y: bubbleSize.height * 0.51)
        root.addSublayer(textLayer)

        root.add(
            positionAnimation(
                points: trackingPoints.map { adjustedBubbleAnchor($0.bubbleAnchor, index: index) },
                renderSize: renderSize,
                duration: trackingDuration(trackingPoints)
            ),
            forKey: "bubblePosition"
        )
        return root
    }

    private func makeSparkleLayer(shape: EyeSparkleShape, renderSize: CGSize, trackingPoints: [FaceTrackingPoint]) -> CALayer {
        let root = CALayer()
        root.frame = CGRect(origin: .zero, size: renderSize)
        root.add(
            positionAnimation(points: trackingPoints.map(\.eyeCenter), renderSize: renderSize, duration: trackingDuration(trackingPoints)),
            forKey: "sparklePosition"
        )

        let glyphs = [
            shape.glyph,
            shape.glyph,
            shape.particleGlyph(0),
            shape.particleGlyph(1),
            shape.particleGlyph(2),
            shape.particleGlyph(3),
            shape.particleGlyph(4),
            shape.particleGlyph(5)
        ]
        let base = renderSize.width * 0.18
        for index in glyphs.indices {
            let angle = CGFloat(index) * .pi * 2 / CGFloat(glyphs.count)
            let radius = base * (0.18 + CGFloat((index + shape.rawValue) % 4) * 0.12)
            let textLayer = CATextLayer()
            textLayer.string = glyphs[index]
            textLayer.alignmentMode = .center
            textLayer.fontSize = index < 2 ? base * 0.23 : base * (0.10 + CGFloat((index + shape.rawValue) % 4) * 0.025)
            textLayer.foregroundColor = uiColor(for: shape, index: index).cgColor
            textLayer.contentsScale = UIScreen.main.scale
            textLayer.bounds = CGRect(x: 0, y: 0, width: base * 0.35, height: base * 0.35)
            textLayer.position = CGPoint(
                x: CGFloat(cos(angle)) * radius,
                y: CGFloat(sin(angle)) * radius * shape.ySpread
            )
            textLayer.add(pulseAnimation(delay: Double(index) * 0.08, speed: shape.speed), forKey: "pulse")
            root.addSublayer(textLayer)
        }
        return root
    }

    private func mangaBubblePath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.22, y: rect.minY + rect.height * 0.21))
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.47, y: rect.minY + rect.height * 0.08),
            controlPoint1: CGPoint(x: rect.minX + rect.width * 0.25, y: rect.minY + rect.height * 0.02),
            controlPoint2: CGPoint(x: rect.minX + rect.width * 0.40, y: rect.minY - rect.height * 0.02)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.73, y: rect.minY + rect.height * 0.18),
            controlPoint1: CGPoint(x: rect.minX + rect.width * 0.55, y: rect.minY - rect.height * 0.05),
            controlPoint2: CGPoint(x: rect.minX + rect.width * 0.70, y: rect.minY + rect.height * 0.02)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX - rect.width * 0.05, y: rect.minY + rect.height * 0.45),
            controlPoint1: CGPoint(x: rect.minX + rect.width * 0.91, y: rect.minY + rect.height * 0.14),
            controlPoint2: CGPoint(x: rect.maxX + rect.width * 0.02, y: rect.minY + rect.height * 0.28)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX - rect.width * 0.18, y: rect.maxY - rect.height * 0.13),
            controlPoint1: CGPoint(x: rect.maxX + rect.width * 0.05, y: rect.minY + rect.height * 0.66),
            controlPoint2: CGPoint(x: rect.maxX - rect.width * 0.05, y: rect.maxY - rect.height * 0.10)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.45, y: rect.maxY - rect.height * 0.04),
            controlPoint1: CGPoint(x: rect.maxX - rect.width * 0.22, y: rect.maxY + rect.height * 0.06),
            controlPoint2: CGPoint(x: rect.minX + rect.width * 0.60, y: rect.maxY + rect.height * 0.08)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.12, y: rect.maxY - rect.height * 0.22),
            controlPoint1: CGPoint(x: rect.minX + rect.width * 0.32, y: rect.maxY + rect.height * 0.06),
            controlPoint2: CGPoint(x: rect.minX + rect.width * 0.14, y: rect.maxY - rect.height * 0.02)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.22, y: rect.minY + rect.height * 0.21),
            controlPoint1: CGPoint(x: rect.minX - rect.width * 0.03, y: rect.maxY - rect.height * 0.37),
            controlPoint2: CGPoint(x: rect.minX + rect.width * 0.02, y: rect.minY + rect.height * 0.25)
        )
        path.close()
        return path
    }

    private func mangaTailPath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.18, y: rect.minY + rect.height * 0.05))
        path.addCurve(
            to: CGPoint(x: rect.maxX - rect.width * 0.03, y: rect.maxY - rect.height * 0.03),
            controlPoint1: CGPoint(x: rect.minX + rect.width * 0.23, y: rect.minY + rect.height * 0.47),
            controlPoint2: CGPoint(x: rect.minX + rect.width * 0.58, y: rect.maxY)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + rect.width * 0.70, y: rect.minY + rect.height * 0.18),
            controlPoint1: CGPoint(x: rect.maxX - rect.width * 0.18, y: rect.maxY - rect.height * 0.52),
            controlPoint2: CGPoint(x: rect.maxX - rect.width * 0.24, y: rect.minY + rect.height * 0.28)
        )
        path.close()
        return path
    }

    private func emphasisMarksPath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.15, y: rect.maxY * 0.72))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.move(to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.22))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        path.move(to: CGPoint(x: rect.maxX - rect.width * 0.16, y: rect.maxY * 0.72))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return path
    }

    private func exportBubbleText(for index: Int, primaryText: String) -> String {
        if index == 0 {
            return primaryText
        }
        let presets = ["すごい!!", "えっ!?", "かわいい", "まって!"]
        return presets[min(index - 1, presets.count - 1)]
    }

    private func adjustedBubbleAnchor(_ anchor: CGPoint, index: Int) -> CGPoint {
        let offsets = [
            CGPoint(x: 0.00, y: 0.00),
            CGPoint(x: -0.24, y: 0.14),
            CGPoint(x: 0.18, y: -0.12),
            CGPoint(x: -0.18, y: -0.16)
        ]
        let offset = offsets[min(index, offsets.count - 1)]
        return CGPoint(
            x: min(0.88, max(0.12, anchor.x + offset.x)),
            y: min(0.88, max(0.08, anchor.y + offset.y))
        )
    }

    private func bubbleScale(for index: Int) -> CGFloat {
        index == 0 ? 1.0 : 0.78
    }

    private func positionAnimation(points: [CGPoint], renderSize: CGSize, duration: Double) -> CAKeyframeAnimation {
        let animation = CAKeyframeAnimation(keyPath: "position")
        animation.values = points.map { point in
            CGPoint(x: point.x * renderSize.width, y: point.y * renderSize.height)
        }
        let count = max(1, points.count - 1)
        animation.keyTimes = (0..<points.count).map { NSNumber(value: Double($0) / Double(count)) }
        animation.duration = max(0.1, duration)
        animation.calculationMode = .linear
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        return animation
    }

    private func trackingDuration(_ trackingPoints: [FaceTrackingPoint]) -> Double {
        trackingPoints.last?.time ?? 0.1
    }

    private func pulseAnimation(delay: Double, speed: Double = 5.0) -> CAAnimationGroup {
        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 0.72
        scale.toValue = 1.18
        scale.autoreverses = true

        let opacity = CABasicAnimation(keyPath: "opacity")
        opacity.fromValue = 0.45
        opacity.toValue = 1.0
        opacity.autoreverses = true

        let group = CAAnimationGroup()
        group.animations = [scale, opacity]
        group.duration = max(0.24, 2.2 / speed)
        group.beginTime = AVCoreAnimationBeginTimeAtZero + delay
        group.repeatCount = .greatestFiniteMagnitude
        return group
    }

    private func uiColor(for shape: EyeSparkleShape, index: Int) -> UIColor {
        let colors: [UIColor] = [
            .systemYellow,
            .systemPink,
            .systemCyan,
            .systemOrange,
            .systemPurple,
            .systemMint,
            .systemRed,
            .systemBlue,
            .systemGreen,
            UIColor(red: 1.0, green: 0.76, blue: 0.18, alpha: 1)
        ]
        return colors[(shape.rawValue + index) % colors.count]
    }

    private func saveToPhotoLibrary(_ url: URL) async throws {
        guard await requestPhotoLibraryAddAccess() else {
            throw ExportError.photoSaveFailed
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            } completionHandler: { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: ExportError.photoSaveFailed)
                }
            }
        }
    }

    private func runExport(_ exportSession: AVAssetExportSession) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            exportSession.exportAsynchronously {
                if let error = exportSession.error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func requestPhotoLibraryAddAccess() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if status == .authorized || status == .limited {
            return true
        }
        if status == .denied || status == .restricted {
            return false
        }
        return await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                continuation.resume(returning: newStatus == .authorized || newStatus == .limited)
            }
        }
    }
}

final class BubbleTextLayer: CATextLayer {
    override func draw(in ctx: CGContext) {
        ctx.saveGState()
        ctx.translateBy(x: 0, y: bounds.height * 0.18)
        super.draw(in: ctx)
        ctx.restoreGState()
    }
}

enum ExportError: Error {
    case missingVideoTrack
    case cannotCreateExportSession
    case exportFailed
    case photoSaveFailed
}
