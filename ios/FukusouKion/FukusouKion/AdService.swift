import AppTrackingTransparency
import GoogleMobileAds
import SwiftUI
import UIKit

enum AdPlacement {
    case homeBottom
}

struct AdConfiguration {
    static let sampleAppID = "ca-app-pub-3940256099942544~1458002511"
    static let sampleBannerUnitID = "ca-app-pub-3940256099942544/2435281174"
    static let sampleInterstitialUnitID = "ca-app-pub-3940256099942544/4411468910"

    static var bannerUnitID: String {
        bundleValue(for: "GADBannerAdUnitID", fallback: sampleBannerUnitID)
    }

    static var interstitialUnitID: String {
        bundleValue(for: "GADInterstitialAdUnitID", fallback: sampleInterstitialUnitID)
    }

    static var usesSampleIDs: Bool {
        bannerUnitID == sampleBannerUnitID || interstitialUnitID == sampleInterstitialUnitID
    }

    static var canShowInterstitial: Bool {
        !interstitialUnitID.isEmpty && interstitialUnitID.lowercased() != "disabled"
    }

    private static func bundleValue(for key: String, fallback: String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
              !value.isEmpty,
              !value.hasPrefix("$(") else {
            return fallback
        }
        return value
    }
}

@MainActor
final class AdService: ObservableObject {
    static let shared = AdService()

    let isAdFree = false
    @Published private(set) var isReady = false

    private init() {}

    func start() async {
        guard !isReady else { return }
        await requestTrackingAuthorizationIfNeeded()
        await MobileAds.shared.start()
        isReady = true
    }

    func bannerUnitID(for placement: AdPlacement) -> String {
        switch placement {
        case .homeBottom:
            AdConfiguration.bannerUnitID
        }
    }

    private func requestTrackingAuthorizationIfNeeded() async {
        guard #available(iOS 14.5, *),
              ATTrackingManager.trackingAuthorizationStatus == .notDetermined else {
            return
        }

        _ = await withCheckedContinuation { continuation in
            ATTrackingManager.requestTrackingAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }
}

struct AdMobBannerSlotView: View {
    let placement: AdPlacement
    @EnvironmentObject private var adService: AdService

    var body: some View {
        if adService.isAdFree || !adService.isReady {
            EmptyView()
        } else {
            BannerViewContainer(
                adSize: AdSizeBanner,
                adUnitID: adService.bannerUnitID(for: placement)
            )
            .frame(width: AdSizeBanner.size.width, height: AdSizeBanner.size.height)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("広告")
        }
    }
}

private struct BannerViewContainer: UIViewRepresentable {
    let adSize: AdSize
    let adUnitID: String

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = adUnitID
        banner.rootViewController = UIApplication.shared.adRootViewController
        banner.load(Request())
        return banner
    }

    func updateUIView(_ banner: BannerView, context: Context) {
        if banner.adUnitID != adUnitID {
            banner.adUnitID = adUnitID
            banner.load(Request())
        }
    }
}

@MainActor
final class InterstitialAdCoordinator: NSObject, ObservableObject, FullScreenContentDelegate {
    private var interstitialAd: InterstitialAd?
    private var isLoading = false

    func load() {
        guard !AdService.shared.isAdFree,
              AdService.shared.isReady,
              AdConfiguration.canShowInterstitial,
              !isLoading else { return }

        isLoading = true
        Task {
            do {
                let ad = try await InterstitialAd.load(
                    with: AdConfiguration.interstitialUnitID,
                    request: Request()
                )
                ad.fullScreenContentDelegate = self
                interstitialAd = ad
            } catch {
                interstitialAd = nil
            }
            isLoading = false
        }
    }

    func showIfReady() {
        guard let interstitialAd,
              let rootViewController = UIApplication.shared.adRootViewController else {
            load()
            return
        }

        self.interstitialAd = nil
        interstitialAd.present(from: rootViewController)
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        load()
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
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
