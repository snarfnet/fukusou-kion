import Foundation

@MainActor
final class NoteStore: ObservableObject {
    @Published private(set) var notes: [SermonNote] = []

    private let fileURL: URL

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = documents.appendingPathComponent("sermon-notes.json")
        load()
    }

    func save(_ note: SermonNote) {
        var edited = note
        edited.updatedAt = Date()

        if let index = notes.firstIndex(where: { $0.id == edited.id }) {
            notes[index] = edited
        } else {
            notes.insert(edited, at: 0)
        }
        persist()
    }

    func delete(_ note: SermonNote) {
        notes.removeAll { $0.id == note.id }
        persist()
    }

    func toggleFavorite(_ note: SermonNote) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        notes[index].isFavorite.toggle()
        notes[index].updatedAt = Date()
        persist()
    }

    func togglePrayer(noteID: UUID, prayerID: UUID) {
        guard let noteIndex = notes.firstIndex(where: { $0.id == noteID }),
              let prayerIndex = notes[noteIndex].prayerRequests.firstIndex(where: { $0.id == prayerID })
        else { return }

        notes[noteIndex].prayerRequests[prayerIndex].isAnswered.toggle()
        notes[noteIndex].updatedAt = Date()
        persist()
    }

    func filteredNotes(query: String, favoritesOnly: Bool) -> [SermonNote] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return notes
            .filter { note in
                (!favoritesOnly || note.isFavorite) &&
                (trimmed.isEmpty || note.searchableText.contains(trimmed))
            }
            .sorted { $0.date > $1.date }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else {
            notes = []
            return
        }

        do {
            notes = try JSONDecoder().decode([SermonNote].self, from: data)
        } catch {
            notes = []
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(notes)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            assertionFailure("Could not save sermon notes: \(error)")
        }
    }
}
