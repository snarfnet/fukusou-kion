import Foundation
import StoreKit

@MainActor
final class PurchaseManager: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var unlockedProductIDs: Set<String> = []
    @Published var purchaseMessage: String?

    var isEventPackUnlocked: Bool {
        unlockedProductIDs.contains(TemplateLibrary.eventPackProductID)
    }

    var isSecondPackUnlocked: Bool {
        unlockedProductIDs.contains(TemplateLibrary.secondPackProductID)
    }

    func isUnlocked(_ template: PhotoTemplate) -> Bool {
        switch template.category {
        case .free:
            return true
        case .eventPack:
            return isEventPackUnlocked
        case .secondPack:
            return isSecondPackUnlocked
        }
    }

    func isUnlocked(_ pack: TemplatePack) -> Bool {
        unlockedProductIDs.contains(pack.productID)
    }

    func product(for pack: TemplatePack) -> Product? {
        products.first(where: { $0.id == pack.productID })
    }

    func loadProducts() async {
        do {
            products = try await Product.products(for: TemplatePack.allCases.map(\.productID))
        } catch {
            purchaseMessage = "商品情報を読み込めませんでした"
        }
    }

    func refreshPurchasedProducts() async {
        var purchased: Set<String> = []
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            purchased.insert(transaction.productID)
        }
        unlockedProductIDs = purchased
    }

    func purchase(_ pack: TemplatePack) async {
        guard let product = product(for: pack) else {
            purchaseMessage = "購入アイテムを準備中です"
            await loadProducts()
            return
        }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    purchaseMessage = "購入を確認できませんでした"
                    return
                }
                unlockedProductIDs.insert(transaction.productID)
                await transaction.finish()
                purchaseMessage = "\(pack.title)を解放しました"
            case .userCancelled:
                purchaseMessage = "購入をキャンセルしました"
            case .pending:
                purchaseMessage = "購入の承認待ちです"
            @unknown default:
                purchaseMessage = "購入を完了できませんでした"
            }
        } catch {
            purchaseMessage = "購入に失敗しました"
        }
    }

    func restore() async {
        do {
            try await AppStore.sync()
            await refreshPurchasedProducts()
            purchaseMessage = unlockedProductIDs.isEmpty ? "復元できる購入はありません" : "購入を復元しました"
        } catch {
            purchaseMessage = "復元に失敗しました"
        }
    }
}
