import XCTest
import UIKit
@testable import EvidenceCamera

final class EvidenceHashTests: XCTestCase {
    func testHashChangesWhenMetadataChanges() throws {
        let imageData = Data([1, 2, 3, 4])
        var metadata = CaptureMetadata(
            capturedAt: Date(timeIntervalSince1970: 1_800_000_000),
            latitude: 35.0,
            longitude: 139.0,
            altitude: 10,
            horizontalAccuracy: 5,
            address: "Tokyo",
            trueHeading: 90,
            magneticHeading: 91,
            pitch: 0.1,
            roll: 0.2,
            yaw: 0.3,
            deviceModel: "iPhone",
            systemVersion: "17.0",
            sessionID: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
            sequenceNumber: 1,
            previousHash: nil,
            note: "before"
        )

        let first = try EvidenceStore.hash(imageData: imageData, metadata: metadata)
        metadata.note = "after"
        let second = try EvidenceStore.hash(imageData: imageData, metadata: metadata)

        XCTAssertNotEqual(first, second)
    }

    func testEmbeddedEvidencePayloadCanBeExtracted() throws {
        let imageData = UIGraphicsImageRenderer(size: CGSize(width: 16, height: 16)).jpegData(withCompressionQuality: 0.9) { context in
            UIColor.systemBlue.setFill()
            context.cgContext.fill(CGRect(x: 0, y: 0, width: 16, height: 16))
        }
        let metadata = CaptureMetadata(
            capturedAt: Date(timeIntervalSince1970: 1_800_000_000),
            latitude: 35.0,
            longitude: 139.0,
            altitude: nil,
            horizontalAccuracy: nil,
            address: "Tokyo",
            trueHeading: 90,
            magneticHeading: nil,
            pitch: nil,
            roll: nil,
            yaw: nil,
            deviceModel: "iPhone",
            systemVersion: "17.0",
            sessionID: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
            sequenceNumber: 1,
            previousHash: nil,
            note: "import"
        )
        let digest = try EvidenceStore.imageDigest(from: imageData)
        let hash = try EvidenceStore.hash(imageDigest: digest, metadata: metadata)
        let payload = EmbeddedEvidencePayload(
            schemaVersion: 1,
            appName: "EvidenceCamera",
            recordID: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
            imageDigest: digest,
            hash: hash,
            metadata: metadata
        )

        let embeddedData = try EvidenceStore.embed(payload: payload, into: imageData)
        let extracted = try EvidenceStore.extractPayload(from: embeddedData)

        XCTAssertEqual(extracted, payload)
    }
}
