import AppKit
import ImageIO
import SwiftUI

enum MacImageExporter {
    static let outputSize = CGSize(width: 1080, height: 1440)

    static func render(basePhoto: NSImage?, layers: [MoriLayer]) -> NSImage {
        let image = NSImage(size: outputSize)
        image.lockFocus()
        defer { image.unlockFocus() }

        let rect = CGRect(origin: .zero, size: outputSize)
        NSColor(red: 1.0, green: 0.92, blue: 0.97, alpha: 1).setFill()
        rect.fill()

        let sorted = layers.sorted { $0.zIndex < $1.zIndex }
        for layer in sorted where layer.zIndex < 5 {
            drawLayer(layer, in: rect)
        }

        if let basePhoto {
            drawAspectFill(basePhoto, in: rect)
        }

        for layer in sorted where layer.zIndex >= 5 {
            drawLayer(layer, in: rect)
        }

        return image
    }

    static func pngData(from image: NSImage) -> Data? {
        guard
            let tiff = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiff)
        else {
            return nil
        }
        return bitmap.representation(using: .png, properties: [:])
    }

    private static func drawLayer(_ layer: MoriLayer, in rect: CGRect) {
        guard let image = MacBundleImage.load(layer.asset.filename, folder: "Overlays", cropSide: layer.cropSide) else { return }

        NSGraphicsContext.current?.saveGraphicsState()
        defer { NSGraphicsContext.current?.restoreGraphicsState() }

        if layer.isBackground {
            drawAspectFill(image, in: rect, opacity: layer.opacity)
            return
        }

        let baseWidth = rect.width * layer.widthRatio
        let width = layer.cropSide == nil ? baseWidth : baseWidth * 0.52
        let imageRatio = image.size.height / max(1, image.size.width)
        let height = width * imageRatio
        let center = CGPoint(x: rect.width * layer.position.x, y: rect.height * layer.position.y)
        let drawRect = CGRect(x: -width / 2, y: -height / 2, width: width, height: height)

        let transform = NSAffineTransform()
        transform.translateX(by: center.x, yBy: center.y)
        transform.rotate(byDegrees: layer.rotation.degrees)
        transform.scaleX(by: layer.isFlipped ? -1 : 1, yBy: 1)
        transform.concat()

        image.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: layer.opacity)
    }

    private static func drawAspectFill(_ image: NSImage, in rect: CGRect, opacity: CGFloat = 1) {
        let scale = max(rect.width / image.size.width, rect.height / image.size.height)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let drawRect = CGRect(
            x: rect.midX - size.width / 2,
            y: rect.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
        image.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: opacity)
    }
}

enum MacBundleImage {
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

    static func load(_ filename: String, folder: String, cropSide: MoriCropSide? = nil) -> NSImage? {
        let nsName = filename as NSString
        let name = nsName.deletingPathExtension
        let image: NSImage?
        if let url = url(filename, folder: folder) {
            image = NSImage(contentsOf: url)
        } else {
            image = NSImage(named: name)
        }
        guard let image else { return nil }
        return cropSide.map { image.cropped(to: $0) } ?? image
    }

    static func animatedImage(url: URL) -> NSImage? {
        NSImage(contentsOf: url)
    }
}

extension NSImage {
    func cropped(to side: MoriCropSide) -> NSImage {
        guard let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil) else { return self }
        let halfWidth = cgImage.width / 2
        let rect = CGRect(
            x: side == .left ? 0 : halfWidth,
            y: 0,
            width: halfWidth,
            height: cgImage.height
        )
        guard let cropped = cgImage.cropping(to: rect) else { return self }
        return NSImage(cgImage: cropped, size: CGSize(width: rect.width, height: rect.height))
    }
}
