import Foundation

struct CrosswordGenerator {
    private struct Placement { let word: WordItem; let start: GridPoint; let direction: Direction; let score: Int }

    func generate(size: Int, seed: Int = Int.random(in: 0...Int.max)) -> CrosswordPuzzle {
        let size = min(20, max(1, size))
        if size == 1 {
            let word = WordBank.words.filter { $0.answer.count == 1 }.randomElement() ?? WordItem("あ", "ひらがなの最初の文字")
            let entry = CrosswordEntry(number: 1, word: word, start: .init(row: 0, column: 0), direction: .across)
            return CrosswordPuzzle(size: 1, solution: [[word.answer.first]], entries: [entry], numbers: [.init(row: 0, column: 0): 1])
        }

        var rng = SeededGenerator(seed: UInt64(seed))
        let candidates = WordBank.words.filter { $0.answer.count >= 2 && $0.answer.count <= size }.shuffled(using: &rng)
        var grid = Array(repeating: Array<Character?>(repeating: nil, count: size), count: size)
        var entries: [CrosswordEntry] = []

        if let first = candidates.max(by: { $0.answer.count < $1.answer.count }) {
            let start = GridPoint(row: size / 2, column: max(0, (size - first.answer.count) / 2))
            place(first, at: start, direction: .across, in: &grid)
            entries.append(.init(word: first, start: start, direction: .across))
        }

        for word in candidates where entries.count < max(3, size * 2) {
            let placements = possiblePlacements(for: word, grid: grid, size: size)
            guard let best = placements.max(by: { $0.score < $1.score }) else { continue }
            place(best.word, at: best.start, direction: best.direction, in: &grid)
            entries.append(.init(word: best.word, start: best.start, direction: best.direction))
        }

        if entries.count < 2 { return stripedFallback(size: size, words: candidates) }
        return finalize(size: size, grid: grid, entries: entries)
    }

    private func possiblePlacements(for word: WordItem, grid: [[Character?]], size: Int) -> [Placement] {
        let letters = Array(word.answer)
        var result: [Placement] = []
        for row in 0..<size { for column in 0..<size {
            guard let existing = grid[row][column] else { continue }
            for (index, letter) in letters.enumerated() where letter == existing {
                for direction in [Direction.across, .down] {
                    let start = GridPoint(row: row - (direction == .down ? index : 0), column: column - (direction == .across ? index : 0))
                    if let score = validate(letters, start: start, direction: direction, grid: grid, size: size) {
                        result.append(.init(word: word, start: start, direction: direction, score: score))
                    }
                }
            }
        }}
        return result
    }

    private func validate(_ letters: [Character], start: GridPoint, direction: Direction, grid: [[Character?]], size: Int) -> Int? {
        let endRow = start.row + (direction == .down ? letters.count - 1 : 0)
        let endColumn = start.column + (direction == .across ? letters.count - 1 : 0)
        guard start.row >= 0, start.column >= 0, endRow < size, endColumn < size else { return nil }
        var intersections = 0
        for (offset, letter) in letters.enumerated() {
            let row = start.row + (direction == .down ? offset : 0)
            let column = start.column + (direction == .across ? offset : 0)
            if let current = grid[row][column] {
                guard current == letter else { return nil }
                intersections += 1
            } else {
                let neighbors = direction == .across ? [(row - 1, column), (row + 1, column)] : [(row, column - 1), (row, column + 1)]
                if neighbors.contains(where: { point in
                    point.0 >= 0 && point.1 >= 0 && point.0 < size && point.1 < size && grid[point.0][point.1] != nil
                }) { return nil }
            }
        }
        guard intersections > 0 else { return nil }
        let before = direction == .across ? (start.row, start.column - 1) : (start.row - 1, start.column)
        let after = direction == .across ? (endRow, endColumn + 1) : (endRow + 1, endColumn)
        for point in [before, after] where point.0 >= 0 && point.1 >= 0 && point.0 < size && point.1 < size {
            if grid[point.0][point.1] != nil { return nil }
        }
        return intersections * 10 + letters.count
    }

    private func place(_ word: WordItem, at start: GridPoint, direction: Direction, in grid: inout [[Character?]]) {
        for (offset, letter) in word.answer.enumerated() {
            grid[start.row + (direction == .down ? offset : 0)][start.column + (direction == .across ? offset : 0)] = letter
        }
    }

    private func finalize(size: Int, grid: [[Character?]], entries: [CrosswordEntry]) -> CrosswordPuzzle {
        let starts = Set(entries.map(\.start))
        let sorted = starts.sorted { $0.row == $1.row ? $0.column < $1.column : $0.row < $1.row }
        let numbers = Dictionary(uniqueKeysWithValues: sorted.enumerated().map { ($0.element, $0.offset + 1) })
        let numbered = entries.map { CrosswordEntry(number: numbers[$0.start] ?? 0, word: $0.word, start: $0.start, direction: $0.direction) }
        return .init(size: size, solution: grid, entries: numbered, numbers: numbers)
    }

    private func stripedFallback(size: Int, words: [WordItem]) -> CrosswordPuzzle {
        var grid = Array(repeating: Array<Character?>(repeating: nil, count: size), count: size)
        var entries: [CrosswordEntry] = []
        var row = 0
        for word in words where row < size {
            guard word.answer.count <= size else { continue }
            place(word, at: .init(row: row, column: 0), direction: .across, in: &grid)
            entries.append(.init(word: word, start: .init(row: row, column: 0), direction: .across))
            row += 2
        }
        return finalize(size: size, grid: grid, entries: entries)
    }
}

private struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x123456789abcdef : seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
