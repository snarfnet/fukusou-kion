import SwiftUI
import UIKit

enum GhostRenderer {
    static func draw(in context: inout GraphicsContext, canvasSize: CGSize, point: PersonTrackPoint?, settings: GhostSettings, time: Double) {
        guard let point, let uiImage = ghostImage(for: settings) else { return }
        let frame = ghostFrame(for: point, imageSize: uiImage.size, canvasSize: canvasSize, settings: settings, time: time)
        let image = Image(uiImage: uiImage)

        context.drawLayer { layer in
            layer.addFilter(.blur(radius: settings.facing == .front ? 18 : 12))
            layer.opacity = settings.opacity * 0.32
            layer.draw(image, in: frame.insetBy(dx: -18, dy: -18))
        }

        context.opacity = settings.opacity
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
            cg.setAlpha(settings.opacity)
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
            let pulse = 1.0 + (sin(time * 2.2) + 1.0) * 0.05
            let height = max(canvasSize.height * 0.30, person.height * settings.scale * 1.18) * pulse
            let width = height * aspect
            let x = person.midX - width / 2 + wobble + person.width * settings.horizontalOffset * 0.25
            let y = person.midY - height * 0.55 + person.height * settings.verticalOffset
            return CGRect(x: x, y: y, width: width, height: height)

        case .side:
            let height = max(canvasSize.height * 0.22, person.height * settings.scale * 0.92)
            let width = height * aspect
            let x = person.midX - width * 0.56 + person.width * settings.horizontalOffset + wobble
            let y = person.midY - height * 0.52 + person.height * settings.verticalOffset
            return CGRect(x: x, y: y, width: width, height: height)
        }
    }
}
