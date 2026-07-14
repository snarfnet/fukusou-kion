import SwiftUI
import SwiftData

@main
struct LostInJapanApp: App {
    var body: some Scene {
        WindowGroup { RootView() }
            .modelContainer(for: LostItemCase.self)
    }
}

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("appLanguage") private var appLanguage = AppLanguage.system.rawValue

    var body: some View {
        Group {
            if hasCompletedOnboarding { AppRouterView() }
            else { OnboardingView { hasCompletedOnboarding = true } }
        }
        .environment(\.locale, AppLanguage(rawValue: appLanguage)?.locale ?? .autoupdatingCurrent)
        .id(appLanguage)
    }
}
