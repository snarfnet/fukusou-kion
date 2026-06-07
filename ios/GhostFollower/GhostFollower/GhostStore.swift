import Foundation
import StoreKit

@MainActor
final class GhostStore: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published var purchaseMessage: String?

    private let productIDs = GhostStyle.allCases.compactMap(\.productID)

    func loadProducts() async {
        do {
            products = try await Product.products(for: productIDs)
            await refreshEntitlements()
        } catch {
            purchaseMessage = "追加パックを読み込めませんでした。"
        }
    }

    func canUse(_ style: GhostStyle) -> Bool {
        guard let productID = style.productID else { return true }
        return purchasedProductIDs.contains(productID)
    }

    func displayPrice(for style: GhostStyle) -> String {
        guard let productID = style.productID else { return "同梱" }
        return products.first(where: { $0.id == productID })?.displayPrice ?? "準備中"
    }

    func purchase(_ style: GhostStyle) async {
        guard let productID = style.productID,
              let product = products.first(where: { $0.id == productID }) else {
            purchaseMessage = "この幽霊はまだ販売準備中です。"
            return
        }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                purchasedProductIDs.insert(transaction.productID)
                await transaction.finish()
                purchaseMessage = "幽霊を追加しました。"
            case .userCancelled:
                purchaseMessage = nil
            case .pending:
                purchaseMessage = "購入の承認待ちです。"
            @unknown default:
                purchaseMessage = "購入状態を確認してください。"
            }
        } catch {
            purchaseMessage = "購入に失敗しました。"
        }
    }

    func refreshEntitlements() async {
        var ids: Set<String> = []
        for await entitlement in Transaction.currentEntitlements {
            if case .verified(let transaction) = entitlement {
                ids.insert(transaction.productID)
            }
        }
        purchasedProductIDs = ids
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value): value
        case .unverified: throw StoreError.failedVerification
        }
    }

    enum StoreError: Error {
        case failedVerification
    }
}
