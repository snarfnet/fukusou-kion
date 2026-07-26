import Foundation

enum GarmentGender: String, Codable, CaseIterable, Identifiable {
    case women = "女性"
    case men = "男性"
    var id: Self { self }
}

struct Garment: Identifiable, Codable, Hashable {
    let id: String
    let gender: GarmentGender
    let community: String
    let garmentName: String
    let region: String
    let summary: String
    let history: String
    let occasions: String
    let materials: String
    let sourceTitle: String
    let sourceURL: URL?

    var imageName: String { id }
}

enum GarmentCatalog {
    static let all: [Garment] = Bundle.main.decode("garments", extension: "json")
}

private extension Bundle {
    func decode<T: Decodable>(_ name: String, extension fileExtension: String) -> T {
        guard let url = url(forResource: name, withExtension: fileExtension),
              let data = try? Data(contentsOf: url),
              let value = try? JSONDecoder().decode(T.self, from: data) else {
            fatalError("Unable to load \(name).\(fileExtension)")
        }
        return value
    }
}
