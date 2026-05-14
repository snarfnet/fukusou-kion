import SwiftUI
import GoogleMobileAds
import AppTrackingTransparency

@main
struct ZettaiOsunaYoApp: App {
    @StateObject private var game = GameViewModel(audioPlayer: AudioTauntPlayer())

    init() {
        GADMobileAds.sharedInstance().start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(game)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        ATTrackingManager.requestTrackingAuthorization { _ in }
                    }
                }
        }
    }
}
