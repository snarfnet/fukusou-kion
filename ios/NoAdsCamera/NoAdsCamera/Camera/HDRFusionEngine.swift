import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import UIKit

final class HDRFusionEngine {
    private let context = CIContext()

    func fuseBracket(images: [CIImage]) throws -> UIImage {
        guard let base = images.first else { throw FusionError.noInput }

        let normalized = images.map { image in
            image
                .cropped(to: base.extent)
                .applyingFilter("CIHighlightShadowAdjust", parameters: [
                    "inputHighlightAmount": 0.65,
                    "inputShadowAmount": 0.45
                ])
        }

        let fused = average(images: normalized)
            .applyingFilter("CIColorControls", parameters: [
                kCIInputContrastKey: 1.08,
                kCIInputSaturationKey: 1.02
            ])

        return try render(fused)
    }

    func makeNightStack(images: [CIImage], shadowBoost: Float = 0.55) throws -> UIImage {
        guard !images.isEmpty else { throw FusionError.noInput }

        let fused = average(images: images)
            .applyingFilter("CINoiseReduction", parameters: [
                "inputNoiseLevel": 0.025,
                "inputSharpness": 0.4
            ])
            .applyingFilter("CIHighlightShadowAdjust", parameters: [
                "inputHighlightAmount": 0.72,
                "inputShadowAmount": shadowBoost
            ])

        return try render(fused)
    }

    func makeSuperResolutionLook(images: [CIImage]) throws -> UIImage {
        guard !images.isEmpty else { throw FusionError.noInput }

        let fused = average(images: images)
            .applyingFilter("CISharpenLuminance", parameters: [
                kCIInputSharpnessKey: 0.52
            ])
            .applyingFilter("CIUnsharpMask", parameters: [
                kCIInputRadiusKey: 1.2,
                kCIInputIntensityKey: 0.35
            ])

        return try render(fused)
    }

    private func average(images: [CIImage]) -> CIImage {
        guard var accumulator = images.first else {
            return CIImage(color: .clear).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        for image in images.dropFirst() {
            accumulator = image.applyingFilter(
                "CIAdditionCompositing",
                parameters: [kCIInputBackgroundImageKey: accumulator]
            )
        }

        return accumulator.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 1.0 / CGFloat(images.count), y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: 1.0 / CGFloat(images.count), z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 1.0 / CGFloat(images.count), w: 0),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1)
        ])
    }

    private func render(_ image: CIImage) throws -> UIImage {
        guard let cgImage = context.createCGImage(image, from: image.extent) else {
            throw FusionError.renderFailed
        }
        return UIImage(cgImage: cgImage)
    }
}

enum FusionError: Error {
    case noInput
    case renderFailed
}
