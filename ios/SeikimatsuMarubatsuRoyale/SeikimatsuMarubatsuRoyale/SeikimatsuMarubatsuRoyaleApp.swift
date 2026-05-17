import SwiftUI

@main
struct SeikimatsuMarubatsuRoyaleApp: App {
    @StateObject private var game = GameStore()
    @StateObject private var adService = RewardedAdService.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(game)
                .environmentObject(adService)
        }
    }
}
