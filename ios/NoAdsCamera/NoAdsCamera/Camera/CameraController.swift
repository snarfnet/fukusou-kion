import AVFoundation
import CoreImage
import CoreMotion
import MobileCoreServices
import Photos
import SwiftUI

final class CameraController: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var authorizationStatus: AVAuthorizationStatus = .notDetermined
    @Published var isRunning = false
    @Published var isSaving = false
    @Published var lastSavedImage: UIImage?
    @Published var selectedMode: CameraMode = .auto
    @Published var shakeLevel: Double = 0
    @Published var statusText = "準備中"
    @Published var supportsRAW = false
    @Published var supportsDepth = false
    @Published var supportsPortraitMatte = false
    @Published var supportsZeroShutterLag = false
    @Published var supportsResponsiveCapture = false
    @Published var supportsFastCapture = false
    @Published var supportsDeferredDelivery = false
    @Published var maxBracketCount = 0
    @Published var readinessText = "Ready"
    @Published var highlightClippingRatio: Double = 0
    @Published var shadowCrushRatio: Double = 0
    @Published var horizonTilt: Double = 0
    @Published var realtimeWarnings: [String] = []
    @Published var bestShotScore: Double = 0
    @Published var semanticExposureMessage = "露出を見ています"
    @Published var activePurposeGuide: PurposeProGuide?

    private let output = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let customISPEngine = CustomISPEngine()
    private let semanticExposureEngine = SemanticExposureEngine()
    private let processedImageContext = CIContext()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    private let videoQueue = DispatchQueue(label: "camera.video.analysis.queue")
    private let motionManager = CMMotionManager()
    private var photoDelegate: PhotoCaptureDelegate?
    private var currentDevice: AVCaptureDevice?
    private var lastAnalysisTime = CACurrentMediaTime()
    private var lastExposureAdjustmentTime = CACurrentMediaTime()
    private var activeExposurePriority: ExposurePriority = .product
    private var activeISPPreset: ISPPreset = .neutral
    private let bestShotBuffer = BestShotBuffer(capacity: 60)

    override init() {
        super.init()
        authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        startMotionUpdates()
    }

    func requestAccessAndStart() {
        switch authorizationStatus {
        case .authorized:
            configureAndStart()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.authorizationStatus = granted ? .authorized : .denied
                    if granted {
                        self?.configureAndStart()
                    } else {
                        self?.statusText = "カメラを許可してください"
                    }
                }
            }
        default:
            statusText = "設定からカメラを許可してください"
        }
    }

    func configureAndStart() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            let session = AVCaptureSession()
            session.beginConfiguration()
            session.sessionPreset = .photo

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let input = try? AVCaptureDeviceInput(device: device),
                  session.canAddInput(input),
                  session.canAddOutput(self.output),
                  session.canAddOutput(self.videoOutput) else {
                DispatchQueue.main.async { self.statusText = "カメラを起動できません" }
                return
            }

            session.addInput(input)
            session.addOutput(self.output)
            session.addOutput(self.videoOutput)
            self.output.maxPhotoQualityPrioritization = .quality
            self.configureRealtimeAnalysis()
            if self.output.isDepthDataDeliverySupported {
                self.output.isDepthDataDeliveryEnabled = true
            }
            if self.output.isPortraitEffectsMatteDeliverySupported {
                self.output.isPortraitEffectsMatteDeliveryEnabled = true
            }
            self.configureMomentCaptureIfAvailable()
            session.commitConfiguration()
            session.startRunning()

            DispatchQueue.main.async {
                self.currentDevice = device
                self.session = session
                self.isRunning = true
                self.supportsRAW = !self.output.availableRawPhotoPixelFormatTypes.isEmpty
                self.supportsDepth = self.output.isDepthDataDeliverySupported
                self.supportsPortraitMatte = self.output.isPortraitEffectsMatteDeliverySupported
                self.supportsZeroShutterLag = self.output.isZeroShutterLagSupported
                self.supportsResponsiveCapture = self.output.isResponsiveCaptureSupported
                self.supportsFastCapture = self.output.isFastCapturePrioritizationSupported
                self.supportsDeferredDelivery = self.output.isAutoDeferredPhotoDeliverySupported
                self.maxBracketCount = self.output.maxBracketedCapturePhotoCount
                self.statusText = self.output.isZeroShutterLagEnabled ? "決定的瞬間に強い設定です" : String(localized: "status_ready")
            }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self, self.session.isRunning else { return }
            self.session.stopRunning()
            DispatchQueue.main.async { self.isRunning = false }
        }
    }

    func capturePhoto() {
        guard !isSaving else { return }
        isSaving = true

        switch selectedMode {
        case .rawMaterial:
            captureRAWPlusProcessed()
            return
        case .hdrBracket:
            captureExposureBracket()
            return
        case .auto, .zen, .strongShake:
            readinessText = "Moment"
        default:
            break
        }

        let settings = AVCapturePhotoSettings()
        settings.flashMode = .off
        settings.photoQualityPrioritization = selectedMode == .strongShake ? .speed : .quality
        enableAuxiliaryDeliveryIfAvailable(settings)
        settings.photoQualityPrioritization = prioritizationForCurrentMode()

        if output.availablePhotoCodecTypes.contains(.hevc) {
            let hevcSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            hevcSettings.flashMode = settings.flashMode
            hevcSettings.photoQualityPrioritization = settings.photoQualityPrioritization
            capture(with: hevcSettings)
        } else {
            capture(with: settings)
        }
    }

    func applyPurposeGuide(_ guide: PurposeProGuide) {
        activePurposeGuide = guide
        activeExposurePriority = guide.exposurePriority
        activeISPPreset = guide.ispPreset
        statusText = "\(guide.preset.rawValue)向けに調整中"
    }

    func lockManualSettings(iso: Float?, exposureDuration: CMTime?, whiteBalance: AVCaptureDevice.WhiteBalanceGains?) {
        guard let device = currentDevice else { return }

        do {
            try device.lockForConfiguration()
            if let iso, let exposureDuration, device.isExposureModeSupported(.custom) {
                let clampedISO = min(max(iso, device.activeFormat.minISO), device.activeFormat.maxISO)
                device.setExposureModeCustom(duration: exposureDuration, iso: clampedISO)
            }
            if let whiteBalance, device.isWhiteBalanceModeSupported(.locked) {
                device.setWhiteBalanceModeLocked(with: normalizedGains(whiteBalance, for: device))
            }
            device.unlockForConfiguration()
            statusText = "設定を固定しました"
        } catch {
            statusText = "固定設定に失敗しました"
        }
    }

    func focus(at point: CGPoint, in size: CGSize) {
        guard let device = currentDevice, size.width > 0, size.height > 0 else { return }

        let focusPoint = CGPoint(x: point.y / size.height, y: 1 - point.x / size.width)
        do {
            try device.lockForConfiguration()
            if device.isFocusPointOfInterestSupported {
                device.focusPointOfInterest = focusPoint
                device.focusMode = .autoFocus
            }
            if device.isExposurePointOfInterestSupported {
                device.exposurePointOfInterest = focusPoint
                device.exposureMode = .continuousAutoExposure
            }
            device.unlockForConfiguration()
            statusText = "ピントを合わせました"
        } catch {
            statusText = "ピント調整に失敗しました"
        }
    }

    var shakeMessage: String {
        switch shakeLevel {
        case 0..<0.08:
            "今が撮りどき"
        case 0..<0.18:
            "少し揺れています"
        default:
            "止めてから撮影"
        }
    }

    private func capture(with settings: AVCapturePhotoSettings) {
        let delegate = PhotoCaptureDelegate { [weak self] result in
            DispatchQueue.main.async {
                self?.handleCapture(result)
            }
        }
        photoDelegate = delegate
        output.capturePhoto(with: settings, delegate: delegate)
    }

    private func captureRAWPlusProcessed() {
        guard let rawFormat = output.availableRawPhotoPixelFormatTypes.first else {
            isSaving = false
            statusText = "この端末はRAW非対応です"
            return
        }

        let processedFormat: [String: Any] = [AVVideoCodecKey: AVVideoCodecType.hevc]
        let settings = AVCapturePhotoSettings(rawPixelFormatType: rawFormat, processedFormat: processedFormat)
        settings.flashMode = .off
        settings.photoQualityPrioritization = .quality
        enableAuxiliaryDeliveryIfAvailable(settings)
        capture(with: settings)
        statusText = "RAW+JPEGで撮影中"
    }

    private func captureExposureBracket() {
        guard output.maxBracketedCapturePhotoCount >= 3 else {
            isSaving = false
            statusText = "この端末はブラケット非対応です"
            return
        }

        let bracketedSettings = [
            AVCaptureAutoExposureBracketedStillImageSettings.autoExposureSettings(exposureTargetBias: -1.0),
            AVCaptureAutoExposureBracketedStillImageSettings.autoExposureSettings(exposureTargetBias: 0.0),
            AVCaptureAutoExposureBracketedStillImageSettings.autoExposureSettings(exposureTargetBias: 1.0)
        ]
        let processedFormat: [String: Any] = [AVVideoCodecKey: AVVideoCodecType.hevc]
        let settings = AVCapturePhotoBracketSettings(rawPixelFormatType: 0, processedFormat: processedFormat, bracketedSettings: bracketedSettings)
        settings.flashMode = .off
        settings.photoQualityPrioritization = .quality
        capture(with: settings)
        statusText = "3枚ブラケットで撮影中"
    }

    private func configureMomentCaptureIfAvailable() {
        if output.isZeroShutterLagSupported {
            output.isZeroShutterLagEnabled = true
        }
        if output.isZeroShutterLagEnabled, output.isResponsiveCaptureSupported {
            output.isResponsiveCaptureEnabled = true
        }
        if output.isFastCapturePrioritizationSupported {
            output.isFastCapturePrioritizationEnabled = true
        }
        if output.isAutoDeferredPhotoDeliverySupported {
            output.isAutoDeferredPhotoDeliveryEnabled = true
        }
    }

    private func prioritizationForCurrentMode() -> AVCapturePhotoOutput.QualityPrioritization {
        switch selectedMode {
        case .strongShake, .auto:
            return .speed
        case .zen:
            return .balanced
        default:
            return .quality
        }
    }

    private func enableAuxiliaryDeliveryIfAvailable(_ settings: AVCapturePhotoSettings) {
        if output.isDepthDataDeliveryEnabled {
            settings.isDepthDataDeliveryEnabled = true
        }
        if output.isPortraitEffectsMatteDeliveryEnabled {
            settings.isPortraitEffectsMatteDeliveryEnabled = true
        }
    }

    private func handleCapture(_ result: Result<CaptureResult, Error>) {
        defer { isSaving = false }
        readinessText = "Ready"

        switch result {
        case .success(let captureResult):
            let adjustedImage = adjustedPreviewImageIfNeeded(captureResult.previewImage)
            lastSavedImage = adjustedImage ?? captureResult.previewImage
            if let adjustedImage, selectedMode == .customISP || selectedMode == .purposePro {
                saveToPhotoLibrary(adjustedImage)
            } else {
                saveToPhotoLibrary(captureResult)
            }
        case .failure:
            statusText = "撮影に失敗しました"
        }
        photoDelegate = nil
    }

    private func adjustedPreviewImageIfNeeded(_ image: UIImage?) -> UIImage? {
        guard selectedMode == .customISP || selectedMode == .purposePro,
              let image,
              let ciImage = CIImage(image: image) else {
            return image
        }

        let preset = selectedMode == .purposePro ? activeISPPreset : .film
        let rendered = customISPEngine.render(ciImage, preset: preset)
        guard let cgImage = processedImageContext.createCGImage(rendered, from: rendered.extent) else {
            return image
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }

    private func saveToPhotoLibrary(_ captureResult: CaptureResult) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async { self.statusText = "写真への保存を許可してください" }
                return
            }

            PHPhotoLibrary.shared().performChanges {
                for item in captureResult.items {
                    let request = PHAssetCreationRequest.forAsset()
                    let options = PHAssetResourceCreationOptions()
                    options.uniformTypeIdentifier = item.uniformTypeIdentifier
                    request.addResource(with: item.resourceType, data: item.data, options: options)
                }
            } completionHandler: { success, _ in
                DispatchQueue.main.async {
                    self.statusText = success ? "保存しました" : "保存に失敗しました"
                }
            }
        }
    }

    private func saveToPhotoLibrary(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async { self.statusText = "写真への保存を許可してください" }
                return
            }

            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, _ in
                DispatchQueue.main.async {
                    self.statusText = success ? "用途別の絵作りで保存しました" : "保存に失敗しました"
                }
            }
        }
    }

    private func normalizedGains(_ gains: AVCaptureDevice.WhiteBalanceGains, for device: AVCaptureDevice) -> AVCaptureDevice.WhiteBalanceGains {
        let maxGain = device.maxWhiteBalanceGain
        return AVCaptureDevice.WhiteBalanceGains(
            redGain: min(max(gains.redGain, 1), maxGain),
            greenGain: min(max(gains.greenGain, 1), maxGain),
            blueGain: min(max(gains.blueGain, 1), maxGain)
        )
    }

    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 30.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            let rate = motion.rotationRate
            let strength = sqrt(rate.x * rate.x + rate.y * rate.y + rate.z * rate.z)
            self.shakeLevel = min(strength / 4.0, 1.0)
            self.horizonTilt = motion.attitude.roll
        }
    }

    private func configureRealtimeAnalysis() {
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
    }

    private func analyze(pixelBuffer: CVPixelBuffer, timestamp: CMTime) {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else { return }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let buffer = baseAddress.assumingMemoryBound(to: UInt8.self)
        let step = 16

        var highlights = 0
        var shadows = 0
        var samples = 0

        for y in stride(from: 0, to: height, by: step) {
            for x in stride(from: 0, to: width, by: step) {
                let offset = y * bytesPerRow + x * 4
                let blue = Double(buffer[offset])
                let green = Double(buffer[offset + 1])
                let red = Double(buffer[offset + 2])
                let luma = 0.2126 * red + 0.7152 * green + 0.0722 * blue

                if luma > 245 {
                    highlights += 1
                } else if luma < 12 {
                    shadows += 1
                }
                samples += 1
            }
        }

        guard samples > 0 else { return }

        let highlightRatio = Double(highlights) / Double(samples)
        let shadowRatio = Double(shadows) / Double(samples)
        let tilt = abs(horizonTilt)
        let shake = shakeLevel
        bestShotBuffer.append(pixelBuffer: pixelBuffer, timestamp: timestamp, highlightRatio: highlightRatio, shadowRatio: shadowRatio, shakeLevel: shake)
        let bestScore = bestShotBuffer.bestCandidate()?.score ?? 0
        let exposureDecision = semanticExposureDecisionIfNeeded(pixelBuffer: pixelBuffer)

        DispatchQueue.main.async {
            self.highlightClippingRatio = highlightRatio
            self.shadowCrushRatio = shadowRatio
            self.bestShotScore = bestScore
            if let exposureDecision {
                self.semanticExposureMessage = exposureDecision.message
            }
            self.realtimeWarnings = self.makeRealtimeWarnings(highlights: highlightRatio, shadows: shadowRatio, tilt: tilt, shake: shake)
        }
    }

    private func semanticExposureDecisionIfNeeded(pixelBuffer: CVPixelBuffer) -> SemanticExposureDecision? {
        guard selectedMode == .semanticExposure || selectedMode == .purposePro else { return nil }

        let decision = semanticExposureEngine.decide(pixelBuffer: pixelBuffer, priority: activeExposurePriority)
        let now = CACurrentMediaTime()
        if now - lastExposureAdjustmentTime > 0.8 {
            lastExposureAdjustmentTime = now
            applyExposureBias(decision.exposureBias)
        }
        return decision
    }

    private func applyExposureBias(_ bias: Float) {
        guard let device = currentDevice, device.isExposureModeSupported(.continuousAutoExposure) else { return }

        do {
            try device.lockForConfiguration()
            let clamped = min(max(bias, device.minExposureTargetBias), device.maxExposureTargetBias)
            device.setExposureTargetBias(clamped, completionHandler: nil)
            device.unlockForConfiguration()
        } catch {
            DispatchQueue.main.async {
                self.statusText = "意味露出の調整に失敗しました"
            }
        }
    }

    private func makeRealtimeWarnings(highlights: Double, shadows: Double, tilt: Double, shake: Double) -> [String] {
        var warnings: [String] = []
        if highlights > 0.08 {
            warnings.append("白飛び")
        }
        if shadows > 0.18 {
            warnings.append("黒つぶれ")
        }
        if shake > 0.18 {
            warnings.append("手ブレ")
        }
        if tilt > 0.08 {
            warnings.append("水平注意")
        }
        return warnings
    }
}

