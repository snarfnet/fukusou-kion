import Foundation

enum Surface: String, Codable, CaseIterable, Identifiable {
    case chrome, bronze, glass, paper, monolith, neon
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum Backdrop: String, Codable, CaseIterable, Identifiable {
    case obsidian, ivory, concrete
    var id: String { rawValue }
    var title: String {
        switch self { case .obsidian: return "黒い空間"; case .ivory: return "白い展示室"; case .concrete: return "コンクリート" }
    }
}

struct Artwork: Codable, Equatable, Identifiable {
    var id = UUID()
    var schemaVersion = 1
    var title = "無題の彫刻"
    var text = "永"
    var depth = 24.0
    var bevel = 2.0
    var spacing = 3.0
    var surface = Surface.chrome
    var backdrop = Backdrop.obsidian
    var light = 1.0
    var yaw = -0.35
    var pitch = 0.12
    var zoom = 1.0
    var panX = 0.0
    var panY = 0.0
    var createdAt = Date()
    var updatedAt = Date()
}

struct EditHistory: Codable {
    private(set) var past: [Artwork] = []
    private(set) var future: [Artwork] = []
    mutating func record(_ value: Artwork) {
        past.append(value)
        if past.count > 60 { past.removeFirst() }
        future.removeAll()
    }
    mutating func undo(_ current: Artwork) -> Artwork? {
        guard let previous = past.popLast() else { return nil }
        future.append(current)
        return previous
    }
    mutating func redo(_ current: Artwork) -> Artwork? {
        guard let next = future.popLast() else { return nil }
        past.append(current)
        return next
    }
}

struct SavedArtwork: Codable {
    var artwork: Artwork
    var history: EditHistory
}

enum InputCheck {
    static func validate(_ text: String) -> String? {
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "文字を入力してください。" }
        if text.count > 12 { return "文字は12文字まで入力できます。" }
        for scalar in text.unicodeScalars {
            let v = scalar.value
            let supported = (0x20...0x7E).contains(v) || (0x3000...0x30FF).contains(v)
                || (0x3400...0x9FFF).contains(v) || (0xFF01...0xFF60).contains(v)
            if !supported { return "「\(scalar)」は未対応です。日本語・英字・数字を使ってください。絵文字と改行は使えません。" }
        }
        return nil
    }
}
