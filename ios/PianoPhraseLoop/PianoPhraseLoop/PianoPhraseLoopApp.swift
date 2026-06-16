import SwiftUI
import GoogleMobileAds

@main
struct PianoPhraseLoopApp: App {
    init() {
        MobileAds.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
