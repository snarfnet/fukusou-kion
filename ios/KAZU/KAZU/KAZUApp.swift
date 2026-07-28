import SwiftUI

@main
struct KAZUApp: App {
    @StateObject private var store = CalculatorStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.light)
        }
    }
}

