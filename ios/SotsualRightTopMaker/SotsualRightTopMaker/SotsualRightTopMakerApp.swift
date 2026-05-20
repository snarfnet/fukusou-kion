import SwiftUI

@main
struct SotsualRightTopMakerApp: App {
    @StateObject private var purchaseManager = PurchaseManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(purchaseManager)
                .task {
                    await purchaseManager.loadProducts()
                    await purchaseManager.refreshPurchasedProducts()
                }
        }
    }
}
