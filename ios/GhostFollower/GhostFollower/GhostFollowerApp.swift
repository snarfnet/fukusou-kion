import SwiftUI

@main
struct GhostFollowerApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var editor = GhostEditorViewModel()
    @StateObject private var store = GhostStore()
    @StateObject private var ads = AdMobManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(editor)
                .environmentObject(store)
                .environmentObject(ads)
                .task {
                    await store.loadProducts()
                }
                .task(id: scenePhase) {
                    if scenePhase == .active {
                        await ads.start()
                    }
                }
        }
    }
}
