import Foundation
import SwiftData

@Model
final class Favorite {
    @Attribute(.unique) var spotID: String
    var savedAt: Date
    @Attribute(.externalStorage) var spotData: Data?

    init(spot: Spot) {
        self.spotID = spot.id
        self.savedAt = .now
        self.spotData = try? JSONEncoder().encode(spot)
    }

    var decodedSpot: Spot? {
        guard let spotData else { return nil }
        return try? JSONDecoder().decode(Spot.self, from: spotData)
    }
}

@Model
final class SpotReport {
    var spotID: String
    var spotName: String
    var reason: String
    var note: String
    var createdAt: Date
    var status: String

    init(spot: Spot, reason: String, note: String) {
        self.spotID = spot.id
        self.spotName = spot.name
        self.reason = reason
        self.note = note
        self.createdAt = .now
        self.status = "pending"
    }
}
