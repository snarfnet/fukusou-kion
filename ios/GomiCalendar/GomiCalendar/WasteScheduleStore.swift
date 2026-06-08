import Foundation

@MainActor
final class WasteScheduleStore: ObservableObject {
    @Published private(set) var rules: [CollectionRule] = []

    private let storageKey = "collectionRules.v1"
    private let calendar = Calendar(identifier: .gregorian)

    init() {
        load()
    }

    func upcomingDays(for address: AddressResult?, limit: Int = 14) -> [CollectionDay] {
        guard let address else { return [] }

        let matchedRules = rules.filter { $0.matches(address: address) }
        guard !matchedRules.isEmpty else { return [] }

        let start = calendar.startOfDay(for: Date())
        let dates = (0..<90).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }

        return dates
            .flatMap { date in
                let weekday = calendar.component(.weekday, from: date)
                return matchedRules
                    .filter { $0.weekday == weekday }
                    .map { CollectionDay(date: date, rule: $0) }
            }
            .sorted { $0.date < $1.date }
            .prefix(limit)
            .map { $0 }
    }

    func addDemoRules(for address: AddressResult) {
        let municipality = address.municipality
        let town = address.town

        let newRules = [
            CollectionRule(municipality: municipality, townKeyword: town, category: .burnable, weekday: 2, memo: "仮データ。公式情報で更新してください。"),
            CollectionRule(municipality: municipality, townKeyword: town, category: .burnable, weekday: 5, memo: "仮データ。公式情報で更新してください。"),
            CollectionRule(municipality: municipality, townKeyword: town, category: .recyclable, weekday: 4, memo: "仮データ。公式情報で更新してください。"),
            CollectionRule(municipality: municipality, townKeyword: town, category: .nonBurnable, weekday: 3, memo: "仮データ。公式情報で更新してください。")
        ]

        rules.removeAll { $0.municipality == municipality && $0.townKeyword == town }
        rules.append(contentsOf: newRules)
        save()
    }

    func remove(_ rule: CollectionRule) {
        rules.removeAll { $0.id == rule.id }
        save()
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([CollectionRule].self, from: data)
        else {
            rules = []
            return
        }

        rules = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(rules) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
