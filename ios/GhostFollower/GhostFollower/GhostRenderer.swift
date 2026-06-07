import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

enum GhostRenderer {
    static func draw(in context: inout GraphicsContext, canvasSize: CGSize, point: PersonTrackPoint?, settings: GhostSettings, time: Double) {
        guard let point else { return }
        let frame = ghostFrame(for: point, canvasSize: canvasSize, settings: settings, time: time)
        let color = settings.style.tint.opacity(settings.opacity)

        context.drawLayer { layer in
            layer.addFilter(.blur(radius: 10))
            layer.opacity = settings.opacity * 0.42
            layer.fill(Path(ellipseIn: frame.insetBy(dx: -16, dy: -24)), with: .color(color))
        }
        context.opacity = settings.opacity
        drawGhostShape(in: &context, frame: frame, style: settings.style, color: color)
    }

    static func makeOverlayImage(size: CGSize, point: PersonTrackPoint?, settings: GhostSettings, time: Double) -> UIImage? {
        guard let point else { return nil }
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { rendererContext in
            let cg = rendererContext.cgContext
            cg.clear(CGRect(origin: .zero, size: size))
            let frame = ghostFrame(for: point, canvasSize: size, settings: settings, time: time)
            drawCGGhost(in: cg, frame: frame, style: settings.style, opacity: settings.opacity)
        }
    }

    static func nearestPoint(at seconds: Double, in points: [PersonTrackPoint]) -> PersonTrackPoint? {
        guard !points.isEmpty else { return nil }
        return points.min { abs($0.time - seconds) < abs($1.time - seconds) }
    }

    private static func ghostFrame(for point: PersonTrackPoint, canvasSize: CGSize, settings: GhostSettings, time: Double) -> CGRect {
        let person = CGRect(
            x: point.boundingBox.minX * canvasSize.width,
            y: (1 - point.boundingBox.maxY) * canvasSize.height,
            width: point.boundingBox.width * canvasSize.width,
            height: point.boundingBox.height * canvasSize.height
        )
        let wobble = sin(time * 11.0) * settings.jitter * person.width
        let width = max(70, person.width * settings.scale)
        let height = max(130, person.height * settings.scale)
        let x = person.midX - width / 2 + person.width * settings.horizontalOffset + wobble
        let y = person.midY - height / 2 + person.height * settings.verticalOffset
        return CGRect(x: x, y: y, width: width, height: height)
    }

    private static func drawGhostShape(in context: inout GraphicsContext, frame: CGRect, style: GhostStyle, color: Color) {
        var body = Path()
        body.move(to: CGPoint(x: frame.midX, y: frame.minY))
        body.addCurve(to: CGPoint(x: frame.minX + frame.width * 0.18, y: frame.minY + frame.height * 0.34),
                      control1: CGPoint(x: frame.minX + frame.width * 0.28, y: frame.minY + frame.height * 0.04),
                      control2: CGPoint(x: frame.minX + frame.width * 0.11, y: frame.minY + frame.height * 0.18))
        body.addCurve(to: CGPoint(x: frame.minX + frame.width * 0.28, y: frame.maxY),
                      control1: CGPoint(x: frame.minX + frame.width * 0.06, y: frame.minY + frame.height * 0.62),
                      control2: CGPoint(x: frame.minX + frame.width * 0.20, y: frame.minY + frame.height * 0.84))
        body.addQuadCurve(to: CGPoint(x: frame.midX, y: frame.maxY - frame.height * 0.08),
                          control: CGPoint(x: frame.minX + frame.width * 0.40, y: frame.maxY - frame.height * 0.18))
        body.addQuadCurve(to: CGPoint(x: frame.maxX - frame.width * 0.22, y: frame.maxY),
                          control: CGPoint(x: frame.maxX - frame.width * 0.36, y: frame.maxY - frame.height * 0.02))
        body.addCurve(to: CGPoint(x: frame.maxX - frame.width * 0.18, y: frame.minY + frame.height * 0.34),
                      control1: CGPoint(x: frame.maxX - frame.width * 0.08, y: frame.minY + frame.height * 0.80),
                      control2: CGPoint(x: frame.maxX - frame.width * 0.06, y: frame.minY + frame.height * 0.58))
        body.addCurve(to: CGPoint(x: frame.midX, y: frame.minY),
                      control1: CGPoint(x: frame.maxX - frame.width * 0.10, y: frame.minY + frame.height * 0.18),
                      control2: CGPoint(x: frame.maxX - frame.width * 0.30, y: frame.minY + frame.height * 0.04))
        body.closeSubpath()

        context.fill(body, with: .color(color))
        context.stroke(body, with: .color(.white.opacity(style == .shadowCrawler ? 0.12 : 0.35)), lineWidth: 1.5)

        let eyeY = frame.minY + frame.height * 0.28
        let eyeW = frame.width * 0.08
        let eyeColor: Color = style == .redMask ? .black : .red.opacity(0.82)
        context.fill(Path(ellipseIn: CGRect(x: frame.midX - frame.width * 0.18, y: eyeY, width: eyeW, height: eyeW * 1.7)), with: .color(eyeColor))
        context.fill(Path(ellipseIn: CGRect(x: frame.midX + frame.width * 0.10, y: eyeY, width: eyeW, height: eyeW * 1.7)), with: .color(eyeColor))

        if style == .staticNoise {
            for index in 0..<8 {
                let y = frame.minY + CGFloat(index) * frame.height / 8
                let line = Path(CGRect(x: frame.minX + CGFloat(index % 3) * 7, y: y, width: frame.width * 0.84, height: 1))
                context.fill(line, with: .color(.white.opacity(0.4)))
            }
        }
    }

