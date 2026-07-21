import Foundation
import SwiftData

enum LostItemCategory: String, Codable, CaseIterable, Identifiable {
    case passport, wallet, smartphone, creditCard, cash, suitcase, bag, camera, keys, earphones, transitCard, residenceCard, airlineTicket, medicine, childItem, other
    var id: String { rawValue }
    var japaneseTitle: String {
        switch self {
        case .passport: "パスポート"; case .wallet: "財布"; case .smartphone: "スマートフォン"
        case .creditCard: "クレジットカード"; case .cash: "現金"; case .suitcase: "スーツケース"
        case .bag: "バッグ"; case .camera: "カメラ"; case .keys: "鍵"; case .earphones: "イヤホン"
        case .transitCard: "交通系ICカード"; case .residenceCard: "在留カード"; case .airlineTicket: "航空券"
        case .medicine: "処方薬"; case .childItem: "子どもの持ち物"; case .other: "その他"
        }
    }
    var icon: String {
        switch self {
        case .passport: "book.closed"
        case .wallet: "wallet.bifold"
        case .smartphone: "iphone"
        case .creditCard: "creditcard"
        case .cash: "banknote"
        case .suitcase: "suitcase.rolling"
        case .bag: "backpack"
        case .camera: "camera"
        case .keys: "key"
        case .earphones: "earbuds"
        case .transitCard: "tramcard"
        case .residenceCard: "person.text.rectangle"
        case .airlineTicket: "airplane"
        case .medicine: "pills"
        case .childItem: "figure.and.child.holdinghands"
        case .other: "shippingbox"
        }
    }
    var title: String {
        let key = "item.\(rawValue)"
        let value = L10n.text(key)
        return value == key ? rawValue.readableIdentifier : value
    }
}

enum LocationCategory: String, Codable, CaseIterable, Identifiable {
    case train, station, bulletTrain, subway, bus, taxi, airport, hotel, restaurant, convenienceStore, mall, attraction, park, street, restroom, locker, rentalCar, unknown
    var id: String { rawValue }
    var title: String {
        let key = "location.\(rawValue)"
        let value = L10n.text(key)
        return value == key ? rawValue.readableIdentifier : value
    }
    var icon: String {
        switch self {
        case .train, .bulletTrain, .subway: "train.side.front.car"
        case .station: "signpost.right"
        case .bus: "bus"
        case .taxi: "car"
        case .airport: "airplane"
        case .hotel: "bed.double"
        case .restaurant: "fork.knife"
        case .convenienceStore, .mall: "storefront"
        case .attraction: "camera.metering.center.weighted"
        case .park: "tree"
        case .street: "road.lanes"
        case .restroom: "toilet"
        case .locker: "lock.rectangle"
        case .rentalCar: "key.horizontal"
        case .unknown: "questionmark"
        }
    }
}

enum UrgencyLevel: String, Codable { case a, b, c }
enum CaseStatus: String, Codable, CaseIterable { case draft, searching, found, completed }

struct ItemDescription: Codable, Hashable {
    var color = ""
    var brand = ""
    var model = ""
    var identifierLastFour = ""
    var details = ""
}

struct LostLocation: Codable, Hashable {
    var category: LocationCategory = .unknown
    var name = ""
    var detail = ""
    var lastSeenAt = Date()
    var latitude: Double?
    var longitude: Double?
}

@Model
final class LostItemCase {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var updatedAt: Date
    var title: String
    var categoryRawValues: [String]
    var itemDescriptionData: Data
    var locationData: Data
    var urgencyRawValue: String
    var statusRawValue: String
    var notes: String

    init(id: UUID = UUID(), title: String, categories: [LostItemCategory], itemDescription: ItemDescription, location: LostLocation, urgency: UrgencyLevel, status: CaseStatus = .searching, notes: String = "") {
        self.id = id; self.createdAt = Date(); self.updatedAt = Date(); self.title = title
        self.categoryRawValues = categories.map(\.rawValue)
        self.itemDescriptionData = (try? JSONEncoder().encode(itemDescription)) ?? Data()
        self.locationData = (try? JSONEncoder().encode(location)) ?? Data()
        self.urgencyRawValue = urgency.rawValue; self.statusRawValue = status.rawValue; self.notes = notes
    }

    var categories: [LostItemCategory] { categoryRawValues.compactMap(LostItemCategory.init(rawValue:)) }
    var itemDescription: ItemDescription { (try? JSONDecoder().decode(ItemDescription.self, from: itemDescriptionData)) ?? .init() }
    var location: LostLocation { (try? JSONDecoder().decode(LostLocation.self, from: locationData)) ?? .init() }
    var urgency: UrgencyLevel { UrgencyLevel(rawValue: urgencyRawValue) ?? .c }
    var status: CaseStatus { CaseStatus(rawValue: statusRawValue) ?? .searching }
}

private extension String {
    var readableIdentifier: String {
        unicodeScalars.reduce(into: "") { result, scalar in
            if CharacterSet.uppercaseLetters.contains(scalar), !result.isEmpty { result.append(" ") }
            result.append(Character(scalar))
        }.replacingOccurrences(of: "bullet Train", with: "Shinkansen")
            .replacingOccurrences(of: "credit Card", with: "Credit card")
            .replacingOccurrences(of: "transit Card", with: "Transit card")
            .replacingOccurrences(of: "residence Card", with: "Residence card")
            .replacingOccurrences(of: "airline Ticket", with: "Airline ticket")
            .capitalized
    }
}
