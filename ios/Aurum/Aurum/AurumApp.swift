import SwiftUI

@main
struct AurumApp: App {
    @StateObject private var store = PracticeStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}
