import Foundation

struct WisdomItem: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let content: String
    let category: String
}
