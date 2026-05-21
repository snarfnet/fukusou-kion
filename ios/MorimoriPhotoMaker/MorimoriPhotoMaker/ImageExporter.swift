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
        guard let image = BundleImage.load(layer.asset.filename, folder: "Overlays") else { return }

        context.saveGState()
        context.setAlpha(layer.opacity)
        defer { context.restoreGState() }

        if layer.isBackground {
            drawAspectFill(image, in: rect)
            return
        }

        let width = rect.width * layer.widthRatio
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
    static func load(_ filename: String, folder: String) -> UIImage? {
        let nsName = filename as NSString
        let name = nsName.deletingPathExtension
        let ext = nsName.pathExtension
        let subdirectories: [String?] = ["Resources/\(folder)", folder, nil]
        for subdirectory in subdirectories {
            if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: subdirectory) {
                return UIImage(contentsOfFile: url.path)
            }
        }
        return UIImage(named: name)
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
