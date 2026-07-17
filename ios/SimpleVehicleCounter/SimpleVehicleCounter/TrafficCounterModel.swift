import AVFoundation
import Combine
import CoreGraphics
import CoreVideo
import Foundation

struct VehicleDetection: Identifiable, Equatable {
    let id = UUID()
    let rect: CGRect
    let motionScore: Double
    let vehicleScore: Double
}

struct VehicleEvent: Identifiable {
    let id = UUID()
    let timestamp: Date
}

final class VehicleCounterViewModel: NSObject, ObservableObject {
    @Published var detections: [VehicleDetection] = []
    @Published var count = 0
    @Published var isRunning = false
    @Published var isCameraReady = false
    @Published var permissionDenied = false
    @Published var statusText = "待機中"
    @Published var recentEvents: [VehicleEvent] = []
    @Published var lineX: CGFloat = CGFloat(UserDefaults.standard.double(forKey: "vehicleLineX")) {
        didSet {
            let clamped = min(max(lineX, 0.12), 0.88)
            if lineX != clamped {
                lineX = clamped
                return
            }
            UserDefaults.standard.set(Double(lineX), forKey: "vehicleLineX")
            tracks = []
        }
    }
    @Published var recognitionDistance: Double = {
        let saved = UserDefaults.standard.double(forKey: "vehicleRecognitionDistance")
        return saved == 0 ? 0.55 : saved
    }() {
        didSet {
            let clamped = min(max(recognitionDistance, 0.0), 1.0)
            if recognitionDistance != clamped {
                recognitionDistance = clamped
                return
            }
            UserDefaults.standard.set(recognitionDistance, forKey: "vehicleRecognitionDistance")
            tracks = []
        }
    }

    let session = AVCaptureSession()

    private let videoOutput = AVCaptureVideoDataOutput()
    private let videoQueue = DispatchQueue(label: "vehicle.counter.video.queue")
    private var previousFrame: SampledFrame?
    private var tracks: [TrackedVehicle] = []
    private let staleFrameLimit = 10
    private let matchThreshold: CGFloat = 0.22

    override init() {
        if UserDefaults.standard.object(forKey: "vehicleLineX") == nil {
            lineX = 0.5
        }
        super.init()
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

    var minMotionAreaRatio: Double {
        0.065 - (recognitionDistance * 0.038)
    }

    var minVehicleWidth: Double {
        0.22 - (recognitionDistance * 0.08)
    }

    var minVehicleHeight: Double {
        0.09 - (recognitionDistance * 0.025)
    }

    var minVehicleBoxArea: Double {
        0.032 - (recognitionDistance * 0.014)
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
        statusText = "計測中"
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
        previousFrame = nil
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
        statusText = "開始できます"
    }

    private func startSessionIfNeeded() {
        guard isCameraReady, !session.isRunning else { return }
        videoQueue.async { [weak self] in
            self?.session.startRunning()
        }
    }

    private func process(pixelBuffer: CVPixelBuffer) {
        let currentFrame = sample(pixelBuffer: pixelBuffer)
        defer { previousFrame = currentFrame }

        guard let previousFrame, isRunning else {
            return
        }

        let detection = detectMovingVehicle(current: currentFrame, previous: previousFrame)
        updateTracks(with: detection)

        DispatchQueue.main.async {
            if let detection {
                self.detections = [detection]
                self.statusText = "車両候補を検出中"
            } else {
                self.detections = []
                self.statusText = self.isRunning ? "検出待ち" : self.statusText
            }
        }
    }

    private func sample(pixelBuffer: CVPixelBuffer) -> SampledFrame {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)!.assumingMemoryBound(to: UInt8.self)
        let columns = 48
        let rows = 72
        var values = [UInt8](repeating: 0, count: columns * rows)

        for row in 0..<rows {
            let y = min(height - 1, row * height / rows)
            for column in 0..<columns {
                let x = min(width - 1, column * width / columns)
                let offset = y * bytesPerRow + x * 4
                let blue = Int(baseAddress[offset])
                let green = Int(baseAddress[offset + 1])
                let red = Int(baseAddress[offset + 2])
                values[row * columns + column] = UInt8((red * 30 + green * 59 + blue * 11) / 100)
            }
        }

        return SampledFrame(columns: columns, rows: rows, values: values)
    }

