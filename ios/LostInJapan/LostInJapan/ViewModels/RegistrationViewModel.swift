import Foundation
import PhotosUI
import SwiftData

@MainActor
final class RegistrationViewModel: ObservableObject {
    @Published var step = 0
    @Published var categories = Set<LostItemCategory>()
    @Published var photoItems = [PhotosPickerItem]()
    @Published var photos = [Data]()
    @Published var details = ItemDescription()
    @Published var location = LostLocation()
    @Published var errorMessage: String?

    var canContinue: Bool { step != 0 || !categories.isEmpty }

    func loadPhotos() async {
        do {
            var loaded = [Data]()
            for item in photoItems.prefix(3) {
                if let data = try await item.loadTransferable(type: Data.self) { loaded.append(data) }
            }
            photos = loaded
        } catch { errorMessage = String(localized: "error.photo") }
    }

    func save(in context: ModelContext) throws -> UUID {
        guard !categories.isEmpty else { throw ValidationError.missingCategory }
        let selected = Array(categories)
        let title = selected.map(\.title).joined(separator: ", ")
        let item = LostItemCase(title: title, categories: selected, itemDescription: details, location: location, photoData: photos, urgency: UrgencyResolver.resolve(selected))
        context.insert(item)
        try context.save()
        return item.id
    }

    enum ValidationError: LocalizedError {
        case missingCategory
        var errorDescription: String? { String(localized: "error.category") }
    }
}

