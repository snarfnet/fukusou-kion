import CoreImage
import Vision

final class OpticalFlowEngine {
    func motionMask(previous: CVPixelBuffer, current: CVPixelBuffer) throws -> CIImage? {
        let request = VNGenerateOpticalFlowRequest(targetedCVPixelBuffer: current, options: [:])
        request.computationAccuracy = .low
        request.outputPixelFormat = kCVPixelFormatType_TwoComponent32Float

        let handler = VNImageRequestHandler(cvPixelBuffer: previous, orientation: .up)
        try handler.perform([request])

        guard let observation = request.results?.first else { return nil }
        let flow = CIImage(cvPixelBuffer: observation.pixelBuffer)

        return flow
            .applyingFilter("CIColorControls", parameters: [
                kCIInputSaturationKey: 0,
                kCIInputContrastKey: 2.0
            ])
            .applyingFilter("CIGaussianBlur", parameters: [
                kCIInputRadiusKey: 1.5
            ])
    }

    func ghostReducedBlend(base: CIImage, moving: CIImage, motionMask: CIImage) -> CIImage {
        base.applyingFilter(
            "CIBlendWithMask",
            parameters: [
                kCIInputBackgroundImageKey: moving,
                kCIInputMaskImageKey: motionMask
            ]
        )
    }
}
