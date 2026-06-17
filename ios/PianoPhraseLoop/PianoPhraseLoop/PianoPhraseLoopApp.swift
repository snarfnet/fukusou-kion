import SwiftUI

@main
struct PianoPhraseLoopApp: App {
    @StateObject private var adMobStartup = AdMobStartup()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(adMobStartup)
        }
    }
}
