import CoreMedia
import Foundation

struct BestShotCandidate {
    let pixelBuffer: CVPixelBuffer
    let timestamp: CMTime
    let score: Double
    let highlightRatio: Double
    let shadowRatio: Double
    let shakeLevel: Double
    let horizonTilt: Double
}

final class BestShotBuffer {
    private let capacity: Int
    private var candidates: [BestShotCandidate] = []

    init(capacity: Int = 60) {
        self.capacity = capacity
    }

    func append(pixelBuffer: CVPixelBuffer, timestamp: CMTime, highlightRatio: Double, shadowRatio: Double, shakeLevel: Double, horizonTilt: Double) {
        let candidate = BestShotCandidate(
            pixelBuffer: pixelBuffer,
            timestamp: timestamp,
            score: Self.score(highlightRatio: highlightRatio, shadowRatio: shadowRatio, shakeLevel: shakeLevel, horizonTilt: horizonTilt),
            highlightRatio: highlightRatio,
            shadowRatio: shadowRatio,
            shakeLevel: shakeLevel,
            horizonTilt: horizonTilt
        )

        candidates.append(candidate)
        while candidates.count > capacity {
            candidates.removeFirst()
        }
    }

    func bestCandidate() -> BestShotCandidate? {
        candidates.max { $0.score < $1.score }
    }

    func removeAll() {
        candidates.removeAll()
    }

    static func score(highlightRatio: Double, shadowRatio: Double, shakeLevel: Double, horizonTilt: Double) -> Double {
        let exposurePenalty = highlightRatio * 2.4 + shadowRatio * 1.4
        let shakePenalty = shakeLevel * 2.0
        let levelPenalty = min(abs(horizonTilt) / 0.35, 1.0) * 0.28
        return max(0, 1.0 - exposurePenalty - shakePenalty - levelPenalty)
    }

    deinit {
        removeAll()
    }
}
