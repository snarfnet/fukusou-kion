import SwiftUI
import GoogleMobileAds

enum AdUnitID {
    static let homeBanner = "ca-app-pub-3940256099942544/2934735716"
    static let templateBanner = "ca-app-pub-3940256099942544/2934735716"
}

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = adUnitID

        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let root = windowScene.windows.first?.rootViewController {
                banner.rootViewController = root
                banner.load(GADRequest())
            }
        }

        return banner
    }

    func updateUIView(_ uiView: GADBannerView, context: Context) {}
}

struct AdBannerSlot: View {
    let unitID: String

    var body: some View {
        BannerAdView(adUnitID: unitID)
            .frame(height: 50)
            .background(.white)
            .accessibilityLabel("広告")
    }
}
