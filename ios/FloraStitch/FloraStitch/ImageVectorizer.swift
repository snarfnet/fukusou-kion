import CoreGraphics
import Foundation
import UIKit

enum ImageVectorizer {
    static func template(from data: Data) -> VectorTemplate? {
        guard let image = UIImage(data: data) else { return nil }
        let target = CGSize(width: 96, height: 96)
        let renderer = UIGraphicsImageRenderer(size: target)
        let rendered = renderer.image { context in
            UIColor.clear.setFill()
            context.fill(CGRect(origin: .zero, size: target))
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        guard let cgImage = rendered.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        let didDraw = pixels.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard didDraw else { return nil }

        var luminanceValues: [Double] = []
        var transparentCount = 0
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * bytesPerPixel
                let alpha = pixels[offset + 3]
                if alpha < 24 {
                    transparentCount += 1
                    continue
                }
                let red = Double(pixels[offset]) / 255.0
                let green = Double(pixels[offset + 1]) / 255.0
                let blue = Double(pixels[offset + 2]) / 255.0
                luminanceValues.append(red * 0.299 + green * 0.587 + blue * 0.114)
            }
        }
        guard !luminanceValues.isEmpty else { return nil }

        let average = luminanceValues.reduce(0, +) / Double(luminanceValues.count)
        let hasAlphaShape = Double(transparentCount) / Double(width * height) > 0.08
        let threshold = min(0.86, max(0.22, average * 0.92))

        var mask = [Bool](repeating: false, count: width * height)
        var minX = width
        var minY = height
        var maxX = 0
        var maxY = 0

        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * bytesPerPixel
                let alpha = Double(pixels[offset + 3]) / 255.0
                let red = Double(pixels[offset]) / 255.0
                let green = Double(pixels[offset + 1]) / 255.0
                let blue = Double(pixels[offset + 2]) / 255.0
                let luminance = red * 0.299 + green * 0.587 + blue * 0.114
                let filled = hasAlphaShape ? alpha > 0.12 : luminance < threshold
                if filled {
                    mask[y * width + x] = true
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                }
            }
        }

        guard minX < maxX, minY < maxY else { return nil }
        let centerX = Double(minX + maxX) / 2.0
        let centerY = Double(minY + maxY) / 2.0
        let scale = Double(max(maxX - minX, maxY - minY))
        guard scale > 0 else { return nil }

        let rayCount = 72
        let raySteps = 80
        let maxRadius = hypot(Double(maxX - minX), Double(maxY - minY)) / 2.0 + 2.0
        var outline: [CGPoint] = []

        for index in 0..<rayCount {
            let angle = Double(index) / Double(rayCount) * Double.pi * 2.0
            var lastHit: CGPoint?
            for step in 0...raySteps {
                let radius = maxRadius * Double(step) / Double(raySteps)
                let x = Int((centerX + cos(angle) * radius).rounded())
                let y = Int((centerY + sin(angle) * radius).rounded())
                guard x >= 0, x < width, y >= 0, y < height else { continue }
                if mask[y * width + x] {
                    lastHit = CGPoint(
                        x: (Double(x) - centerX) / scale,
                        y: (Double(y) - centerY) / scale
                    )
                }
            }
            if let lastHit {
                outline.append(lastHit)
            }
        }

        guard outline.count >= 8 else { return nil }
        return VectorTemplate(outlines: [outline])
    }
}
