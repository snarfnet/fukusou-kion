import SwiftUI
import GoogleMobileAds

enum AdUnitID {
    static let topBanner = "ca-app-pub-9404799280370656/5013884061"
    static let bottomBanner = "ca-app-pub-9404799280370656/6749032323"
}

struct AdBannerSlot: View {
    let unitID: String

    var body: some View {
        AdMobBannerView(unitID: unitID)
            .frame(height: 50)
            .background(Color.white)
            .accessibilityLabel("Ad")
    }
}

private struct AdMobBannerView: UIViewRepresentable {
    let unitID: String

    func makeUIView(context: Context) -> GADBannerView {
        let banner = GADBannerView(adSize: GADAdSizeBanner)
        banner.adUnitID = unitID

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
