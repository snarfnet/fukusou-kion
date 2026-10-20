import Foundation
import UIKit
import SceneKit
import AVFoundation
import ImageIO
import UniformTypeIdentifiers

enum ImageFormat: String, CaseIterable, Identifiable {
    case png = "PNG", jpeg = "JPEG", heic = "HEIC"
    var id: String { rawValue }
    var type: UTType {
        switch self { case .png: return .png; case .jpeg: return .jpeg; case .heic: return .heic }
    }
    var supported: Bool { (CGImageDestinationCopyTypeIdentifiers() as! [String]).contains(type.identifier) }
}

enum ExportError: LocalizedError {
    case failed(String)
    var errorDescription: String? {
        switch self { case .failed(let message): return L10n.text(message) }
    }
}

@MainActor
enum ExportService {
    static func image(_ artwork: Artwork, size: CGSize, format: ImageFormat, transparent: Bool) async throws -> URL {
        try Task.checkCancellation()
        await Task.yield()
        let image = try SculptureRenderer().image(artwork, size: size, transparent: transparent && format == .png)
        guard let cgImage = image.cgImage else { throw ExportError.failed("画像を作れませんでした。") }
        let url = temporaryURL(format.type.preferredFilenameExtension ?? "png")
        do {
            guard let destination = CGImageDestinationCreateWithURL(url as CFURL, format.type.identifier as CFString, 1, nil) else {
                throw ExportError.failed("この端末は選んだ画像形式に対応していません。")
            }
            CGImageDestinationAddImage(destination, cgImage,
                                      [kCGImageDestinationLossyCompressionQuality: 0.95] as CFDictionary)
            guard CGImageDestinationFinalize(destination) else { throw ExportError.failed("画像を書き込めません。空き容量を確認してください。") }
            try Task.checkCancellation()
            return url
        } catch {
            try? FileManager.default.removeItem(at: url)
            throw error
        }
    }

    static func movie(_ artwork: Artwork, size: CGSize, seconds: Int, fps: Int32 = 30,
                      progress: @escaping (Double) -> Void) async throws -> URL {
        let url = temporaryURL("mp4")
        let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        let width = Int(size.width), height = Int(size.height)
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: width, AVVideoHeightKey: height,
            AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: max(500_000, width * height * 5),
                                               AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel]
        ])
        input.expectsMediaDataInRealTime = false
        guard writer.canAdd(input) else { throw ExportError.failed("動画の設定を作れませんでした。") }
        writer.add(input)
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
            kCVPixelBufferWidthKey as String: width, kCVPixelBufferHeightKey as String: height,
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ])
        do {
            guard writer.startWriting() else { throw writer.error ?? ExportError.failed("動画の作成を開始できませんでした。") }
            writer.startSession(atSourceTime: .zero)
            let sculpture = SculptureRenderer()
            try sculpture.update(artwork, aspect: size.width / size.height)
            let renderer = sculpture.snapshotRenderer()
            let frameCount = seconds * Int(fps)
            guard frameCount > 0, let pool = adaptor.pixelBufferPool else {
                throw ExportError.failed("動画用のメモリを確保できませんでした。")
            }
            for frame in 0..<frameCount {
                try Task.checkCancellation()
                let startedWaiting = Date()
                while !input.isReadyForMoreMediaData {
                    try Task.checkCancellation()
                    guard writer.status == .writing else { throw writer.error ?? ExportError.failed("動画の作成が中断しました。") }
                    guard Date().timeIntervalSince(startedWaiting) < 120 else {
                        throw ExportError.failed("動画の処理に時間がかかっています。サイズを下げて再試行してください。")
                    }
                    try await Task.sleep(for: .milliseconds(10))
                }
                var rotated = artwork
                rotated.yaw += Double(frame) / Double(frameCount) * .pi * 2
                try sculpture.update(rotated, aspect: size.width / size.height)
                try autoreleasepool {
                    let image = renderer.snapshot(atTime: Double(frame) / Double(fps), with: size, antialiasingMode: .multisampling4X)
                    guard let cgImage = image.cgImage else { throw ExportError.failed("動画のフレームを作れませんでした。") }
                    var optionalBuffer: CVPixelBuffer?
                    guard CVPixelBufferPoolCreatePixelBuffer(nil, pool, &optionalBuffer) == kCVReturnSuccess,
                          let buffer = optionalBuffer else { throw ExportError.failed("動画用のメモリが不足しています。") }
                    CVPixelBufferLockBaseAddress(buffer, [])
                    defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
                    guard let context = CGContext(data: CVPixelBufferGetBaseAddress(buffer), width: width, height: height,
                                                  bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                                  space: CGColorSpaceCreateDeviceRGB(),
                                                  bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
                        throw ExportError.failed("動画の描画領域を作れませんでした。")
                    }
                    context.draw(cgImage, in: CGRect(origin: .zero, size: size))
                    guard adaptor.append(buffer, withPresentationTime: CMTime(value: Int64(frame), timescale: fps)) else {
                        throw writer.error ?? ExportError.failed("フレームを書き込めません。空き容量を確認してください。")
                    }
                }
                progress(Double(frame + 1) / Double(frameCount))
                try await Task.sleep(for: .milliseconds(1))
            }
            input.markAsFinished()
            writer.endSession(atSourceTime: CMTime(value: Int64(frameCount), timescale: fps))
            await writer.finishWriting()
            try Task.checkCancellation()
            guard writer.status == .completed else { throw writer.error ?? ExportError.failed("動画を保存できませんでした。") }
            return url
        } catch {
            if writer.status == .writing || writer.status == .unknown { writer.cancelWriting() }
            try? FileManager.default.removeItem(at: url)
            throw error
        }
    }

    static func temporaryURL(_ extensionName: String) -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("TYPO-\(UUID().uuidString)")
            .appendingPathExtension(extensionName)
    }
}
