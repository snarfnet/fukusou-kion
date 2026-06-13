import Foundation

struct PianoNote: Identifiable, Hashable {
    let id = UUID()
    let pitch: Int
    let velocity: Int
    let start: Double
    let duration: Double
}

struct PianoPhrase: Identifiable {
    let id = UUID()
    let name: String
    let bpm: Int
    let keyName: String
    let duration: Double
    let notes: [PianoNote]

    var noteCount: Int {
        notes.count
    }
}

enum PhraseMood: String, CaseIterable, Identifiable {
    case mellow = "Mellow"
    case bright = "Bright"
    case midnight = "Midnight"

    var id: String { rawValue }

    var scale: [Int] {
        switch self {
        case .mellow:
            return [0, 2, 3, 5, 7, 10]
        case .bright:
            return [0, 2, 4, 7, 9]
        case .midnight:
            return [0, 3, 5, 7, 8, 10]
        }
    }
}
