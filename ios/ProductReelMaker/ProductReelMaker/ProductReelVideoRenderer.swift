import AVFoundation
import Photos
import SwiftUI
import UIKit

enum ProductReelVideoRenderer {
    static let size = CGSize(width: 1080, height: 1920)
    static let sceneDuration: Double = 3
    static let fps: Int32 = 30

    static func render(scenes: [ReelScene]) async throws -> URL {
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("product-reel-\(UUID().uuidString).mp4")

        let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: Int(size.width),
            AVVideoHeightKey: Int(size.height),
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 7_500_000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
            ]
        ]

        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = false

        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                kCVPixelBufferWidthKey as String: Int(size.width),
                kCVPixelBufferHeightKey as String: Int(size.height)
            ]
        )

        guard writer.canAdd(input) else { throw RendererError.cannotAddInput }
        writer.add(input)
        guard writer.startWriting() else { throw writer.error ?? RendererError.writerFailed }
        writer.startSession(atSourceTime: .zero)

        let totalFramesPerScene = Int(sceneDuration * Double(fps))
        var frameIndex: Int64 = 0

        for sceneIndex in scenes.indices {
            for localFrame in 0..<totalFramesPerScene {
                while !input.isReadyForMoreMediaData {
                    try await Task.sleep(nanoseconds: 5_000_000)
                }

                let progress = Double(localFrame) / Double(totalFramesPerScene)
                guard let buffer = makePixelBuffer() else { throw RendererError.pixelBufferFailed }
                draw(scene: scenes[sceneIndex], sceneIndex: sceneIndex, progress: progress, into: buffer)
                let time = CMTime(value: frameIndex, timescale: fps)
                if !adaptor.append(buffer, withPresentationTime: time) {
                    throw writer.error ?? RendererError.appendFailed
                }
                frameIndex += 1
            }
        }

        input.markAsFinished()
        await withCheckedContinuation { continuation in
            writer.finishWriting {
                continuation.resume()
            }
        }
        if writer.status != .completed {
            throw writer.error ?? RendererError.writerFailed
        }
        return outputURL
    }

    static func saveToPhotos(url: URL) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { throw RendererError.photoPermissionDenied }

        try await withCheckedThrowingContinuation { continuation in
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            } completionHandler: { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: RendererError.writerFailed)
                }
            }
        }
    }

    private static func makePixelBuffer() -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32ARGB,
            [
                kCVPixelBufferCGImageCompatibilityKey: true,
                kCVPixelBufferCGBitmapContextCompatibilityKey: true
            ] as CFDictionary,
            &pixelBuffer
        )
        return pixelBuffer
    }

    private static func draw(scene: ReelScene, sceneIndex: Int, progress: Double, into pixelBuffer: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pixelBuffer),
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else { return }

        UIGraphicsPushContext(context)
        defer { UIGraphicsPopContext() }

        UIColor(red: 0.08, green: 0.07, blue: 0.06, alpha: 1).setFill()
        UIBezierPath(rect: CGRect(origin: .zero, size: size)).fill()
        drawCoverImage(scene.image, progress: progress)
        drawGradient()
        drawSceneTag(sceneIndex)
        drawMotions(scene.motionStickers, progress: progress)
        drawTextStickers(scene.textStickers, progress: progress)
        drawCaption(scene.caption, sceneIndex: sceneIndex, progress: progress)
    }

    private static func drawCoverImage(_ image: UIImage, progress: Double) {
        let scale = max(size.width / image.size.width, size.height / image.size.height)
        let drawSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let pan = CGFloat(progress - 0.5) * 80
        let rect = CGRect(
            x: (size.width - drawSize.width) / 2 + pan,
            y: (size.height - drawSize.height) / 2,
            width: drawSize.width,
            height: drawSize.height
        )
        image.draw(in: rect)
    }

    private static func drawGradient() {
        let colors = [
            UIColor.black.withAlphaComponent(0.25).cgColor,
            UIColor.clear.cgColor,
            UIColor.black.withAlphaComponent(0.62).cgColor
        ] as CFArray
        let locations: [CGFloat] = [0, 0.55, 1]
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) else { return }
        UIGraphicsGetCurrentContext()?.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: 0),
            end: CGPoint(x: 0, y: size.height),
            options: []
        )
    }

    private static func drawSceneTag(_ index: Int) {
        let text = "SCENE \(index + 1)"
        let rect = CGRect(x: 76, y: 132, width: 190, height: 62)
        UIColor(red: 0.84, green: 0.61, blue: 0.18, alpha: 1).setFill()
        UIColor.black.setStroke()
        let path = UIBezierPath(roundedRect: rect, cornerRadius: 10)
        path.lineWidth = 5
        path.fill()
        path.stroke()
        drawString(text, in: rect.insetBy(dx: 16, dy: 14), fontSize: 30, color: .black, alignment: .center)
    }

    private static func drawTextStickers(_ stickers: [PlacedTextSticker], progress: Double) {
        for (index, item) in stickers.enumerated() {
            let point = point(for: item.position, index: index)
            let pop = min(progress / 0.18, 1)
            let fade = progress > 0.82 ? 1 - min((progress - 0.82) / 0.18, 1) : 1
            let scale = CGFloat(0.2 + pop * 0.82) * item.scale * max(0.76, 1 - CGFloat(index) * 0.06)
            let rect = CGRect(x: -210, y: -88, width: 420, height: 176)

            let context = UIGraphicsGetCurrentContext()
            context?.saveGState()
            context?.translateBy(x: point.x, y: point.y)
            context?.rotate(by: CGFloat(item.sticker.tilt * .pi / 180))
            context?.scaleBy(x: scale, y: scale)
            context?.setAlpha(CGFloat(fade))

            UIColor.white.setFill()
            UIColor.black.setStroke()
            let outline = UIBezierPath(roundedRect: rect.insetBy(dx: -18, dy: -18), cornerRadius: 34)
            outline.lineWidth = 12
            outline.fill()
            outline.stroke()

            let fill = UIBezierPath(roundedRect: rect, cornerRadius: 24)
            item.sticker.uiColors.first?.setFill()
            fill.fill()
            UIColor.black.setStroke()
            fill.lineWidth = 6
            fill.stroke()

            drawString(item.sticker.text, in: rect.insetBy(dx: 22, dy: 28), fontSize: 56, color: .white, alignment: .center)
            context?.restoreGState()
        }
    }

    private static func drawMotions(_ stickers: [PlacedMotionSticker], progress: Double) {
        for (layer, item) in stickers.enumerated() {
            let point = point(for: item.position, index: layer)
            let alpha = progress > 0.82 ? 1 - min((progress - 0.82) / 0.18, 1) : min(progress / 0.18, 1)
            let color = item.sticker.uiColor.withAlphaComponent(alpha)

            for index in 0..<14 {
                let angle = Double(index) * 0.72 + progress * 7
                let radius = CGFloat(70 + index * 9) * item.scale
                let x = point.x + cos(angle) * radius
                let y = point.y + sin(angle * 0.8) * radius * 0.75
                drawStar(center: CGPoint(x: x, y: y), radius: CGFloat(20 + index % 4 * 6), color: color)
            }
        }
    }

    private static func drawCaption(_ text: String, sceneIndex: Int, progress: Double) {
        let yIn = min(progress / 0.22, 1)
        let yOut = progress > 0.78 ? min((progress - 0.78) / 0.22, 1) : 0
        let y = size.height * 0.78 - CGFloat(110 * yIn) - CGFloat(90 * yOut)
        let color: UIColor = sceneIndex % 3 == 1 ? .systemMint : sceneIndex % 3 == 2 ? .systemYellow : .systemRed
        let lines = captionLines(text)

        for (index, line) in lines.enumerated() {
            let rect = CGRect(x: 82, y: y + CGFloat(index) * 112, width: size.width * 0.84, height: 116)
            drawString(line, in: rect, fontSize: 96, color: .white, alignment: .left, stroke: true)
        }

        color.setFill()
        UIBezierPath(rect: CGRect(x: 82, y: y + CGFloat(lines.count) * 112 + 18, width: 450, height: 28)).fill()
    }

    private static func drawString(
        _ text: String,
        in rect: CGRect,
        fontSize: CGFloat,
        color: UIColor,
        alignment: NSTextAlignment,
        stroke: Bool = false
    ) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        paragraph.lineBreakMode = .byWordWrapping
        let font = UIFont.systemFont(ofSize: fontSize, weight: .black)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph,
            .strokeColor: UIColor.black,
            .strokeWidth: stroke ? -5 : 0
        ]
        text.draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes)
    }

    private static func drawStar(center: CGPoint, radius: CGFloat, color: UIColor) {
        let path = UIBezierPath()
        for index in 0..<8 {
            let angle = CGFloat(index) * .pi / 4 - .pi / 2
            let r = index.isMultiple(of: 2) ? radius : radius * 0.32
            let point = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
            index == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        path.close()
        color.setFill()
        path.fill()
    }

    private static func point(for position: LayerPosition, index: Int) -> CGPoint {
        let base = position.unitPoint
        let offsets = [CGPoint.zero, CGPoint(x: 42, y: -28), CGPoint(x: -42, y: 34), CGPoint(x: 60, y: 42), CGPoint(x: -60, y: -36)]
        let offset = offsets[index % offsets.count]
        return CGPoint(x: base.x * size.width + offset.x, y: base.y * size.height + offset.y)
    }

    private static func captionLines(_ text: String) -> [String] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 12 else { return [trimmed] }
        let chars = Array(trimmed)
        let split = min(12, max(6, chars.count / 2))
        let first = String(chars[0..<split])
        let second = String(chars[split..<chars.count])
        return [first, second]
    }
}

private enum RendererError: Error {
    case cannotAddInput
    case writerFailed
    case appendFailed
    case pixelBufferFailed
    case photoPermissionDenied
}

private extension TextSticker {
    var uiColors: [UIColor] {
        colors.map(UIColor.init)
    }
}

private extension MotionSticker {
    var uiColor: UIColor {
        UIColor(color)
    }
}
