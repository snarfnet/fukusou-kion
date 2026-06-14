import CoreGraphics
import UIKit

enum ImageArtError: LocalizedError {
    case cannotReadImage
    case cannotCreateBitmap

    var errorDescription: String? {
        switch self {
        case .cannotReadImage:
            return "画像を読み込めませんでした。"
        case .cannotCreateBitmap:
            return "セルアート用の画像データを作れませんでした。"
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
        let targetWidth = max(16, min(settings.width, 260))
        let targetHeight = max(8, Int(round(CGFloat(targetWidth) * sourceHeight / sourceWidth)))
        let rawPixels = try drawPixels(from: cgImage, width: targetWidth, height: targetHeight)
        let tunedPixels = rawPixels.map {
            enhance($0, contrast: settings.contrastBoost, saturation: settings.saturationBoost)
        }
        let palette = buildPalette(from: tunedPixels, maxColors: settings.paletteSize)
        let mapped = settings.dither
            ? dither(tunedPixels, width: targetWidth, height: targetHeight, palette: palette)
            : tunedPixels.map { nearestColor(for: $0, in: palette) }

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
        let colorCount = max(4, min(maxColors, 128))
        let sample = sampledPixels(from: pixels, limit: 8_000)
        guard !sample.isEmpty else {
            return [CellColor(red: 255, green: 255, blue: 255)]
        }

        var centroids = initialCentroids(from: sample, count: colorCount)
        if centroids.isEmpty {
            return [CellColor(red: 255, green: 255, blue: 255)]
        }

        for _ in 0..<8 {
            var sums = Array(repeating: ColorSum(), count: centroids.count)
            for pixel in sample {
                let nearest = nearestIndex(for: pixel.vector, in: centroids)
                sums[nearest].add(pixel.vector)
            }

            for index in centroids.indices {
                if sums[index].count > 0 {
                    centroids[index] = sums[index].average
                }
            }
        }

        var seen = Set<CellColor>()
        let palette = centroids
            .map { $0.color }
            .filter { seen.insert($0).inserted }
            .sorted { luminance($0) < luminance($1) }
        return palette.isEmpty ? [CellColor(red: 255, green: 255, blue: 255)] : palette
    }

    private func sampledPixels(from pixels: [CellColor], limit: Int) -> [CellColor] {
        guard pixels.count > limit else { return pixels }
        let step = max(1, pixels.count / limit)
        return stride(from: 0, to: pixels.count, by: step).map { pixels[$0] }
    }

    private func initialCentroids(from pixels: [CellColor], count: Int) -> [ColorVector] {
        let bucketed = pixels.map { color in
            CellColor(red: color.red / 16 * 16, green: color.green / 16 * 16, blue: color.blue / 16 * 16)
        }
        let counts = Dictionary(grouping: bucketed, by: { $0 }).mapValues(\.count)
        let frequent = counts.sorted { first, second in
            if first.value == second.value {
                return luminance(first.key) < luminance(second.key)
            }
            return first.value > second.value
        }
        return frequent.prefix(count).map { $0.key.vector }
    }

    private func dither(_ pixels: [CellColor], width: Int, height: Int, palette: [CellColor]) -> [CellColor] {
        var buffer = pixels.map(\.vector)
        var output = Array(repeating: CellColor(red: 255, green: 255, blue: 255), count: pixels.count)

        for row in 0..<height {
            for column in 0..<width {
                let index = row * width + column
                let old = buffer[index].clamped
                let newColor = nearestColor(for: old.color, in: palette)
                let newVector = newColor.vector
                output[index] = newColor
                let error = old - newVector

                add(error, factor: 7.0 / 16.0, to: &buffer, row: row, column: column + 1, width: width, height: height)
                add(error, factor: 3.0 / 16.0, to: &buffer, row: row + 1, column: column - 1, width: width, height: height)
                add(error, factor: 5.0 / 16.0, to: &buffer, row: row + 1, column: column, width: width, height: height)
                add(error, factor: 1.0 / 16.0, to: &buffer, row: row + 1, column: column + 1, width: width, height: height)
            }
        }

        return output
    }

    private func add(_ error: ColorVector, factor: Double, to buffer: inout [ColorVector], row: Int, column: Int, width: Int, height: Int) {
        guard row >= 0, row < height, column >= 0, column < width else { return }
        let index = row * width + column
        buffer[index] = buffer[index] + error * factor
    }

    private func nearestColor(for color: CellColor, in palette: [CellColor]) -> CellColor {
        palette.min { distance(color, $0) < distance(color, $1) } ?? color
    }

    private func nearestIndex(for vector: ColorVector, in palette: [ColorVector]) -> Int {
        var bestIndex = 0
        var bestDistance = Double.greatestFiniteMagnitude
        for (index, candidate) in palette.enumerated() {
            let current = distance(vector, candidate)
            if current < bestDistance {
                bestDistance = current
                bestIndex = index
            }
        }
        return bestIndex
    }

    private func distance(_ a: CellColor, _ b: CellColor) -> Int {
        let red = Int(a.red) - Int(b.red)
        let green = Int(a.green) - Int(b.green)
        let blue = Int(a.blue) - Int(b.blue)
        return red * red * 3 + green * green * 4 + blue * blue * 2
    }

    private func distance(_ a: ColorVector, _ b: ColorVector) -> Double {
        let red = a.red - b.red
        let green = a.green - b.green
        let blue = a.blue - b.blue
        return red * red * 3 + green * green * 4 + blue * blue * 2
    }

    private func enhance(_ color: CellColor, contrast: Double, saturation: Double) -> CellColor {
        let red = Double(color.red)
        let green = Double(color.green)
        let blue = Double(color.blue)
        let luma = red * 0.299 + green * 0.587 + blue * 0.114

        func channel(_ value: Double) -> UInt8 {
            let saturated = luma + (value - luma) * saturation
            let contrasted = (saturated - 128.0) * contrast + 128.0
            return UInt8(max(0, min(255, round(contrasted))))
        }

        return CellColor(red: channel(red), green: channel(green), blue: channel(blue))
    }

    private func luminance(_ color: CellColor) -> Double {
        Double(color.red) * 0.299 + Double(color.green) * 0.587 + Double(color.blue) * 0.114
    }
}

private struct ColorVector {
    var red: Double
    var green: Double
    var blue: Double

