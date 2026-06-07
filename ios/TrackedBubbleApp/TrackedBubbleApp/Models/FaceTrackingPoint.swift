import CoreGraphics
import Foundation

struct FaceTrackingPoint: Identifiable, Codable, Hashable {
    let id = UUID()
    let time: Double
    let faceRect: CGRect
    let leftEye: CGPoint?
    let rightEye: CGPoint?

    var bubbleAnchor: CGPoint {
        let x = min(0.88, max(0.12, faceRect.midX + faceRect.width * 0.30))
        let y = min(0.86, max(0.08, faceRect.minY - faceRect.height * 0.18))
        return CGPoint(x: x, y: y)
    }

    var eyeCenter: CGPoint {
        if let leftEye, let rightEye {
            return CGPoint(x: (leftEye.x + rightEye.x) * 0.5, y: (leftEye.y + rightEye.y) * 0.5)
        }
        return CGPoint(x: faceRect.midX, y: faceRect.minY + faceRect.height * 0.38)
    }

    var eyeWidth: CGFloat {
        if let leftEye, let rightEye {
            return max(0.08, abs(rightEye.x - leftEye.x))
        }
        return max(0.10, faceRect.width * 0.42)
    }
}

extension Array where Element == FaceTrackingPoint {
    func interpolatedPoint(at time: Double) -> FaceTrackingPoint? {
        guard let first else { return nil }
        guard count > 1 else { return first }
        if time <= first.time { return first }
        guard let last else { return nil }
        if time >= last.time { return last }

        guard let upperIndex = firstIndex(where: { $0.time >= time }), upperIndex > startIndex else {
            return first
        }
        let lower = self[index(before: upperIndex)]
        let upper = self[upperIndex]
        let progress = CGFloat((time - lower.time) / max(0.001, upper.time - lower.time))
        return FaceTrackingPoint(
            time: time,
            faceRect: lower.faceRect.lerp(to: upper.faceRect, progress: progress),
            leftEye: lower.leftEye.lerp(to: upper.leftEye, progress: progress),
            rightEye: lower.rightEye.lerp(to: upper.rightEye, progress: progress)
        )
    }
}

private extension CGRect {
    func lerp(to other: CGRect, progress: CGFloat) -> CGRect {
        CGRect(
            x: origin.x + (other.origin.x - origin.x) * progress,
            y: origin.y + (other.origin.y - origin.y) * progress,
            width: width + (other.width - width) * progress,
            height: height + (other.height - height) * progress
        )
    }
}

private extension Optional where Wrapped == CGPoint {
    func lerp(to other: CGPoint?, progress: CGFloat) -> CGPoint? {
        guard let self, let other else { return self ?? other }
        return CGPoint(
            x: self.x + (other.x - self.x) * progress,
            y: self.y + (other.y - self.y) * progress
        )
    }
}
