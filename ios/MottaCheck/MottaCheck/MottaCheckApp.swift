import SwiftData
import SwiftUI
import GoogleMobileAds
import AppTrackingTransparency

@main
struct MottaCheckApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PackingList.self,
            PackingItem.self,
            ForgottenRecord.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("ModelContainerを作成できませんでした: \(error)")
        }
    }()

    init() {
        MobileAds.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        ATTrackingManager.requestTrackingAuthorization { _ in }
                    }
                }
        }
    }
}
