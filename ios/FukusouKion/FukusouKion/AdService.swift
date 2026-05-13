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
final class AdService {
    static let shared = AdService()

    let isAdFree = false

    private init() {}

    func start() {
        MobileAds.shared.start()
    }

    func bannerUnitID(for placement: AdPlacement) -> String {
        switch placement {
        case .homeBottom:
            AdConfiguration.bannerUnitID
        }
    }
}

struct AdMobBannerSlotView: View {
    let placement: AdPlacement

    var body: some View {
        if AdService.shared.isAdFree {
            EmptyView()
        } else {
            GeometryReader { proxy in
                let width = max(proxy.size.width, 320)
                let adSize = largeAnchoredAdaptiveBanner(width: width)

                BannerViewContainer(
                    adSize: adSize,
                    adUnitID: AdService.shared.bannerUnitID(for: placement)
                )
                .frame(width: adSize.size.width, height: adSize.size.height)
                .frame(maxWidth: .infinity)
            }
            .frame(height: 60)
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
