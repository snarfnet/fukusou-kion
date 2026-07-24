import XCTest
import CoreLocation
import UIKit
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

    func testHeroArtworkIsBundled() {
        XCTAssertNotNil(UIImage(named: "cool-breeze-background"))
    }

    func testSelectingTokyoKeepsKawasakiAsDistanceOrigin() {
        let locationService = LocationService()
        locationService.location = CLLocation(latitude: 35.5308, longitude: 139.7030)
        let model = SpotViewModel(
            repository: AreaSelectionRepository(),
            locationService: locationService
        )
        model.followsCurrentLocation = true

        model.selectPrefecture("13")

        XCTAssertFalse(model.followsCurrentLocation)
        XCTAssertFalse(model.distanceFilterEnabled)
        XCTAssertEqual(model.currentLocation.coordinate.latitude, 35.5308, accuracy: 0.0001)
        XCTAssertEqual(model.currentLocation.coordinate.longitude, 139.7030, accuracy: 0.0001)
        XCTAssertTrue(model.distanceBasisText.contains("現在地"))
    }

    func testDefaultResultsDoNotHideUnknownPriceMuseums() {
        let model = SpotViewModel(repository: AreaSelectionRepository())
        XCTAssertFalse(model.freeOnly)
        XCTAssertTrue(model.indoorOnly)
    }

    func testRecommendationsMixFacilityTypes() {
        let model = SpotViewModel(repository: DiversityRepository())
        let categories = Set(model.recommended.prefix(4).map(\.category))

        XCTAssertEqual(categories.count, 4)
    }
}

private struct AreaSelectionRepository: SpotRepositoryProtocol {
    func loadCatalog() throws -> [PrefectureCatalog] {
        [
            .init(code: "13", name: "東京都", fileName: "spots_13", spotCount: 0, centerLatitude: 35.6762, centerLongitude: 139.6503),
            .init(code: "14", name: "神奈川県", fileName: "spots_14", spotCount: 0, centerLatitude: 35.4478, centerLongitude: 139.6425)
        ]
    }

    func load(prefecture: PrefectureCatalog) throws -> [Spot] {
        []
    }
}

private struct DiversityRepository: SpotRepositoryProtocol {
    func loadCatalog() throws -> [PrefectureCatalog] {
        [.init(code: "14", name: "神奈川県", fileName: "spots_14", spotCount: 4, centerLatitude: 35.4478, centerLongitude: 139.6425)]
    }

    func load(prefecture: PrefectureCatalog) throws -> [Spot] {
        [
            testSpot(id: "library", category: "図書館"),
            testSpot(id: "museum", category: "博物館"),
            testSpot(id: "gallery", category: "ギャラリー"),
            testSpot(id: "guide", category: "ビジターセンター")
        ]
    }
}

private func testSpot(id: String, category: String) -> Spot {
    Spot(
        id: id,
        name: id,
        category: category,
        latitude: 35.4478,
        longitude: 139.6425,
        address: "",
        price: category == "図書館" ? 0 : -1,
        indoor: true,
        airConditioned: nil,
        hasSeats: nil,
        hasToilet: nil,
        hasWifi: nil,
        hasPower: nil,
        soloFriendly: 4,
        funScore: 4,
        stayScore: 3,
        estimatedStayMinutes: 60,
        openingHoursText: "未確認",
        officialURL: "",
        notes: "",
        lastVerifiedAt: "2026-07-25",
        sourceName: "OpenStreetMap contributors",
        sourceURL: "https://www.openstreetmap.org/",
        verificationStatus: "unverified"
    )
}
