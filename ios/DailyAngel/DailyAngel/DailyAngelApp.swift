import SwiftUI

@main
struct DailyAngelApp: App {
    @StateObject private var store = AngelMessageStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
