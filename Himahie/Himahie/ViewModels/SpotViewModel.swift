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
        didSet { loadSelectedPrefecture() }
    }
    var followsCurrentLocation = false
    var searchText = ""
    var categoryFilter: SpotCategoryFilter = .all
    var maxDistance = 15.0
    var distanceFilterEnabled = true
    var freeOnly = false
    var indoorOnly = true
    var seatsOnly = false
    var toiletOnly = false
    var wifiOnly = false
    var verifiedOnly = false
    var errorMessage: String?
    let locationService: LocationService
    private let repository: SpotRepositoryProtocol

    init(
        repository: SpotRepositoryProtocol = SpotRepository(),
        locationService: LocationService = LocationService()
    ) {
        self.repository = repository
        self.locationService = locationService
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
    var hasPreciseLocation: Bool { locationService.location != nil }
    var currentLocation: CLLocation { locationService.location ?? fallbackLocation }
    var distanceBasisText: String {
        if let location = locationService.location {
            return "現在地からの直線距離（精度 ±\(max(1, Int(location.horizontalAccuracy)))m）"
        }
        return "\(selectedPrefecture?.name ?? "地域")中心からの概算距離"
    }
    var filtered: [Spot] {
        spots.filter { spot in
            let matchesText = searchText.isEmpty || spot.name.localizedCaseInsensitiveContains(searchText) || spot.category.localizedCaseInsensitiveContains(searchText) || spot.address.localizedCaseInsensitiveContains(searchText)
            return matchesText && categoryFilter.matches(spot) && (!freeOnly || spot.isFree) && (!indoorOnly || spot.indoor) && (!seatsOnly || spot.hasSeats == true) && (!toiletOnly || spot.hasToilet == true) && (!wifiOnly || spot.hasWifi == true) && (!verifiedOnly || spot.verificationStatus == "verified") && (!distanceFilterEnabled || distance(to: spot) <= maxDistance)
        }.sorted { distance(to: $0) < distance(to: $1) }
    }
    func distance(to spot: Spot) -> Double { currentLocation.distance(from: .init(latitude: spot.latitude, longitude: spot.longitude)) / 1000 }
    func distanceText(to spot: Spot) -> String {
        let value = distance(to: spot)
        let prefix = hasPreciseLocation ? "" : "約"
        if value < 1 {
            return "\(prefix)\(max(10, Int((value * 1000 / 10).rounded()) * 10))m"
        }
        return "\(prefix)\(String(format: value < 10 ? "%.1fkm" : "%.0fkm", value))"
    }
    func travelText(to spot: Spot) -> String {
        let value = distance(to: spot)
        if value <= 5 {
            return "徒歩約\(max(1, Int(value / 4.5 * 60)))分"
        }
        return "直線 \(distanceText(to: spot))"
    }
    func recommendation(minutes: Int) -> Spot? {
        filtered.filter { $0.estimatedStayMinutes >= minutes }.max { score($0) < score($1) } ?? filtered.first
    }
    var recommended: [Spot] {
        let ranked = filtered.sorted { score($0) > score($1) }
        guard !ranked.isEmpty else { return [] }
        let buckets = Dictionary(grouping: ranked, by: categoryGroup)
        let groupOrder = buckets.keys.sorted {
            score(buckets[$0]!.first!) > score(buckets[$1]!.first!)
        }
        var result: [Spot] = []
        var index = 0
        while result.count < ranked.count {
            var appended = false
            for group in groupOrder {
                guard let items = buckets[group], index < items.count else { continue }
                result.append(items[index])
                appended = true
            }
            if !appended { break }
            index += 1
        }
        return result
    }
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
    func selectPrefecture(_ code: String) {
        followsCurrentLocation = false
        distanceFilterEnabled = false
        selectedPrefectureCode = code
    }
    func searchFromCurrentLocation() {
        followsCurrentLocation = true
        distanceFilterEnabled = true
        maxDistance = 15
        syncPrefectureToCurrentLocation()
        locationService.request()
    }
    func syncPrefectureToCurrentLocation() {
        guard followsCurrentLocation, let location = locationService.location else { return }
        if let administrativeArea = locationService.administrativeArea,
           let matched = prefectures.first(where: {
               $0.name == administrativeArea
               || $0.name.replacingOccurrences(of: "都", with: "")
                   .replacingOccurrences(of: "府", with: "")
                   .replacingOccurrences(of: "県", with: "") == administrativeArea
           }) {
            if selectedPrefectureCode != matched.code {
                selectedPrefectureCode = matched.code
            }
            return
        }
        guard let nearest = prefectures.min(by: {
                  location.distance(from: CLLocation(latitude: $0.centerLatitude, longitude: $0.centerLongitude))
                  < location.distance(from: CLLocation(latitude: $1.centerLatitude, longitude: $1.centerLongitude))
              }) else { return }
        if selectedPrefectureCode != nearest.code {
            selectedPrefectureCode = nearest.code
        }
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
        + (spot.isFree ? 12 : 0)
        + (spot.price < 0 ? 3 : 0)
        + (spot.airConditioned == true ? 15 : 0)
        - min(distance(to: spot), 50) * 0.4
    }
    private func categoryGroup(_ spot: Spot) -> String {
        if spot.category.contains("図書") { return "library" }
        if spot.category.contains("博物館") { return "museum" }
        if spot.category.contains("ギャラリー") || spot.category.contains("文化") { return "culture" }
        return "guide"
    }
}
