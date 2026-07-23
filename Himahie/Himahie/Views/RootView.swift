import SwiftUI

struct RootView: View {
    @State private var model = SpotViewModel()
    var body: some View {
        TabView {
            NavigationStack { HomeView(model: model) }.tabItem { Label("探す", systemImage: "snowflake") }
            NavigationStack { SpotListView(model: model) }.tabItem { Label("一覧", systemImage: "list.bullet") }
            NavigationStack { SpotMapView(model: model) }.tabItem { Label("地図", systemImage: "map") }
            NavigationStack { FavoritesView(model: model) }.tabItem { Label("お気に入り", systemImage: "heart") }
        }
        .tint(Theme.blue)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
    }
}
