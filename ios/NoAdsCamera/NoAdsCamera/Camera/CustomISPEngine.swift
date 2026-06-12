import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

enum ISPPreset: String, CaseIterable, Identifiable {
    case neutral = "Neutral"
    case food = "Food"
    case portrait = "Portrait"
    case product = "Product"
    case film = "Film"

    var id: String { rawValue }
}

final class CustomISPEngine {
    func render(_ image: CIImage, preset: ISPPreset) -> CIImage {
        let recovered = recoverHighlightsAndShadows(image)

        switch preset {
        case .neutral:
            return applyBaseISP(recovered, saturation: 1.02, contrast: 1.04, sharpness: 0.25)
        case .food:
            return applyBaseISP(recovered, saturation: 1.14, contrast: 1.06, sharpness: 0.22)
                .applyingFilter("CITemperatureAndTint", parameters: [
                    "inputNeutral": CIVector(x: 6100, y: 4),
                    "inputTargetNeutral": CIVector(x: 6500, y: 0)
                ])
        case .portrait:
            return applyBaseISP(recovered, saturation: 0.98, contrast: 0.96, sharpness: 0.12)
                .applyingFilter("CIHighlightShadowAdjust", parameters: [
                    "inputHighlightAmount": 0.74,
                    "inputShadowAmount": 0.32
                ])
        case .product:
            return applyBaseISP(recovered, saturation: 1.04, contrast: 1.12, sharpness: 0.55)
        case .film:
            return applyFilmTone(
                applyBaseISP(recovered, saturation: 0.96, contrast: 1.05, sharpness: 0.18)
            )
        }
    }

    private func recoverHighlightsAndShadows(_ image: CIImage) -> CIImage {
        image.applyingFilter("CIHighlightShadowAdjust", parameters: [
            "inputHighlightAmount": 0.68,
            "inputShadowAmount": 0.28
        ])
    }

    private func applyBaseISP(_ image: CIImage, saturation: Float, contrast: Float, sharpness: Float) -> CIImage {
        image
            .applyingFilter("CINoiseReduction", parameters: [
                "inputNoiseLevel": 0.022,
                "inputSharpness": sharpness
            ])
            .applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: saturation,
                kCIInputContrastKey: contrast,
                kCIInputBrightnessKey: 0.0
            ])
            .applyingFilter("CISharpenLuminance", parameters: [
                kCIInputSharpnessKey: sharpness
            ])
    }

    private func applyFilmTone(_ image: CIImage) -> CIImage {
        image
            .applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: 1.05, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: 0.99, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: 0.9, w: 0),
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1),
                "inputBiasVector": CIVector(x: 0.006, y: 0.002, z: -0.01, w: 0)
            ])
            .applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0.98,
                kCIInputContrastKey: 1.04,
                kCIInputBrightnessKey: 0.01
            ])
            .applyingFilter("CIVibrance", parameters: [
                "inputAmount": 0.18
            ])
    }
}
