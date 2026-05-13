import SwiftUI

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
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.64))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black.opacity(0.08), lineWidth: 1)
                    )
                Text("広告")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .frame(height: 50)
                .frame(maxWidth: .infinity)
                .accessibilityLabel("広告")
        }
    }
}

@MainActor
final class InterstitialAdCoordinator: ObservableObject {
    func load() {}
    func showIfReady() {}
}
