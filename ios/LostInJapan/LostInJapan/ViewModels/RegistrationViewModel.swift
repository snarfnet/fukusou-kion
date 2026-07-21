import Foundation
import SwiftData
import SwiftUI

@MainActor
final class RegistrationViewModel: ObservableObject {
    @Published var step = 0
    @Published var categories = Set<LostItemCategory>()
    @Published var details = ItemDescription()
    @Published var location = LostLocation()
    @Published var errorMessage: String?

    var canContinue: Bool { step != 0 || !categories.isEmpty }

    func save(in context: ModelContext) throws -> UUID {
        guard !categories.isEmpty else { throw ValidationError.missingCategory }
        let selected = Array(categories)
        let title = selected.map(\.title).joined(separator: ", ")
        let item = LostItemCase(title: title, categories: selected, itemDescription: details, location: location, urgency: UrgencyResolver.resolve(selected))
        context.insert(item)
        try context.save()
        return item.id
    }

    enum ValidationError: LocalizedError {
        case missingCategory
        var errorDescription: String? { String(localized: "error.category") }
    }
}
