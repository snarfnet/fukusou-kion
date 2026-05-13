import Foundation

final class ResultHistoryStore: ObservableObject {
    @Published private(set) var items: [NumberHistoryItem] = []

    private let key = "number_story_history_v1"
    private let maxItems = 50

    init() {
        load()
    }

    func add(theme: NumberTheme, input: String, reading: NumberReading) {
        let item = NumberHistoryItem(
            id: UUID(),
            date: Date(),
            theme: theme,
            input: input.isEmpty ? theme.rawValue : input,
            number: reading.number,
            title: reading.title,
            message: reading.message
        )
        items.insert(item, at: 0)
        items = Array(items.prefix(maxItems))
        save()
    }

    func clear() {
        items.removeAll()
        save()
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let decoded = try? JSONDecoder().decode([NumberHistoryItem].self, from: data)
        else { return }

        items = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
