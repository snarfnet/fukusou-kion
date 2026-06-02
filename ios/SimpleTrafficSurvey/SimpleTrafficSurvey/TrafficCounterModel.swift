import AVFoundation
import Combine
import CoreGraphics
import CoreML
import Foundation
import ImageIO
import Vision

struct PersonDetection: Identifiable, Equatable {
    let id: UUID
    let rect: CGRect
    let confidence: Float
    let source: DetectionSource
}

enum DetectionSource: Equatable {
    case vision
    case coreML
}

struct CountEvent: Identifiable {
    let id = UUID()
    let timestamp: Date
    let direction: CountDirection
}

enum CountDirection: String {
    case `in` = "IN"
    case out = "OUT"
    case pedestrian = "\u{901A}\u{884C}"
}

enum CountMode: String, Equatable {
    case storeTraffic
    case pedestrianTraffic

    static let storageKey = "countMode"

    static var saved: CountMode {
        let rawValue = UserDefaults.standard.string(forKey: storageKey) ?? ""
        return CountMode(rawValue: rawValue) ?? .pedestrianTraffic
    }

    var title: String {
        self == .storeTraffic ? "\u{5165}\u{9000}\u{5E97}" : "\u{901A}\u{884C}\u{91CF}"
    }

    var guideText: String {
        self == .storeTraffic
            ? "線を越えた向きに合わせてIN / OUTを記録します。"
            : "画面内で動いた歩行者を通行量として数えます。"
    }
}

enum CountDirectionMode: String, Equatable {
    case leftToRightIn
    case rightToLeftIn

    static let storageKey = "countDirectionMode"

    static var saved: CountDirectionMode {
        let rawValue = UserDefaults.standard.string(forKey: storageKey) ?? ""
        return CountDirectionMode(rawValue: rawValue) ?? .leftToRightIn
    }

    var leftLabel: String {
        self == .leftToRightIn ? "OUT" : "IN"
    }

    var rightLabel: String {
        self == .leftToRightIn ? "IN" : "OUT"
    }

    var guideText: String {
        self == .leftToRightIn
            ? "左から右はIN、右から左はOUTです。線はカメラ画面上で左右に動かせます。"
            : "右から左はIN、左から右はOUTです。線はカメラ画面上で左右に動かせます。"
    }
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
    @Published var countMode: CountMode = CountMode.saved {
        didSet {
            UserDefaults.standard.set(countMode.rawValue, forKey: CountMode.storageKey)
            tracks = []
        }
    }
    @Published var directionMode: CountDirectionMode = CountDirectionMode.saved {
        didSet {
            UserDefaults.standard.set(directionMode.rawValue, forKey: CountDirectionMode.storageKey)
            tracks = []
        }
    }

    let session = AVCaptureSession()

    private let videoOutput = AVCaptureVideoDataOutput()
    private let videoQueue = DispatchQueue(label: "camera.counter.video.queue")
    private let visionQueue = DispatchQueue(label: "camera.counter.vision.queue")
    private var isProcessingFrame = false
    private var coreMLRequest: VNCoreMLRequest?
    private var tracks: [TrackedPerson] = []
    private let matchThreshold: CGFloat = 0.22
    private let staleFrameLimit = 20
    private let pedestrianMinimumFrames = 3
    private let pedestrianMovementThreshold: CGFloat = 0.055
    private let pedestrianEdgeMovementThreshold: CGFloat = 0.025

