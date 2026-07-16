import SwiftUI

@MainActor
final class GameViewModel: ObservableObject {
    @Published var selectedSize = 5
    @Published private(set) var puzzle: CrosswordPuzzle?
    @Published var answers: [GridPoint: Character] = [:]
    @Published var selectedEntryID: UUID?
    @Published var selectedPoint: GridPoint?
    @Published var companion = CompanionLine(event: .launch, expression: .gentle, text: "席、取っておいたよ。今日は何マスにする？")
    @Published var streak = 0
    @Published var isShowingSetup = true
    @Published var feedback: String?
    @Published var completionCelebrationID: UUID?
    private var recentLines: [String] = []

    var selectedEntry: CrosswordEntry? { puzzle?.entries.first { $0.id == selectedEntryID } }
    var isComplete: Bool {
        guard let puzzle else { return false }
        return puzzle.solution.enumerated().allSatisfy { row, cells in cells.enumerated().allSatisfy { column, value in value == nil || answers[.init(row: row, column: column)] == value } }
    }

    func generate() {
        puzzle = CrosswordGenerator().generate(size: selectedSize)
        answers = [:]; streak = 0; feedback = nil; completionCelebrationID = nil; isShowingSetup = false
        selectedEntryID = puzzle?.entries.first?.id
        selectedPoint = puzzle?.entries.first?.start
        speak(.generated)
    }

    func select(_ point: GridPoint) {
        guard let puzzle, puzzle.solution[point.row][point.column] != nil else { return }
        selectedPoint = point
        let matches = puzzle.entries.filter { $0.points.contains(point) }
        if let current = selectedEntry, matches.count > 1, current.points.contains(point) {
            selectedEntryID = matches.first { $0.id != current.id }?.id ?? matches.first?.id
        } else { selectedEntryID = matches.first?.id }
        speak(.selected)
    }

    func type(_ character: Character) {
        guard let point = selectedPoint, let puzzle else { return }
        answers[point] = character
        if let entry = selectedEntry {
            let complete = entry.points.allSatisfy { answers[$0] != nil }
            if complete {
                let correct = entry.points.enumerated().allSatisfy { answers[$0.element] == Array(entry.word.answer)[$0.offset] }
                if correct { streak += 1; speak(streak >= 3 ? .streak : .correct) }
                else { streak = 0; speak(.incorrect) }
            }
            moveNext(in: entry, puzzle: puzzle)
        }
        if isComplete, completionCelebrationID == nil {
            completionCelebrationID = UUID()
            speak(.completed)
        }
    }

    func finishCelebration() {
        completionCelebrationID = nil
    }

    func deleteCurrent() {
        guard let point = selectedPoint, let entry = selectedEntry else { return }
        if answers[point] != nil {
            answers.removeValue(forKey: point)
            return
        }
        guard let index = entry.points.firstIndex(of: point), index > 0 else { return }
        let previous = entry.points[index - 1]
        answers.removeValue(forKey: previous)
        selectedPoint = previous
    }

    func hint() {
        guard let entry = selectedEntry, let puzzle else { return }
        if let point = entry.points.first(where: { answers[$0] != puzzle.solution[$0.row][$0.column] }), let letter = puzzle.solution[point.row][point.column] {
            answers[point] = letter; selectedPoint = point; speak(.hint)
        }
    }

    func check() {
        guard let puzzle else { return }
        let wrong = answers.filter { puzzle.solution[$0.key.row][$0.key.column] != $0.value }.count
        feedback = wrong == 0 ? "ここまで全部合ってるよ" : "違うマスが\(wrong)個あるみたい"
        speak(wrong == 0 ? .correct : .incorrect)
    }

    private func moveNext(in entry: CrosswordEntry, puzzle: CrosswordPuzzle) {
        guard let point = selectedPoint, let index = entry.points.firstIndex(of: point) else { return }
        if index + 1 < entry.points.count { selectedPoint = entry.points[index + 1] }
    }

    private func speak(_ event: DialogueEvent) {
        let next = DialogueBank.line(for: event, size: selectedSize, streak: streak, excluding: Set(recentLines))
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { companion = next }
        recentLines.append(next.text)
        if recentLines.count > 8 { recentLines.removeFirst() }
    }
}
