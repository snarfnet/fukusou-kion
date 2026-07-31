import CoreGraphics
import UIKit

enum SizeReference: String, CaseIterable, Identifiable {
    case none = "基準なし"
    case tenYen = "10円玉 23.5mm"
    case looseCase = "ルースケース 20mm"
    case ruler = "定規目盛 30mm"

    var id: String { rawValue }

    var millimeters: Double? {
        switch self {
        case .none: return nil
        case .tenYen: return 23.5
        case .looseCase: return 20
        case .ruler: return 30
        }
    }
}

enum ImageClassifier {
    private struct PixelSample {
        let x: Int
        let y: Int
        let red: Double
        let green: Double
        let blue: Double
        let hue: Double
        let saturation: Double
        let brightness: Double
    }

    private struct BackgroundProfile {
        let red: Double
        let green: Double
        let blue: Double
        let saturation: Double
        let brightness: Double
    }

    static func classify(_ image: UIImage, reference: SizeReference) -> (metrics: ScanMetrics, candidates: [StoneCandidate]) {
        let metrics = analyze(image, reference: reference)
        let candidates = GemstoneDatabase.stones
            .map { StoneCandidate(gemstone: $0, score: score($0, metrics: metrics)) }
            .sorted { $0.score > $1.score }
            .prefix(5)
        return (metrics, Array(candidates))
    }

