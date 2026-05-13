import SwiftUI

@main
struct NichanMatomeApp: App {
    @StateObject private var store = FeedStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .task {
                    AdService.shared.start()
                }
        }
    }
}
