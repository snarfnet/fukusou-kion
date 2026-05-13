import SwiftUI

@main
struct LifeRouletteApp: App {
    @StateObject private var historyStore = ResultHistoryStore()
    private let adService = PlaceholderAdService()

    var body: some Scene {
        WindowGroup {
            ContentView(adService: adService)
                .environmentObject(historyStore)
        }
    }
}
