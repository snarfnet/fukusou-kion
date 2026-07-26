import UIKit
import SwiftUI

enum ImageComposer {
    static func compose(photo: UIImage, garment: UIImage?, offset: CGSize, scale: CGFloat, rotation: Angle) -> UIImage {
        let outputSize = aspectFillSize(for: photo.size, aspect: PhotoCanvas.aspectRatio)
        let format = UIGraphicsImageRendererFormat()
        format.scale = photo.scale
        return UIGraphicsImageRenderer(size: outputSize, format: format).image { context in
            let photoRect = aspectFillRect(imageSize: photo.size, canvasSize: outputSize)
            photo.draw(in: photoRect)
            guard let garment else { return }
            let baseWidth = outputSize.width * 0.88
            let aspect = garment.size.height / garment.size.width
            let size = CGSize(width: baseWidth * scale, height: baseWidth * aspect * scale)
            context.cgContext.saveGState()
            context.cgContext.translateBy(x: outputSize.width / 2 + offset.width * outputSize.width / 390,
                                          y: outputSize.height / 2 + offset.height * outputSize.height / 520)
            context.cgContext.rotate(by: CGFloat(rotation.radians))
            garment.draw(in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))
            context.cgContext.restoreGState()
        }
    }

    private static func aspectFillSize(for size: CGSize, aspect: CGFloat) -> CGSize {
        if size.width / size.height > aspect {
            return CGSize(width: size.height * aspect, height: size.height)
        }
        return CGSize(width: size.width, height: size.width / aspect)
    }

    private static func aspectFillRect(imageSize: CGSize, canvasSize: CGSize) -> CGRect {
        let factor = max(canvasSize.width / imageSize.width, canvasSize.height / imageSize.height)
        let scaled = CGSize(width: imageSize.width * factor, height: imageSize.height * factor)
        return CGRect(x: (canvasSize.width - scaled.width) / 2,
                      y: (canvasSize.height - scaled.height) / 2,
                      width: scaled.width, height: scaled.height)
    }
}
