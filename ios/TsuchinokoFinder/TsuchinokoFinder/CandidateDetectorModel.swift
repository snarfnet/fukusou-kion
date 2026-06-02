import AVFoundation
import CoreML
import Foundation
import UserNotifications
import Vision

struct CandidateEvent: Identifiable {
    let id = UUID()
    let timestamp: Date
    let confidence: Double
}

private struct CandidateFrameAnalysis {
    let shapeScore: Double
    let objectArea: Double
    let aspectRatio: Double

    static let unavailable = CandidateFrameAnalysis(shapeScore: 0.35, objectArea: 1, aspectRatio: 1)
}

final class CandidateDetectorViewModel: NSObject, ObservableObject {
    @Published var isScanning = false
    @Published var isCameraReady = false
    @Published var permissionDenied = false
    @Published var modelReady = false
    @Published var statusText = Copy.preparing
    @Published var candidateConfidence = 0.0
    @Published var candidateLabel = Copy.noCandidate
    @Published var notificationStatusText = Copy.notificationOff
    @Published var notificationEnabled: Bool = UserDefaults.standard.bool(forKey: "tsuchinokoNotificationEnabled") {
        didSet {
            UserDefaults.standard.set(notificationEnabled, forKey: "tsuchinokoNotificationEnabled")
            if notificationEnabled {
                requestNotificationPermission()
            } else {
                notificationStatusText = Copy.notificationOff
            }
        }
    }
    @Published var recentEvents: [CandidateEvent] = []
    @Published var threshold: Double = {
        let saved = UserDefaults.standard.double(forKey: "tsuchinokoThreshold")
        return saved == 0 ? 0.97 : max(saved, 0.90)
    }() {
        didSet {
            let clamped = min(max(threshold, 0.90), 0.99)
            if threshold != clamped {
                threshold = clamped
                return
            }
            UserDefaults.standard.set(threshold, forKey: "tsuchinokoThreshold")
        }
    }

    let session = AVCaptureSession()

    private let videoOutput = AVCaptureVideoDataOutput()
    private let videoQueue = DispatchQueue(label: "tsuchinoko.finder.video.queue")
    private var visionRequest: VNCoreMLRequest?
    private var frameIndex = 0
    private var isProcessingFrame = false
    private var lastCandidateAt = Date.distantPast
    private var lastNotificationAt = Date.distantPast
    private var lastFrameSignature: [UInt8]?
    private var lastMotionScore = 0.0
    private var latestFrameAnalysis = CandidateFrameAnalysis.unavailable
    private var candidateStreak = 0
    private let inferenceFrameStride = 15
    private let requiredCandidateStreak = 5
    private let minimumMotionScore = 0.018
    private let minimumShapeScore = 0.62

    var thresholdLabel: String {
        "\(Int(threshold * 100))%"
    }

    var confidenceLabel: String {
        "\(Int(candidateConfidence * 100))%"
    }

