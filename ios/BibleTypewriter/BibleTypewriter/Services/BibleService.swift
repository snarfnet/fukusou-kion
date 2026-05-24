import Foundation

enum BibleServiceError: LocalizedError {
    case invalidURL
    case emptyChapter

    var errorDescription: String? {
        switch self {
        case .invalidURL: "読み込み先を作れませんでした。"
        case .emptyChapter: "本文を取得できませんでした。"
        }
    }
}

struct BibleService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func loadChapter(book: BibleBook, chapter: Int, translation: BibleTranslation) async throws -> BibleChapter {
        try await loadEnglishChapter(book: book, chapter: chapter, translation: translation)
    }

    private func loadEnglishChapter(book: BibleBook, chapter: Int, translation: BibleTranslation) async throws -> BibleChapter {
        var components = URLComponents(string: "https://thebibleapi.netlify.app/.netlify/functions/getChapter")
        components?.queryItems = [
            URLQueryItem(name: "book", value: book.englishName),
            URLQueryItem(name: "chapter", value: String(chapter)),
            URLQueryItem(name: "translation", value: translation.rawValue)
        ]

        guard let url = components?.url else {
            throw BibleServiceError.invalidURL
        }

        let (data, _) = try await session.data(from: url)
        let decoded = try JSONDecoder().decode(RemoteChapter.self, from: data)
        let verses = decoded.verses.enumerated().map { index, text in
            BibleVerse(verse: index + 1, text: text)
        }

        guard !verses.isEmpty else {
            throw BibleServiceError.emptyChapter
        }

        return BibleChapter(book: book, chapter: decoded.chapter ?? chapter, translation: translation, verses: verses)
    }
}

private struct RemoteChapter: Decodable {
    let book: String?
    let chapter: Int?
    let translation: String?
    let verses: [String]
}
