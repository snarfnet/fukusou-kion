import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    case korean = "ko"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case thai = "th"
    case japanese = "ja"

    var id: String { rawValue }

    var locale: Locale {
        self == .system ? .autoupdatingCurrent : Locale(identifier: rawValue)
    }

    var titleKey: String {
        switch self {
        case .system: "language.system"
        case .english: "language.english"
        case .simplifiedChinese: "language.chineseSimplified"
        case .traditionalChinese: "language.chineseTraditional"
        case .korean: "language.korean"
        case .spanish: "language.spanish"
        case .french: "language.french"
        case .german: "language.german"
        case .thai: "language.thai"
        case .japanese: "language.japanese"
        }
    }

    var nativeTitle: String {
        switch self {
        case .system: "System language"
        case .english: "English"
        case .simplifiedChinese: "简体中文"
        case .traditionalChinese: "繁體中文"
        case .korean: "한국어"
        case .spanish: "Español"
        case .french: "Français"
        case .german: "Deutsch"
        case .thai: "ไทย"
        case .japanese: "日本語"
        }
    }

    static let selectableLanguages = allCases.filter { $0 != .system }

    static var selected: AppLanguage {
        AppLanguage(rawValue: UserDefaults.standard.string(forKey: "appLanguage") ?? "system") ?? .system
    }
}

enum L10n {
    static func text(_ key: String, locale: Locale = AppLanguage.selected.locale) -> String {
        String(localized: String.LocalizationValue(key), locale: locale)
    }
}

