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

    func testCurrentLocationResultsAreSortedByDistance() {
        let locationService = LocationService()
        locationService.location = CLLocation(latitude: 35.0, longitude: 139.0)
        let model = SpotViewModel(
            repository: DistanceRepository(),
            locationService: locationService
        )
        model.indoorOnly = false
        model.distanceFilterEnabled = false

        XCTAssertEqual(model.filtered.map(\.id), ["near", "middle", "far"])
        XCTAssertLessThan(model.distance(to: model.filtered[0]), model.distance(to: model.filtered[1]))
        XCTAssertLessThan(model.distance(to: model.filtered[1]), model.distance(to: model.filtered[2]))
    }

    func testFacilityTypesCanBeCombined() {
        let model = SpotViewModel(repository: DiversityRepository())
        model.selectedFacilityTypes = [.library, .museum]

        XCTAssertEqual(Set(model.filtered.map(\.category)), ["図書館", "博物館"])
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

private struct DistanceRepository: SpotRepositoryProtocol {
    func loadCatalog() throws -> [PrefectureCatalog] {
        [.init(code: "14", name: "神奈川県", fileName: "spots_14", spotCount: 3, centerLatitude: 35.0, centerLongitude: 139.0)]
    }

    func load(prefecture: PrefectureCatalog) throws -> [Spot] {
        [
            testSpot(id: "far", category: "図書館", latitude: 35.3),
            testSpot(id: "near", category: "博物館", latitude: 35.01),
            testSpot(id: "middle", category: "ギャラリー", latitude: 35.1)
        ]
    }
}

private func testSpot(
    id: String,
    category: String,
    latitude: Double = 35.4478
) -> Spot {
    Spot(
        id: id,
        name: id,
        category: category,
        latitude: latitude,
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
