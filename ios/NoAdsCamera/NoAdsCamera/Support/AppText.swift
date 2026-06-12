import Foundation

enum AppText {
    static var isJapanese: Bool {
        Locale.current.language.languageCode?.identifier == "ja"
    }

    static func pick(ja: String, en: String) -> String {
        isJapanese ? ja : en
    }
}
