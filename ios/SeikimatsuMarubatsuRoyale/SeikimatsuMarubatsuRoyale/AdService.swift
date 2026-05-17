import GoogleMobileAds
import SwiftUI
import UIKit

@MainActor
final class RewardedAdService: NSObject, ObservableObject, GADFullScreenContentDelegate {
    static let shared = RewardedAdService()

    @Published private(set) var isLoaded = false
    @Published private(set) var isLoading = false

    private let rewardedAdUnitID = "ca-app-pub-9404799280370656/8535760863"
    private var rewardedAd: GADRewardedAd?
    private var pendingReward: (() -> Void)?

    private override init() {
        super.init()
        load()
    }

    func load() {
        guard !isLoading else { return }

        isLoading = true
        Task { @MainActor in
            do {
                let ad = try await GADRewardedAd.load(
                    withAdUnitID: rewardedAdUnitID,
                    request: GADRequest()
                )
                ad.fullScreenContentDelegate = self
                rewardedAd = ad
                isLoaded = true
            } catch {
                rewardedAd = nil
                isLoaded = false
            }
            isLoading = false
        }
    }

    func showRewardedAd(onReward: @escaping () -> Void, onUnavailable: @escaping () -> Void) {
        guard let rewardedAd,
              let rootViewController = UIApplication.shared.adRootViewController else {
            onUnavailable()
            load()
            return
        }

        self.rewardedAd = nil
        isLoaded = false
        pendingReward = onReward

        rewardedAd.present(fromRootViewController: rootViewController) { [weak self] in
            self?.pendingReward?()
            self?.pendingReward = nil
        }
    }

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        pendingReward = nil
        load()
    }

    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        pendingReward = nil
        load()
    }
}

private extension UIApplication {
    var adRootViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController?
            .topPresentedViewController
    }
}

private extension UIViewController {
    var topPresentedViewController: UIViewController {
        presentedViewController?.topPresentedViewController ?? self
    }
}
