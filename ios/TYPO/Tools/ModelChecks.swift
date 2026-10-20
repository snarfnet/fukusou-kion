import Foundation

@main
struct Checks {
    static func main() throws {
        var count = 0
        func check(_ condition: Bool, _ message: String) {
            precondition(condition, message)
            count += 1
        }
        for value in ["永", "A", "8", "O", "TYPO 2026", "ひらがな", "カタカナ", "A\nB\nC"] {
            check(InputCheck.validate(value) == nil, value)
        }
        for value in ["", "   ", "😀", "A\nB\nC\nD", String(repeating: "A", count: 13)] {
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
        artwork.text = "A B\nC"
        check(artwork.editableIndices == [0, 2, 4], "Character indices include whitespace offsets")
        artwork.group([0, 2])
        check(artwork.expandedSelection([0]) == [0, 2], "Expand group selection")
        artwork.group([2, 4])
        check(artwork.expandedSelection([4]) == [0, 2, 4], "Merge whole group")
        artwork.ungroup([2])
        check(artwork.expandedSelection([0]) == [0], "Ungroup all members")
        artwork.updateGlyph(at: 0) { $0.surface = .glass; $0.z = 42 }
        let glyphRestored = try JSONDecoder().decode(Artwork.self, from: JSONEncoder().encode(artwork))
        check(glyphRestored.adjustment(at: 0).surface == .glass, "Persist per-character material")
        check(glyphRestored.adjustment(at: 0).z == 42, "Persist per-character transform")
        let priorGlyphs = artwork.glyphs
        artwork.updateGlyph(at: 1) { $0.x = 50 }
        check(artwork.glyphs == priorGlyphs, "Whitespace cannot be transformed")
        artwork.replaceText("永")
        check(artwork.glyphs.isEmpty, "Text replacement resets glyph identity")
        for preset in ArtworkPreset.allCases {
            preset.apply(to: &artwork)
            check(artwork.text == "永" && artwork.depth >= 0 && artwork.depth <= 100, "Preset \(preset.title)")
        }
        // Simulate an original v1 JSON document with no new optional fields.
        var old = try JSONSerialization.jsonObject(with: JSONEncoder().encode(artwork)) as! [String: Any]
        for key in ["composition", "glyphAdjustments", "materialSettings", "lightRig"] { old.removeValue(forKey: key) }
        let migrated = try JSONDecoder().decode(Artwork.self, from: JSONSerialization.data(withJSONObject: old))
        check(migrated.layout == Composition(), "Migrate original geometry defaults")
        check(migrated.glyphs.isEmpty && migrated.finish == MaterialSettings(), "Migrate original material defaults")
        print("PASS: \(count) model checks")
    }
}
