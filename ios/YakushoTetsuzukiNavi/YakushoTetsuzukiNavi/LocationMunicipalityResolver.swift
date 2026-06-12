import CoreLocation
import Foundation

final class LocationMunicipalityResolver: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var isResolving = false
    @Published var resolvedMunicipality: Municipality?
    @Published var message: String?

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func locate() {
        guard CLLocationManager.locationServicesEnabled() else {
            message = "位置情報サービスがオフです。iPhoneの設定から位置情報を有効にしてください。"
            return
        }

        isResolving = true
        message = nil

        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            isResolving = false
            message = "位置情報の利用が許可されていません。設定アプリで許可すると、現在地から自治体を選べます。"
        @unknown default:
            isResolving = false
            message = "位置情報の状態を確認できませんでした。自治体検索から選んでください。"
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            isResolving = false
            message = "位置情報の利用が許可されていません。設定アプリで許可すると、現在地から自治体を選べます。"
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            isResolving = false
            message = "現在地を取得できませんでした。少し時間を置いて再試行してください。"
            return
        }

        geocoder.reverseGeocodeLocation(location, preferredLocale: Locale(identifier: "ja_JP")) { [weak self] placemarks, error in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isResolving = false

                if error != nil {
                    self.message = "現在地から自治体を判定できませんでした。自治体検索から選んでください。"
                    return
                }

                guard let placemark = placemarks?.first,
                      let municipality = Self.matchMunicipality(from: placemark) else {
                    self.message = "近い自治体が見つかりませんでした。自治体名で検索してください。"
                    return
                }

                self.resolvedMunicipality = municipality
                self.message = "\(municipality.displayName) を選択しました。"
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isResolving = false
        message = "現在地を取得できませんでした。電波状況を確認して再試行してください。"
    }

    private static func matchMunicipality(from placemark: CLPlacemark) -> Municipality? {
        guard let prefecture = placemark.administrativeArea else { return nil }

        let locality = placemark.locality
        let subLocality = placemark.subLocality
        let subAdministrativeArea = placemark.subAdministrativeArea
        let candidates = [
            joined(locality, subLocality),
            locality,
            subLocality,
            subAdministrativeArea
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }

        let municipalities = MunicipalityData.all.filter { $0.prefecture == prefecture }

        for candidate in candidates {
            if let exact = municipalities.first(where: { $0.name == candidate }) {
                return exact
            }
        }

        for candidate in candidates {
            if let partial = municipalities.first(where: { $0.name.localizedStandardContains(candidate) || candidate.localizedStandardContains($0.name) }) {
                return partial
            }
        }

        return nil
    }

    private static func joined(_ lhs: String?, _ rhs: String?) -> String? {
        guard let lhs, let rhs, !lhs.isEmpty, !rhs.isEmpty else { return nil }
        return "\(lhs) \(rhs)"
    }
}
