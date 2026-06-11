import AVFoundation
import CoreImage
import Vision

final class SemanticMaskEngine {
    private let context = CIContext()
    private let personRequest: VNGeneratePersonSegmentationRequest = {
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .balanced
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8
        return request
    }()

    func makePersonMask(from pixelBuffer: CVPixelBuffer) throws -> CIImage? {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        try handler.perform([personRequest])
        guard let observation = personRequest.results?.first else { return nil }
        return CIImage(cvPixelBuffer: observation.pixelBuffer)
    }

    func combine(personMask: CIImage?, depthData: AVDepthData?, targetExtent: CGRect) -> CIImage? {
        var masks: [CIImage] = []

        if let personMask {
            masks.append(personMask.transformed(toFill: targetExtent))
        }

        if let depthData {
            let convertedDepth = depthData.converting(toDepthDataType: kCVPixelFormatType_DisparityFloat32)
            let depthMask = CIImage(cvPixelBuffer: convertedDepth.depthDataMap)
                .normalizedDepthMask()
                .transformed(toFill: targetExtent)
            masks.append(depthMask)
        }

        guard let first = masks.first else { return nil }
        return masks.dropFirst().reduce(first) { partial, next in
            partial.applyingFilter("CIMaximumCompositing", parameters: [kCIInputBackgroundImageKey: next])
        }
    }

    func liftSubject(from image: CIImage, mask: CIImage) -> CIImage {
        let transparent = CIImage(color: .clear).cropped(to: image.extent)
        return image.applyingFilter(
            "CIBlendWithMask",
            parameters: [
                kCIInputBackgroundImageKey: transparent,
                kCIInputMaskImageKey: mask.transformed(toFill: image.extent)
            ]
        )
    }
}

private extension CIImage {
    func transformed(toFill rect: CGRect) -> CIImage {
        let scaleX = rect.width / extent.width
        let scaleY = rect.height / extent.height
        return transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))
            .cropped(to: rect)
    }

    func normalizedDepthMask() -> CIImage {
        applyingFilter(
            "CIColorControls",
            parameters: [
                kCIInputSaturationKey: 0,
                kCIInputContrastKey: 1.6,
                kCIInputBrightnessKey: 0
            ]
        )
    }
}
