import AVFoundation
import CoreLocation
import CoreMotion
import SwiftUI
import UIKit

@MainActor
final class CaptureContext: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var authorizationText = "確認中"
    @Published var location: CLLocation?
    @Published var heading: CLHeading?
    @Published var pitch: Double?
    @Published var roll: Double?
    @Published var yaw: Double?
    @Published var address: String?

    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private let motionManager = CMMotionManager()
    private var lastGeocodedLocation: CLLocation?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5
        locationManager.headingFilter = 1
    }

    func start() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            authorizationText = "位置情報の許可待ち"
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            authorizationText = "記録中"
            locationManager.startUpdatingLocation()
            if CLLocationManager.headingAvailable() {
                locationManager.startUpdatingHeading()
            }
        case .denied, .restricted:
            authorizationText = "位置情報なし"
        @unknown default:
            authorizationText = "確認中"
        }

        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.2
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
                guard let self, let attitude = motion?.attitude else { return }
                Task { @MainActor in
                    self.pitch = attitude.pitch
                    self.roll = attitude.roll
                    self.yaw = attitude.yaw
                }
            }
        }
    }

    func stop() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
        motionManager.stopDeviceMotionUpdates()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        start()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        location = latest

        if let lastGeocodedLocation,
           latest.distance(from: lastGeocodedLocation) < 20,
           address != nil {
            return
        }

        lastGeocodedLocation = latest
        geocoder.reverseGeocodeLocation(latest) { [weak self] placemarks, _ in
            guard let self, let placemark = placemarks?.first else { return }
            let parts = [
                placemark.administrativeArea,
                placemark.locality,
                placemark.subLocality,
                placemark.thoroughfare,
                placemark.subThoroughfare
            ].compactMap { $0 }.filter { !$0.isEmpty }

            Task { @MainActor in
                self.address = parts.joined(separator: " ")
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = newHeading
    }
}

@MainActor
final class CameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var isReady = false
    @Published var permissionDenied = false
    @Published var lastError: String?
    @Published var isCapturing = false

    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var completion: ((Result<Data, Error>) -> Void)?

    func configure() {
        Task {
            let granted = await requestAccess()
            await MainActor.run {
                if granted {
                    setupSession()
                } else {
                    permissionDenied = true
                }
            }
        }
    }

    func capture(completion: @escaping (Result<Data, Error>) -> Void) {
        guard isReady else { return }
        self.completion = completion
        isCapturing = true
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        output.capturePhoto(with: settings, delegate: self)
    }

    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        Task { @MainActor in
            self.isCapturing = false

            if let error {
                self.completion?(.failure(error))
                self.completion = nil
                return
            }

            guard let data = photo.fileDataRepresentation() else {
                self.completion?(.failure(CameraError.noPhotoData))
                self.completion = nil
                return
            }

            self.completion?(.success(data))
            self.completion = nil
        }
    }

    private func requestAccess() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }

    private func setupSession() {
        guard !isReady else { return }

        session.beginConfiguration()
        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input),
              session.canAddOutput(output) else {
            lastError = "カメラを開始できません"
            session.commitConfiguration()
            return
        }

        session.addInput(input)
        session.addOutput(output)
        output.maxPhotoQualityPrioritization = .quality
        session.commitConfiguration()

        let captureSession = session
        DispatchQueue.global(qos: .userInitiated).async {
            captureSession.startRunning()
            Task { @MainActor in
                self.isReady = true
            }
        }
    }
}

enum CameraError: LocalizedError {
    case noPhotoData

    var errorDescription: String? {
        "写真データを取得できませんでした"
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }

    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
