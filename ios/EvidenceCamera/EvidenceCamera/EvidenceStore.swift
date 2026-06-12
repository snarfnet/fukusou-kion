import CryptoKit
import Foundation
import ImageIO
import Photos
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
        let normalizedImageData = try Self.normalizedJPEGData(from: imageData)

        let firstPayload = EmbeddedEvidencePayload(
            schemaVersion: 1,
            appName: "EvidenceCamera",
            recordID: id,
            imageDigest: "",
            hash: "",
            metadata: metadata
        )
        let firstImageData = try Self.embed(payload: firstPayload, into: normalizedImageData)
        let firstDigest = try Self.imageDigest(from: firstImageData)
        let firstHash = try Self.hash(imageDigest: firstDigest, metadata: metadata)
        let finalPayload = EmbeddedEvidencePayload(
            schemaVersion: 1,
            appName: "EvidenceCamera",
            recordID: id,
            imageDigest: firstDigest,
            hash: firstHash,
            metadata: metadata
        )
        let finalImageData = try Self.embed(payload: finalPayload, into: firstImageData)
        let writtenDigest = try Self.imageDigest(from: finalImageData)
        let writtenHash = try Self.hash(imageDigest: writtenDigest, metadata: metadata)

        try finalImageData.write(to: imageURL, options: [.atomic])

        let record = EvidenceRecord(
            id: id,
            imageFileName: imageFileName,
            metadata: metadata,
            hash: writtenHash,
            imageDigest: writtenDigest
        )
        records.insert(record, at: 0)
        try persist()
        Self.saveToPhotoLibrary(imageData: finalImageData)
    }

    func verificationState(for record: EvidenceRecord) -> VerificationState {
        let url = imageURL(for: record)
        guard let imageData = try? Data(contentsOf: url) else {
            return .missingImage
        }
        guard let currentDigest = try? Self.imageDigest(from: imageData),
              let currentHash = try? Self.hash(imageDigest: currentDigest, metadata: record.metadata) else {
            return .changed
        }
        if currentHash == record.hash {
            return .verified
        }
        if let payload = try? Self.extractPayload(from: imageData),
           payload.recordID == record.id,
           payload.hash == record.hash,
           payload.metadata == record.metadata {
            return .verified
        }
        return .changed
    }

    nonisolated func importedEvidence(from imageData: Data) -> ImportedEvidence? {
        guard let payload = try? Self.extractPayload(from: imageData),
              let currentDigest = try? Self.imageDigest(from: imageData),
              let currentHash = try? Self.hash(imageDigest: currentDigest, metadata: payload.metadata) else {
            return nil
        }

        let state: VerificationState = currentDigest == payload.imageDigest && currentHash == payload.hash
            ? .verified
            : .changed

        return ImportedEvidence(
            id: payload.recordID,
            payload: payload,
            currentImageDigest: currentDigest,
            state: state
        )
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

    nonisolated static func hash(imageDigest: String, metadata: CaptureMetadata) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        var hasher = SHA256()
        hasher.update(data: Data(imageDigest.utf8))
        hasher.update(data: try encoder.encode(metadata))
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    nonisolated static func hash(imageData: Data, metadata: CaptureMetadata) throws -> String {
        try hash(imageDigest: imageDigest(from: imageData), metadata: metadata)
    }

    nonisolated static func imageDigest(from imageData: Data) throws -> String {
        guard let image = UIImage(data: imageData), let cgImage = image.cgImage else {
            throw EvidenceStoreError.invalidImage
        }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        var pixels = Data(count: height * bytesPerRow)

        try pixels.withUnsafeMutableBytes { rawBuffer in
            guard let baseAddress = rawBuffer.baseAddress else {
                throw EvidenceStoreError.invalidImage
            }

            guard let context = CGContext(
                data: baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                throw EvidenceStoreError.invalidImage
            }

            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }

        var hasher = SHA256()
        hasher.update(data: Data("\(width)x\(height):".utf8))
        hasher.update(data: pixels)
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    nonisolated static func embed(payload: EmbeddedEvidencePayload, into imageData: Data) throws -> Data {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let type = CGImageSourceGetType(source),
              CGImageSourceGetCount(source) > 0 else {
            throw EvidenceStoreError.invalidImage
        }

        let metadata = (CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any]) ?? [:]
        var mutableMetadata = metadata
        let payloadText = evidencePrefix + String(data: try payloadJSON(payload), encoding: .utf8)!
        mutableMetadata[kCGImagePropertyOrientation as String] = 1

        var tiff = (mutableMetadata[kCGImagePropertyTIFFDictionary as String] as? [String: Any]) ?? [:]
        tiff[kCGImagePropertyTIFFOrientation as String] = 1
        tiff[kCGImagePropertyTIFFImageDescription as String] = payloadText
        mutableMetadata[kCGImagePropertyTIFFDictionary as String] = tiff

        var exif = (mutableMetadata[kCGImagePropertyExifDictionary as String] as? [String: Any]) ?? [:]
        exif[kCGImagePropertyExifUserComment as String] = payloadText
        mutableMetadata[kCGImagePropertyExifDictionary as String] = exif

        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, type, 1, nil) else {
            throw EvidenceStoreError.invalidImage
        }

        CGImageDestinationAddImageFromSource(destination, source, 0, mutableMetadata as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw EvidenceStoreError.invalidImage
        }

        return output as Data
    }

    nonisolated static func normalizedJPEGData(from imageData: Data) throws -> Data {
        guard let image = UIImage(data: imageData) else {
            throw EvidenceStoreError.invalidImage
        }

        if image.imageOrientation == .up, imageData.starts(with: [0xFF, 0xD8]) {
            return imageData
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        let uprightImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }

        guard let jpegData = uprightImage.jpegData(compressionQuality: 0.95) else {
            throw EvidenceStoreError.invalidImage
        }

        return jpegData
    }

    nonisolated static func extractPayload(from imageData: Data) throws -> EmbeddedEvidencePayload {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            throw EvidenceStoreError.noEmbeddedPayload
        }

        let tiff = metadata[kCGImagePropertyTIFFDictionary as String] as? [String: Any]
        let exif = metadata[kCGImagePropertyExifDictionary as String] as? [String: Any]
        let candidates = [
            tiff?[kCGImagePropertyTIFFImageDescription as String],
            exif?[kCGImagePropertyExifUserComment as String]
        ]

        for candidate in candidates {
            guard let text = candidate as? String,
                  text.hasPrefix(evidencePrefix) else {
                continue
            }

            let jsonText = String(text.dropFirst(evidencePrefix.count))
            guard let data = jsonText.data(using: .utf8) else {
                continue
            }
            return try JSONDecoder.evidenceDecoder.decode(EmbeddedEvidencePayload.self, from: data)
        }

        throw EvidenceStoreError.noEmbeddedPayload
    }

    private nonisolated static let evidencePrefix = "EvidenceCamera:"

    private nonisolated static func payloadJSON(_ payload: EmbeddedEvidencePayload) throws -> Data {
        try JSONEncoder.evidenceEncoder.encode(payload)
    }

    private nonisolated static func saveToPhotoLibrary(imageData: Data) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                return
            }

            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetCreationRequest.forAsset()
                request.addResource(with: .photo, data: imageData, options: nil)
            }
        }
    }
}

enum EvidenceStoreError: Error {
    case invalidImage
    case noEmbeddedPayload
}

private extension JSONEncoder {
    static var evidenceEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var evidenceDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
