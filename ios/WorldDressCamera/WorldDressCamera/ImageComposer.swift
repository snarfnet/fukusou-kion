import UIKit
import SwiftUI
import CoreImage
import Vision

struct BlendSettings: Equatable {
    var opacity: Double = 1
    var brightness: Double = 0
    var saturation: Double = 1
    var contrast: Double = 1
    var width: Double = 1
    var height: Double = 1
    var softness: Double = 0
}

enum ImageComposer {
    static func compose(photo: UIImage, garment: UIImage?, offset: CGSize, scale: CGFloat,
                        rotation: Angle, blend: BlendSettings, faceForeground: UIImage?) -> UIImage {
        let outputSize = aspectFillSize(for: photo.size, aspect: PhotoCanvas.aspectRatio)
        let format = UIGraphicsImageRendererFormat()
        format.scale = photo.scale
        return UIGraphicsImageRenderer(size: outputSize, format: format).image { context in
            let photoRect = aspectFillRect(imageSize: photo.size, canvasSize: outputSize)
            photo.draw(in: photoRect)
            guard let garment else { return }
            let baseWidth = outputSize.width * 0.88
            let aspect = garment.size.height / garment.size.width
            let size = CGSize(width: baseWidth * scale * blend.width,
                              height: baseWidth * aspect * scale * blend.height)
            let renderedGarment = filtered(garment, blend: blend)
            context.cgContext.saveGState()
            context.cgContext.setAlpha(blend.opacity)
            context.cgContext.translateBy(x: outputSize.width / 2 + offset.width * outputSize.width / 390,
                                          y: outputSize.height / 2 + offset.height * outputSize.height / 520)
            context.cgContext.rotate(by: CGFloat(rotation.radians))
            renderedGarment.draw(in: CGRect(x: -size.width / 2, y: -size.height / 2,
                                            width: size.width, height: size.height))
            context.cgContext.restoreGState()
            faceForeground?.draw(in: CGRect(origin: .zero, size: outputSize))
        }
    }

    static func suggestedBlend(photo: UIImage, garment: UIImage) -> BlendSettings {
        let delta = averageBrightness(photo) - averageBrightness(garment)
        var settings = BlendSettings()
        settings.brightness = min(max(delta * 0.55, -0.28), 0.28)
        settings.saturation = 0.92
        settings.contrast = 0.96
        settings.opacity = 0.97
        settings.softness = 0.45
        return settings
    }

    static func makeFaceForeground(photo: UIImage) -> UIImage? {
        guard let cgImage = photo.cgImage else { return nil }
        let request = VNDetectFaceRectanglesRequest()
        try? VNImageRequestHandler(cgImage: cgImage, orientation: .up).perform([request])
        guard let face = (request.results as? [VNFaceObservation])?.max(by: {
            $0.boundingBox.width < $1.boundingBox.width
        }) else { return nil }

        let outputSize = aspectFillSize(for: photo.size, aspect: PhotoCanvas.aspectRatio)
        let photoRect = aspectFillRect(imageSize: photo.size, canvasSize: outputSize)
        let factor = photoRect.width / photo.size.width
        let source = face.boundingBox
        let faceRect = CGRect(
            x: photoRect.minX + source.minX * photo.size.width * factor,
            y: photoRect.minY + (1 - source.maxY) * photo.size.height * factor,
            width: source.width * photo.size.width * factor,
            height: source.height * photo.size.height * factor
        )
        let hairAndFace = faceRect.insetBy(dx: -faceRect.width * 0.48,
                                           dy: -faceRect.height * 0.52)
            .offsetBy(dx: 0, dy: -faceRect.height * 0.12)
        let format = UIGraphicsImageRendererFormat()
        format.scale = photo.scale
        return UIGraphicsImageRenderer(size: outputSize, format: format).image { context in
            context.cgContext.addEllipse(in: hairAndFace)
            context.cgContext.clip()
            photo.draw(in: photoRect)
        }
    }

    private static func filtered(_ image: UIImage, blend: BlendSettings) -> UIImage {
        guard var input = CIImage(image: image) else { return image }
        input = input.applyingFilter("CIColorControls", parameters: [
            kCIInputBrightnessKey: blend.brightness,
            kCIInputSaturationKey: blend.saturation,
            kCIInputContrastKey: blend.contrast
        ])
        if blend.softness > 0 {
            input = input.applyingFilter("CIGaussianBlur", parameters: [
                kCIInputRadiusKey: blend.softness * Double(image.scale)
            ]).cropped(to: input.extent)
        }
        let context = CIContext(options: [.useSoftwareRenderer: false])
        guard let output = context.createCGImage(input, from: input.extent) else { return image }
        return UIImage(cgImage: output, scale: image.scale, orientation: .up)
    }

    private static func averageBrightness(_ image: UIImage) -> Double {
        guard let source = CIImage(image: image) else { return 0.5 }
        let input = source.composited(over:
            CIImage(color: CIColor(gray: 0.5)).cropped(to: source.extent)
        )
        let extent = input.extent
        let parameters: [String: Any] = [
            kCIInputExtentKey: CIVector(cgRect: extent)
        ]
        let output = input.applyingFilter("CIAreaAverage", parameters: parameters)
            .cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
        var pixel = [UInt8](repeating: 0, count: 4)
        CIContext().render(output, toBitmap: &pixel, rowBytes: 4,
                           bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                           format: .RGBA8, colorSpace: CGColorSpaceCreateDeviceRGB())
        return (0.2126 * Double(pixel[0]) + 0.7152 * Double(pixel[1])
                + 0.0722 * Double(pixel[2])) / 255
    }

    static func aspectFillSize(for size: CGSize, aspect: CGFloat) -> CGSize {
        if size.width / size.height > aspect {
            return CGSize(width: size.height * aspect, height: size.height)
        }
        return CGSize(width: size.width, height: size.width / aspect)
    }

    static func aspectFillRect(imageSize: CGSize, canvasSize: CGSize) -> CGRect {
        let factor = max(canvasSize.width / imageSize.width, canvasSize.height / imageSize.height)
        let scaled = CGSize(width: imageSize.width * factor, height: imageSize.height * factor)
        return CGRect(x: (canvasSize.width - scaled.width) / 2,
                      y: (canvasSize.height - scaled.height) / 2,
                      width: scaled.width, height: scaled.height)
    }
}
