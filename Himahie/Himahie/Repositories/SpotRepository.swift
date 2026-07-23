import Foundation

protocol SpotRepositoryProtocol {
    func loadCatalog() throws -> [PrefectureCatalog]
    func load(prefecture: PrefectureCatalog) throws -> [Spot]
}

struct SpotRepository: SpotRepositoryProtocol {
    func loadCatalog() throws -> [PrefectureCatalog] {
        try decode(resource: "prefectures")
    }

    func load(prefecture: PrefectureCatalog) throws -> [Spot] {
        try decode(resource: prefecture.fileName)
    }

    private func decode<T: Decodable>(resource: String) throws -> T {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try JSONDecoder().decode(T.self, from: Data(contentsOf: url))
    }
}
