import SwiftUI
import GoogleMobileAds

enum AdPlacement {
    case homeBottom
}

struct AdService {
    static let shared = AdService()

    let isAdFree = false

    func bannerUnitID(for placement: AdPlacement) -> String {
        switch placement {
        case .homeBottom:
            "ca-app-pub-3940256099942544/2934735716"
        }
    }
}

struct AdMobBannerSlotView: View {
    let placement: AdPlacement

    var body: some View {
        if AdService.shared.isAdFree {
            EmptyView()
        } else {
            AdMobBannerView(unitID: AdService.shared.bannerUnitID(for: placement))
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .accessibilityLabel("広告")
        }
    }
}

private struct AdMobBannerView: UIViewRepresentable {
    let unitID: String

    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = unitID

        DispatchQueue.main.async {
            if let rootViewController = UIApplication.shared.activeRootViewController {
                banner.rootViewController = rootViewController
                banner.load(GADRequest())
            }
        }

        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}
}

@MainActor
final class InterstitialAdCoordinator: NSObject, ObservableObject, GADFullScreenContentDelegate {
    private var ad: GADInterstitialAd?
    private let unitID = "ca-app-pub-3940256099942544/4411468910"

    func load() {
        guard !AdService.shared.isAdFree else { return }
        GADInterstitialAd.load(withAdUnitID: unitID, request: GADRequest()) { [weak self] ad, _ in
            self?.ad = ad
            self?.ad?.fullScreenContentDelegate = self
        }
    }

    func showIfReady() {
        guard let rootViewController = UIApplication.shared.activeRootViewController,
              let ad else {
            load()
            return
        }

        ad.present(fromRootViewController: rootViewController)
        self.ad = nil
    }

    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        load()
    }
}

private extension UIApplication {
    var activeRootViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}
