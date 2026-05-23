import AppTrackingTransparency
import GoogleMobileAds
import SwiftUI

@main
struct ChiebukuroNagareApp: App {
    init() {
        MobileAds.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
                    try? await Task.sleep(for: .seconds(1.2))
                    await ATTrackingManager.requestAuthorization()
                }
        }
    }
}

private extension ATTrackingManager {
    static func requestAuthorization() async {
        await withCheckedContinuation { continuation in
            requestTrackingAuthorization { _ in
                continuation.resume()
            }
        }
    }
}
