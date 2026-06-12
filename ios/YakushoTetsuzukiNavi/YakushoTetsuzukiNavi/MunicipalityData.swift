import Foundation

struct Municipality: Codable, Identifiable, Hashable {
    let code: String
    let prefecture: String
    let name: String
    let kana: String
    let officialURL: String

    var id: String { code }
    var displayName: String { "\(prefecture) \(name)" }

    func matches(_ query: String) -> Bool {
        guard !query.isEmpty else { return true }
        return displayName.localizedStandardContains(query)
            || kana.localizedStandardContains(query)
            || code.localizedStandardContains(query)
    }
}

enum MunicipalityData {
    static let sourceName = "code4fukui/localgovjp"
    static let sourceURL = "https://code4fukui.github.io/localgovjp/localgovjp-utf8.csv"
    static let lastBundledUpdate = "2026/06/12"
    static let all: [Municipality] = loadMunicipalities()

    static func find(displayName: String) -> Municipality? {
        all.first { $0.displayName == displayName }
    }

    static var prefectures: [String] {
        var seen: Set<String> = []
        return all.compactMap { municipality in
            guard !seen.contains(municipality.prefecture) else { return nil }
            seen.insert(municipality.prefecture)
            return municipality.prefecture
        }
    }

    private static func loadMunicipalities() -> [Municipality] {
        guard let url = Bundle.main.url(forResource: "Municipalities", withExtension: "json") else {
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([Municipality].self, from: data)
        } catch {
            return []
        }
    }
}
