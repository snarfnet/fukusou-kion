import SwiftUI
import SwiftData

@main
struct HimahieApp: App {
    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(for: [Favorite.self, SpotReport.self])
    }
}