    private func detectMovingVehicle(current: SampledFrame, previous: SampledFrame) -> VehicleDetection? {
        let threshold = 28
        var minX = current.columns
        var maxX = 0
        var minY = current.rows
        var maxY = 0
        var changed = 0

        for index in current.values.indices {
            let delta = abs(Int(current.values[index]) - Int(previous.values[index]))
            guard delta > threshold else { continue }
            let x = index % current.columns
            let y = index / current.columns
            minX = min(minX, x)
            maxX = max(maxX, x)
            minY = min(minY, y)
            maxY = max(maxY, y)
            changed += 1
        }

        let ratio = Double(changed) / Double(current.values.count)
        guard ratio >= minMotionAreaRatio, maxX > minX, maxY > minY else {
            return nil
        }

        let rect = CGRect(
            x: CGFloat(minX) / CGFloat(current.columns),
            y: 1 - CGFloat(maxY + 1) / CGFloat(current.rows),
            width: CGFloat(maxX - minX + 1) / CGFloat(current.columns),
            height: CGFloat(maxY - minY + 1) / CGFloat(current.rows)
        )
        guard let vehicleScore = vehicleCandidateScore(for: rect, motionRatio: ratio) else {
            return nil
        }
        return VehicleDetection(rect: rect, motionScore: ratio, vehicleScore: vehicleScore)
    }

    private func vehicleCandidateScore(for rect: CGRect, motionRatio: Double) -> Double? {
        let width = Double(rect.width)
        let height = Double(rect.height)
        let area = width * height
        let aspectRatio = width / max(height, 0.001)
        let centerY = Double(rect.midY)

        guard width >= minVehicleWidth, height >= minVehicleHeight, area >= minVehicleBoxArea else {
            return nil
        }

        guard aspectRatio >= 1.15 && aspectRatio <= 5.8 else {
            return nil
        }

        guard centerY <= 0.68 else {
            return nil
        }

        let widthScore = min(1.0, width / 0.32)
        let heightScore = min(1.0, height / 0.18)
        let shapeScore = 1.0 - min(1.0, abs(aspectRatio - 2.3) / 2.3)
        let roadPositionScore = 1.0 - min(1.0, max(0.0, centerY - 0.18) / 0.5)
        let motionScore = min(1.0, motionRatio / 0.12)
        let vehicleScore = (widthScore * 0.28)
            + (heightScore * 0.18)
            + (shapeScore * 0.28)
            + (roadPositionScore * 0.14)
            + (motionScore * 0.12)

        return vehicleScore >= 0.52 ? vehicleScore : nil
    }

    private func updateTracks(with detection: VehicleDetection?) {
        tracks = tracks.map { track in
            var copy = track
            copy.framesSinceSeen += 1
            return copy
        }

        guard let detection else {
            tracks.removeAll { $0.framesSinceSeen > staleFrameLimit }
            return
        }

        let center = CGPoint(x: detection.rect.midX, y: detection.rect.midY)
        if let matchIndex = bestMatchIndex(for: center) {
            let previousX = tracks[matchIndex].lastCenter.x
            tracks[matchIndex].lastCenter = center
            tracks[matchIndex].framesSinceSeen = 0
            countCrossingIfNeeded(previousX: previousX, currentX: center.x, trackIndex: matchIndex)
        } else {
            tracks.append(TrackedVehicle(lastCenter: center))
        }

        tracks.removeAll { $0.framesSinceSeen > staleFrameLimit }
    }

    private func bestMatchIndex(for center: CGPoint) -> Int? {
        var bestIndex: Int?
        var bestDistance = CGFloat.greatestFiniteMagnitude

        for index in tracks.indices where tracks[index].framesSinceSeen < 5 {
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
        recentEvents.insert(VehicleEvent(timestamp: Date()), at: 0)
        if recentEvents.count > 6 {
            recentEvents.removeLast()
        }
    }
}

extension VehicleCounterViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
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

private struct SampledFrame {
    let columns: Int
    let rows: Int
    let values: [UInt8]
}

private struct TrackedVehicle {
    var lastCenter: CGPoint
    var framesSinceSeen = 0
    var hasCounted = false
}
