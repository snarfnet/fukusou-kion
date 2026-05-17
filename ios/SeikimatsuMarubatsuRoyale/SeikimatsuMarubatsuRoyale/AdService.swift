import SwiftUI

@MainActor
final class RewardedAdService: ObservableObject {
    static let shared = RewardedAdService()

    @Published private(set) var isLoaded = false
    @Published private(set) var isLoading = false

    private init() {}

    func load() {}

    func showRewardedAd(onReward: @escaping () -> Void, onUnavailable: @escaping () -> Void) {
        onUnavailable()
    }
}
