import CoreLocation
import Observation

@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    var location: CLLocation?
    var administrativeArea: String?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var errorMessage: String?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }
    func request() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            errorMessage = "位置情報を利用できません。都道府県の中心を基準に表示します。"
        @unknown default:
            errorMessage = "位置情報の状態を確認できませんでした。"
        }
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse { manager.requestLocation() }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations
            .filter { $0.horizontalAccuracy >= 0 }
            .max(by: { $0.timestamp < $1.timestamp })
        errorMessage = location == nil ? "精度のよい現在地を取得できませんでした。" : nil
        if let location {
            geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
                self?.administrativeArea = placemarks?.first?.administrativeArea
            }
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { errorMessage = "現在地を取得できませんでした。地域の中心を基準に表示します。" }
}
