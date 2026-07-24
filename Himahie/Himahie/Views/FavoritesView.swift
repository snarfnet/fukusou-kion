import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Query(sort: \Favorite.savedAt, order: .reverse) private var favorites: [Favorite]
    @Bindable var model: SpotViewModel
    var saved: [Spot] {
        favorites.compactMap { favorite in
            favorite.decodedSpot ?? model.spots.first { $0.id == favorite.spotID }
        }
    }
    var body: some View {
        Group {
            if saved.isEmpty { ContentUnavailableView("まだ保存していません", systemImage: "heart", description: Text("詳細画面のハートから追加できます。")) }
            else { List(saved) { spot in NavigationLink(value: spot) { SpotCard(spot: spot, distanceText: model.distanceText(to: spot)) }.listRowSeparator(.hidden) }.listStyle(.plain) }
        }.navigationTitle("お気に入り").navigationDestination(for: Spot.self) { SpotDetailView(spot: $0, distance: model.distance(to: $0)) }
    }
}
