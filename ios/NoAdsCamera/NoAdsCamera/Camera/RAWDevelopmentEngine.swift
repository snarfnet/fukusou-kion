import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import UIKit

struct RAWDevelopmentSettings {
    var exposure: Float = 0
    var highlightRecovery: Float = 1
    var shadowBoost: Float = 0
    var temperature: Float = 6500
    var tint: Float = 0
    var noiseReduction: Float = 0.25
    var sharpness: Float = 0.35
}

final class RAWDevelopmentEngine {
    private let context = CIContext(options: [
        .workingColorSpace: CGColorSpace(name: CGColorSpace.displayP3) as Any,
        .outputColorSpace: CGColorSpace(name: CGColorSpace.displayP3) as Any
    ])

    func develop(rawData: Data, settings: RAWDevelopmentSettings = RAWDevelopmentSettings()) throws -> UIImage {
        guard let rawFilter = CIFilter(imageData: rawData, options: nil) else {
            throw RAWDevelopmentError.invalidRAW
        }

        rawFilter.setValue(settings.exposure, forKey: kCIInputEVKey)
        rawFilter.setValue(true, forKey: "inputEnableChromaticNoiseTracking")
        rawFilter.setValue(settings.noiseReduction, forKey: "inputNoiseReductionAmount")
        rawFilter.setValue(settings.sharpness, forKey: "inputBoostAmount")

        guard var image = rawFilter.outputImage else {
            throw RAWDevelopmentError.invalidRAW
        }

        image = applyWhiteBalance(to: image, temperature: settings.temperature, tint: settings.tint)
        image = applyToneRecovery(to: image, shadows: settings.shadowBoost)

        guard let cgImage = context.createCGImage(image, from: image.extent) else {
            throw RAWDevelopmentError.renderFailed
        }

        return UIImage(cgImage: cgImage)
    }

    func heifData(from image: UIImage, quality: CGFloat = 0.94) -> Data? {
        guard let ciImage = CIImage(image: image),
              let colorSpace = CGColorSpace(name: CGColorSpace.displayP3) else {
            return nil
        }

        return context.heifRepresentation(
            of: ciImage,
            format: .RGBA8,
            colorSpace: colorSpace,
            options: [:]
        )
    }

    private func applyWhiteBalance(to image: CIImage, temperature: Float, tint: Float) -> CIImage {
        let filter = CIFilter.temperatureAndTint()
        filter.inputImage = image
        filter.neutral = CIVector(x: CGFloat(temperature), y: CGFloat(tint))
        filter.targetNeutral = CIVector(x: 6500, y: 0)
        return filter.outputImage ?? image
    }

    private func applyToneRecovery(to image: CIImage, shadows: Float) -> CIImage {
        let filter = CIFilter.highlightShadowAdjust()
        filter.inputImage = image
        filter.shadowAmount = shadows
        filter.highlightAmount = 0.8
        return filter.outputImage ?? image
    }
}

enum RAWDevelopmentError: Error {
    case invalidRAW
    case renderFailed
}
