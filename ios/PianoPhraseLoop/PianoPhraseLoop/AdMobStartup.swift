import AppTrackingTransparency
import Foundation
import GoogleMobileAds

@MainActor
final class AdMobStartup: ObservableObject {
    @Published private(set) var isReady = false

    private var didStart = false

    func requestTrackingAuthorizationThenStartAds() {
        guard !didStart else { return }
        didStart = true

        if #available(iOS 14, *) {
            if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
                ATTrackingManager.requestTrackingAuthorization { [weak self] _ in
                    DispatchQueue.main.async {
                        self?.startAds()
                    }
                }
                return
            }
        }

        startAds()
    }

    private func startAds() {
        MobileAds.shared.start()
        isReady = true
    }
}
