import AVFoundation
import Vision

final class PersonDetector {
    func analyze(url: URL, progress: @escaping @Sendable (Double) -> Void) async throws -> (points: [PersonTrackPoint], summary: AnalysisSummary) {
        let asset = AVURLAsset(url: url)
        let duration = try await asset.load(.duration).seconds
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw EditorError.noVideoTrack
        }

        let reader = try AVAssetReader(asset: asset)
        let output = AVAssetReaderTrackOutput(
            track: videoTrack,
            outputSettings: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
        )
        output.alwaysCopiesSampleData = false
        guard reader.canAdd(output) else { throw EditorError.readerSetupFailed }
        reader.add(output)

        let request = VNDetectHumanRectanglesRequest()
        request.upperBodyOnly = false
        let handler = VNSequenceRequestHandler()
        var points: [PersonTrackPoint] = []
        var processedFrames = 0
        var detectedFrames = 0
        var lastAnalyzedSecond = -1.0

        reader.startReading()

        while reader.status == .reading, let sampleBuffer = output.copyNextSampleBuffer() {
            try Task.checkCancellation()
            let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
            guard time - lastAnalyzedSecond >= 0.16 || lastAnalyzedSecond < 0 else { continue }
            lastAnalyzedSecond = time
            processedFrames += 1

            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { continue }
            try handler.perform([request], on: pixelBuffer, orientation: .up)

            if let best = request.results?.max(by: { $0.confidence < $1.confidence }) {
                detectedFrames += 1
                points.append(PersonTrackPoint(time: time, boundingBox: best.boundingBox, confidence: best.confidence))
            }
            if duration > 0 {
                progress(min(0.98, time / duration))
            }
        }

        if reader.status == .failed {
            throw reader.error ?? EditorError.readerSetupFailed
        }

        progress(1.0)
        return (
            points,
            AnalysisSummary(duration: duration, processedFrames: processedFrames, detectedFrames: detectedFrames)
        )
    }
}

enum EditorError: LocalizedError {
    case noVideoTrack
    case readerSetupFailed
    case exportSessionFailed
    case missingAnalysis
    case photoSaveFailed

    var errorDescription: String? {
        switch self {
        case .noVideoTrack: "動画トラックが見つかりません。"
        case .readerSetupFailed: "動画の読み込み準備に失敗しました。"
        case .exportSessionFailed: "動画の書き出しに失敗しました。"
        case .missingAnalysis: "先に人物検出を実行してください。"
        case .photoSaveFailed: "写真ライブラリへの保存に失敗しました。"
        }
    }
}
