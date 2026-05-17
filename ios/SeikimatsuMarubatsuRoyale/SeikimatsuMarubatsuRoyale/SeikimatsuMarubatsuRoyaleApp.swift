import SwiftUI
import GoogleMobileAds

@main
struct SeikimatsuMarubatsuRoyaleApp: App {
    @StateObject private var game = GameStore()
    @StateObject private var adService = RewardedAdService.shared

    init() {
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(game)
                .environmentObject(adService)
        }
    }
}
