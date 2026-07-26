import SwiftUI

enum AppTab: Hashable {
    case search
    case list
    case map
    case favorites
}

struct RootView: View {
    @State private var model = SpotViewModel()
    @State private var selectedTab: AppTab = .search
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { HomeView(model: model, selectedTab: $selectedTab) }
                .tabItem { Label("探す", systemImage: "snowflake") }
                .tag(AppTab.search)
            NavigationStack { SpotListView(model: model) }
                .tabItem { Label("一覧", systemImage: "list.bullet") }
                .tag(AppTab.list)
            NavigationStack { SpotMapView(model: model) }
                .tabItem { Label("地図", systemImage: "map") }
                .tag(AppTab.map)
            NavigationStack { FavoritesView(model: model) }
                .tabItem { Label("お気に入り", systemImage: "heart") }
                .tag(AppTab.favorites)
        }
        .tint(Theme.blue)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
    }
}
