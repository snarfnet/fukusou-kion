import SwiftUI
import GoogleMobileAds
import UserMessagingPlatform

@MainActor
final class AdState: ObservableObject {
    @Published private(set) var canRequestAds = false
    @Published private(set) var isPrivacyOptionsRequired = false

    private var hasStartedMobileAds = false
    private var isPreparing = false

    init() {
        updateConsentState()
    }

    func prepare() {
        guard !ZenRuntime.hidesAdsForScreenshots, !isPreparing else { return }
        isPreparing = true

        let parameters = RequestParameters()
        parameters.isTaggedForUnderAgeOfConsent = false

        ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { [weak self] requestConsentError in
            Task { @MainActor in
                guard let self else { return }

                if requestConsentError != nil {
                    self.finishConsentFlow()
                    return
                }

                do {
                    try await ConsentForm.loadAndPresentIfRequired(from: nil)
                } catch {
                    // If the form cannot be shown, keep using the previous consent state.
                }

                self.finishConsentFlow()
            }
        }
    }

    func presentPrivacyOptions() {
        guard isPrivacyOptionsRequired else { return }

        Task { @MainActor in
            do {
                try await ConsentForm.presentPrivacyOptionsForm(from: nil)
            } catch {
                return
            }

            updateConsentState()
            startMobileAdsIfAllowed()
        }
    }

    private func finishConsentFlow() {
        isPreparing = false
        updateConsentState()
        startMobileAdsIfAllowed()
    }

    private func updateConsentState() {
        canRequestAds = !ZenRuntime.hidesAdsForScreenshots && ConsentInformation.shared.canRequestAds
        isPrivacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }

    private func startMobileAdsIfAllowed() {
        guard canRequestAds, !hasStartedMobileAds else { return }
        MobileAds.shared.start()
        hasStartedMobileAds = true
    }
}

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
