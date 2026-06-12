import CryptoKit
import Foundation
import UIKit

@MainActor
final class EvidenceStore: ObservableObject {
    @Published private(set) var records: [EvidenceRecord] = []

    private let recordsFileName = "evidence-records.json"
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init() {
        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        load()
    }

    func imageURL(for record: EvidenceRecord) -> URL {
        imagesDirectory.appendingPathComponent(record.imageFileName)
    }

    func image(for record: EvidenceRecord) -> UIImage? {
        UIImage(contentsOfFile: imageURL(for: record).path)
    }

    func saveCapture(imageData: Data, metadata: CaptureMetadata) throws {
        try FileManager.default.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)

        let id = UUID()
        let imageFileName = "\(id.uuidString).jpg"
        let imageURL = imagesDirectory.appendingPathComponent(imageFileName)
        try imageData.write(to: imageURL, options: [.atomic])

        let hash = try Self.hash(imageData: imageData, metadata: metadata)
        let record = EvidenceRecord(id: id, imageFileName: imageFileName, metadata: metadata, hash: hash)
        records.insert(record, at: 0)
        try persist()
    }

    func verificationState(for record: EvidenceRecord) -> VerificationState {
        let url = imageURL(for: record)
        guard let imageData = try? Data(contentsOf: url) else {
            return .missingImage
        }
        guard let currentHash = try? Self.hash(imageData: imageData, metadata: record.metadata) else {
            return .changed
        }
        return currentHash == record.hash ? .verified : .changed
    }

    func delete(_ record: EvidenceRecord) {
        records.removeAll { $0.id == record.id }
        try? FileManager.default.removeItem(at: imageURL(for: record))
        try? persist()
    }

    private func load() {
        guard let data = try? Data(contentsOf: recordsURL),
              let decoded = try? decoder.decode([EvidenceRecord].self, from: data) else {
            records = []
            return
        }
        records = decoded.sorted { $0.metadata.capturedAt > $1.metadata.capturedAt }
    }

    private func persist() throws {
        let data = try encoder.encode(records)
        try data.write(to: recordsURL, options: [.atomic])
    }

    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var imagesDirectory: URL {
        documentsDirectory.appendingPathComponent("EvidenceImages", isDirectory: true)
    }

    private var recordsURL: URL {
        documentsDirectory.appendingPathComponent(recordsFileName)
    }

    nonisolated static func hash(imageData: Data, metadata: CaptureMetadata) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        var hasher = SHA256()
        hasher.update(data: imageData)
        hasher.update(data: try encoder.encode(metadata))
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}
