import SwiftUI
import Foundation

@main
struct SukebanMahjongApp: App {
    init() {
        let environment = ProcessInfo.processInfo.environment
        guard environment["SUKEBAN_UI_TEST_RESET"] == "1" else { return }

        let defaults = UserDefaults.standard
        [
            "tutorial.completed",
            "story.prologueSeen",
            "sukebanMahjong.clearedSchools",
            "sukebanMahjong.activeMatch.v1",
            "settings.sound",
            "settings.haptics",
            "settings.confirmDiscard"
        ].forEach(defaults.removeObject(forKey:))

        if environment["SUKEBAN_UI_TEST_SKIP_ONBOARDING"] == "1" {
            defaults.set(true, forKey: "tutorial.completed")
            defaults.set(true, forKey: "story.prologueSeen")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
    }
}