    private static func analyze(_ image: UIImage, reference: SizeReference) -> ScanMetrics {
        let width = 180
        let height = 180
        let size = CGSize(width: width, height: height)
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixels = [UInt8](repeating: 0, count: height * bytesPerRow)

        let didRender = pixels.withUnsafeMutableBytes { rawBuffer in
            guard let baseAddress = rawBuffer.baseAddress,
                  let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
                  let context = CGContext(
                    data: baseAddress,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: bytesPerRow,
                    space: colorSpace,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                  ) else {
                return false
            }

            context.setFillColor(UIColor.black.cgColor)
            context.fill(CGRect(origin: .zero, size: size))
            UIGraphicsPushContext(context)
            let imageSize = image.size
            let scale = min(size.width / imageSize.width, size.height / imageSize.height)
            let drawSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
            let origin = CGPoint(x: (size.width - drawSize.width) / 2, y: (size.height - drawSize.height) / 2)
            image.draw(in: CGRect(origin: origin, size: drawSize))
            UIGraphicsPopContext()
            return true
        }

        guard didRender else {
            return ScanMetrics(hue: 0, saturation: 0, brightness: 0, clarityScore: 0, levelScore: 0, coverageScore: 0, estimatedMillimeters: nil)
        }

        var samples: [PixelSample] = []
        samples.reserveCapacity((width / 2) * (height / 2))

        for y in stride(from: 0, to: height, by: 2) {
            for x in stride(from: 0, to: width, by: 2) {
                let offset = y * bytesPerRow + x * bytesPerPixel
                let red = CGFloat(pixels[offset]) / 255
                let green = CGFloat(pixels[offset + 1]) / 255
                let blue = CGFloat(pixels[offset + 2]) / 255
                let hsb = hsbFromRGB(red: red, green: green, blue: blue)
                samples.append(
                    PixelSample(
                        x: x,
                        y: y,
                        red: Double(red),
                        green: Double(green),
                        blue: Double(blue),
                        hue: hsb.hue,
                        saturation: hsb.saturation,
                        brightness: hsb.brightness
                    )
                )
            }
        }

        let background = backgroundProfile(from: samples, width: width, height: height)
        var foreground: [PixelSample] = []
        foreground.reserveCapacity(samples.count / 3)
        var minX = width
        var minY = height
        var maxX = 0
        var maxY = 0

        for sample in samples where isForeground(sample, background: background, width: width, height: height) {
            foreground.append(sample)
            minX = min(minX, sample.x)
            minY = min(minY, sample.y)
            maxX = max(maxX, sample.x)
            maxY = max(maxY, sample.y)
        }

        if foreground.count < 70 {
            foreground.removeAll(keepingCapacity: true)
            minX = width
            minY = height
            maxX = 0
            maxY = 0
            for sample in samples where isFallbackForeground(sample, width: width, height: height) {
                foreground.append(sample)
                minX = min(minX, sample.x)
                minY = min(minY, sample.y)
                maxX = max(maxX, sample.x)
                maxY = max(maxY, sample.y)
            }
        }

        let measuredSamples = foreground.isEmpty ? samples : foreground
        var hueX = 0.0
        var hueY = 0.0
        var hueWeightTotal = 0.0
        var saturationTotal = 0.0
        var brightnessTotal = 0.0
        var sampleWeightTotal = 0.0

        for sample in measuredSamples {
            let contrast = colorDistance(sample, background: background)
            let center = centerWeight(x: sample.x, y: sample.y, width: width, height: height)
            let sampleWeight = max(0.2, center + contrast)
            let hueWeight = max(0, sample.saturation - 8) * sampleWeight
            let radians = sample.hue * .pi / 180
            hueX += cos(radians) * hueWeight
            hueY += sin(radians) * hueWeight
            hueWeightTotal += hueWeight
            saturationTotal += sample.saturation * sampleWeight
            brightnessTotal += sample.brightness * sampleWeight
            sampleWeightTotal += sampleWeight
        }

        var hue = atan2(hueY, hueX) * 180 / .pi
        if hue < 0 { hue += 360 }
        if hueWeightTotal == 0 {
            hue = 0
        }

        let saturation = saturationTotal / max(sampleWeightTotal, 1)
        let brightness = brightnessTotal / max(sampleWeightTotal, 1)
        let coverage = Double(foreground.count) / max(Double(samples.count), 1)
        let bounding = foreground.isEmpty ? 0 : max(Double(maxX - minX) / Double(width), Double(maxY - minY) / Double(height))
        let clarity = Int(min(100, max(8, brightness * 0.72 + saturation * 0.32)))
        let level = Int(min(100, max(10, Double(clarity) * 0.55 + saturation * 0.45 + coverage * 8)))
        let coverageScore = Int(min(100, max(0, bounding * 100)))
        let estimated = reference.millimeters.map { Int(max(1, round($0 * max(0.45, bounding * 1.8)))) }

        return ScanMetrics(
            hue: hue,
            saturation: saturation,
            brightness: brightness,
            clarityScore: clarity,
            levelScore: level,
            coverageScore: coverageScore,
            estimatedMillimeters: estimated
        )
    }

    private static func hsbFromRGB(red: CGFloat, green: CGFloat, blue: CGFloat) -> (hue: Double, saturation: Double, brightness: Double) {
        let maxValue = max(red, green, blue)
        let minValue = min(red, green, blue)
        let delta = maxValue - minValue
        var hue: CGFloat = 0

        if delta != 0 {
            if maxValue == red {
                hue = ((green - blue) / delta).truncatingRemainder(dividingBy: 6)
            } else if maxValue == green {
                hue = (blue - red) / delta + 2
            } else {
                hue = (red - green) / delta + 4
            }
            hue *= 60
            if hue < 0 { hue += 360 }
        }

        let saturation = maxValue == 0 ? 0 : delta / maxValue
        return (Double(hue), Double(saturation * 100), Double(maxValue * 100))
    }

    private static func backgroundProfile(from samples: [PixelSample], width: Int, height: Int) -> BackgroundProfile {
        let border = samples.filter { sample in
            sample.x < 18 || sample.y < 18 || sample.x > width - 20 || sample.y > height - 20
        }
        let source = border.isEmpty ? samples : border
        let count = Double(max(source.count, 1))
        return BackgroundProfile(
            red: source.reduce(0) { $0 + $1.red } / count,
            green: source.reduce(0) { $0 + $1.green } / count,
            blue: source.reduce(0) { $0 + $1.blue } / count,
            saturation: source.reduce(0) { $0 + $1.saturation } / count,
            brightness: source.reduce(0) { $0 + $1.brightness } / count
        )
    }

