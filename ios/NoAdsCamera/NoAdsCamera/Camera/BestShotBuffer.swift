import CoreMedia
import Foundation

struct BestShotCandidate {
    let pixelBuffer: CVPixelBuffer
    let timestamp: CMTime
    let score: Double
    let highlightRatio: Double
    let shadowRatio: Double
    let shakeLevel: Double
}

final class BestShotBuffer {
    private let capacity: Int
    private var candidates: [BestShotCandidate] = []

    init(capacity: Int = 60) {
        self.capacity = capacity
    }

    func append(pixelBuffer: CVPixelBuffer, timestamp: CMTime, highlightRatio: Double, shadowRatio: Double, shakeLevel: Double) {
        let candidate = BestShotCandidate(
            pixelBuffer: pixelBuffer,
            timestamp: timestamp,
            score: score(highlightRatio: highlightRatio, shadowRatio: shadowRatio, shakeLevel: shakeLevel),
            highlightRatio: highlightRatio,
            shadowRatio: shadowRatio,
            shakeLevel: shakeLevel
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

    private func score(highlightRatio: Double, shadowRatio: Double, shakeLevel: Double) -> Double {
        let exposurePenalty = highlightRatio * 2.4 + shadowRatio * 1.4
        let shakePenalty = shakeLevel * 2.0
        return max(0, 1.0 - exposurePenalty - shakePenalty)
    }

    deinit {
        removeAll()
    }
}
