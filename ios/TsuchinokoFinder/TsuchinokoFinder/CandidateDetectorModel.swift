import AVFoundation
import CoreML
import Foundation
import ImageIO
import UIKit
import Vision

struct CandidateEvent: Identifiable {
    let id = UUID()
    let timestamp: Date
    let confidence: Double
}

final class CandidateDetectorViewModel: NSObject, ObservableObject {
    @Published var isScanning = false
    @Published var isCameraReady = false
    @Published var permissionDenied = false
    @Published var modelReady = false
    @Published var statusText = Copy.preparing
    @Published var candidateConfidence = 0.0
    @Published var candidateLabel = Copy.noCandidate
    @Published var sampleText = Copy.noSample
    @Published var recentEvents: [CandidateEvent] = []
    @Published var threshold: Double = {
        let saved = UserDefaults.standard.double(forKey: "tsuchinokoThreshold")
        return saved == 0 ? 0.76 : saved
    }() {
        didSet {
            let clamped = min(max(threshold, 0.55), 0.95)
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
    private var sampleIndex = 0
    private let inferenceFrameStride = 15
    private let sampleNames = [
        "candidate_forest_path",
        "candidate_gravel_road",
        "negative_branch",
        "negative_hose",
    ]

    var thresholdLabel: String {
        "\(Int(threshold * 100))%"
    }

    var confidenceLabel: String {
        "\(Int(candidateConfidence * 100))%"
    }

    var hasCandidate: Bool {
        candidateConfidence >= threshold
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
        sampleText = Copy.noSample
        statusText = isScanning ? Copy.scanning : Copy.resetDone
    }

    func runNextSample() {
        loadModel()
        guard let visionRequest else {
            statusText = Copy.modelUnavailable
            return
        }

        let sampleName = sampleNames[sampleIndex % sampleNames.count]
        sampleIndex += 1

        guard
            let url = sampleURL(for: sampleName),
            let cgImage = downsampledCGImage(at: url)
        else {
            statusText = Copy.sampleMissing
            return
        }

        DispatchQueue.main.async {
            self.sampleText = "\(Copy.samplePrefix) \(self.sampleDisplayName(for: sampleName))"
            self.statusText = Copy.sampleRunning
        }

        videoQueue.async {
            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
            do {
                try handler.perform([visionRequest])
            } catch {
                DispatchQueue.main.async {
                    self.statusText = Copy.analysisFailed
                }
            }
        }
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
        DispatchQueue.main.async {
            self.candidateConfidence = confidence

            if confidence >= self.threshold {
                self.candidateLabel = Copy.tsuchinokoCandidate
                self.statusText = Copy.candidateDetected
                self.appendEventIfNeeded(confidence: confidence)
            } else if confidence >= 0.45 {
                self.candidateLabel = Copy.reviewNeeded
                self.statusText = Copy.motionToReview
            } else {
                self.candidateLabel = Copy.noCandidate
                self.statusText = self.isScanning ? Copy.scanning : self.statusText
            }
        }
    }

    private func appendEventIfNeeded(confidence: Double) {
        guard Date().timeIntervalSince(lastCandidateAt) > 4 else { return }
        lastCandidateAt = Date()
        recentEvents.insert(CandidateEvent(timestamp: Date(), confidence: confidence), at: 0)
        if recentEvents.count > 8 {
            recentEvents.removeLast()
        }
    }

    private func sampleURL(for name: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: "png", subdirectory: "ReviewSamples")
            ?? Bundle.main.url(forResource: name, withExtension: "png")
    }

    private func downsampledCGImage(at url: URL, maxPixelSize: CGFloat = 1024) -> CGImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else {
            return nil
        }

        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: false,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ] as CFDictionary

        return CGImageSourceCreateThumbnailAtIndex(source, 0, options)
    }

    private func sampleDisplayName(for name: String) -> String {
        switch name {
        case "candidate_forest_path":
            return Copy.sampleCandidateForest
        case "candidate_gravel_road":
            return Copy.sampleCandidateGravel
        case "negative_branch":
            return Copy.sampleNegativeBranch
        case "negative_hose":
            return Copy.sampleNegativeHose
        default:
            return name
        }
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
    static let motionToReview = "\u{8981}\u{78BA}\u{8A8D}\u{306E}\u{52D5}\u{4F53}"
    static let noSample = "\u{30B5}\u{30F3}\u{30D7}\u{30EB}\u{672A}\u{5B9F}\u{884C}"
    static let samplePrefix = "\u{30B5}\u{30F3}\u{30D7}\u{30EB}"
    static let sampleRunning = "\u{30B5}\u{30F3}\u{30D7}\u{30EB}\u{89E3}\u{6790}\u{4E2D}"
    static let sampleMissing = "\u{30B5}\u{30F3}\u{30D7}\u{30EB}\u{304C}\u{898B}\u{3064}\u{304B}\u{308A}\u{307E}\u{305B}\u{3093}"
    static let sampleCandidateForest = "\u{5019}\u{88DC}\u{30FB}\u{5C71}\u{9053}"
    static let sampleCandidateGravel = "\u{5019}\u{88DC}\u{30FB}\u{7802}\u{5229}\u{9053}"
    static let sampleNegativeBranch = "\u{78BA}\u{8A8D}\u{7528}\u{30FB}\u{679D}"
    static let sampleNegativeHose = "\u{78BA}\u{8A8D}\u{7528}\u{30FB}\u{30DB}\u{30FC}\u{30B9}"
    static let cameraPermissionNeeded = "\u{30AB}\u{30E1}\u{30E9}\u{8A31}\u{53EF}\u{304C}\u{5FC5}\u{8981}\u{3067}\u{3059}"
    static let cameraUnavailable = "\u{30AB}\u{30E1}\u{30E9}\u{3092}\u{958B}\u{3051}\u{307E}\u{305B}\u{3093}"
    static let modelMissing = "Model file is missing"
    static let modelUnavailable = "Model is not ready"
    static let modelLoadError = "Model load error"
    static let analysisFailed = "Analysis failed"
}
