import Foundation
import CoreLocation

struct Spot: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let latitude: Double
    let longitude: Double
    let address: String
    let price: Int
    let indoor: Bool
    let airConditioned, hasSeats, hasToilet, hasWifi, hasPower: Bool?
    let soloFriendly, funScore, stayScore: Int
    let estimatedStayMinutes: Int
    let openingHoursText: String
    let officialURL: String
    let notes: String
    let lastVerifiedAt: String
    let sourceName: String?
    let sourceURL: String?
    let verificationStatus: String?

    var coordinate: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
    var isFree: Bool { price == 0 }
    var comfortScore: Int { Int(round(Double(soloFriendly + funScore + stayScore) / 3)) }
    var priceText: String {
        if price < 0 { return "料金未確認" }
        if isFree { return verificationStatus == "verified" ? "無料" : "無料情報あり" }
        return "\(price)円"
    }
    var verificationText: String { verificationStatus == "verified" ? "公式情報で確認済み" : "候補情報・要確認" }
    var stayText: String { estimatedStayMinutes >= 60 ? "約\(estimatedStayMinutes / 60)時間" : "約\(estimatedStayMinutes)分" }

    func availabilityText(_ value: Bool?) -> String {
        switch value {
        case true: "あり"
        case false: "なし"
        case nil: "未確認"
        }
    }
}
