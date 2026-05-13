import SwiftData
import SwiftUI

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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(sharedModelContainer)
        }
    }
}
