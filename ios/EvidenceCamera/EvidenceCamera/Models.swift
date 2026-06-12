import CoreLocation
import Foundation

struct CaptureMetadata: Codable, Equatable {
    var capturedAt: Date
    var latitude: Double?
    var longitude: Double?
    var altitude: Double?
    var horizontalAccuracy: Double?
    var address: String?
    var trueHeading: Double?
    var magneticHeading: Double?
    var pitch: Double?
    var roll: Double?
    var yaw: Double?
    var deviceModel: String
    var systemVersion: String
    var sessionID: UUID
    var sequenceNumber: Int
    var previousHash: String?
    var note: String
}

struct EvidenceRecord: Codable, Identifiable, Equatable {
    var id: UUID
    var imageFileName: String
    var metadata: CaptureMetadata
    var hash: String
    var imageDigest: String?

    var shortHash: String {
        String(hash.prefix(12))
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let latitude = metadata.latitude, let longitude = metadata.longitude else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct EmbeddedEvidencePayload: Codable, Equatable {
    var schemaVersion: Int
    var appName: String
    var recordID: UUID
    var imageDigest: String
    var hash: String
    var metadata: CaptureMetadata
}

struct ImportedEvidence: Identifiable, Equatable {
    var id: UUID
    var payload: EmbeddedEvidencePayload
    var currentImageDigest: String
    var state: VerificationState
}

enum VerificationState: Equatable {
    case verified
    case changed
    case missingImage

    var title: String {
        switch self {
        case .verified:
            return "検証済み"
        case .changed:
            return "変更の可能性"
        case .missingImage:
            return "写真なし"
        }
    }
}
