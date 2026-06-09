import SwiftUI

@main
struct VoiceprintInstallationApp: App {
    @StateObject private var recorder = VoiceRecorder()
    @StateObject private var gallery = ArtworkGallery()
    private let screenshotDemo = ProcessInfo.processInfo.arguments.contains("--screenshot-demo")

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(recorder)
                .environmentObject(gallery)
                .task {
                    if screenshotDemo {
                        gallery.useDemoArtworks(DemoArtworkFactory.artworks())
                    }
                }
        }
    }
}
