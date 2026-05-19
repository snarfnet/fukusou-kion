import SwiftUI
import GoogleMobileAds

enum AdIDs {
    static var banner: String {
        Bundle.main.object(forInfoDictionaryKey: "GADBannerAdUnitID") as? String
            ?? "ca-app-pub-3940256099942544/2435281174"
    }
}

struct BannerAdView: UIViewRepresentable {
    let width: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> BannerView {
        let adSize = largeAnchoredAdaptiveBanner(width: width)
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = AdIDs.banner
        banner.delegate = context.coordinator
        banner.load(Request())
        return banner
    }

    func updateUIView(_ banner: BannerView, context: Context) {
        let adSize = largeAnchoredAdaptiveBanner(width: width)
        if !CGSizeEqualToSize(banner.adSize.size, adSize.size) {
            banner.adSize = adSize
            banner.load(Request())
        }
    }

    final class Coordinator: NSObject, BannerViewDelegate {}
}
