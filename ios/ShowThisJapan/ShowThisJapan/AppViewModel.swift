import Foundation

@MainActor final class AppViewModel: ObservableObject {
    @Published var language: AppLanguage { didSet { defaults.set(language.rawValue, forKey: "language") } }
    @Published var categories: [PhraseCategory] = []; @Published var cards: [PhraseCard] = []
    @Published var favorites: Set<String> { didSet { defaults.set(Array(favorites), forKey: "favorites") } }
    @Published var recentIDs: [String] { didSet { defaults.set(recentIDs, forKey: "recent") } }
    @Published var profile: EmergencyProfile { didSet { saveProfile() } }
    @Published var loadError: String?
    let defaults: UserDefaults

    init(defaults: UserDefaults = .standard, loadData: Bool = true) {
        self.defaults = defaults
        language = AppLanguage(rawValue: defaults.string(forKey: "language") ?? "en") ?? .en
        favorites = Set(defaults.stringArray(forKey: "favorites") ?? [])
        recentIDs = defaults.stringArray(forKey: "recent") ?? []
        profile = (defaults.data(forKey: "profile").flatMap { try? JSONDecoder().decode(EmergencyProfile.self, from: $0) }) ?? .init()
        if loadData { load() }
    }
    func load() { do {
        categories = try PhraseDataService.load([PhraseCategory].self, file: "categories").sorted{$0.sortOrder < $1.sortOrder}
        let core = try PhraseDataService.load([PhraseCard].self, file: "phrase_cards")
        let expansion = try PhraseDataService.load([PhraseCard].self, file: "phrase_cards_expansion")
        cards = core + expansion
    } catch { loadError = error.localizedDescription } }
    func toggleFavorite(_ id: String) { if favorites.contains(id) { favorites.remove(id) } else { favorites.insert(id) } }
    func record(_ id: String) { recentIDs.removeAll{$0 == id}; recentIDs.insert(id, at: 0); recentIDs = Array(recentIDs.prefix(10)) }
    func search(_ query: String) -> [PhraseCard] { guard !query.isEmpty else { return cards }; let q = query.localizedLowercase; return cards.filter { $0.japaneseText.localizedLowercase.contains(q) || $0.text(in: language).localizedLowercase.contains(q) || $0.searchKeywords.joined(separator:" ").localizedLowercase.contains(q) } }
    private func saveProfile() { if let data = try? JSONEncoder().encode(profile) { defaults.set(data, forKey: "profile") } }
}
