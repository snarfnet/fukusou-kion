import Foundation

struct SermonNote: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var churchName: String
    var pastorName: String
    var scripture: String
    var date: Date
    var body: String
    var tags: [String]
    var prayerRequests: [PrayerRequest]
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String = "",
        churchName: String = "",
        pastorName: String = "",
        scripture: String = "",
        date: Date = Date(),
        body: String = "",
        tags: [String] = [],
        prayerRequests: [PrayerRequest] = [],
        isFavorite: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.churchName = churchName
        self.pastorName = pastorName
        self.scripture = scripture
        self.date = date
        self.body = body
        self.tags = tags
        self.prayerRequests = prayerRequests
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled sermon" : trimmed
    }

    var searchableText: String {
        ([title, churchName, pastorName, scripture, body] + tags + prayerRequests.map(\.text))
            .joined(separator: " ")
            .lowercased()
    }
}

struct PrayerRequest: Identifiable, Codable, Equatable {
    var id: UUID
    var text: String
    var isAnswered: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        text: String = "",
        isAnswered: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.isAnswered = isAnswered
        self.createdAt = createdAt
    }
}
