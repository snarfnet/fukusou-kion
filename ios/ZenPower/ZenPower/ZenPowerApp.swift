import SwiftUI

@main
struct ZenPowerApp: App {
    @StateObject private var progressStore = ZenProgressStore()
    @StateObject private var adState = AdState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(progressStore)
                .environmentObject(adState)
                .onAppear {
                    adState.prepare()
                }
        }
    }
}