    var hasCandidate: Bool {
        candidateStreak >= requiredCandidateStreak && candidateConfidence >= threshold
    }

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        if notificationEnabled {
            requestNotificationPermission()
        }
    }

    func requestCameraAccess() {
        loadModel()

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

    func startScanning() {
        guard modelReady else {
            statusText = Copy.modelUnavailable
            return
        }
        isScanning = true
        statusText = Copy.scanning
        startSessionIfNeeded()
    }

    func pauseScanning() {
        isScanning = false
        statusText = Copy.paused
    }

    func resetLog() {
        recentEvents = []
        candidateConfidence = 0
        candidateLabel = Copy.noCandidate
        candidateStreak = 0
        lastFrameSignature = nil
        lastMotionScore = 0
        latestFrameAnalysis = .unavailable
        statusText = isScanning ? Copy.scanning : Copy.resetDone
    }

    private func loadModel() {
        guard visionRequest == nil else { return }

        guard let modelURL = Bundle.main.url(forResource: "TsuchinokoCandidate", withExtension: "mlmodelc") else {
            statusText = Copy.modelMissing
            return
        }

        do {
            let model = try MLModel(contentsOf: modelURL)
            let visionModel = try VNCoreMLModel(for: model)
            let request = VNCoreMLRequest(model: visionModel) { [weak self] request, _ in
                self?.handleVisionResult(request.results)
            }
            request.imageCropAndScaleOption = .centerCrop
            visionRequest = request
            modelReady = true
            statusText = Copy.ready
        } catch {
            statusText = Copy.modelLoadError
        }
    }

    private func markPermissionDenied() {
        permissionDenied = true
        statusText = Copy.cameraPermissionNeeded
    }

    private func configureSession() {
        guard !isCameraReady else { return }

        session.beginConfiguration()
        session.sessionPreset = .vga640x480

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            statusText = Copy.cameraUnavailable
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
        statusText = modelReady ? Copy.ready : statusText
    }

    private func startSessionIfNeeded() {
        guard isCameraReady, !session.isRunning else { return }
        videoQueue.async { [weak self] in
            self?.session.startRunning()
        }
    }

    private func process(pixelBuffer: CVPixelBuffer) {
        guard isScanning, let visionRequest else { return }
        frameIndex += 1
        guard frameIndex % inferenceFrameStride == 0, !isProcessingFrame else { return }

        lastMotionScore = motionScore(for: pixelBuffer)
        latestFrameAnalysis = candidateFrameAnalysis(for: pixelBuffer)
        isProcessingFrame = true
        defer { isProcessingFrame = false }
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right)
        do {
            try handler.perform([visionRequest])
        } catch {
            DispatchQueue.main.async {
                self.statusText = Copy.analysisFailed
            }
        }
    }

    private func handleVisionResult(_ results: [Any]?) {
        guard
            let observations = results as? [VNClassificationObservation],
            let candidate = observations.first(where: { $0.identifier == "tsuchinoko_candidate" })
        else {
            DispatchQueue.main.async {
                self.candidateConfidence = 0
                self.candidateLabel = Copy.noCandidate
            }
            return
        }

        let confidence = Double(candidate.confidence)
        let frameAnalysis = latestFrameAnalysis
        let calibratedConfidence = candidateScore(rawConfidence: confidence, frameAnalysis: frameAnalysis)
        DispatchQueue.main.async {
            let hasEnoughMotion = self.lastMotionScore >= self.minimumMotionScore
            let hasCandidateShape = frameAnalysis.shapeScore >= self.minimumShapeScore
            let isStrongCandidate = calibratedConfidence >= self.threshold && hasEnoughMotion && hasCandidateShape
            self.candidateStreak = isStrongCandidate ? min(self.candidateStreak + 1, self.requiredCandidateStreak) : 0
            self.candidateConfidence = self.displayConfidence(for: calibratedConfidence, rawConfidence: confidence, frameAnalysis: frameAnalysis)

            if self.candidateStreak >= self.requiredCandidateStreak {
                self.candidateLabel = Copy.tsuchinokoCandidate
                self.statusText = Copy.candidateDetected
                self.appendEventIfNeeded(confidence: self.candidateConfidence)
            } else if confidence >= 0.82 && !hasCandidateShape {
                self.candidateLabel = Copy.noCandidate
                self.statusText = Copy.shapeRejected
            } else if calibratedConfidence >= 0.58 {
                self.candidateLabel = Copy.reviewNeeded
                self.statusText = Copy.confirmingCandidate
            } else {
                self.candidateLabel = Copy.noCandidate
                self.statusText = self.isScanning ? Copy.scanning : self.statusText
            }
        }
    }

    private func candidateScore(rawConfidence: Double, frameAnalysis: CandidateFrameAnalysis) -> Double {
        let areaPenalty = frameAnalysis.objectArea > 0.36 ? 0.35 : 1
        let score = rawConfidence * frameAnalysis.shapeScore * areaPenalty
        return min(max(score, 0), 0.99)
    }

    private func displayConfidence(
        for calibratedConfidence: Double,
        rawConfidence: Double,
        frameAnalysis: CandidateFrameAnalysis
    ) -> Double {
        guard candidateStreak >= requiredCandidateStreak else {
            if rawConfidence >= 0.82 && frameAnalysis.shapeScore < minimumShapeScore {
                return min(calibratedConfidence, 0.49)
            }
            return min(calibratedConfidence, threshold - 0.01)
        }
        return calibratedConfidence
    }

    private func motionScore(for pixelBuffer: CVPixelBuffer) -> Double {
        guard let signature = frameSignature(for: pixelBuffer) else {
            return 1
        }
        defer { lastFrameSignature = signature }
        guard let previous = lastFrameSignature, previous.count == signature.count else {
            return 1
        }

        let total = zip(previous, signature).reduce(0) { partial, pair in
            partial + abs(Int(pair.0) - Int(pair.1))
        }
        return Double(total) / Double(signature.count * 255)
    }

    private func frameSignature(for pixelBuffer: CVPixelBuffer) -> [UInt8]? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard
            CVPixelBufferGetPixelFormatType(pixelBuffer) == kCVPixelFormatType_32BGRA,
            let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        else {
            return nil
        }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
        let columns = 12
        let rows = 16
        var signature: [UInt8] = []
        signature.reserveCapacity(columns * rows)

        for row in 0..<rows {
            let y = min(height - 1, max(0, (row * height) / rows))
            for column in 0..<columns {
                let x = min(width - 1, max(0, (column * width) / columns))
                let offset = y * bytesPerRow + x * 4
                let blue = Int(pointer[offset])
                let green = Int(pointer[offset + 1])
                let red = Int(pointer[offset + 2])
                signature.append(UInt8((red + green + blue) / 3))
            }
        }

        return signature
    }

    private func candidateFrameAnalysis(for pixelBuffer: CVPixelBuffer) -> CandidateFrameAnalysis {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard
            CVPixelBufferGetPixelFormatType(pixelBuffer) == kCVPixelFormatType_32BGRA,
            let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        else {
            return .unavailable
        }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let pointer = baseAddress.assumingMemoryBound(to: UInt8.self)
        let columns = 48
        let rows = 36
        let cellCount = columns * rows
        var redValues = Array(repeating: 0.0, count: cellCount)
        var greenValues = Array(repeating: 0.0, count: cellCount)
        var blueValues = Array(repeating: 0.0, count: cellCount)
        var brightnessValues = Array(repeating: 0.0, count: cellCount)

        for row in 0..<rows {
            let y = min(height - 1, max(0, ((row * 2 + 1) * height) / (rows * 2)))
            for column in 0..<columns {
                let x = min(width - 1, max(0, ((column * 2 + 1) * width) / (columns * 2)))
                let offset = y * bytesPerRow + x * 4
                let blue = Double(pointer[offset])
                let green = Double(pointer[offset + 1])
                let red = Double(pointer[offset + 2])
                let index = row * columns + column
                redValues[index] = red
                greenValues[index] = green
                blueValues[index] = blue
                brightnessValues[index] = (red + green + blue) / 3
            }
        }

        let borderIndexes = (0..<cellCount).filter { index in
            let row = index / columns
            let column = index % columns
            return row == 0 || row == rows - 1 || column == 0 || column == columns - 1
        }
        guard !borderIndexes.isEmpty else { return .unavailable }

        let borderRed = borderIndexes.reduce(0) { $0 + redValues[$1] } / Double(borderIndexes.count)
        let borderGreen = borderIndexes.reduce(0) { $0 + greenValues[$1] } / Double(borderIndexes.count)
        let borderBlue = borderIndexes.reduce(0) { $0 + blueValues[$1] } / Double(borderIndexes.count)
        let borderBrightness = borderIndexes.reduce(0) { $0 + brightnessValues[$1] } / Double(borderIndexes.count)

        var maskCount = 0
        var minColumn = columns
        var maxColumn = 0
        var minRow = rows
        var maxRow = 0

        for row in 1..<(rows - 1) {
            for column in 1..<(columns - 1) {
                let index = row * columns + column
                let colorDistance = abs(redValues[index] - borderRed)
                    + abs(greenValues[index] - borderGreen)
                    + abs(blueValues[index] - borderBlue)
                let horizontalEdge = abs(brightnessValues[index] - brightnessValues[index - 1])
                let verticalEdge = abs(brightnessValues[index] - brightnessValues[index - columns])
                let brightnessDistance = abs(brightnessValues[index] - borderBrightness)
                let isForeground = colorDistance > 72 || brightnessDistance > 34 || horizontalEdge + verticalEdge > 58

                if isForeground {
                    maskCount += 1
                    minColumn = min(minColumn, column)
                    maxColumn = max(maxColumn, column)
                    minRow = min(minRow, row)
                    maxRow = max(maxRow, row)
                }
            }
        }

        guard maskCount > 10, minColumn <= maxColumn, minRow <= maxRow else {
            return CandidateFrameAnalysis(shapeScore: 0.18, objectArea: 0, aspectRatio: 1)
        }

        let objectArea = Double(maskCount) / Double(cellCount)
        let boxWidth = maxColumn - minColumn + 1
        let boxHeight = maxRow - minRow + 1
        let longSide = Double(max(boxWidth, boxHeight))
        let shortSide = Double(max(1, min(boxWidth, boxHeight)))
        let aspectRatio = longSide / shortSide
        let fillRatio = Double(maskCount) / Double(boxWidth * boxHeight)
        let edgeTouchCount = [
            minColumn <= 1,
            maxColumn >= columns - 2,
            minRow <= 1,
            maxRow >= rows - 2
        ].filter { $0 }.count

        let areaScore = scoreBand(objectArea, min: 0.018, idealMin: 0.045, idealMax: 0.24, max: 0.36)
        let aspectScore = scoreBand(aspectRatio, min: 1.45, idealMin: 1.85, idealMax: 5.8, max: 8.5)
        let fillScore = scoreBand(fillRatio, min: 0.12, idealMin: 0.20, idealMax: 0.66, max: 0.84)
        let edgeScore: Double = edgeTouchCount >= 2 ? 0.35 : (edgeTouchCount == 1 ? 0.72 : 1)
        let score = areaScore * aspectScore * fillScore * edgeScore

        return CandidateFrameAnalysis(
            shapeScore: min(max(score, 0), 1),
            objectArea: objectArea,
            aspectRatio: aspectRatio
        )
    }

    private func scoreBand(_ value: Double, min: Double, idealMin: Double, idealMax: Double, max: Double) -> Double {
        if value < min || value > max {
            return 0
        }
        if value >= idealMin && value <= idealMax {
            return 1
        }
        if value < idealMin {
            return (value - min) / (idealMin - min)
        }
        return (max - value) / (max - idealMax)
    }

    private func appendEventIfNeeded(confidence: Double) {
        guard Date().timeIntervalSince(lastCandidateAt) > 4 else { return }
        lastCandidateAt = Date()
        recentEvents.insert(CandidateEvent(timestamp: Date(), confidence: confidence), at: 0)
        if recentEvents.count > 8 {
            recentEvents.removeLast()
        }
        sendCandidateNotificationIfNeeded(confidence: confidence)
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                self?.notificationStatusText = granted ? Copy.notificationOn : Copy.notificationDenied
                if !granted {
                    self?.notificationEnabled = false
                    self?.notificationStatusText = Copy.notificationDenied
                }
            }
        }
    }

    private func sendCandidateNotificationIfNeeded(confidence: Double) {
        guard notificationEnabled, Date().timeIntervalSince(lastNotificationAt) > 60 else {
            return
        }
        lastNotificationAt = Date()

        let content = UNMutableNotificationContent()
        content.title = Copy.notificationTitle
        content.body = "\(Copy.notificationBody) \(Int(confidence * 100))%"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "tsuchinoko-candidate-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

}

