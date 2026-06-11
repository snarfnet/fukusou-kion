import CoreImage
import Vision

struct PrivacyFinding: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let confidence: Float
    let boundingBox: CGRect
}

final class PrivacyDetectionEngine {
    private let textRequest = VNRecognizeTextRequest()
    private let barcodeRequest = VNDetectBarcodesRequest()
    private let faceRequest = VNDetectFaceRectanglesRequest()

    init() {
        textRequest.recognitionLevel = .fast
        textRequest.usesLanguageCorrection = true
        barcodeRequest.symbologies = [.qr, .aztec, .pdf417, .code128, .ean13]
    }

    func detect(pixelBuffer: CVPixelBuffer) -> [PrivacyFinding] {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        try? handler.perform([textRequest, barcodeRequest, faceRequest])

        var findings: [PrivacyFinding] = []
        findings.append(contentsOf: textFindings())
        findings.append(contentsOf: barcodeFindings())
        findings.append(contentsOf: faceFindings())
        return findings
    }

    private func textFindings() -> [PrivacyFinding] {
        guard let observations = textRequest.results else { return [] }

        return observations.compactMap { observation in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            let text = candidate.string
            let label = classify(text: text)
            guard let label else { return nil }

            return PrivacyFinding(
                label: label,
                confidence: candidate.confidence,
                boundingBox: observation.boundingBox
            )
        }
    }

    private func barcodeFindings() -> [PrivacyFinding] {
        barcodeRequest.results?.map {
            PrivacyFinding(label: "QR/バーコード", confidence: $0.confidence, boundingBox: $0.boundingBox)
        } ?? []
    }

    private func faceFindings() -> [PrivacyFinding] {
        faceRequest.results?.map {
            PrivacyFinding(label: "顔の写り込み", confidence: $0.confidence, boundingBox: $0.boundingBox)
        } ?? []
    }

    private func classify(text: String) -> String? {
        let compact = text.replacingOccurrences(of: " ", with: "")
        if compact.range(of: #"(\d{4}[-\s]?){3}\d{4}"#, options: .regularExpression) != nil {
            return "カード番号かも"
        }
        if compact.range(of: #"\d{3}-?\d{4}"#, options: .regularExpression) != nil {
            return "郵便番号かも"
        }
        if compact.contains("住所") || compact.contains("丁目") || compact.contains("番地") || compact.contains("号") {
            return "住所かも"
        }
        if compact.contains("氏名") || compact.contains("名前") || compact.contains("名札") {
            return "名前かも"
        }
        if compact.contains("TEL") || compact.contains("電話") || compact.range(of: #"0\d{1,4}-?\d{1,4}-?\d{4}"#, options: .regularExpression) != nil {
            return "電話番号かも"
        }
        return nil
    }
}
