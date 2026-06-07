import GoogleMobileAds
import SwiftUI

@main
struct GhostFollowerApp: App {
    @StateObject private var editor = GhostEditorViewModel()
    @StateObject private var store = GhostStore()

    init() {
        MobileAds.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(editor)
                .environmentObject(store)
                .task {
                    await store.loadProducts()
                }
        }
    }
}
