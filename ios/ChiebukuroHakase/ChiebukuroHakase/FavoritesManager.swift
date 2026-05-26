import SwiftUI

@Observable
final class FavoritesManager {
    private(set) var favoriteIds: Set<Int> = []
    private let key = "favoriteWisdomIds"

    init() {
        let ids = UserDefaults.standard.array(forKey: key) as? [Int] ?? []
        favoriteIds = Set(ids)
    }

    func toggle(_ id: Int) {
        if favoriteIds.contains(id) {
            favoriteIds.remove(id)
        } else {
            favoriteIds.insert(id)
        }
        UserDefaults.standard.set(Array(favoriteIds), forKey: key)
    }

    func isFavorite(_ id: Int) -> Bool {
        favoriteIds.contains(id)
    }

    func favoriteWisdoms(from all: [WisdomItem]) -> [WisdomItem] {
        all.filter { favoriteIds.contains($0.id) }
    }
}