    var clamped: ColorVector {
        ColorVector(
            red: max(0, min(255, red)),
            green: max(0, min(255, green)),
            blue: max(0, min(255, blue))
        )
    }

    var color: CellColor {
        let safe = clamped
        return CellColor(
            red: UInt8(max(0, min(255, round(safe.red)))),
            green: UInt8(max(0, min(255, round(safe.green)))),
            blue: UInt8(max(0, min(255, round(safe.blue))))
        )
    }

    static func + (left: ColorVector, right: ColorVector) -> ColorVector {
        ColorVector(red: left.red + right.red, green: left.green + right.green, blue: left.blue + right.blue)
    }

    static func - (left: ColorVector, right: ColorVector) -> ColorVector {
        ColorVector(red: left.red - right.red, green: left.green - right.green, blue: left.blue - right.blue)
    }

    static func * (left: ColorVector, factor: Double) -> ColorVector {
        ColorVector(red: left.red * factor, green: left.green * factor, blue: left.blue * factor)
    }
}

private struct ColorSum {
    var red: Double = 0
    var green: Double = 0
    var blue: Double = 0
    var count: Double = 0

    mutating func add(_ vector: ColorVector) {
        red += vector.red
        green += vector.green
        blue += vector.blue
        count += 1
    }

    var average: ColorVector {
        ColorVector(red: red / count, green: green / count, blue: blue / count)
    }
}

private extension CellColor {
    var vector: ColorVector {
        ColorVector(red: Double(red), green: Double(green), blue: Double(blue))
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
