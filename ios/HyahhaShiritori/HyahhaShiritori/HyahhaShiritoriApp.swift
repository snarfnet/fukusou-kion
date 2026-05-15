import SwiftUI

@main
struct HyahhaShiritoriApp: App {
    @StateObject private var game = GameViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(game)
        }
    }
}
