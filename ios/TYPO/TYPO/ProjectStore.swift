import Foundation
import SwiftUI

@MainActor
final class ProjectStore: ObservableObject {
    @Published private(set) var projects: [Artwork] = []
    @Published var issue: String?
    private let folder: URL

    init(folder: URL? = nil) {
        self.folder = folder ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Artworks", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: self.folder, withIntermediateDirectories: true)
            try reload()
        } catch { issue = L10n.text("作品を読み込めませんでした。") + error.localizedDescription }
    }

    func file(_ id: UUID) -> URL { folder.appendingPathComponent(id.uuidString).appendingPathExtension("json") }
    func thumbnail(_ id: UUID) -> URL { folder.appendingPathComponent(id.uuidString).appendingPathExtension("png") }

    func reload() throws {
        let files = try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
        var loaded: [Artwork] = []
        var rejected = 0
        for url in files where url.pathExtension == "json" {
            do {
                let saved = try JSONDecoder().decode(SavedArtwork.self, from: Data(contentsOf: url))
                guard saved.artwork.schemaVersion == 1 else { rejected += 1; continue }
                loaded.append(saved.artwork)
            } catch { rejected += 1 }
        }
        projects = loaded.sorted { $0.updatedAt > $1.updatedAt }
        if rejected > 0 { issue = L10n.format("%lld件の作品を読み込めませんでした。元のファイルは保持しています。", rejected) }
    }

    func load(_ artwork: Artwork) throws -> SavedArtwork {
        let result = try JSONDecoder().decode(SavedArtwork.self, from: Data(contentsOf: file(artwork.id)))
        guard result.artwork.schemaVersion == 1 else { throw CocoaError(.coderReadCorrupt) }
        return result
    }

    func save(_ artwork: Artwork, history: EditHistory, thumbnail: Data? = nil) throws {
        var updated = artwork
        updated.updatedAt = Date()
        let data = try JSONEncoder().encode(SavedArtwork(artwork: updated, history: history))
        try data.write(to: file(updated.id), options: .atomic)
        if let thumbnail { try thumbnail.write(to: self.thumbnail(updated.id), options: .atomic) }
        try reload()
    }

    func delete(_ artwork: Artwork) throws {
        try FileManager.default.removeItem(at: file(artwork.id))
        if FileManager.default.fileExists(atPath: thumbnail(artwork.id).path) {
            try FileManager.default.removeItem(at: thumbnail(artwork.id))
        }
        try reload()
    }
}
