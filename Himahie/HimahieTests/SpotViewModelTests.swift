import XCTest
@testable import Himahie

final class SpotViewModelTests: XCTestCase {
    func testSpotComputedValues() {
        let spot = Spot(id: "x", name: "test", category: "図書館", latitude: 35.4, longitude: 139.6, address: "", price: 0, indoor: true, airConditioned: true, hasSeats: true, hasToilet: true, hasWifi: false, hasPower: false, soloFriendly: 5, funScore: 4, stayScore: 3, estimatedStayMinutes: 90, openingHoursText: "", officialURL: "", notes: "", lastVerifiedAt: "", sourceName: nil, sourceURL: nil, verificationStatus: "verified")
        XCTAssertTrue(spot.isFree); XCTAssertEqual(spot.stayText, "約1時間"); XCTAssertEqual(spot.comfortScore, 4)
        XCTAssertEqual(spot.priceText, "無料")
        XCTAssertEqual(spot.availabilityText(nil), "未確認")
        XCTAssertEqual(spot.categoryIcon, "books.vertical.fill")
    }

    func testPrefectureCatalogDecoding() throws {
        let data = #"[{"code":"14","name":"神奈川県","fileName":"spots_14","spotCount":20,"centerLatitude":35.4,"centerLongitude":139.6}]"#.data(using: .utf8)!
        let catalog = try JSONDecoder().decode([PrefectureCatalog].self, from: data)
        XCTAssertEqual(catalog.first?.fileName, "spots_14")
        XCTAssertEqual(catalog.first?.spotCount, 20)
    }

    func testBundledRegionalDataCanBeLoaded() throws {
        let repository = SpotRepository()
        let catalog = try repository.loadCatalog()

        XCTAssertEqual(catalog.count, 47)
        XCTAssertTrue(catalog.contains { $0.code == "14" })

        for prefecture in catalog {
            let spots = try repository.load(prefecture: prefecture)
            XCTAssertEqual(
                spots.count,
                prefecture.spotCount,
                "\(prefecture.name)の登録件数とJSON件数が一致しません"
            )
        }
    }
}
