import AVFoundation
import Combine
import CoreGraphics
import Foundation
import Vision

struct PersonDetection: Identifiable, Equatable {
    let id: UUID
    let rect: CGRect
    let confidence: Float
}

struct CountEvent: Identifiable {
    let id = UUID()
    let timestamp: Date
    let direction: CountDirection
}

enum CountDirection: String {
    case `in` = "IN"
    case out = "OUT"
}

final class CameraCounterViewModel: NSObject, ObservableObject {
    @Published var detections: [PersonDetection] = []
    @Published var countIn = 0
    @Published var countOut = 0
    @Published var isRunning = false
    @Published var isCameraReady = false
    @Published var permissionDenied = false
    @Published var statusText = "\u{5F85}\u{6A5F}\u{4E2D}"
    @Published var recentEvents: [CountEvent] = []
    @Published private(set) var lineX: CGFloat = 0.5

    let session = AVCaptureSession()

    private let videoOutput = AVCaptureVideoDataOutput()
    private let videoQueue = DispatchQueue(label: "camera.counter.video.queue")
    private let visionQueue = DispatchQueue(label: "camera.counter.vision.queue")
    private var isProcessingFrame = false
    private var tracks: [TrackedPerson] = []
    private let matchThreshold: CGFloat = 0.16
    private let staleFrameLimit = 12

    var total: Int {
        countIn + countOut
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
        statusText = "\u{8ABF}\u{67FB}\u{4E2D}"
        startSessionIfNeeded()
    }

    func pauseCounting() {
        isRunning = false
        statusText = "\u{4E00}\u{6642}\u{505C}\u{6B62}"
    }

    func reset() {
        countIn = 0
        countOut = 0
        recentEvents = []
        tracks = []
        statusText = isRunning ? "\u{8ABF}\u{67FB}\u{4E2D}" : "\u{30EA}\u{30BB}\u{30C3}\u{30C8}\u{6E08}\u{307F}"
    }

    func adjust(_ direction: CountDirection, amount: Int) {
        switch direction {
        case .in:
            countIn = max(0, countIn + amount)
        case .out:
            countOut = max(0, countOut + amount)
        }
        if amount > 0 {
            appendEvent(direction)
        }
    }

    func moveLine(to normalizedX: CGFloat) {
        lineX = min(max(normalizedX, 0.12), 0.88)
        tracks = []
    }

    private func markPermissionDenied() {
        permissionDenied = true
        statusText = "\u{30AB}\u{30E1}\u{30E9}\u{8A31}\u{53EF}\u{304C}\u{5FC5}\u{8981}\u{3067}\u{3059}"
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
            statusText = "\u{30AB}\u{30E1}\u{30E9}\u{3092}\u{958B}\u{59CB}\u{3067}\u{304D}\u{307E}\u{305B}\u{3093}"
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
        statusText = "\u{958B}\u{59CB}\u{3067}\u{304D}\u{307E}\u{3059}"
    }

    private func startSessionIfNeeded() {
        guard isCameraReady, !session.isRunning else { return }
        videoQueue.async { [weak self] in
            self?.session.startRunning()
        }
    }

    private func handleDetections(_ observations: [VNHumanObservation]) {
        let normalizedDetections = observations
            .filter { $0.confidence > 0.35 }
            .map { PersonDetection(id: UUID(), rect: $0.boundingBox, confidence: $0.confidence) }

        updateTracks(with: normalizedDetections)

        DispatchQueue.main.async {
            self.detections = normalizedDetections
            if self.isRunning {
                self.statusText = normalizedDetections.isEmpty ? "\u{691C}\u{51FA}\u{5F85}\u{3061}" : "\(normalizedDetections.count)\u{4EBA}\u{3092}\u{691C}\u{51FA}\u{4E2D}"
            }
        }
    }

    private func updateTracks(with detections: [PersonDetection]) {
        tracks = tracks.map { track in
            var copy = track
            copy.framesSinceSeen += 1
            return copy
        }

        for detection in detections {
            let center = CGPoint(x: detection.rect.midX, y: detection.rect.midY)
            if let matchIndex = bestMatchIndex(for: center) {
                let previousX = tracks[matchIndex].lastCenter.x
                tracks[matchIndex].lastCenter = center
                tracks[matchIndex].framesSinceSeen = 0
                countCrossingIfNeeded(previousX: previousX, currentX: center.x, trackIndex: matchIndex)
            } else {
                tracks.append(TrackedPerson(lastCenter: center))
            }
        }

        tracks.removeAll { $0.framesSinceSeen > staleFrameLimit }
    }

    private func bestMatchIndex(for center: CGPoint) -> Int? {
        var bestIndex: Int?
        var bestDistance = CGFloat.greatestFiniteMagnitude

        for index in tracks.indices where tracks[index].framesSinceSeen < 4 {
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

        if crossedLeftToRight {
            tracks[trackIndex].hasCounted = true
            DispatchQueue.main.async {
                self.countIn += 1
                self.appendEvent(.in)
            }
        } else if crossedRightToLeft {
            tracks[trackIndex].hasCounted = true
            DispatchQueue.main.async {
                self.countOut += 1
                self.appendEvent(.out)
            }
        }
    }

    private func appendEvent(_ direction: CountDirection) {
        recentEvents.insert(CountEvent(timestamp: Date(), direction: direction), at: 0)
        if recentEvents.count > 6 {
            recentEvents.removeLast()
        }
    }
}

extension CameraCounterViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard isRunning, !isProcessingFrame, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        isProcessingFrame = true
        let request = VNDetectHumanRectanglesRequest { [weak self] request, _ in
            guard let self else { return }
            let observations = request.results as? [VNHumanObservation] ?? []
            self.handleDetections(observations)
            self.isProcessingFrame = false
        }
        request.upperBodyOnly = false

        visionQueue.async {
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
            do {
                try handler.perform([request])
            } catch {
                self.isProcessingFrame = false
            }
        }
    }
}

private struct TrackedPerson {
    var lastCenter: CGPoint
    var framesSinceSeen = 0
    var hasCounted = false
}
