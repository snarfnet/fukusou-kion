import AVFoundation
import Combine
import CoreGraphics
import CoreML
import CoreVideo
import Foundation
import ImageIO
import Vision

struct BicycleDetection: Identifiable, Equatable {
    let id = UUID()
    let rect: CGRect
    let confidence: Double
}

struct BicycleEvent: Identifiable {
    let id = UUID()
    let timestamp: Date
}

final class BicycleCounterViewModel: NSObject, ObservableObject {
    @Published var detections: [BicycleDetection] = []
    @Published var count = 0
    @Published var isRunning = false
    @Published var isCameraReady = false
    @Published var permissionDenied = false
    @Published var statusText = "待機中"
    @Published var recentEvents: [BicycleEvent] = []
    @Published var lineX: CGFloat = CGFloat(UserDefaults.standard.double(forKey: "bicycleLineX")) {
        didSet {
            let clamped = min(max(lineX, 0.12), 0.88)
            if lineX != clamped {
                lineX = clamped
                return
            }
            UserDefaults.standard.set(Double(lineX), forKey: "bicycleLineX")
            tracks = []
        }
    }
    @Published var recognitionDistance: Double = {
        let saved = UserDefaults.standard.double(forKey: "bicycleRecognitionDistance")
        return saved == 0 ? 0.55 : saved
    }() {
        didSet {
            let clamped = min(max(recognitionDistance, 0.0), 1.0)
            if recognitionDistance != clamped {
                recognitionDistance = clamped
                return
            }
            UserDefaults.standard.set(recognitionDistance, forKey: "bicycleRecognitionDistance")
            tracks = []
        }
    }

    let session = AVCaptureSession()

    private let videoOutput = AVCaptureVideoDataOutput()
    private let videoQueue = DispatchQueue(label: "bicycle.counter.video.queue")
    private var visionRequest: VNCoreMLRequest?
    private var tracks: [TrackedBicycle] = []
    private var frameIndex = 0
    private let staleFrameLimit = 8
    private let matchThreshold: CGFloat = 0.18

    override init() {
        if UserDefaults.standard.object(forKey: "bicycleLineX") == nil {
            lineX = 0.5
        }
        super.init()
        configureVisionModel()
    }

    var distanceLabel: String {
        switch recognitionDistance {
        case ..<0.34:
            return "近距離"
        case ..<0.67:
            return "標準"
        default:
            return "遠距離"
        }
    }

    var confidenceThreshold: VNConfidence {
        VNConfidence(0.58 - (recognitionDistance * 0.18))
    }

    var minBicycleArea: Double {
        0.014 - (recognitionDistance * 0.007)
    }

