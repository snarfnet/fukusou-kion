import Foundation
import UIKit

enum APNGStickerRenderer {
    static func duration(settings: StickerSettings) -> Double {
        let base = 1.2 / max(0.35, settings.speed)
        return min(4.0, max(0.5, base))
    }

    static func delay(settings: StickerSettings) -> TimeInterval {
        duration(settings: settings) / Double(settings.frameCount)
    }

    static func frames(from source: UIImage, settings: StickerSettings) -> [UIImage] {
        (0..<settings.frameCount).map { index in
            let progress = Double(index) / Double(max(1, settings.frameCount - 1))
            return frame(from: source, settings: settings, progress: progress, index: index)
        }
    }

    static func frame(from source: UIImage, settings: StickerSettings, progress: Double, index: Int) -> UIImage {
        let size = LineStickerSpec.canvasSize
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = settings.background != .transparent

        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            let rect = CGRect(origin: .zero, size: size)
            settings.background.color.setFill()
            UIRectFill(rect)

            drawDecorations(effect: settings.effect, strength: settings.strength, progress: progress, index: index, in: rect)
            drawSource(source, settings: settings, progress: progress, in: rect)
            drawForeground(effect: settings.effect, strength: settings.strength, progress: progress, index: index, in: rect)
        }
    }

    private static func drawSource(_ image: UIImage, settings: StickerSettings, progress: Double, in rect: CGRect) {
        let imageRect = aspectFitRect(imageSize: image.size, in: rect.insetBy(dx: 18, dy: 18))
        let transform = transformFor(effect: settings.effect, strength: settings.strength, progress: progress, rect: rect)
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        context?.translateBy(x: rect.midX + transform.offset.width, y: rect.midY + transform.offset.height)
        context?.rotate(by: transform.rotation)
        context?.scaleBy(x: transform.scale, y: transform.scale)
        context?.translateBy(x: -rect.midX, y: -rect.midY)
        image.draw(in: imageRect)
        context?.restoreGState()
    }

    private static func transformFor(effect: StickerEffect, strength: Double, progress: Double, rect: CGRect) -> (scale: CGFloat, rotation: CGFloat, offset: CGSize) {
        let wave = sin(progress * .pi * 2)
        let punch = sin(progress * .pi)
        let power = CGFloat(strength)

        switch effect {
        case .pop:
            return (0.84 + 0.20 * CGFloat(punch) * power, 0, .zero)
        case .shake:
            return (1, CGFloat(wave) * 0.08 * power, CGSize(width: CGFloat(wave) * 12 * power, height: 0))
        case .bounce:
            return (1 + 0.05 * CGFloat(punch) * power, 0, CGSize(width: 0, height: -CGFloat(punch) * 24 * power))
        case .float:
            return (1, CGFloat(wave) * 0.035 * power, CGSize(width: CGFloat(wave) * 7 * power, height: -CGFloat(punch) * 18 * power))
        case .sparkle, .heart, .confetti:
            return (1 + 0.04 * CGFloat(punch) * power, 0, .zero)
        }
    }

    private static func drawDecorations(effect: StickerEffect, strength: Double, progress: Double, index: Int, in rect: CGRect) {
        guard effect == .confetti else { return }

        for item in 0..<18 {
            let seed = Double(item)
            let x = CGFloat((seed * 37).truncatingRemainder(dividingBy: Double(rect.width)))
            let travel = CGFloat(progress) * rect.height * (0.7 + CGFloat((seed.truncatingRemainder(dividingBy: 5)) / 10))
            let y = CGFloat((seed * 29).truncatingRemainder(dividingBy: 80)) + travel - 24
            let hue = CGFloat((seed * 0.13).truncatingRemainder(dividingBy: 1))
            UIColor(hue: hue, saturation: 0.55, brightness: 0.95, alpha: 0.75).setFill()

            let center = CGPoint(x: x, y: y.truncatingRemainder(dividingBy: rect.height + 30) - 15)
            let piece = CGRect(x: center.x - 4, y: center.y - 7, width: 8, height: 14)
            let path = UIBezierPath(roundedRect: piece, cornerRadius: 2)
            rotate(path, around: center, angle: CGFloat(seed + Double(index)) * 0.21)
            path.fill()
        }
    }

    private static func drawForeground(effect: StickerEffect, strength: Double, progress: Double, index: Int, in rect: CGRect) {
        switch effect {
        case .sparkle:
            drawSparkles(strength: strength, progress: progress, index: index, in: rect)
        case .heart:
            drawHearts(strength: strength, progress: progress, index: index, in: rect)
        default:
            return
        }
    }

    private static func drawSparkles(strength: Double, progress: Double, index: Int, in rect: CGRect) {
        let alpha = CGFloat(0.35 + 0.45 * sin(progress * .pi))
        UIColor(red: 1, green: 0.86, blue: 0.25, alpha: alpha).setFill()

        for item in 0..<7 {
            let seed = CGFloat(item + index)
            let x = rect.width * (0.18 + CGFloat(item % 4) * 0.20)
            let y = rect.height * (0.18 + CGFloat((item * 2) % 5) * 0.13)
            let radius = CGFloat(5 + (item % 3) * 3) * CGFloat(strength)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: x, y: y - radius * 2))
            path.addLine(to: CGPoint(x: x + radius, y: y))
            path.addLine(to: CGPoint(x: x, y: y + radius * 2))
            path.addLine(to: CGPoint(x: x - radius, y: y))
            path.close()
            rotate(path, around: CGPoint(x: x, y: y), angle: seed * 0.17)
            path.fill()
        }
    }

    private static func drawHearts(strength: Double, progress: Double, index: Int, in rect: CGRect) {
        UIColor(red: 1, green: 0.22, blue: 0.38, alpha: 0.78).setFill()

        for item in 0..<6 {
            let baseX = rect.width * (0.18 + CGFloat(item % 3) * 0.30)
            let rise = CGFloat(progress) * 48 * CGFloat(strength)
            let baseY = rect.height * (0.78 - CGFloat(item / 3) * 0.32) - rise
            let size = CGFloat(11 + item * 2)
            let offset = CGFloat(sin((progress * 2 + Double(item)) * .pi)) * 8
            drawHeart(center: CGPoint(x: baseX + offset, y: baseY), size: size, rotation: CGFloat(index + item) * 0.08)
        }
    }

    private static func drawHeart(center: CGPoint, size: CGFloat, rotation: CGFloat) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: center.x, y: center.y + size * 0.45))
        path.addCurve(
            to: CGPoint(x: center.x - size, y: center.y - size * 0.10),
            controlPoint1: CGPoint(x: center.x - size * 0.85, y: center.y),
            controlPoint2: CGPoint(x: center.x - size, y: center.y - size * 0.75)
        )
        path.addCurve(
            to: CGPoint(x: center.x, y: center.y - size * 0.35),
            controlPoint1: CGPoint(x: center.x - size, y: center.y - size * 0.95),
            controlPoint2: CGPoint(x: center.x - size * 0.35, y: center.y - size * 1.05)
        )
        path.addCurve(
            to: CGPoint(x: center.x + size, y: center.y - size * 0.10),
            controlPoint1: CGPoint(x: center.x + size * 0.35, y: center.y - size * 1.05),
            controlPoint2: CGPoint(x: center.x + size, y: center.y - size * 0.95)
        )
        path.addCurve(
            to: CGPoint(x: center.x, y: center.y + size * 0.45),
            controlPoint1: CGPoint(x: center.x + size, y: center.y - size * 0.75),
            controlPoint2: CGPoint(x: center.x + size * 0.85, y: center.y)
        )
        path.apply(CGAffineTransform(translationX: -center.x, y: -center.y))
        path.apply(CGAffineTransform(rotationAngle: rotation))
        path.apply(CGAffineTransform(translationX: center.x, y: center.y))
        path.fill()
    }

    private static func rotate(_ path: UIBezierPath, around center: CGPoint, angle: CGFloat) {
        path.apply(CGAffineTransform(translationX: -center.x, y: -center.y))
        path.apply(CGAffineTransform(rotationAngle: angle))
        path.apply(CGAffineTransform(translationX: center.x, y: center.y))
    }

    private static func aspectFitRect(imageSize: CGSize, in rect: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return rect }
        let scale = min(rect.width / imageSize.width, rect.height / imageSize.height)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        return CGRect(
            x: rect.midX - size.width / 2,
            y: rect.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
    }
}