extension CameraController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let now = CACurrentMediaTime()
        guard now - lastAnalysisTime > 0.18 else { return }
        lastAnalysisTime = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        analyze(pixelBuffer: pixelBuffer, timestamp: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
    }
}

struct CaptureResult {
    let items: [CaptureItem]
    let previewImage: UIImage?
}

struct CaptureItem {
    let data: Data
    let uniformTypeIdentifier: String
    let resourceType: PHAssetResourceType
}

private final class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private let completion: (Result<CaptureResult, Error>) -> Void
    private var items: [CaptureItem] = []
    private var previewImage: UIImage?
    private var captureError: Error?

    init(completion: @escaping (Result<CaptureResult, Error>) -> Void) {
        self.completion = completion
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error {
            captureError = error
            return
        }

        guard let data = photo.fileDataRepresentation() else {
            captureError = CameraError.invalidImage
            return
        }

        if previewImage == nil {
            previewImage = UIImage(data: data)
        }

        items.append(
            CaptureItem(
                data: data,
                uniformTypeIdentifier: photo.isRawPhoto ? "com.adobe.raw-image" : "public.heic",
                resourceType: photo.isRawPhoto ? .alternatePhoto : .photo
            )
        )
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCapturingDeferredPhotoProxy deferredPhotoProxy: AVCaptureDeferredPhotoProxy?, error: Error?) {
        if let error {
            captureError = error
            return
        }

        guard let data = deferredPhotoProxy?.fileDataRepresentation() else { return }
        items.append(
            CaptureItem(
                data: data,
                uniformTypeIdentifier: "public.heic",
                resourceType: .photoProxy
            )
        )
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        if let error {
            completion(.failure(error))
        } else if let captureError {
            completion(.failure(captureError))
        } else if items.isEmpty {
            completion(.failure(CameraError.invalidImage))
        } else {
            completion(.success(CaptureResult(items: items, previewImage: previewImage)))
        }
    }
}

private enum CameraError: Error {
    case invalidImage
}
