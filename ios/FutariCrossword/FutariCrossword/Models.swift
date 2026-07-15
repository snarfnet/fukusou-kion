import Foundation

struct WordItem: Identifiable, Hashable, Codable {
    let id: String
    let answer: String
    let clues: [String]
    let category: String
    let difficulty: Int

    init(_ answer: String, _ clue: String, category: String = "日常", difficulty: Int = 1) {
        self.id = "\(answer)-\(clue)"
        self.answer = answer
        self.clues = [clue]
        self.category = category
        self.difficulty = difficulty
    }
}

enum Direction: String, Codable { case across, down }

struct GridPoint: Hashable, Codable {
    let row: Int
    let column: Int
}

struct CrosswordEntry: Identifiable, Hashable, Codable {
    let id: UUID
    let number: Int
    let word: WordItem
    let start: GridPoint
    let direction: Direction

    init(number: Int = 0, word: WordItem, start: GridPoint, direction: Direction) {
        self.id = UUID()
        self.number = number
        self.word = word
        self.start = start
        self.direction = direction
    }

    var points: [GridPoint] {
        word.answer.indices.enumerated().map { offset, _ in
            GridPoint(row: start.row + (direction == .down ? offset : 0),
                      column: start.column + (direction == .across ? offset : 0))
        }
    }
}

struct CrosswordPuzzle {
    let size: Int
    let solution: [[Character?]]
    let entries: [CrosswordEntry]
    let numbers: [GridPoint: Int]
}

enum CompanionExpression: String, CaseIterable {
    case gentle, thinking, delighted, surprised, worried, cheering, proud, shy

    var label: String {
        switch self {
        case .gentle: "にっこり"
        case .thinking: "考え中"
        case .delighted: "うれしい"
        case .surprised: "びっくり"
        case .worried: "心配"
        case .cheering: "応援"
        case .proud: "得意げ"
        case .shy: "照れ"
        }
    }
}

enum DialogueEvent { case launch, generated, selected, correct, incorrect, hint, streak, completed, idle }

struct CompanionLine: Identifiable {
    let id = UUID()
    let event: DialogueEvent
    let expression: CompanionExpression
    let text: String
}

