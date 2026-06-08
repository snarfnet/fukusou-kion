import Foundation

@MainActor
final class CaseStore: ObservableObject {
    @Published private(set) var cases: [TroubleCase] = []
    @Published private(set) var loadError: String?

    init() {
        load()
    }

    var categories: [String] {
        ["全部"] + Array(Set(cases.map(\.category))).sorted()
    }

    func load() {
        guard let url = Bundle.main.url(forResource: "trouble_cases_1200", withExtension: "json") else {
            loadError = "事例データが見つかりません。"
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let payload = try JSONDecoder().decode(TroubleCasePayload.self, from: data)
            cases = payload.cases
        } catch {
            loadError = "事例データを読み込めませんでした: \(error.localizedDescription)"
        }
    }
}