    func requestCameraAccess() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    granted ? self?.configureSession() : self?.markPermissionDenied()
                }
            }
        default:
            markPermissionDenied()
        }
    }

    func startCounting() {
        isRunning = true
        statusText = visionRequest == nil ? "モデル読込エラー" : "計測中"
        startSessionIfNeeded()
    }

    func pauseCounting() {
        isRunning = false
        statusText = "一時停止"
    }

    func reset() {
        count = 0
        recentEvents = []
        tracks = []
        detections = []
        statusText = isRunning ? "計測中" : "リセット済み"
    }

    func adjust(amount: Int) {
        count = max(0, count + amount)
        if amount > 0 {
            appendEvent()
        }
    }

    func moveLine(to normalizedX: CGFloat) {
        lineX = normalizedX
    }

    private func configureVisionModel() {
        do {
            let configuration = MLModelConfiguration()
            configuration.computeUnits = .all
            let model = try YOLOv3TinyInt8LUT(configuration: configuration).model
            let visionModel = try VNCoreMLModel(for: model)
            let request = VNCoreMLRequest(model: visionModel)
            request.imageCropAndScaleOption = .scaleFill
            visionRequest = request
        } catch {
            statusText = "モデル読込エラー"
        }
    }

    private func markPermissionDenied() {
        permissionDenied = true
        statusText = "カメラ許可が必要です"
    }

    private func configureSession() {
        guard !isCameraReady else { return }

        session.beginConfiguration()
        session.sessionPreset = .hd1280x720

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            statusText = "カメラを開始できません"
            session.commitConfiguration()
            return
        }

        session.addInput(input)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        videoOutput.connection(with: .video)?.videoOrientation = .portrait
        session.commitConfiguration()

        isCameraReady = true
        statusText = visionRequest == nil ? "モデル読込エラー" : "開始できます"
    }

    private func startSessionIfNeeded() {
        guard isCameraReady, !session.isRunning else { return }
        videoQueue.async { [weak self] in
            self?.session.startRunning()
        }
    }

    private func process(pixelBuffer: CVPixelBuffer) {
        guard isRunning, let visionRequest else {
            return
        }

        frameIndex += 1
        guard frameIndex % 3 == 0 else {
            return
        }

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right)
        do {
            try handler.perform([visionRequest])
            let observations = (visionRequest.results as? [VNRecognizedObjectObservation]) ?? []
            let bicycleDetections = bicycleDetections(from: observations)
            updateTracks(with: bicycleDetections)

            DispatchQueue.main.async {
                self.detections = bicycleDetections
                self.statusText = bicycleDetections.isEmpty ? "検出待ち" : "自転車検出中"
            }
        } catch {
            DispatchQueue.main.async {
                self.statusText = "検出エラー"
            }
        }
    }

    private func bicycleDetections(from observations: [VNRecognizedObjectObservation]) -> [BicycleDetection] {
        observations.compactMap { observation in
            guard let label = observation.labels.first else {
                return nil
            }
            guard label.identifier == "bicycle", label.confidence >= confidenceThreshold else {
                return nil
            }

            let rect = observation.boundingBox
            let area = Double(rect.width * rect.height)
            let aspectRatio = Double(rect.width / max(rect.height, 0.001))
            guard area >= minBicycleArea, aspectRatio >= 0.45, aspectRatio <= 3.8 else {
                return nil
            }

            return BicycleDetection(rect: rect, confidence: Double(label.confidence))
        }
        .sorted { $0.confidence > $1.confidence }
        .prefix(8)
        .map { $0 }
    }

    private func updateTracks(with detections: [BicycleDetection]) {
        tracks = tracks.map { track in
            var copy = track
            copy.framesSinceSeen += 1
            return copy
        }

        var matchedTrackIndexes = Set<Int>()
        for detection in detections {
            let center = CGPoint(x: detection.rect.midX, y: detection.rect.midY)
            if let matchIndex = bestMatchIndex(for: center, excluding: matchedTrackIndexes) {
                let previousX = tracks[matchIndex].lastCenter.x
                tracks[matchIndex].lastCenter = center
                tracks[matchIndex].framesSinceSeen = 0
                matchedTrackIndexes.insert(matchIndex)
                countCrossingIfNeeded(previousX: previousX, currentX: center.x, trackIndex: matchIndex)
            } else {
                tracks.append(TrackedBicycle(lastCenter: center))
            }
        }

        tracks.removeAll { $0.framesSinceSeen > staleFrameLimit }
    }

    private func bestMatchIndex(for center: CGPoint, excluding matchedTrackIndexes: Set<Int>) -> Int? {
        var bestIndex: Int?
        var bestDistance = CGFloat.greatestFiniteMagnitude

        for index in tracks.indices where tracks[index].framesSinceSeen < 4 && !matchedTrackIndexes.contains(index) {
            let distance = hypot(center.x - tracks[index].lastCenter.x, center.y - tracks[index].lastCenter.y)
            if distance < bestDistance {
                bestDistance = distance
                bestIndex = index
            }
        }

        return bestDistance < matchThreshold ? bestIndex : nil
    }

    private func countCrossingIfNeeded(previousX: CGFloat, currentX: CGFloat, trackIndex: Int) {
        guard isRunning, !tracks[trackIndex].hasCounted else { return }

        let crossedLeftToRight = previousX < lineX && currentX >= lineX
        let crossedRightToLeft = previousX > lineX && currentX <= lineX
        guard crossedLeftToRight || crossedRightToLeft else { return }

        tracks[trackIndex].hasCounted = true
        DispatchQueue.main.async {
            self.count += 1
            self.appendEvent()
        }
    }

    private func appendEvent() {
        recentEvents.insert(BicycleEvent(timestamp: Date()), at: 0)
        if recentEvents.count > 6 {
            recentEvents.removeLast()
        }
    }
}

extension BicycleCounterViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        process(pixelBuffer: pixelBuffer)
    }
}

private struct TrackedBicycle {
    var lastCenter: CGPoint
    var framesSinceSeen = 0
    var hasCounted = false
}
