import Foundation

@main
struct Checks {
    static func main() throws {
        var count = 0
        func check(_ condition: Bool, _ message: String) {
            precondition(condition, message)
            count += 1
        }
        for value in ["永", "A", "8", "O", "TYPO 2026", "ひらがな", "カタカナ"] {
            check(InputCheck.validate(value) == nil, value)
        }
        for value in ["", "   ", "😀", "A\nB", String(repeating: "A", count: 13)] {
            check(InputCheck.validate(value) != nil, value)
        }
        var artwork = Artwork()
        var history = EditHistory()
        for i in 0..<80 { history.record(artwork); artwork.depth = Double(i) }
        check(history.past.count == 60, "Bounded undo")
        let last = artwork
        artwork = history.undo(artwork)!
        check(history.redo(artwork) == last, "Redo restores")
        _ = history.undo(last)
        history.record(artwork)
        check(history.future.isEmpty, "Branch discards redo")
        let saved = SavedArtwork(artwork: artwork, history: history)
        let data = try JSONEncoder().encode(saved)
        let restored = try JSONDecoder().decode(SavedArtwork.self, from: data)
        check(restored.artwork == artwork, "Project JSON roundtrip")
        check(restored.history.past.count == history.past.count, "History JSON roundtrip")
        check(restored.artwork.schemaVersion == 1, "Schema version")
        print("PASS: \(count) model checks")
    }
}
