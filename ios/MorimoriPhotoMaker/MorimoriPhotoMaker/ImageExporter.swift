import ImageIO
import SwiftUI
import UIKit

enum MoriImageExporter {
    static let outputSize = CGSize(width: 1080, height: 1440)

    static func render(basePhoto: UIImage?, layers: [MoriLayer]) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        return UIGraphicsImageRenderer(size: outputSize, format: format).image { context in
            let rect = CGRect(origin: .zero, size: outputSize)
            drawStageBackground(in: rect)

            let sorted = layers.sorted { $0.zIndex < $1.zIndex }
            for layer in sorted where layer.zIndex < 5 {
                drawLayer(layer, in: rect, context: context.cgContext)
            }

            if let basePhoto {
                drawAspectFill(basePhoto, in: rect)
            }

            for layer in sorted where layer.zIndex >= 5 {
                drawLayer(layer, in: rect, context: context.cgContext)
            }
        }
    }

    private static func drawStageBackground(in rect: CGRect) {
        UIColor(red: 1.0, green: 0.92, blue: 0.97, alpha: 1).setFill()
        UIRectFill(rect)
    }

    private static func drawLayer(_ layer: MoriLayer, in rect: CGRect, context: CGContext) {
        guard let image = BundleImage.load(layer.asset.filename, folder: "Overlays", cropSide: layer.cropSide) else { return }

        context.saveGState()
        context.setAlpha(layer.opacity)
        defer { context.restoreGState() }

        if layer.isBackground {
            drawAspectFill(image, in: rect)
            return
        }

        let baseWidth = rect.width * layer.widthRatio
        let width = layer.cropSide == nil ? baseWidth : baseWidth * 0.52
        let imageRatio = image.size.height / max(1, image.size.width)
        let height = width * imageRatio
        let center = CGPoint(x: rect.width * layer.position.x, y: rect.height * layer.position.y)
        let drawRect = CGRect(x: -width / 2, y: -height / 2, width: width, height: height)

        context.translateBy(x: center.x, y: center.y)
        context.rotate(by: CGFloat(layer.rotation.degrees * .pi / 180))
        context.scaleBy(x: layer.isFlipped ? -1 : 1, y: 1)
        image.draw(in: drawRect)
    }

    private static func drawAspectFill(_ image: UIImage, in rect: CGRect) {
        let scale = max(rect.width / image.size.width, rect.height / image.size.height)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let drawRect = CGRect(
            x: rect.midX - size.width / 2,
            y: rect.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
        image.draw(in: drawRect)
    }
}

enum BundleImage {
    static func url(_ filename: String, folder: String) -> URL? {
        let nsName = filename as NSString
        let name = nsName.deletingPathExtension
        let ext = nsName.pathExtension
        let subdirectories: [String?] = ["Resources/\(folder)", folder, nil]
        for subdirectory in subdirectories {
            if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: subdirectory) {
                return url
            }
        }
        return nil
    }

    static func load(_ filename: String, folder: String, cropSide: MoriCropSide? = nil) -> UIImage? {
        let nsName = filename as NSString
        let name = nsName.deletingPathExtension
        let image: UIImage?
        if let url = url(filename, folder: folder) {
            image = UIImage(contentsOfFile: url.path)
        } else {
            image = UIImage(named: name)
        }
        guard let image else { return nil }
        return cropSide.map { image.cropped(to: $0) } ?? image
    }

    static func animatedImage(url: URL) -> UIImage? {
        guard
            let source = CGImageSourceCreateWithURL(url as CFURL, nil),
            CGImageSourceGetCount(source) > 1
        else {
            return UIImage(contentsOfFile: url.path)
        }

        var frames: [UIImage] = []
        var duration: TimeInterval = 0
        let count = CGImageSourceGetCount(source)
        for index in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else { continue }
            frames.append(UIImage(cgImage: cgImage))
            duration += frameDuration(at: index, source: source)
        }
        return UIImage.animatedImage(with: frames, duration: max(duration, 0.1))
    }

    private static func frameDuration(at index: Int, source: CGImageSource) -> TimeInterval {
        guard
            let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
            let gif = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any]
        else {
            return 0.08
        }
        let unclamped = gif[kCGImagePropertyGIFUnclampedDelayTime] as? Double
        let clamped = gif[kCGImagePropertyGIFDelayTime] as? Double
        let value = unclamped ?? clamped ?? 0.08
        return value < 0.02 ? 0.08 : value
    }
}

extension UIImage {
    func hasVisiblePixel(at normalizedPoint: CGPoint) -> Bool {
        guard
            normalizedPoint.x >= 0,
            normalizedPoint.x <= 1,
            normalizedPoint.y >= 0,
            normalizedPoint.y <= 1,
            let cgImage,
            let dataProvider = cgImage.dataProvider,
            let data = dataProvider.data,
            let bytes = CFDataGetBytePtr(data)
        else {
            return false
        }

        let x = min(cgImage.width - 1, max(0, Int(normalizedPoint.x * CGFloat(cgImage.width))))
        let y = min(cgImage.height - 1, max(0, Int(normalizedPoint.y * CGFloat(cgImage.height))))
        let bitsPerPixel = cgImage.bitsPerPixel
        let bytesPerPixel = max(1, bitsPerPixel / 8)
        let offset = y * cgImage.bytesPerRow + x * bytesPerPixel

        guard bitsPerPixel >= 32 else {
            return true
        }

        let alphaInfo = cgImage.alphaInfo
        let alpha: UInt8
        switch alphaInfo {
        case .premultipliedLast, .last:
            alpha = bytes[offset + 3]
        case .premultipliedFirst, .first:
            alpha = bytes[offset]
        case .none, .noneSkipLast, .noneSkipFirst:
            alpha = 255
        @unknown default:
            alpha = bytes[offset + min(3, bytesPerPixel - 1)]
        }
        return alpha > 24
    }

    func cropped(to side: MoriCropSide) -> UIImage {
        guard let cgImage else { return self }
        let halfWidth = cgImage.width / 2
        let rect = CGRect(
            x: side == .left ? 0 : halfWidth,
            y: 0,
            width: halfWidth,
            height: cgImage.height
        )
        guard let cropped = cgImage.cropping(to: rect) else { return self }
        return UIImage(cgImage: cropped, scale: scale, orientation: imageOrientation)
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
