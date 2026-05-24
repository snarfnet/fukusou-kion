import Foundation

enum BibleTranslation: String, CaseIterable, Identifiable {
    case web
    case kjv

    var id: String { rawValue }

    var title: String {
        switch self {
        case .web: "WEB"
        case .kjv: "KJV"
        }
    }
}

struct BibleBook: Identifiable, Hashable {
    let id: String
    let name: String
    let englishName: String
    let chapters: Int
    let category: BackgroundCategory
}

struct BibleVerse: Identifiable, Hashable {
    let verse: Int
    let text: String

    var id: Int { verse }
}

struct BibleChapter: Hashable {
    let book: BibleBook
    let chapter: Int
    let translation: BibleTranslation
    let verses: [BibleVerse]

    var reference: String {
        "\(book.name) \(chapter) / \(translation.title)"
    }

    var text: String {
        verses
            .map { "[\($0.verse)] \($0.text)" }
            .joined(separator: "\n\n")
    }
}

enum BackgroundCategory: String, CaseIterable {
    case genesis
    case exodus
    case psalms
    case proverbs
    case prophets
    case gospels
    case acts
    case letters
    case revelation

    var count: Int {
        switch self {
        case .genesis: 10
        case .exodus: 9
        case .psalms: 9
        case .proverbs: 9
        case .prophets: 9
        case .gospels: 9
        case .acts: 8
        case .letters: 8
        case .revelation: 9
        }
    }
}

