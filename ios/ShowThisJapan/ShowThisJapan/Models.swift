import Foundation

enum AppLanguage: String, CaseIterable, Codable, Identifiable {
    case en, zhHans = "zh-Hans", ko, es
    var id: String { rawValue }
    var name: String { switch self { case .en: "English"; case .zhHans: "简体中文"; case .ko: "한국어"; case .es: "Español" } }
}

enum ResponseType: String, Codable { case yesNo, availability, payment, waitingTime, direction, custom, none }

struct PhraseCard: Identifiable, Codable, Hashable {
    let id: String
    let categoryID: String
    let iconName: String
    let japaneseText: String
    let translations: [String: String]
    let searchKeywords: [String]
    let responseType: ResponseType
    let isEmergency: Bool
    func text(in language: AppLanguage) -> String { translations[language.rawValue] ?? translations["en"] ?? japaneseText }
}

struct PhraseCategory: Identifiable, Codable, Hashable {
    let id: String
    let iconName: String
    let titles: [String: String]
    let sortOrder: Int
    func title(in language: AppLanguage) -> String { titles[language.rawValue] ?? titles["en"] ?? id }
}

struct EmergencyProfile: Codable, Equatable {
    var fullName = ""; var nationality = ""; var age = ""; var gender = ""
    var hotelName = ""; var hotelAddress = ""; var emergencyContactName = ""; var emergencyContactPhone = ""
    var bloodType = ""; var allergies = ""; var medicalConditions = ""; var medications = ""
    var dietaryRestrictions = ""; var accessibilityNeeds = ""; var insuranceCompany = ""; var insurancePolicyNumber = ""
}

enum AppError: LocalizedError { case dataLoad
    var errorDescription: String? { "Phrase data could not be loaded. Please restart the app." }
}

