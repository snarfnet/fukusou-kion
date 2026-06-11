import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

enum VideoLook {
    case neutral
    case logPreview
    case cinemaWarm
    case nightClean
}

final class VideoLookEngine {
    private let context = CIContext()

    func renderPreview(pixelBuffer: CVPixelBuffer, look: VideoLook, zebraThreshold: Float = 0.94, peakingAmount: Float = 0.65) -> CIImage {
        let input = CIImage(cvPixelBuffer: pixelBuffer)
        let graded = applyLook(input, look: look)
        let zebra = zebraMask(from: input, threshold: zebraThreshold)
        let peaking = focusPeaking(from: input, amount: peakingAmount)

        return peaking.composited(over: zebra.composited(over: graded))
    }

    func histogramBuckets(pixelBuffer: CVPixelBuffer, bucketCount: Int = 32) -> [Float] {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer), bucketCount > 0 else {
            return []
        }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        let step = 12
        var buckets = Array(repeating: Float(0), count: bucketCount)
        var samples: Float = 0

        for y in stride(from: 0, to: height, by: step) {
            for x in stride(from: 0, to: width, by: step) {
                let offset = y * bytesPerRow + x * 4
                let blue = Float(buffer[offset])
                let green = Float(buffer[offset + 1])
                let red = Float(buffer[offset + 2])
                let luma = (0.2126 * red + 0.7152 * green + 0.0722 * blue) / 255.0
                let bucket = min(bucketCount - 1, max(0, Int(luma * Float(bucketCount))))
                buckets[bucket] += 1
                samples += 1
            }
        }

        guard samples > 0 else { return buckets }
        return buckets.map { $0 / samples }
    }

    private func applyLook(_ image: CIImage, look: VideoLook) -> CIImage {
        switch look {
        case .neutral:
            return image
        case .logPreview:
            return image
                .applyingFilter("CIColorControls", parameters: [
                    kCIInputContrastKey: 0.72,
                    kCIInputSaturationKey: 0.86,
                    kCIInputBrightnessKey: 0.02
                ])
        case .cinemaWarm:
            return image
                .applyingFilter("CITemperatureAndTint", parameters: [
                    "inputNeutral": CIVector(x: 6200, y: 8),
                    "inputTargetNeutral": CIVector(x: 6500, y: 0)
                ])
                .applyingFilter("CIColorControls", parameters: [
                    kCIInputContrastKey: 1.08,
                    kCIInputSaturationKey: 0.95
                ])
        case .nightClean:
            return image
                .applyingFilter("CINoiseReduction", parameters: [
                    "inputNoiseLevel": 0.035,
                    "inputSharpness": 0.38
                ])
                .applyingFilter("CIHighlightShadowAdjust", parameters: [
                    "inputHighlightAmount": 0.78,
                    "inputShadowAmount": 0.42
                ])
        }
    }

    private func zebraMask(from image: CIImage, threshold: Float) -> CIImage {
        let thresholded = image
            .applyingFilter("CIColorControls", parameters: [kCIInputSaturationKey: 0])
            .applyingFilter("CIColorThreshold", parameters: ["inputThreshold": threshold])

        let stripe = CIFilter.stripesGenerator()
        stripe.color0 = CIColor(red: 1, green: 0.95, blue: 0, alpha: 0.62)
        stripe.color1 = CIColor(red: 0, green: 0, blue: 0, alpha: 0)
        stripe.width = 4
        stripe.sharpness = 0.9

        return stripe.outputImage?
            .cropped(to: image.extent)
            .applyingFilter("CIBlendWithMask", parameters: [
                kCIInputBackgroundImageKey: CIImage(color: .clear).cropped(to: image.extent),
                kCIInputMaskImageKey: thresholded
            ]) ?? CIImage(color: .clear).cropped(to: image.extent)
    }

    private func focusPeaking(from image: CIImage, amount: Float) -> CIImage {
        let edges = image
            .applyingFilter("CIEdges", parameters: [kCIInputIntensityKey: amount])
            .applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0,
                kCIInputContrastKey: 3.0
            ])

        let color = CIImage(color: CIColor(red: 0, green: 1, blue: 0.7, alpha: 0.75)).cropped(to: image.extent)
        return color.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputBackgroundImageKey: CIImage(color: .clear).cropped(to: image.extent),
            kCIInputMaskImageKey: edges
        ])
    }
}
