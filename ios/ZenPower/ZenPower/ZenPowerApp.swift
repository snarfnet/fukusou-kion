import SwiftUI
import GoogleMobileAds

@main
struct ZenPowerApp: App {
    @StateObject private var progressStore = ZenProgressStore()

    init() {
        MobileAds.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(progressStore)
        }
    }
}
