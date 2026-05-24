import SwiftUI

@MainActor
final class BibleReaderViewModel: ObservableObject {
    @Published var translation: BibleTranslation = .kougo
    @Published var selectedBook: BibleBook = BibleCatalog.kougoBooks[0]
    @Published var selectedChapter = 1
    @Published var currentChapter: BibleChapter?
    @Published var visibleText = ""
    @Published var isPaused = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    let books = BibleCatalog.kougoBooks

    private let service = BibleService()
    private var typeTask: Task<Void, Never>?
    private var autoNextTask: Task<Void, Never>?
    private var fullText = ""
    private var typedCount = 0

    var backgroundName: String {
        let category = selectedBook.category
        let start = startIndex(for: category)
        let offset = max(0, selectedChapter - 1) % category.count
        return String(format: "chapter_bg_%03d", start + offset)
    }

    func start() {
        Task { await loadChapter() }
    }

    func loadChapter() async {
        typeTask?.cancel()
        autoNextTask?.cancel()
        isLoading = true
        isPaused = false
        visibleText = ""
        errorMessage = nil

        do {
            let loaded = try await service.loadChapter(book: selectedBook, chapter: selectedChapter, translation: translation)
            currentChapter = loaded
            fullText = loaded.text
            typedCount = 0
            isLoading = false
            beginTyping()
        } catch {
            let fallback = BibleChapter(
                book: selectedBook,
                chapter: selectedChapter,
                translation: translation,
                verses: [
                    BibleVerse(verse: 1, text: "初めに言があった。言は神と共にあった。言は神であった。"),
                    BibleVerse(verse: 2, text: "この言は初めに神と共にあった。")
                ]
            )
            currentChapter = fallback
            fullText = fallback.text
            typedCount = 0
            isLoading = false
            errorMessage = "通信できないため、サンプル本文を表示しています。"
            beginTyping()
        }
    }

    func togglePause() {
        isPaused.toggle()
        if isPaused {
            typeTask?.cancel()
        } else {
            beginTyping()
        }
    }

    func nextChapter() {
        if selectedChapter < selectedBook.chapters {
            selectedChapter += 1
        } else if let index = books.firstIndex(of: selectedBook) {
            selectedBook = books[(index + 1) % books.count]
            selectedChapter = 1
        }
        Task { await loadChapter() }
    }

    func previousChapter() {
        if selectedChapter > 1 {
            selectedChapter -= 1
        } else if let index = books.firstIndex(of: selectedBook) {
            let previousIndex = (index - 1 + books.count) % books.count
            selectedBook = books[previousIndex]
            selectedChapter = selectedBook.chapters
        }
        Task { await loadChapter() }
    }

    func randomChapter() {
        guard let book = books.randomElement() else { return }
        selectedBook = book
        selectedChapter = Int.random(in: 1...book.chapters)
        Task { await loadChapter() }
    }

    func didChangeSelection() {
        selectedChapter = min(selectedChapter, selectedBook.chapters)
        Task { await loadChapter() }
    }

    private func beginTyping() {
        typeTask?.cancel()
        typeTask = Task { [weak self] in
            guard let self else { return }

            while !Task.isCancelled, typedCount <= fullText.count {
                let index = fullText.index(fullText.startIndex, offsetBy: typedCount)
                visibleText = String(fullText[..<index])
                typedCount += 1

                let previous = typedCount > 1 ? fullText[fullText.index(fullText.startIndex, offsetBy: typedCount - 2)] : " "
                let delay = "。、，,;:!?！？\n".contains(previous) ? 230_000_000 : UInt64(Int.random(in: 58_000_000...94_000_000))
                try? await Task.sleep(nanoseconds: delay)
            }

            scheduleAutoNext()
        }
    }

    private func scheduleAutoNext() {
        autoNextTask?.cancel()
        autoNextTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 4_200_000_000)
            guard let self, !Task.isCancelled, !isPaused else { return }
            nextChapter()
        }
    }

    private func startIndex(for category: BackgroundCategory) -> Int {
        switch category {
        case .genesis: 1
        case .exodus: 11
        case .psalms: 20
        case .proverbs: 29
        case .prophets: 38
        case .gospels: 47
        case .acts: 56
        case .letters: 64
        case .revelation: 72
        }
    }
}
