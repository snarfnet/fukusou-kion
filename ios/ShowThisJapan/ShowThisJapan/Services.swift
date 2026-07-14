import AVFoundation
import CoreLocation
import Foundation

enum PhraseDataService {
    static func load<T: Decodable>(_ type: T.Type, file: String, bundle: Bundle = .main) throws -> T {
        guard let url = bundle.url(forResource: file, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let value = try? JSONDecoder().decode(T.self, from: data) else { throw AppError.dataLoad }
        return value
    }
}

@MainActor final class SpeechService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published var isSpeaking = false
    private let synthesizer = AVSpeechSynthesizer()
    override init() { super.init(); synthesizer.delegate = self }
    func toggle(_ text: String) {
        if synthesizer.isSpeaking { synthesizer.stopSpeaking(at: .immediate); return }
        let utterance = AVSpeechUtterance(string: text); utterance.voice = .init(language: "ja-JP"); utterance.rate = 0.42
        synthesizer.speak(utterance); isSpeaking = true
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) { isSpeaking = false }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) { isSpeaking = false }
}

@MainActor final class LocationService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var location: CLLocation?; @Published var address = ""; @Published var errorMessage: String?
    private let manager = CLLocationManager(); private let geocoder = CLGeocoder()
    override init() { super.init(); manager.delegate = self; manager.desiredAccuracy = kCLLocationAccuracyBest }
    func request() {
        switch manager.authorizationStatus {
        case .notDetermined: manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse: manager.requestLocation()
        default: errorMessage = "Location access is off. Enable it in Settings."
        }
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) { if manager.authorizationStatus == .authorizedWhenInUse { manager.requestLocation() } }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }; location = latest; errorMessage = nil
        geocoder.reverseGeocodeLocation(latest) { [weak self] places, _ in
            let p = places?.first; self?.address = [p?.postalCode, p?.administrativeArea, p?.locality, p?.name].compactMap{$0}.joined(separator: " ")
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { errorMessage = "Your location could not be found. Try again outdoors." }
}

