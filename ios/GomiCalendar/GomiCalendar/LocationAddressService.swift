import CoreLocation
import Foundation

struct AddressResult: Equatable {
    var postalCode: String
    var prefecture: String
    var municipality: String
    var town: String
    var street: String
    var coordinate: CLLocationCoordinate2D

    var fullText: String {
        [postalCodeText, prefecture, municipality, town, street]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    var areaKey: String {
        [municipality, town].filter { !$0.isEmpty }.joined(separator: " ")
    }

    private var postalCodeText: String {
        postalCode.isEmpty ? "" : "〒\(postalCode)"
    }

    static func == (lhs: AddressResult, rhs: AddressResult) -> Bool {
        lhs.fullText == rhs.fullText &&
        lhs.coordinate.latitude == rhs.coordinate.latitude &&
        lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}

@MainActor
final class LocationAddressService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var authorizationStatus: CLAuthorizationStatus
    @Published private(set) var currentAddress: AddressResult?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var continuation: CheckedContinuation<CLLocation, Error>?

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let location = try await requestLocation()
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else {
                errorMessage = "住所を取得できませんでした。少し移動して再試行してください。"
                return
            }

            currentAddress = AddressResult(
                postalCode: placemark.postalCode ?? "",
                prefecture: placemark.administrativeArea ?? "",
                municipality: placemark.locality ?? placemark.subAdministrativeArea ?? "",
                town: placemark.subLocality ?? "",
                street: [placemark.thoroughfare, placemark.subThoroughfare]
                    .compactMap { $0 }
                    .joined(separator: " "),
                coordinate: location.coordinate
            )
        } catch {
            errorMessage = message(for: error)
        }
    }

    private func requestLocation() async throws -> CLLocation {
        authorizationStatus = manager.authorizationStatus

        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            throw LocationError.permissionDenied
        default:
            break
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            manager.requestLocation()
        }
    }

    private func message(for error: Error) -> String {
        if let locationError = error as? LocationError {
            return locationError.localizedDescription
        }

        let nsError = error as NSError
        if nsError.domain == kCLErrorDomain {
            return "現在地を取得できませんでした。位置情報の許可と通信状態を確認してください。"
        }

        return error.localizedDescription
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            continuation?.resume(returning: location)
            continuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }
}

enum LocationError: LocalizedError {
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            "位置情報が許可されていません。設定アプリから許可してください。"
        }
    }
}
