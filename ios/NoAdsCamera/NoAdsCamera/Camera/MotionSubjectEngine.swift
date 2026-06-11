import CoreImage
import Foundation

final class MotionSubjectEngine {
    private let opticalFlowEngine = OpticalFlowEngine()

    func motionAwareComposite(stableFrames: [CIImage], subjectFrame: CIImage, motionMask: CIImage?) -> CIImage {
        let background = averageStableBackground(frames: stableFrames) ?? subjectFrame
        guard let motionMask else { return subjectFrame }

        let sharpSubject = subjectFrame
            .applyingFilter("CISharpenLuminance", parameters: [
                kCIInputSharpnessKey: 0.58
            ])
            .applyingFilter("CIUnsharpMask", parameters: [
                kCIInputRadiusKey: 1.1,
                kCIInputIntensityKey: 0.42
            ])

        return sharpSubject.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputBackgroundImageKey: background,
            kCIInputMaskImageKey: motionMask
        ])
    }

    func makeMotionMask(previous: CVPixelBuffer, current: CVPixelBuffer, extent: CGRect) -> CIImage? {
        guard let mask = try? opticalFlowEngine.motionMask(previous: previous, current: current) else {
            return nil
        }

        return mask
            .applyingFilter("CIColorControls", parameters: [
                kCIInputContrastKey: 2.4,
                kCIInputBrightnessKey: -0.08
            ])
            .applyingFilter("CIGaussianBlur", parameters: [
                kCIInputRadiusKey: 2.0
            ])
            .cropped(to: extent)
    }

    private func averageStableBackground(frames: [CIImage]) -> CIImage? {
        guard var accumulator = frames.first else { return nil }

        for frame in frames.dropFirst() {
            accumulator = frame.applyingFilter(
                "CIAdditionCompositing",
                parameters: [kCIInputBackgroundImageKey: accumulator]
            )
        }

        return accumulator.applyingFilter("CIColorMatrix", parameters: [
            "inputRVector": CIVector(x: 1.0 / CGFloat(frames.count), y: 0, z: 0, w: 0),
            "inputGVector": CIVector(x: 0, y: 1.0 / CGFloat(frames.count), z: 0, w: 0),
            "inputBVector": CIVector(x: 0, y: 0, z: 1.0 / CGFloat(frames.count), w: 0),
            "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 1)
        ])
    }
}