extension CandidateDetectorViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
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

private enum Copy {
    static let preparing = "\u{6E96}\u{5099}\u{4E2D}"
    static let ready = "\u{958B}\u{59CB}\u{3067}\u{304D}\u{307E}\u{3059}"
    static let scanning = "\u{63A2}\u{7D22}\u{4E2D}"
    static let paused = "\u{4E00}\u{6642}\u{505C}\u{6B62}"
    static let resetDone = "\u{30EA}\u{30BB}\u{30C3}\u{30C8}\u{6E08}\u{307F}"
    static let noCandidate = "\u{5019}\u{88DC}\u{306A}\u{3057}"
    static let tsuchinokoCandidate = "\u{30C4}\u{30C1}\u{30CE}\u{30B3}\u{5019}\u{88DC}"
    static let reviewNeeded = "\u{8981}\u{78BA}\u{8A8D}"
    static let candidateDetected = "\u{5019}\u{88DC}\u{3092}\u{691C}\u{77E5}"
    static let confirmingCandidate = "\u{9023}\u{7D9A}\u{78BA}\u{8A8D}\u{4E2D}"
    static let shapeRejected = "\u{5F62}\u{72B6}\u{304C}\u{5019}\u{88DC}\u{5916}"
    static let notificationOff = "通知はオフ"
    static let notificationOn = "通知はオン"
    static let notificationDenied = "通知が許可されていません"
    static let notificationTitle = "ツチノコ候補を検知"
    static let notificationBody = "候補らしさ:"
    static let cameraPermissionNeeded = "\u{30AB}\u{30E1}\u{30E9}\u{8A31}\u{53EF}\u{304C}\u{5FC5}\u{8981}\u{3067}\u{3059}"
    static let cameraUnavailable = "\u{30AB}\u{30E1}\u{30E9}\u{3092}\u{958B}\u{3051}\u{307E}\u{305B}\u{3093}"
    static let modelMissing = "Model file is missing"
    static let modelUnavailable = "Model is not ready"
    static let modelLoadError = "Model load error"
    static let analysisFailed = "Analysis failed"
}

extension CandidateDetectorViewModel: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
