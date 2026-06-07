import SwiftUI
import UIKit

enum GhostRenderer {
    static func draw(in context: inout GraphicsContext, canvasSize: CGSize, point: PersonTrackPoint?, settings: GhostSettings, time: Double) {
        guard let point, let uiImage = ghostImage(for: settings) else { return }
        let frame = ghostFrame(for: point, imageSize: uiImage.size, canvasSize: canvasSize, settings: settings, time: time)
        let image = Image(uiImage: uiImage)
        let opacity = effectiveOpacity(settings: settings, time: time)
        let blurRadius = settings.facing == .front ? 20.0 : 14.0

        context.drawLayer { layer in
            layer.addFilter(.blur(radius: blurRadius))
            layer.blendMode = .screen
            layer.opacity = opacity * 0.28
            layer.draw(image, in: frame.insetBy(dx: -22, dy: -22))
        }

        context.drawLayer { layer in
            layer.blendMode = .plusLighter
            layer.opacity = opacity * 0.16
            layer.draw(image, in: frame.offsetBy(dx: -8, dy: 4))
            layer.draw(image, in: frame.offsetBy(dx: 8, dy: -4))
        }

        context.blendMode = .screen
        context.opacity = opacity
        context.draw(image, in: frame)
    }

    static func makeOverlayImage(size: CGSize, point: PersonTrackPoint?, settings: GhostSettings, time: Double) -> UIImage? {
        guard let point, let image = ghostImage(for: settings) else { return nil }
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { rendererContext in
            let cg = rendererContext.cgContext
            cg.clear(CGRect(origin: .zero, size: size))
            let frame = ghostFrame(for: point, imageSize: image.size, canvasSize: size, settings: settings, time: time)
            cg.saveGState()
            cg.setBlendMode(.screen)
            cg.setAlpha(effectiveOpacity(settings: settings, time: time) * 0.24)
            image.draw(in: frame.insetBy(dx: -18, dy: -18))
            cg.setBlendMode(.plusLighter)
            cg.setAlpha(effectiveOpacity(settings: settings, time: time) * 0.14)
            image.draw(in: frame.offsetBy(dx: -8, dy: 4))
            image.draw(in: frame.offsetBy(dx: 8, dy: -4))
            cg.setBlendMode(.screen)
            cg.setAlpha(effectiveOpacity(settings: settings, time: time))
            image.draw(in: frame)
            cg.restoreGState()
        }
    }

    static func nearestPoint(at seconds: Double, in points: [PersonTrackPoint]) -> PersonTrackPoint? {
        guard !points.isEmpty else { return nil }
        return points.min { abs($0.time - seconds) < abs($1.time - seconds) }
    }

    private static func ghostImage(for settings: GhostSettings) -> UIImage? {
        UIImage(named: settings.style.assetName(for: settings.facing))
    }

    private static func ghostFrame(
        for point: PersonTrackPoint,
        imageSize: CGSize,
        canvasSize: CGSize,
        settings: GhostSettings,
        time: Double
    ) -> CGRect {
        let person = CGRect(
            x: point.boundingBox.minX * canvasSize.width,
            y: (1 - point.boundingBox.maxY) * canvasSize.height,
            width: point.boundingBox.width * canvasSize.width,
            height: point.boundingBox.height * canvasSize.height
        )
        let aspect = max(0.1, imageSize.width / max(1, imageSize.height))
        let wobble = sin(time * 9.0) * settings.jitter * person.width

        switch settings.facing {
        case .front:
            let approach = approachProgress(at: time)
            let eased = approach * approach * (3 - 2 * approach)
            let distanceScale = 0.42 + eased * 0.78
            let pulse = 1.0 + (sin(time * 2.2) + 1.0) * 0.035
            let height = max(canvasSize.height * 0.30, person.height * settings.scale * 1.18) * distanceScale * pulse
            let width = height * aspect
            let x = person.midX - width / 2 + wobble + person.width * settings.horizontalOffset * 0.25
            let y = person.midY - height * (0.44 + eased * 0.14) + person.height * settings.verticalOffset - canvasSize.height * (1 - eased) * 0.08
            return CGRect(x: x, y: y, width: width, height: height)

        case .side:
            let height = max(canvasSize.height * 0.22, person.height * settings.scale * 0.92)
            let width = height * aspect
            let phase = sideTravelProgress(at: time)
            let startX = -width * 0.95
            let endX = canvasSize.width - width * 0.05
            let x = startX + (endX - startX) * phase + wobble
            let y = person.midY - height * 0.52 + person.height * settings.verticalOffset
            return CGRect(x: x, y: y, width: width, height: height)
        }
    }

    private static func effectiveOpacity(settings: GhostSettings, time: Double) -> Double {
        switch settings.facing {
        case .front:
            let approach = approachProgress(at: time)
            return settings.opacity * (0.36 + approach * 0.64)
        case .side:
            let phase = sideTravelProgress(at: time)
            let edgeFade = min(1, min(phase, 1 - phase) / 0.12)
            return settings.opacity * (0.50 + edgeFade * 0.42)
        }
    }

    private static func approachProgress(at time: Double) -> Double {
        let cycle = 5.6
        return (time.truncatingRemainder(dividingBy: cycle)) / cycle
    }

    private static func sideTravelProgress(at time: Double) -> Double {
        let cycle = 6.8
        return (time.truncatingRemainder(dividingBy: cycle)) / cycle
    }
}
