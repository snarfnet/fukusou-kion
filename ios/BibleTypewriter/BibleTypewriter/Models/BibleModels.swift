import Foundation

enum BibleTranslation: String, CaseIterable, Identifiable {
    case kougo
    case web
    case kjv

    var id: String { rawValue }

    var title: String {
        switch self {
        case .kougo: "口語訳"
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
    static let kougoBooks: [BibleBook] = [
        BibleBook(id: "gen", name: "創世記", englishName: "Genesis", chapters: 50, category: .genesis),
        BibleBook(id: "exod", name: "出エジプト記", englishName: "Exodus", chapters: 40, category: .exodus),
        BibleBook(id: "lev", name: "レビ記", englishName: "Leviticus", chapters: 27, category: .genesis),
        BibleBook(id: "num", name: "民数記", englishName: "Numbers", chapters: 36, category: .genesis),
        BibleBook(id: "deut", name: "申命記", englishName: "Deuteronomy", chapters: 34, category: .genesis),
        BibleBook(id: "josh", name: "ヨシュア記", englishName: "Joshua", chapters: 24, category: .genesis),
        BibleBook(id: "judg", name: "士師記", englishName: "Judges", chapters: 21, category: .genesis),
        BibleBook(id: "ruth", name: "ルツ記", englishName: "Ruth", chapters: 4, category: .genesis),
        BibleBook(id: "1sam", name: "サムエル記上", englishName: "1 Samuel", chapters: 31, category: .prophets),
        BibleBook(id: "2sam", name: "サムエル記下", englishName: "2 Samuel", chapters: 24, category: .prophets),
        BibleBook(id: "1kgs", name: "列王紀上", englishName: "1 Kings", chapters: 22, category: .prophets),
        BibleBook(id: "2kgs", name: "列王紀下", englishName: "2 Kings", chapters: 25, category: .prophets),
        BibleBook(id: "1chr", name: "歴代志上", englishName: "1 Chronicles", chapters: 29, category: .prophets),
        BibleBook(id: "2chr", name: "歴代志下", englishName: "2 Chronicles", chapters: 36, category: .prophets),
        BibleBook(id: "ezra", name: "エズラ記", englishName: "Ezra", chapters: 10, category: .prophets),
        BibleBook(id: "neh", name: "ネヘミヤ書", englishName: "Nehemiah", chapters: 13, category: .prophets),
        BibleBook(id: "esth", name: "エステル記", englishName: "Esther", chapters: 10, category: .prophets),
        BibleBook(id: "job", name: "ヨブ記", englishName: "Job", chapters: 42, category: .psalms),
        BibleBook(id: "ps", name: "詩篇", englishName: "Psalms", chapters: 150, category: .psalms),
        BibleBook(id: "prov", name: "箴言", englishName: "Proverbs", chapters: 31, category: .proverbs),
        BibleBook(id: "eccl", name: "伝道の書", englishName: "Ecclesiastes", chapters: 12, category: .proverbs),
        BibleBook(id: "song", name: "雅歌", englishName: "Song of Solomon", chapters: 8, category: .proverbs),
        BibleBook(id: "isa", name: "イザヤ書", englishName: "Isaiah", chapters: 66, category: .prophets),
        BibleBook(id: "jer", name: "エレミヤ書", englishName: "Jeremiah", chapters: 52, category: .prophets),
        BibleBook(id: "lam", name: "哀歌", englishName: "Lamentations", chapters: 5, category: .prophets),
        BibleBook(id: "ezek", name: "エゼキエル書", englishName: "Ezekiel", chapters: 48, category: .prophets),
        BibleBook(id: "dan", name: "ダニエル書", englishName: "Daniel", chapters: 12, category: .prophets),
        BibleBook(id: "hos", name: "ホセア書", englishName: "Hosea", chapters: 14, category: .prophets),
        BibleBook(id: "joel", name: "ヨエル書", englishName: "Joel", chapters: 3, category: .prophets),
        BibleBook(id: "amos", name: "アモス書", englishName: "Amos", chapters: 9, category: .prophets),
        BibleBook(id: "obad", name: "オバデヤ書", englishName: "Obadiah", chapters: 1, category: .prophets),
        BibleBook(id: "jonah", name: "ヨナ書", englishName: "Jonah", chapters: 4, category: .prophets),
        BibleBook(id: "mic", name: "ミカ書", englishName: "Micah", chapters: 7, category: .prophets),
        BibleBook(id: "nah", name: "ナホム書", englishName: "Nahum", chapters: 3, category: .prophets),
        BibleBook(id: "hab", name: "ハバクク書", englishName: "Habakkuk", chapters: 3, category: .prophets),
        BibleBook(id: "zeph", name: "ゼパニヤ書", englishName: "Zephaniah", chapters: 3, category: .prophets),
        BibleBook(id: "hag", name: "ハガイ書", englishName: "Haggai", chapters: 2, category: .prophets),
        BibleBook(id: "zech", name: "ゼカリヤ書", englishName: "Zechariah", chapters: 14, category: .prophets),
        BibleBook(id: "mal", name: "マラキ書", englishName: "Malachi", chapters: 4, category: .prophets),
        BibleBook(id: "matt", name: "マタイによる福音書", englishName: "Matthew", chapters: 28, category: .gospels),
        BibleBook(id: "mark", name: "マルコによる福音書", englishName: "Mark", chapters: 16, category: .gospels),
        BibleBook(id: "luke", name: "ルカによる福音書", englishName: "Luke", chapters: 24, category: .gospels),
        BibleBook(id: "john", name: "ヨハネによる福音書", englishName: "John", chapters: 21, category: .gospels),
        BibleBook(id: "acts", name: "使徒行伝", englishName: "Acts", chapters: 28, category: .acts),
        BibleBook(id: "rom", name: "ローマ人への手紙", englishName: "Romans", chapters: 16, category: .letters),
        BibleBook(id: "1cor", name: "コリント人への第一の手紙", englishName: "1 Corinthians", chapters: 16, category: .letters),
        BibleBook(id: "2cor", name: "コリント人への第二の手紙", englishName: "2 Corinthians", chapters: 13, category: .letters),
        BibleBook(id: "gal", name: "ガラテヤ人への手紙", englishName: "Galatians", chapters: 6, category: .letters),
        BibleBook(id: "eph", name: "エペソ人への手紙", englishName: "Ephesians", chapters: 6, category: .letters),
        BibleBook(id: "phil", name: "ピリピ人への手紙", englishName: "Philippians", chapters: 4, category: .letters),
        BibleBook(id: "col", name: "コロサイ人への手紙", englishName: "Colossians", chapters: 4, category: .letters),
        BibleBook(id: "1thess", name: "テサロニケ人への第一の手紙", englishName: "1 Thessalonians", chapters: 5, category: .letters),
        BibleBook(id: "2thess", name: "テサロニケ人への第二の手紙", englishName: "2 Thessalonians", chapters: 3, category: .letters),
        BibleBook(id: "1tim", name: "テモテへの第一の手紙", englishName: "1 Timothy", chapters: 6, category: .letters),
        BibleBook(id: "2tim", name: "テモテへの第二の手紙", englishName: "2 Timothy", chapters: 4, category: .letters),
        BibleBook(id: "titus", name: "テトスへの手紙", englishName: "Titus", chapters: 3, category: .letters),
        BibleBook(id: "phlm", name: "ピレモンへの手紙", englishName: "Philemon", chapters: 1, category: .letters),
        BibleBook(id: "heb", name: "ヘブル人への手紙", englishName: "Hebrews", chapters: 13, category: .letters),
        BibleBook(id: "jas", name: "ヤコブの手紙", englishName: "James", chapters: 5, category: .letters),
        BibleBook(id: "1pet", name: "ペテロの第一の手紙", englishName: "1 Peter", chapters: 5, category: .letters),
        BibleBook(id: "2pet", name: "ペテロの第二の手紙", englishName: "2 Peter", chapters: 3, category: .letters),
        BibleBook(id: "1john", name: "ヨハネの第一の手紙", englishName: "1 John", chapters: 5, category: .letters),
        BibleBook(id: "2john", name: "ヨハネの第二の手紙", englishName: "2 John", chapters: 1, category: .letters),
        BibleBook(id: "3john", name: "ヨハネの第三の手紙", englishName: "3 John", chapters: 1, category: .letters),
        BibleBook(id: "jude", name: "ユダの手紙", englishName: "Jude", chapters: 1, category: .letters),
        BibleBook(id: "rev", name: "ヨハネの黙示録", englishName: "Revelation", chapters: 22, category: .revelation)
    ]
}
