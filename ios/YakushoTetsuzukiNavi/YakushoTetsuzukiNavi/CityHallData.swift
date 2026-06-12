import Foundation

struct CityHallOffice: Codable, Identifiable, Hashable {
    let baseCode: String
    let prefecture: String
    let cityName: String
    let building: String
    let zipcode: String
    let address: String
    let tel: String

    var id: String { baseCode }
    var postalAddress: String { "〒\(zipcode) \(address)" }
}

enum CityHallData {
    static let sourceName = "ASTI 地方公共団体の位置データ"
    static let lastBundledUpdate = "2026/01"
    static let all: [CityHallOffice] = loadCityHalls()

    static func find(for municipality: Municipality?) -> CityHallOffice? {
        guard let municipality, let cityName = parentCityName(from: municipality.name) else {
            return nil
        }

        return all.first {
            $0.prefecture == municipality.prefecture && $0.cityName == cityName
        }
    }

    private static func parentCityName(from municipalityName: String) -> String? {
        if municipalityName.hasSuffix("市"), !municipalityName.contains(" ") {
            return municipalityName
        }

        let parts = municipalityName.split(separator: " ")
        return parts.first(where: { $0.hasSuffix("市") }).map(String.init)
    }

    private static func loadCityHalls() -> [CityHallOffice] {
        guard let url = Bundle.main.url(forResource: "CityHalls", withExtension: "json") else {
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([CityHallOffice].self, from: data)
        } catch {
            return []
        }
    }
}
