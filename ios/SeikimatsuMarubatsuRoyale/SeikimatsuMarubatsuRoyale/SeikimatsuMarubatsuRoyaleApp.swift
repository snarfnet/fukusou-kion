import SwiftUI

@main
struct SeikimatsuMarubatsuRoyaleApp: App {
    @StateObject private var game = GameStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(game)
        }
    }
}
