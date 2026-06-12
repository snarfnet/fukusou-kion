import XCTest
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
}
