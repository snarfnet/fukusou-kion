import GoogleMobileAds
import SwiftUI
import UIKit

enum AdMobConfig {
    static let sampleBannerUnitID = "ca-app-pub-3940256099942544/2435281174"

    static var bannerUnitID: String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "GADBannerAdUnitID") as? String,
              !value.isEmpty,
              !value.hasPrefix("$(") else {
            return sampleBannerUnitID
        }
        return value
    }
}

struct BannerAdView: View {
    var body: some View {
        BannerViewContainer(adSize: AdSizeBanner, adUnitID: AdMobConfig.bannerUnitID)
            .frame(width: AdSizeBanner.size.width, height: AdSizeBanner.size.height)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(.black.opacity(0.3))
            .accessibilityLabel("広告")
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
