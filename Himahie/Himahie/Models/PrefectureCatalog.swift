import Foundation

struct PrefectureCatalog: Codable, Identifiable, Hashable {
    let code: String
    let name: String
    let fileName: String
    let spotCount: Int
    let centerLatitude: Double
    let centerLongitude: Double

    var id: String { code }
}
