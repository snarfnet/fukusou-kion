import SwiftUI

@main
struct NeruMaeOkyoApp: App {
    @StateObject private var audioManager = SleepAudioManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(audioManager)
                .preferredColorScheme(.dark)
        }
    }
}
