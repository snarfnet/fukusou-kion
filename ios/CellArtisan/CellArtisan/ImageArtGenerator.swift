import CoreGraphics
import UIKit

enum ImageArtError: LocalizedError {
    case cannotReadImage
    case cannotCreateBitmap

    var errorDescription: String? {
        switch self {
        case .cannotReadImage: return "画像を読み込めませんでした。"
        case .cannotCreateBitmap: return "セルアート用の画像データを作れませんでした。"
        }
    }
}

final class ImageArtGenerator {
    func generate(from image: UIImage, settings: CellArtSettings) throws -> CellArtDocument {
        guard let cgImage = image.fixedOrientation().cgImage else {
            throw ImageArtError.cannotReadImage
        }

        let sourceWidth = CGFloat(cgImage.width)
        let sourceHeight = CGFloat(cgImage.height)
        let targetWidth = max(12, min(settings.width, 140))
        let targetHeight = max(8, Int(round(CGFloat(targetWidth) * sourceHeight / sourceWidth)))
        let pixels = try drawPixels(from: cgImage, width: targetWidth, height: targetHeight)
        let palette = buildPalette(from: pixels, maxColors: settings.paletteSize)
        let mapped = pixels.map { nearestColor(for: $0, in: palette) }

        var cells: [PixelCell] = []
        cells.reserveCapacity(targetWidth * targetHeight)
        for row in 0..<targetHeight {
            for column in 0..<targetWidth {
                let color = mapped[row * targetWidth + column]
                cells.append(PixelCell(row: row + 1, column: column + 1, color: color))
            }
        }

        return CellArtDocument(width: targetWidth, height: targetHeight, cells: cells, palette: palette)
    }

    private func drawPixels(from image: CGImage, width: Int, height: Int) throws -> [CellColor] {
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var data = [UInt8](repeating: 0, count: height * bytesPerRow)
        guard let context = CGContext(
            data: &data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw ImageArtError.cannotCreateBitmap
        }

        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        var colors: [CellColor] = []
        colors.reserveCapacity(width * height)
        for index in stride(from: 0, to: data.count, by: bytesPerPixel) {
            colors.append(CellColor(red: data[index], green: data[index + 1], blue: data[index + 2]))
        }
        return colors
    }

    private func buildPalette(from pixels: [CellColor], maxColors: Int) -> [CellColor] {
        let bucketed = pixels.map { color in
            CellColor(red: color.red / 24 * 24, green: color.green / 24 * 24, blue: color.blue / 24 * 24)
        }
        let counts = Dictionary(grouping: bucketed, by: { $0 }).mapValues(\.count)
        let sorted = counts.sorted { first, second in
            if first.value == second.value {
                return luminance(first.key) < luminance(second.key)
            }
            return first.value > second.value
        }
        let palette = sorted.prefix(max(4, maxColors)).map(\.key)
        return palette.isEmpty ? [CellColor(red: 255, green: 255, blue: 255)] : palette
    }

    private func nearestColor(for color: CellColor, in palette: [CellColor]) -> CellColor {
        palette.min { distance(color, $0) < distance(color, $1) } ?? color
    }

    private func distance(_ a: CellColor, _ b: CellColor) -> Int {
        let red = Int(a.red) - Int(b.red)
        let green = Int(a.green) - Int(b.green)
        let blue = Int(a.blue) - Int(b.blue)
        return red * red * 3 + green * green * 4 + blue * blue * 2
    }

    private func luminance(_ color: CellColor) -> Double {
        Double(color.red) * 0.299 + Double(color.green) * 0.587 + Double(color.blue) * 0.114
    }
}

private extension UIImage {
    func fixedOrientation() -> UIImage {
        if imageOrientation == .up {
            return self
        }

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalized ?? self
    }
}
