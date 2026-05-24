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
        switch translation {
        case .kougo:
            return try await loadKougoChapter(book: book, chapter: chapter)
        case .web, .kjv:
            return try await loadEnglishChapter(book: book, chapter: chapter, translation: translation)
        }
    }

    private func loadKougoChapter(book: BibleBook, chapter: Int) async throws -> BibleChapter {
        guard let url = URL(string: "https://jpn.bible/kougo/\(book.id)") else {
            throw BibleServiceError.invalidURL
        }

        let (data, _) = try await session.data(from: url)
        guard let html = String(data: data, encoding: .utf8) else {
            throw BibleServiceError.emptyChapter
        }

        let verses = extractKougoVerses(from: html, chapter: chapter)
        guard !verses.isEmpty else {
            throw BibleServiceError.emptyChapter
        }

        return BibleChapter(book: book, chapter: chapter, translation: .kougo, verses: verses)
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

    private func extractKougoVerses(from html: String, chapter: Int) -> [BibleVerse] {
        let pattern = #"<span class="verse" id="\#(chapter):(\d+)">([\s\S]*?)</span>\s*</span>"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsRange = NSRange(html.startIndex..<html.endIndex, in: html)

        return regex.matches(in: html, range: nsRange).compactMap { match in
            guard
                let verseRange = Range(match.range(at: 1), in: html),
                let bodyRange = Range(match.range(at: 2), in: html),
                let verse = Int(html[verseRange])
            else {
                return nil
            }

            let raw = String(html[bodyRange])
            let content = raw
                .replacingOccurrences(of: #"<rt[\s\S]*?</rt>"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: #"<rp[\s\S]*?</rp>"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: "&nbsp;", with: " ")
                .replacingOccurrences(of: "&quot;", with: "\"")
                .replacingOccurrences(of: "&#39;", with: "'")
                .replacingOccurrences(of: "&lt;", with: "<")
                .replacingOccurrences(of: "&gt;", with: ">")
                .replacingOccurrences(of: "&amp;", with: "&")
                .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            return content.isEmpty ? nil : BibleVerse(verse: verse, text: content)
        }
    }
}

private struct RemoteChapter: Decodable {
    let book: String?
    let chapter: Int?
    let translation: String?
    let verses: [String]
}
