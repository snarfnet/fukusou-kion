import AVFoundation
import CoreImage
import Vision

final class FaceTrackingService {
    func analyze(videoURL: URL, frameInterval: Double = 0.15) async throws -> [FaceTrackingPoint] {
        let asset = AVURLAsset(url: videoURL)
        let duration = try await asset.load(.duration).seconds
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.03, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.03, preferredTimescale: 600)

        var points: [FaceTrackingPoint] = []
        var previous: FaceTrackingPoint?
        var time = 0.0

        while time <= duration {
            try Task.checkCancellation()
            let cmTime = CMTime(seconds: time, preferredTimescale: 600)
            if let image = try? generator.copyCGImage(at: cmTime, actualTime: nil),
               let detected = detectFace(in: image, time: time, previous: previous) {
                points.append(detected)
                previous = detected
            } else if let previous {
                let carried = FaceTrackingPoint(
                    time: time,
                    faceRect: previous.faceRect,
                    leftEye: previous.leftEye,
                    rightEye: previous.rightEye
                )
                points.append(carried)
            }
            time += frameInterval
        }

        return points
    }

    private func detectFace(in image: CGImage, time: Double, previous: FaceTrackingPoint?) -> FaceTrackingPoint? {
        let request = VNDetectFaceLandmarksRequest()
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        try? handler.perform([request])

        guard let face = request.results?.max(by: { lhs, rhs in
            lhs.boundingBox.width * lhs.boundingBox.height < rhs.boundingBox.width * rhs.boundingBox.height
        }) else {
            return nil
        }

        let rect = convertVisionRect(face.boundingBox)
        let leftEye = eyeCenter(face.landmarks?.leftEye, in: face.boundingBox)
        let rightEye = eyeCenter(face.landmarks?.rightEye, in: face.boundingBox)
        let raw = FaceTrackingPoint(time: time, faceRect: rect, leftEye: leftEye, rightEye: rightEye)
        guard let previous else { return raw }
        return smooth(raw, with: previous)
    }

    private func convertVisionRect(_ rect: CGRect) -> CGRect {
        CGRect(
            x: rect.origin.x,
            y: 1 - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
    }

    private func eyeCenter(_ region: VNFaceLandmarkRegion2D?, in faceRect: CGRect) -> CGPoint? {
        guard let region, region.pointCount > 0 else { return nil }
        let sum = region.normalizedPoints.reduce(CGPoint.zero) { partial, point in
            CGPoint(x: partial.x + point.x, y: partial.y + point.y)
        }
        let average = CGPoint(x: sum.x / CGFloat(region.pointCount), y: sum.y / CGFloat(region.pointCount))
        return CGPoint(
            x: faceRect.origin.x + average.x * faceRect.width,
            y: 1 - (faceRect.origin.y + average.y * faceRect.height)
        )
    }

    private func smooth(_ point: FaceTrackingPoint, with previous: FaceTrackingPoint) -> FaceTrackingPoint {
        let weight: CGFloat = 0.34
        return FaceTrackingPoint(
            time: point.time,
            faceRect: previous.faceRect.lerp(to: point.faceRect, weight: weight),
            leftEye: previous.leftEye.lerp(to: point.leftEye, weight: weight),
            rightEye: previous.rightEye.lerp(to: point.rightEye, weight: weight)
        )
    }
}

private extension CGRect {
    func lerp(to other: CGRect, weight: CGFloat) -> CGRect {
        CGRect(
            x: origin.x * (1 - weight) + other.origin.x * weight,
            y: origin.y * (1 - weight) + other.origin.y * weight,
            width: width * (1 - weight) + other.width * weight,
            height: height * (1 - weight) + other.height * weight
        )
    }
}

private extension Optional where Wrapped == CGPoint {
    func lerp(to other: CGPoint?, weight: CGFloat) -> CGPoint? {
        guard let self, let other else { return self ?? other }
        return CGPoint(
            x: self.x * (1 - weight) + other.x * weight,
            y: self.y * (1 - weight) + other.y * weight
        )
    }
}
