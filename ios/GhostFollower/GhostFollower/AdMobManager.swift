import AppTrackingTransparency
import Foundation
import GoogleMobileAds
import UIKit

@MainActor
final class AdMobManager: ObservableObject {
    @Published private(set) var isReady = false
    private var didStart = false

    func start() async {
        guard !didStart else { return }
        didStart = true

        await requestTrackingAuthorizationIfNeeded()
        await withCheckedContinuation { continuation in
            MobileAds.shared.start { _ in
                continuation.resume()
            }
        }
        isReady = true
    }

    private func requestTrackingAuthorizationIfNeeded() async {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        await waitForActiveApplication()
        try? await Task.sleep(nanoseconds: 700_000_000)
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }

        await withCheckedContinuation { continuation in
            ATTrackingManager.requestTrackingAuthorization { _ in
                continuation.resume()
            }
        }
    }

    private func waitForActiveApplication() async {
        for _ in 0..<30 {
            if UIApplication.shared.applicationState == .active {
                return
            }
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
    }
}
