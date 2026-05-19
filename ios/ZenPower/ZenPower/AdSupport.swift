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
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = AdIDs.banner
        banner.delegate = context.coordinator
        return banner
    }

    func updateUIView(_ banner: BannerView, context: Context) {
        guard !context.coordinator.didLoad else { return }

        DispatchQueue.main.async {
            guard !context.coordinator.didLoad else { return }
            let rootViewController = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .compactMap { $0.keyWindow }
                .first?.rootViewController
                ?? banner.window?.rootViewController

            guard let rootViewController else { return }
            banner.rootViewController = rootViewController
            banner.load(Request())
            context.coordinator.didLoad = true
        }
    }

    final class Coordinator: NSObject, BannerViewDelegate {
        var didLoad = false
    }
}
