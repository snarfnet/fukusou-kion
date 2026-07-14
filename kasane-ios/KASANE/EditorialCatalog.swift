import Foundation

private struct EditorialPlace: Decodable {
    struct Names: Decodable { let ja: String; let en: String; let former: [String] }
    struct Location: Decodable { let latitude: Double; let longitude: Double; let prefecture: String; let municipality: String? }
    struct Story: Decodable {
        let headline: String
        let summary: String
        let body: String
        let placeNameOrigin: String
        let claims: [Claim]
    }
    struct Claim: Decodable { let id: String; let text: String; let sourceIds: [String] }
    struct Timeline: Decodable { let label: String; let year: Int?; let text: String; let sourceIds: [String] }
    struct Nearby: Decodable { let name: String; let distanceMeters: Int; let sourceIds: [String] }
    struct Source: Decodable { let id: String; let title: String; let publisher: String; let url: String }

    let id: String
    let status: String
    let names: Names
    let location: Location
    let story: Story
    let timeline: [Timeline]
    let nearby: [Nearby]
    let sources: [Source]
}

enum EditorialCatalog {
    static let detailedStories: [PlaceStory] = {
        guard let url = Bundle.main.url(forResource: "places", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let records = try? JSONDecoder().decode([EditorialPlace].self, from: data) else { return [] }

        return records.filter { !$0.story.body.isEmpty }.map { record in
            let eras = record.timeline.map { item in
                Era(year: item.year.map(String.init) ?? item.label, story: item.text)
            }
            let nearby = record.nearby.map { item in
                NearbyStory(kanji: "歩", category: "NEARBY TRACE", title: item.name, place: record.location.prefecture, distance: item.distanceMeters)
            }
            let sources = record.sources.map {
                StorySource(id: $0.id, title: $0.title, publisher: $0.publisher, url: URL(string: $0.url))
            }
            return PlaceStory(
                id: record.id,
                kanji: record.names.ja,
                name: record.names.en,
                area: [record.location.municipality, record.location.prefecture].compactMap { $0 }.joined(separator: ", "),
                latitude: record.location.latitude,
                longitude: record.location.longitude,
                headline: record.story.headline,
                introduction: record.story.summary,
                foundedLabel: eras.last?.year ?? "—",
                oldName: record.names.former.first ?? record.names.ja,
                eras: eras,
                nearby: nearby,
                body: record.story.body,
                placeNameOrigin: record.story.placeNameOrigin,
                claims: record.story.claims.map { StoryClaim(id: $0.id, text: $0.text, sourceIds: $0.sourceIds) },
                sources: sources,
                editorialStatus: record.status
            )
        }
    }()
}
