import Foundation
import StoreKit

@MainActor
final class PurchaseStore: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedPacks: Set<MoriPack> = []
    @Published private(set) var hasAllAccessSubscription = false
    @Published var errorMessage: String?

    private var updatesTask: Task<Void, Never>?

    var packProducts: [Product] {
        products.filter { product in
            MoriPack.allCases.contains { $0.productID == product.id }
        }
    }

    var subscriptionProduct: Product? {
        products.first { $0.id == MoriSubscription.allAccessMonthly.productID }
    }

    init() {
        updatesTask = Task {
            for await update in Transaction.updates {
                await handle(update)
            }
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func load() async {
        do {
            let ids = Set(MoriPack.allCases.compactMap(\.productID) + [MoriSubscription.allAccessMonthly.productID])
            products = try await Product.products(for: ids).sorted { $0.displayName < $1.displayName }
            await refreshEntitlements()
        } catch {
            errorMessage = "課金情報を読み込めませんでした"
        }
    }

    func product(for pack: MoriPack) -> Product? {
        guard let productID = pack.productID else { return nil }
        return products.first { $0.id == productID }
    }

    func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                await handle(verification)
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = "購入を完了できませんでした"
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            errorMessage = "購入を復元できませんでした"
        }
    }

    private func refreshEntitlements() async {
        var packs: Set<MoriPack> = []
        var allAccess = false
        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement else { continue }
            if transaction.revocationDate != nil { continue }
            if transaction.productID == MoriSubscription.allAccessMonthly.productID {
                allAccess = true
                continue
            }
            if let pack = MoriPack.allCases.first(where: { $0.productID == transaction.productID }) {
                packs.insert(pack)
            }
        }
        purchasedPacks = packs
        hasAllAccessSubscription = allAccess
    }

    private func handle(_ verification: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = verification else {
            errorMessage = "購入を確認できませんでした"
            return
        }
        await transaction.finish()
        await refreshEntitlements()
    }
}
