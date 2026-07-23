import Foundation
import CoreLocation
import Observation

enum SpotCategoryFilter: String, CaseIterable, Identifiable {
    case all = "すべて"
    case culture = "文化・学び"
    case exhibition = "展示・博物館"
    case guide = "案内・見学"

    var id: String { rawValue }
    var icon: String {
        switch self {
        case .all: "square.grid.2x2"
        case .culture: "books.vertical"
        case .exhibition: "building.columns"
        case .guide: "map"
        }
    }

    func matches(_ spot: Spot) -> Bool {
        switch self {
        case .all: true
        case .culture: spot.category.contains("図書") || spot.category.contains("文化")
        case .exhibition: spot.category.contains("博物館") || spot.category.contains("ギャラリー") || spot.category.contains("展示") || spot.category.contains("ショールーム")
        case .guide: spot.category.contains("ビジター") || spot.category.contains("見学")
        }
    }
}

@Observable
final class SpotViewModel {
    var spots: [Spot] = []
    var prefectures: [PrefectureCatalog] = []
    var selectedPrefectureCode = "14" {
        didSet {
            usesCurrentLocation = false
            loadSelectedPrefecture()
        }
    }
    var usesCurrentLocation = true
    var searchText = ""
    var categoryFilter: SpotCategoryFilter = .all
    var maxDistance = 5.0
    var distanceFilterEnabled = true
    var freeOnly = true
    var indoorOnly = true
    var seatsOnly = false
    var toiletOnly = false
    var wifiOnly = false
    var verifiedOnly = false
    var errorMessage: String?
    let locationService = LocationService()
    private let repository: SpotRepositoryProtocol

    init(repository: SpotRepositoryProtocol = SpotRepository()) {
        self.repository = repository
        do {
            prefectures = try repository.loadCatalog()
            if !prefectures.contains(where: { $0.code == selectedPrefectureCode }), let first = prefectures.first {
                selectedPrefectureCode = first.code
            }
            loadSelectedPrefecture()
        } catch {
            errorMessage = "地域データを読み込めませんでした。"
        }
    }
    var selectedPrefecture: PrefectureCatalog? { prefectures.first { $0.code == selectedPrefectureCode } }
    var loadedSpotCount: Int { spots.count }
    var totalSpotCount: Int { prefectures.reduce(0) { $0 + $1.spotCount } }
    var fallbackLocation: CLLocation {
        .init(
            latitude: selectedPrefecture?.centerLatitude ?? 35.4478,
            longitude: selectedPrefecture?.centerLongitude ?? 139.6425
        )
    }
    var currentLocation: CLLocation {
        usesCurrentLocation ? (locationService.location ?? fallbackLocation) : fallbackLocation
    }
    var filtered: [Spot] {
        spots.filter { spot in
            let matchesText = searchText.isEmpty || spot.name.localizedCaseInsensitiveContains(searchText) || spot.category.localizedCaseInsensitiveContains(searchText) || spot.address.localizedCaseInsensitiveContains(searchText)
            return matchesText && categoryFilter.matches(spot) && (!freeOnly || spot.isFree) && (!indoorOnly || spot.indoor) && (!seatsOnly || spot.hasSeats == true) && (!toiletOnly || spot.hasToilet == true) && (!wifiOnly || spot.hasWifi == true) && (!verifiedOnly || spot.verificationStatus == "verified") && (!distanceFilterEnabled || distance(to: spot) <= maxDistance)
        }.sorted { distance(to: $0) < distance(to: $1) }
    }
    func distance(to spot: Spot) -> Double { currentLocation.distance(from: .init(latitude: spot.latitude, longitude: spot.longitude)) / 1000 }
    func recommendation(minutes: Int) -> Spot? {
        filtered.filter { $0.estimatedStayMinutes >= minutes }.max { score($0) < score($1) } ?? filtered.first
    }
    var recommended: [Spot] { filtered.sorted { score($0) > score($1) } }
    var hasActiveFilters: Bool { categoryFilter != .all || freeOnly || indoorOnly || seatsOnly || toiletOnly || wifiOnly || verifiedOnly || distanceFilterEnabled || !searchText.isEmpty }
    func resetFilters() {
        searchText = ""
        categoryFilter = .all
        freeOnly = false
        indoorOnly = false
        seatsOnly = false
        toiletOnly = false
        wifiOnly = false
        verifiedOnly = false
        distanceFilterEnabled = false
    }
    func searchFromCurrentLocation() {
        usesCurrentLocation = true
        locationService.request()
    }
    func loadSelectedPrefecture() {
        guard let prefecture = selectedPrefecture else { return }
        do {
            spots = try repository.load(prefecture: prefecture)
            errorMessage = spots.count == prefecture.spotCount ? nil : "登録件数とデータ件数が一致しません。"
        } catch {
            spots = []
            errorMessage = "\(prefecture.name)のスポット情報を読み込めませんでした。"
        }
    }
    private func score(_ spot: Spot) -> Double {
        Double(spot.funScore * 8 + spot.stayScore * 4)
        + (spot.verificationStatus == "verified" ? 30 : 0)
        + (spot.isFree ? 15 : 0)
        + (spot.airConditioned == true ? 15 : 0)
        - distance(to: spot) * 2
    }
}