    private static func drawCGGhost(in cg: CGContext, frame: CGRect, style: GhostStyle, opacity: Double) {
        cg.saveGState()
        cg.setAlpha(opacity)
        let tint = UIColor(style.tint).withAlphaComponent(opacity)
        cg.setFillColor(tint.cgColor)
        cg.setShadow(offset: .zero, blur: 18, color: tint.withAlphaComponent(0.5).cgColor)

        let path = UIBezierPath()
        path.move(to: CGPoint(x: frame.midX, y: frame.minY))
        path.addCurve(to: CGPoint(x: frame.minX + frame.width * 0.17, y: frame.minY + frame.height * 0.35),
                      controlPoint1: CGPoint(x: frame.minX + frame.width * 0.30, y: frame.minY + frame.height * 0.02),
                      controlPoint2: CGPoint(x: frame.minX + frame.width * 0.10, y: frame.minY + frame.height * 0.17))
        path.addCurve(to: CGPoint(x: frame.minX + frame.width * 0.27, y: frame.maxY),
                      controlPoint1: CGPoint(x: frame.minX + frame.width * 0.04, y: frame.minY + frame.height * 0.62),
                      controlPoint2: CGPoint(x: frame.minX + frame.width * 0.18, y: frame.minY + frame.height * 0.84))
        path.addQuadCurve(to: CGPoint(x: frame.midX, y: frame.maxY - frame.height * 0.08),
                          controlPoint: CGPoint(x: frame.minX + frame.width * 0.40, y: frame.maxY - frame.height * 0.18))
        path.addQuadCurve(to: CGPoint(x: frame.maxX - frame.width * 0.20, y: frame.maxY),
                          controlPoint: CGPoint(x: frame.maxX - frame.width * 0.35, y: frame.maxY - frame.height * 0.02))
        path.addCurve(to: CGPoint(x: frame.maxX - frame.width * 0.17, y: frame.minY + frame.height * 0.35),
                      controlPoint1: CGPoint(x: frame.maxX - frame.width * 0.06, y: frame.minY + frame.height * 0.80),
                      controlPoint2: CGPoint(x: frame.maxX - frame.width * 0.04, y: frame.minY + frame.height * 0.58))
        path.addCurve(to: CGPoint(x: frame.midX, y: frame.minY),
                      controlPoint1: CGPoint(x: frame.maxX - frame.width * 0.10, y: frame.minY + frame.height * 0.17),
                      controlPoint2: CGPoint(x: frame.maxX - frame.width * 0.30, y: frame.minY + frame.height * 0.02))
        path.close()
        path.fill()

        cg.setShadow(offset: .zero, blur: 0, color: nil)
        cg.setFillColor((style == .redMask ? UIColor.black : UIColor.red).withAlphaComponent(0.82).cgColor)
        let eyeY = frame.minY + frame.height * 0.28
        let eyeW = frame.width * 0.08
        cg.fillEllipse(in: CGRect(x: frame.midX - frame.width * 0.18, y: eyeY, width: eyeW, height: eyeW * 1.7))
        cg.fillEllipse(in: CGRect(x: frame.midX + frame.width * 0.10, y: eyeY, width: eyeW, height: eyeW * 1.7))
        cg.restoreGState()
    }
}