enum BibleCatalog {
    static let books: [BibleBook] = [
        BibleBook(id: "genesis", name: "Genesis", englishName: "Genesis", chapters: 50, category: .genesis),
        BibleBook(id: "exodus", name: "Exodus", englishName: "Exodus", chapters: 40, category: .exodus),
        BibleBook(id: "leviticus", name: "Leviticus", englishName: "Leviticus", chapters: 27, category: .genesis),
        BibleBook(id: "numbers", name: "Numbers", englishName: "Numbers", chapters: 36, category: .genesis),
        BibleBook(id: "deuteronomy", name: "Deuteronomy", englishName: "Deuteronomy", chapters: 34, category: .genesis),
        BibleBook(id: "joshua", name: "Joshua", englishName: "Joshua", chapters: 24, category: .genesis),
        BibleBook(id: "judges", name: "Judges", englishName: "Judges", chapters: 21, category: .genesis),
        BibleBook(id: "ruth", name: "Ruth", englishName: "Ruth", chapters: 4, category: .genesis),
        BibleBook(id: "1-samuel", name: "1 Samuel", englishName: "1 Samuel", chapters: 31, category: .prophets),
        BibleBook(id: "2-samuel", name: "2 Samuel", englishName: "2 Samuel", chapters: 24, category: .prophets),
        BibleBook(id: "1-kings", name: "1 Kings", englishName: "1 Kings", chapters: 22, category: .prophets),
        BibleBook(id: "2-kings", name: "2 Kings", englishName: "2 Kings", chapters: 25, category: .prophets),
        BibleBook(id: "1-chronicles", name: "1 Chronicles", englishName: "1 Chronicles", chapters: 29, category: .prophets),
        BibleBook(id: "2-chronicles", name: "2 Chronicles", englishName: "2 Chronicles", chapters: 36, category: .prophets),
        BibleBook(id: "ezra", name: "Ezra", englishName: "Ezra", chapters: 10, category: .prophets),
        BibleBook(id: "nehemiah", name: "Nehemiah", englishName: "Nehemiah", chapters: 13, category: .prophets),
        BibleBook(id: "esther", name: "Esther", englishName: "Esther", chapters: 10, category: .prophets),
        BibleBook(id: "job", name: "Job", englishName: "Job", chapters: 42, category: .psalms),
        BibleBook(id: "psalms", name: "Psalms", englishName: "Psalms", chapters: 150, category: .psalms),
        BibleBook(id: "proverbs", name: "Proverbs", englishName: "Proverbs", chapters: 31, category: .proverbs),
        BibleBook(id: "ecclesiastes", name: "Ecclesiastes", englishName: "Ecclesiastes", chapters: 12, category: .proverbs),
        BibleBook(id: "song-of-solomon", name: "Song of Solomon", englishName: "Song of Solomon", chapters: 8, category: .proverbs),
        BibleBook(id: "isaiah", name: "Isaiah", englishName: "Isaiah", chapters: 66, category: .prophets),
        BibleBook(id: "jeremiah", name: "Jeremiah", englishName: "Jeremiah", chapters: 52, category: .prophets),
        BibleBook(id: "lamentations", name: "Lamentations", englishName: "Lamentations", chapters: 5, category: .prophets),
        BibleBook(id: "ezekiel", name: "Ezekiel", englishName: "Ezekiel", chapters: 48, category: .prophets),
        BibleBook(id: "daniel", name: "Daniel", englishName: "Daniel", chapters: 12, category: .prophets),
        BibleBook(id: "hosea", name: "Hosea", englishName: "Hosea", chapters: 14, category: .prophets),
        BibleBook(id: "joel", name: "Joel", englishName: "Joel", chapters: 3, category: .prophets),
        BibleBook(id: "amos", name: "Amos", englishName: "Amos", chapters: 9, category: .prophets),
        BibleBook(id: "obadiah", name: "Obadiah", englishName: "Obadiah", chapters: 1, category: .prophets),
        BibleBook(id: "jonah", name: "Jonah", englishName: "Jonah", chapters: 4, category: .prophets),
        BibleBook(id: "micah", name: "Micah", englishName: "Micah", chapters: 7, category: .prophets),
        BibleBook(id: "nahum", name: "Nahum", englishName: "Nahum", chapters: 3, category: .prophets),
        BibleBook(id: "habakkuk", name: "Habakkuk", englishName: "Habakkuk", chapters: 3, category: .prophets),
        BibleBook(id: "zephaniah", name: "Zephaniah", englishName: "Zephaniah", chapters: 3, category: .prophets),
        BibleBook(id: "haggai", name: "Haggai", englishName: "Haggai", chapters: 2, category: .prophets),
        BibleBook(id: "zechariah", name: "Zechariah", englishName: "Zechariah", chapters: 14, category: .prophets),
        BibleBook(id: "malachi", name: "Malachi", englishName: "Malachi", chapters: 4, category: .prophets),
        BibleBook(id: "matthew", name: "Matthew", englishName: "Matthew", chapters: 28, category: .gospels),
        BibleBook(id: "mark", name: "Mark", englishName: "Mark", chapters: 16, category: .gospels),
        BibleBook(id: "luke", name: "Luke", englishName: "Luke", chapters: 24, category: .gospels),
        BibleBook(id: "john", name: "John", englishName: "John", chapters: 21, category: .gospels),
        BibleBook(id: "acts", name: "Acts", englishName: "Acts", chapters: 28, category: .acts),
        BibleBook(id: "romans", name: "Romans", englishName: "Romans", chapters: 16, category: .letters),
        BibleBook(id: "1-corinthians", name: "1 Corinthians", englishName: "1 Corinthians", chapters: 16, category: .letters),
        BibleBook(id: "2-corinthians", name: "2 Corinthians", englishName: "2 Corinthians", chapters: 13, category: .letters),
        BibleBook(id: "galatians", name: "Galatians", englishName: "Galatians", chapters: 6, category: .letters),
        BibleBook(id: "ephesians", name: "Ephesians", englishName: "Ephesians", chapters: 6, category: .letters),
        BibleBook(id: "philippians", name: "Philippians", englishName: "Philippians", chapters: 4, category: .letters),
        BibleBook(id: "colossians", name: "Colossians", englishName: "Colossians", chapters: 4, category: .letters),
        BibleBook(id: "1-thessalonians", name: "1 Thessalonians", englishName: "1 Thessalonians", chapters: 5, category: .letters),
        BibleBook(id: "2-thessalonians", name: "2 Thessalonians", englishName: "2 Thessalonians", chapters: 3, category: .letters),
        BibleBook(id: "1-timothy", name: "1 Timothy", englishName: "1 Timothy", chapters: 6, category: .letters),
        BibleBook(id: "2-timothy", name: "2 Timothy", englishName: "2 Timothy", chapters: 4, category: .letters),
        BibleBook(id: "titus", name: "Titus", englishName: "Titus", chapters: 3, category: .letters),
        BibleBook(id: "philemon", name: "Philemon", englishName: "Philemon", chapters: 1, category: .letters),
        BibleBook(id: "hebrews", name: "Hebrews", englishName: "Hebrews", chapters: 13, category: .letters),
        BibleBook(id: "james", name: "James", englishName: "James", chapters: 5, category: .letters),
        BibleBook(id: "1-peter", name: "1 Peter", englishName: "1 Peter", chapters: 5, category: .letters),
        BibleBook(id: "2-peter", name: "2 Peter", englishName: "2 Peter", chapters: 3, category: .letters),
        BibleBook(id: "1-john", name: "1 John", englishName: "1 John", chapters: 5, category: .letters),
        BibleBook(id: "2-john", name: "2 John", englishName: "2 John", chapters: 1, category: .letters),
        BibleBook(id: "3-john", name: "3 John", englishName: "3 John", chapters: 1, category: .letters),
        BibleBook(id: "jude", name: "Jude", englishName: "Jude", chapters: 1, category: .letters),
        BibleBook(id: "revelation", name: "Revelation", englishName: "Revelation", chapters: 22, category: .revelation)
    ]
}
