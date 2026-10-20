import Foundation

enum Surface: String, Codable, CaseIterable, Identifiable {
    case chrome, bronze, glass, paper, monolith, neon
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum Backdrop: String, Codable, CaseIterable, Identifiable {
    case obsidian, ivory, concrete, frosted, gradient
    var id: String { rawValue }
    var title: String {
        switch self {
        case .obsidian: return "黒い空間"
        case .ivory: return "白い展示室"
        case .concrete: return "コンクリート"
        case .frosted: return "乳白ガラス"
        case .gradient: return "グラデーション"
        }
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
    // Optional additions keep v1 documents readable without discarding their history.
    var composition: Composition?
    var glyphAdjustments: [GlyphAdjustment]?
    var materialSettings: MaterialSettings?
    var lightRig: LightRig?

    var layout: Composition {
        get { composition ?? Composition() }
        set { composition = newValue }
    }
    var finish: MaterialSettings {
        get { materialSettings ?? MaterialSettings() }
        set { materialSettings = newValue }
    }
    var lighting: LightRig {
        get { lightRig ?? LightRig() }
        set { lightRig = newValue }
    }
    var glyphs: [GlyphAdjustment] {
        get { glyphAdjustments ?? [] }
        set { glyphAdjustments = newValue }
    }
    var editableIndices: [Int] {
        Array(text).indices.filter { !Array(text)[$0].isWhitespace }
    }
    func adjustment(at index: Int) -> GlyphAdjustment {
        glyphs.first { $0.id == index } ?? GlyphAdjustment(id: index)
    }
    mutating func updateGlyph(at index: Int, _ edit: (inout GlyphAdjustment) -> Void) {
        guard editableIndices.contains(index) else { return }
        var item = adjustment(at: index)
        edit(&item)
        var values = glyphs.filter { $0.id != index }
        values.append(item)
        glyphs = values.sorted { $0.id < $1.id }
    }
    func expandedSelection(_ indices: Set<Int>) -> Set<Int> {
        let groups = Set(indices.compactMap { adjustment(at: $0).group })
        return Set(editableIndices.filter { index in
            indices.contains(index) || adjustment(at: index).group.map(groups.contains) == true
        })
    }
    mutating func group(_ selection: Set<Int>) {
        let indices = expandedSelection(selection)
        guard indices.count > 1 else { return }
        let group = UUID()
        for index in indices { updateGlyph(at: index) { $0.group = group } }
    }
    mutating func ungroup(_ selection: Set<Int>) {
        for index in expandedSelection(selection) { updateGlyph(at: index) { $0.group = nil } }
    }
    mutating func replaceText(_ newText: String) {
        text = newText
        glyphAdjustments = nil
    }
}

enum TextAlignmentMode: String, Codable, CaseIterable, Identifiable {
    case leading, center, trailing
    var id: String { rawValue }
    var title: String {
        switch self { case .leading: return "左揃え"; case .center: return "中央揃え"; case .trailing: return "右揃え" }
    }
}

struct Composition: Codable, Equatable {
    var roll = 0.0
    var arc = 0.0
    var lineHeight = 1.2
    var alignment = TextAlignmentMode.center
    var smoothness = 0.25
}

struct GlyphAdjustment: Codable, Equatable, Identifiable {
    var id: Int
    var x = 0.0
    var y = 0.0
    var z = 0.0
    var rotationX = 0.0
    var rotationY = 0.0
    var rotationZ = 0.0
    var scale = 1.0
    var layer = 0
    var surface: Surface?
    var group: UUID?
}

struct MaterialSettings: Codable, Equatable {
    var roughness = 0.22
    var metallic = 0.95
    var clearCoat = 0.25
    var scratches = 0.0
}

enum LightStyle: String, Codable, CaseIterable, Identifiable {
    case gallery, daylight, dramatic
    var id: String { rawValue }
    var title: String {
        switch self { case .gallery: return "ギャラリー"; case .daylight: return "自然光"; case .dramatic: return "スポットライト" }
    }
}

struct LightRig: Codable, Equatable {
    var style = LightStyle.gallery
    var fill = 0.65
    var rim = 1.0
    var temperature = 0.0
}

enum ArtworkPreset: String, CaseIterable, Identifiable {
    case monolith, chrome, museum, glass, bronze, paper, neon, architectural
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var caption: String {
        switch self {
        case .monolith: return "静かな黒。厚みのある一文字。"
        case .chrome: return "反射する光を、文字の輪郭に。"
        case .museum: return "白い空間に佇む彫刻。"
        case .glass: return "光が透ける、青いガラス。"
        case .bronze: return "時を重ねた金属の色。"
        case .paper: return "紙を切り重ねたような柔らかさ。"
        case .neon: return "暗闇に浮かぶ、光の文字。"
        case .architectural: return "構造を見せる、建築模型。"
        }
    }
    func apply(to artwork: inout Artwork) {
        artwork.glyphAdjustments = nil
        artwork.layout = Composition()
        artwork.finish = MaterialSettings()
        artwork.lighting = LightRig()
        artwork.zoom = 1; artwork.panX = 0; artwork.panY = 0
        artwork.yaw = -0.35; artwork.pitch = 0.12
        artwork.spacing = 3; artwork.bevel = 2; artwork.light = 1
        switch self {
        case .monolith:
            artwork.surface = .monolith; artwork.backdrop = .obsidian; artwork.depth = 65
            artwork.lighting.style = .dramatic
        case .chrome:
            artwork.surface = .chrome; artwork.backdrop = .obsidian; artwork.depth = 30
        case .museum:
            artwork.surface = .bronze; artwork.backdrop = .ivory; artwork.depth = 25
            artwork.lighting.style = .daylight
        case .glass:
            artwork.surface = .glass; artwork.backdrop = .gradient; artwork.depth = 40
        case .bronze:
            artwork.surface = .bronze; artwork.backdrop = .obsidian; artwork.depth = 36
            artwork.finish.roughness = 0.38; artwork.finish.scratches = 0.3
        case .paper:
            artwork.surface = .paper; artwork.backdrop = .concrete; artwork.depth = 5
            artwork.bevel = 0.5
        case .neon:
            artwork.surface = .neon; artwork.backdrop = .obsidian; artwork.depth = 12
            artwork.light = 0.4
        case .architectural:
            artwork.surface = .paper; artwork.backdrop = .ivory; artwork.depth = 60
            artwork.bevel = 0; artwork.yaw = -0.785; artwork.pitch = 0.615
        }
    }
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
        if text.filter({ $0 != "\n" }).count > 12 { return "文字は12文字まで入力できます。" }
        if text.filter({ $0 == "\n" }).count > 2 { return "改行は2回まで使えます。" }
        for scalar in text.unicodeScalars {
            let v = scalar.value
            let supported = v == 10 || (0x20...0x7E).contains(v) || (0x3000...0x30FF).contains(v)
                || (0x3400...0x9FFF).contains(v) || (0xFF01...0xFF60).contains(v)
            if !supported { return "「\(scalar)」は未対応です。日本語・英字・数字を使ってください。絵文字は使えません。" }
        }
        return nil
    }
}
