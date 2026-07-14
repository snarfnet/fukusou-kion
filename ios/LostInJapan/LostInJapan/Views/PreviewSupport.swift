import SwiftUI
import SwiftData

@MainActor
enum PreviewSupport {
    static let container: ModelContainer = {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: LostItemCase.self, configurations: configuration)
        let sample = LostItemCase(
            title: "Passport",
            categories: [.passport],
            itemDescription: ItemDescription(color: "Navy", details: "Blue cover"),
            location: LostLocation(category: .train, name: "Yamanote Line", detail: "Near the door"),
            urgency: .a
        )
        container.mainContext.insert(sample)
        return container
    }()
}
