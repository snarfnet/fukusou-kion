import CoreImage
import Vision

final class RealtimeAIDevelopmentEngine {
    private let semanticMaskEngine = SemanticMaskEngine()
    private let textRequest = VNRecognizeTextRequest()

    init() {
        textRequest.recognitionLevel = .fast
        textRequest.usesLanguageCorrection = false
    }

    func renderPreview(pixelBuffer: CVPixelBuffer) -> CIImage {
        let image = CIImage(cvPixelBuffer: pixelBuffer)
        var result = baseNaturalCorrection(image)

        if let personMask = try? semanticMaskEngine.makePersonMask(from: pixelBuffer) {
            result = brightenSubject(in: result, mask: personMask.scaled(toFill: image.extent))
        }

        if let textMask = makeTextMask(pixelBuffer: pixelBuffer, extent: image.extent) {
            result = sharpenRegion(in: result, mask: textMask)
        }

        return result
    }

    private func baseNaturalCorrection(_ image: CIImage) -> CIImage {
        image
            .applyingFilter("CIHighlightShadowAdjust", parameters: [
                "inputHighlightAmount": 0.74,
                "inputShadowAmount": 0.22
            ])
            .applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 1.04,
                kCIInputContrastKey: 1.03
            ])
    }

    private func brightenSubject(in image: CIImage, mask: CIImage) -> CIImage {
        let subject = image
            .applyingFilter("CIHighlightShadowAdjust", parameters: [
                "inputHighlightAmount": 0.82,
                "inputShadowAmount": 0.42
            ])
            .applyingFilter("CIColorControls", parameters: [
                kCIInputBrightnessKey: 0.035,
                kCIInputSaturationKey: 1.02
            ])

        return subject.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputBackgroundImageKey: image,
            kCIInputMaskImageKey: mask
        ])
    }

    private func sharpenRegion(in image: CIImage, mask: CIImage) -> CIImage {
        let sharp = image
            .applyingFilter("CISharpenLuminance", parameters: [
                kCIInputSharpnessKey: 0.72
            ])
            .applyingFilter("CIColorControls", parameters: [
                kCIInputContrastKey: 1.12
            ])

        return sharp.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputBackgroundImageKey: image,
            kCIInputMaskImageKey: mask
        ])
    }

    private func makeTextMask(pixelBuffer: CVPixelBuffer, extent: CGRect) -> CIImage? {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        try? handler.perform([textRequest])

        guard let observations = textRequest.results, !observations.isEmpty else { return nil }

        var mask = CIImage(color: .clear).cropped(to: extent)
        for observation in observations.prefix(8) {
            let rect = VNImageRectForNormalizedRect(observation.boundingBox, Int(extent.width), Int(extent.height))
            let textRegion = CIImage(color: .white).cropped(to: rect)
            mask = textRegion.composited(over: mask)
        }
        return mask
            .applyingFilter("CIGaussianBlur", parameters: [kCIInputRadiusKey: 3])
            .cropped(to: extent)
    }
}

private extension CIImage {
    func scaled(toFill rect: CGRect) -> CIImage {
        let scaleX = rect.width / extent.width
        let scaleY = rect.height / extent.height
        return transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
            .cropped(to: rect)
    }
}
