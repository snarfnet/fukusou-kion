import SwiftUI

@main
struct VoiceprintInstallationApp: App {
    @StateObject private var recorder = VoiceRecorder()
    @StateObject private var gallery = ArtworkGallery()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(recorder)
                .environmentObject(gallery)
        }
    }
}