    private static func isForeground(_ sample: PixelSample, background: BackgroundProfile, width: Int, height: Int) -> Bool {
        let x = Double(sample.x) / Double(width)
        let y = Double(sample.y) / Double(height)
        let inGuide = abs(x - 0.5) < 0.43 && abs(y - 0.5) < 0.43
        guard inGuide, sample.brightness > 5, sample.brightness < 98 else { return false }

        let colorContrast = colorDistance(sample, background: background)
        let brightnessContrast = abs(sample.brightness - background.brightness)
        let saturationLift = sample.saturation - background.saturation
        return colorContrast > 0.16 || brightnessContrast > 16 || saturationLift > 7 || sample.saturation > 34
    }

    private static func isFallbackForeground(_ sample: PixelSample, width: Int, height: Int) -> Bool {
        let x = Double(sample.x) / Double(width)
        let y = Double(sample.y) / Double(height)
        let centerDistance = abs(x - 0.5) + abs(y - 0.5)
        return centerDistance < 0.54 && sample.brightness > 7 && sample.brightness < 97 && sample.saturation > 10
    }

    private static func centerWeight(x: Int, y: Int, width: Int, height: Int) -> Double {
        let dx = abs(Double(x) / Double(width) - 0.5)
        let dy = abs(Double(y) / Double(height) - 0.5)
        return max(0.15, 1.0 - (dx + dy) * 1.35)
    }

    private static func colorDistance(_ sample: PixelSample, background: BackgroundProfile) -> Double {
        let red = sample.red - background.red
        let green = sample.green - background.green
        let blue = sample.blue - background.blue
        return sqrt(red * red + green * green + blue * blue)
    }

    private static func score(_ stone: Gemstone, metrics: ScanMetrics) -> Int {
        let hueScore: Double
        if stone.hueRange.lowerBound == 0, stone.hueRange.upperBound == 360 {
            hueScore = metrics.saturation < 24 ? 44 : 32
        } else if hueMatches(metrics.hue, range: stone.hueRange) {
            hueScore = 62
        } else {
            let center = hueCenter(stone.hueRange)
            hueScore = max(0, 62 - hueDistance(metrics.hue, center) * 0.75)
        }

        let saturationCenter = (stone.saturationRange.lowerBound + stone.saturationRange.upperBound) / 2
        let saturationScore = max(0, 24 - abs(metrics.saturation - saturationCenter) * 0.26)
        let brightnessBonus = stone.colors.contains("黒") && metrics.brightness < 28 ? 18 : 0
        let mixedBonus = (stone.colors.contains("虹") || stone.colors.contains("多色")) && metrics.saturation > 28 ? 12 : 0
        let clearBonus = (stone.colors.contains("無色") || stone.colors.contains("白")) && metrics.saturation < 20 && metrics.brightness > 45 ? 15 : 0
        let raw = hueScore + saturationScore + Double(brightnessBonus + mixedBonus + clearBonus) + Double(metrics.coverageScore) * 0.08
        return Int(min(99, max(8, round(raw))))
    }

    private static func hueDistance(_ a: Double, _ b: Double) -> Double {
        let diff = abs(a - b)
        return min(diff, 360 - diff)
    }

    private static func hueMatches(_ hue: Double, range: ClosedRange<Double>) -> Bool {
        if range.contains(hue) {
            return true
        }
        if range.lowerBound >= 300, hue <= 30 {
            return true
        }
        return false
    }

    private static func hueCenter(_ range: ClosedRange<Double>) -> Double {
        if range.lowerBound >= 300 {
            return ((range.lowerBound + range.upperBound + 360) / 2).truncatingRemainder(dividingBy: 360)
        }
        return (range.lowerBound + range.upperBound) / 2
    }
}
