import CoreImage
import Vision

enum ExposurePriority: String, CaseIterable, Identifiable {
    case face = "Face"
    case product = "Product"
    case skySafe = "Sky"
    case document = "Text"

    var id: String { rawValue }
}

struct SemanticExposureDecision {
    let exposureBias: Float
    let message: String
    let priority: ExposurePriority
}

final class SemanticExposureEngine {
    private let faceRequest = VNDetectFaceRectanglesRequest()
    private let textRequest = VNRecognizeTextRequest()

    init() {
        textRequest.recognitionLevel = .fast
        textRequest.usesLanguageCorrection = false
    }

    func decide(pixelBuffer: CVPixelBuffer, priority: ExposurePriority) -> SemanticExposureDecision {
        let luma = regionLuma(pixelBuffer: pixelBuffer, rect: priorityRect(pixelBuffer: pixelBuffer, priority: priority))
        let target = targetLuma(for: priority)
        let delta = target - luma
        let bias = Float(max(-1.5, min(1.5, delta * 3.0)))

        return SemanticExposureDecision(
            exposureBias: bias,
            message: message(for: priority, bias: bias),
            priority: priority
        )
    }

    private func priorityRect(pixelBuffer: CVPixelBuffer, priority: ExposurePriority) -> CGRect {
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let cgWidth = CGFloat(width)
        let cgHeight = CGFloat(height)

        switch priority {
        case .face:
            return firstFaceRect(pixelBuffer: pixelBuffer, width: width, height: height)
                ?? CGRect(x: cgWidth / 4, y: cgHeight / 5, width: cgWidth / 2, height: cgHeight / 2)
        case .document:
            return firstTextRect(pixelBuffer: pixelBuffer, width: width, height: height)
                ?? CGRect(x: cgWidth / 8, y: cgHeight / 5, width: cgWidth * 3 / 4, height: cgHeight * 3 / 5)
        case .skySafe:
            return CGRect(x: 0, y: 0, width: cgWidth, height: cgHeight / 3)
        case .product:
            return CGRect(x: cgWidth / 5, y: cgHeight / 4, width: cgWidth * 3 / 5, height: cgHeight / 2)
        }
    }

    private func firstFaceRect(pixelBuffer: CVPixelBuffer, width: Int, height: Int) -> CGRect? {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        try? handler.perform([faceRequest])
        return faceRequest.results?.first.map {
            VNImageRectForNormalizedRect($0.boundingBox, width, height)
        }
    }

    private func firstTextRect(pixelBuffer: CVPixelBuffer, width: Int, height: Int) -> CGRect? {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        try? handler.perform([textRequest])
        return textRequest.results?.first.map {
            VNImageRectForNormalizedRect($0.boundingBox, width, height)
        }
    }

    private func regionLuma(pixelBuffer: CVPixelBuffer, rect: CGRect) -> Double {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return 0.5 }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)

        let minX = max(0, Int(rect.minX))
        let maxX = min(width - 1, Int(rect.maxX))
        let minY = max(0, Int(rect.minY))
        let maxY = min(height - 1, Int(rect.maxY))

        var total = 0.0
        var samples = 0.0
        for y in stride(from: minY, through: maxY, by: 12) {
            for x in stride(from: minX, through: maxX, by: 12) {
                let offset = y * bytesPerRow + x * 4
                let blue = Double(buffer[offset])
                let green = Double(buffer[offset + 1])
                let red = Double(buffer[offset + 2])
                total += (0.2126 * red + 0.7152 * green + 0.0722 * blue) / 255.0
                samples += 1
            }
        }

        return samples > 0 ? total / samples : 0.5
    }

    private func targetLuma(for priority: ExposurePriority) -> Double {
        switch priority {
        case .face:
            return 0.58
        case .product:
            return 0.62
        case .skySafe:
            return 0.72
        case .document:
            return 0.68
        }
    }

    private func message(for priority: ExposurePriority, bias: Float) -> String {
        if abs(bias) < 0.15 {
            return "\(priority.rawValue)に露出が合っています"
        }
        return bias > 0 ? "\(priority.rawValue)を明るくします" : "\(priority.rawValue)を守るため暗くします"
    }
}