    override init() {
        super.init()
        configureCoreMLModel()
    }

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
        detections = []
        statusText = isRunning ? "\u{8ABF}\u{67FB}\u{4E2D}" : "\u{30EA}\u{30BB}\u{30C3}\u{30C8}\u{6E08}\u{307F}"
    }

    func adjust(_ direction: CountDirection, amount: Int) {
        switch direction {
        case .in, .pedestrian:
            countIn = max(0, countIn + amount)
        case .out:
            countOut = max(0, countOut + amount)
        }
        if amount > 0 {
            appendEvent(direction == .pedestrian ? .pedestrian : direction)
        }
    }

    func moveLine(to normalizedX: CGFloat) {
        lineX = min(max(normalizedX, 0.12), 0.88)
        tracks = []
    }

    func toggleDirectionMode() {
        directionMode = directionMode == .leftToRightIn ? .rightToLeftIn : .leftToRightIn
    }

    func setDirectionMode(_ mode: CountDirectionMode) {
        directionMode = mode
    }

    func toggleCountMode() {
        countMode = countMode == .storeTraffic ? .pedestrianTraffic : .storeTraffic
    }

    func setCountMode(_ mode: CountMode) {
        countMode = mode
    }

    private func configureCoreMLModel() {
        do {
            let configuration = MLModelConfiguration()
            configuration.computeUnits = .all
            let model = try YOLOv3TinyInt8LUT(configuration: configuration).model
            let visionModel = try VNCoreMLModel(for: model)
            let request = VNCoreMLRequest(model: visionModel)
            request.imageCropAndScaleOption = .scaleFill
            coreMLRequest = request
        } catch {
            coreMLRequest = nil
        }
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

    private func handleDetections(
        humanObservations: [VNHumanObservation],
        objectObservations: [VNRecognizedObjectObservation]
    ) {
        let normalizedDetections = mergedPersonDetections(
            humanObservations: humanObservations,
            objectObservations: objectObservations
        )

        updateTracks(with: normalizedDetections)

        DispatchQueue.main.async {
            self.detections = normalizedDetections
            if self.isRunning {
                self.statusText = normalizedDetections.isEmpty ? "\u{691C}\u{51FA}\u{5F85}\u{3061}" : "\(normalizedDetections.count)\u{4EBA}\u{3092}\u{691C}\u{51FA}\u{4E2D}"
            }
        }
    }

    private func mergedPersonDetections(
        humanObservations: [VNHumanObservation],
        objectObservations: [VNRecognizedObjectObservation]
    ) -> [PersonDetection] {
        let visionDetections = humanObservations
            .filter { $0.confidence > 0.20 }
            .map {
                PersonDetection(
                    id: UUID(),
                    rect: $0.boundingBox,
                    confidence: $0.confidence,
                    source: .vision
                )
            }

        let coreMLDetections = objectObservations.compactMap { observation -> PersonDetection? in
            guard let label = observation.labels.first,
                  label.identifier == "person",
                  label.confidence >= 0.25
            else {
                return nil
            }

            let rect = observation.boundingBox
            let area = rect.width * rect.height
            let aspectRatio = rect.width / max(rect.height, 0.001)
            guard area >= 0.0015, rect.height >= 0.04, aspectRatio >= 0.12, aspectRatio <= 1.7 else {
                return nil
            }

            return PersonDetection(
                id: UUID(),
                rect: rect,
                confidence: label.confidence,
                source: .coreML
            )
        }

        return deduplicatedDetections(visionDetections + coreMLDetections)
    }

    private func deduplicatedDetections(_ detections: [PersonDetection]) -> [PersonDetection] {
        var merged: [PersonDetection] = []
        let sorted = detections.sorted { lhs, rhs in
            if lhs.source != rhs.source {
                return lhs.source == .vision
            }
            return lhs.confidence > rhs.confidence
        }

        for detection in sorted {
            guard !merged.contains(where: { intersectionOverUnion($0.rect, detection.rect) > 0.45 }) else {
                continue
            }
            merged.append(detection)
        }

        return Array(merged.prefix(30))
    }

    private func intersectionOverUnion(_ lhs: CGRect, _ rhs: CGRect) -> CGFloat {
        let intersection = lhs.intersection(rhs)
        guard !intersection.isNull else {
            return 0
        }

        let intersectionArea = intersection.width * intersection.height
        let unionArea = (lhs.width * lhs.height) + (rhs.width * rhs.height) - intersectionArea
        return unionArea > 0 ? intersectionArea / unionArea : 0
    }

    private func updateTracks(with detections: [PersonDetection]) {
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
                tracks[matchIndex].seenFrames += 1
                tracks[matchIndex].lastCenter = center
                tracks[matchIndex].framesSinceSeen = 0
                matchedTrackIndexes.insert(matchIndex)
                countCrossingIfNeeded(previousX: previousX, currentX: center.x, trackIndex: matchIndex)
                countPedestrianIfNeeded(trackIndex: matchIndex)
            } else {
                var newTrack = TrackedPerson(lastCenter: center)
                newTrack.firstCenter = center
                newTrack.startedNearEdge = isNearFrameEdge(center)
                tracks.append(newTrack)
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
        guard countMode == .storeTraffic, isRunning, !tracks[trackIndex].hasCounted else { return }

        let crossedLeftToRight = previousX < lineX && currentX >= lineX
        let crossedRightToLeft = previousX > lineX && currentX <= lineX

        if crossedLeftToRight {
            tracks[trackIndex].hasCounted = true
            DispatchQueue.main.async {
                self.applyCrossing(.leftToRightIn)
            }
        } else if crossedRightToLeft {
            tracks[trackIndex].hasCounted = true
            DispatchQueue.main.async {
                self.applyCrossing(.rightToLeftIn)
            }
        }
    }

    private func countPedestrianIfNeeded(trackIndex: Int) {
        guard countMode == .pedestrianTraffic, isRunning, !tracks[trackIndex].hasCounted else { return }

        let track = tracks[trackIndex]
        guard track.seenFrames >= pedestrianMinimumFrames else { return }

        let movement = hypot(track.lastCenter.x - track.firstCenter.x, track.lastCenter.y - track.firstCenter.y)
        let movementThreshold = track.startedNearEdge ? pedestrianEdgeMovementThreshold : pedestrianMovementThreshold
        guard movement >= movementThreshold else { return }

        tracks[trackIndex].hasCounted = true
        DispatchQueue.main.async {
            self.countIn += 1
            self.appendEvent(.pedestrian)
        }
    }

    private func isNearFrameEdge(_ point: CGPoint) -> Bool {
        point.x < 0.18 || point.x > 0.82 || point.y < 0.18 || point.y > 0.82
    }

    private func applyCrossing(_ crossingMode: CountDirectionMode) {
        let direction: CountDirection = directionMode == crossingMode ? .in : .out
        switch direction {
        case .in:
            countIn += 1
        case .out:
            countOut += 1
        case .pedestrian:
            countIn += 1
        }
        appendEvent(direction)
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
        visionQueue.async {
            let humanRequest = VNDetectHumanRectanglesRequest()
            humanRequest.upperBodyOnly = false
            var requests: [VNRequest] = [humanRequest]
            if let coreMLRequest = self.coreMLRequest {
                requests.append(coreMLRequest)
            }

            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
            do {
                try handler.perform(requests)
                let humanObservations = humanRequest.results ?? []
                let objectObservations = self.coreMLRequest?.results as? [VNRecognizedObjectObservation] ?? []
                self.handleDetections(
                    humanObservations: humanObservations,
                    objectObservations: objectObservations
                )
            } catch {
                DispatchQueue.main.async {
                    self.statusText = "検出エラー"
                }
            }
            self.isProcessingFrame = false
        }
    }
}

private struct TrackedPerson {
    var firstCenter: CGPoint
    var lastCenter: CGPoint
    var framesSinceSeen = 0
    var seenFrames = 1
    var hasCounted = false
    var startedNearEdge = false

    init(lastCenter: CGPoint) {
        self.firstCenter = lastCenter
        self.lastCenter = lastCenter
    }
}
