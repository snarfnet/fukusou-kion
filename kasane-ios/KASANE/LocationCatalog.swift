import Foundation
import CoreLocation

struct LocationSummary: Codable, Identifiable, Hashable {
    let id: String
    let kanji: String
    let name: String
    let prefecture: String
    let region: String
    let latitude: Double
    let longitude: Double
    let theme: String
    let tier: String

    var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
    var isFeatured: Bool { tier == "featured" }

    func distance(from location: CLLocation?) -> CLLocationDistance? {
        guard let location else { return nil }
        return location.distance(from: CLLocation(latitude: latitude, longitude: longitude))
    }
}

enum LocationCatalog {
    static let all: [LocationSummary] = {
        guard let url = Bundle.main.url(forResource: "locations-300", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let values = try? JSONDecoder().decode([LocationSummary].self, from: data) else { return [] }
        return values
    }()

    static let regions = ["All", "Tokyo", "Kyoto", "Hokkaido & Tohoku", "Kanto", "Chubu & Hokuriku", "Kansai", "Chugoku & Shikoku", "Kyushu & Okinawa", "Cross-regional"]
}
