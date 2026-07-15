import XCTest
@testable import FutariCrossword

final class CrosswordGeneratorTests: XCTestCase {
    func testEverySupportedSizeStaysInBounds() {
        for size in 1...20 {
            let puzzle = CrosswordGenerator().generate(size: size, seed: size)
            XCTAssertEqual(puzzle.size, size)
            XCTAssertEqual(puzzle.solution.count, size)
            XCTAssertTrue(puzzle.entries.allSatisfy { $0.points.allSatisfy { $0.row >= 0 && $0.column >= 0 && $0.row < size && $0.column < size } })
        }
    }

    func testEntryLettersMatchSolution() {
        let puzzle = CrosswordGenerator().generate(size: 20, seed: 42)
        for entry in puzzle.entries {
            for (index, point) in entry.points.enumerated() {
                XCTAssertEqual(puzzle.solution[point.row][point.column], Array(entry.word.answer)[index])
            }
        }
    }
}

