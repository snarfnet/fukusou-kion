import Foundation

enum CraftTool: String, CaseIterable, Identifiable {
    case angle = "角度"
    case level = "水平"
    case convert = "変換"
    case slope = "勾配"
    case material = "材料"
    case checklist = "点検"
    case photo = "写真"
    case centerGuide = "中心線"
    case notes = "履歴"

    var id: String { rawValue }

    var testID: String {
        switch self {
        case .angle: "angle"
        case .level: "level"
        case .convert: "convert"
        case .slope: "slope"
        case .material: "material"
        case .checklist: "checklist"
        case .photo: "photo"
        case .centerGuide: "center-guide"
        case .notes: "notes"
        }
    }

    var symbol: String {
        switch self {
        case .angle: "angle"
        case .level: "circle.dashed.inset.filled"
        case .convert: "arrow.left.arrow.right"
        case .slope: "chart.line.uptrend.xyaxis"
        case .material: "square.grid.3x3"
        case .checklist: "checklist"
        case .photo: "camera.viewfinder"
        case .centerGuide: "plus.viewfinder"
        case .notes: "doc.richtext"
        }
    }
}

enum ConverterKind: String, CaseIterable, Identifiable, Codable {
    case length = "長さ"
    case area = "面積"

    var id: String { rawValue }
}

enum CraftUnit: String, CaseIterable, Identifiable, Codable {
    case meter = "m"
    case centimeter = "cm"
    case millimeter = "mm"
    case shaku = "尺"
    case sun = "寸"
    case inch = "inch"
    case feet = "feet"
    case squareMeter = "m2"
    case tsubo = "坪"
    case jo = "畳"

    var id: String { rawValue }

    var kind: ConverterKind {
        switch self {
        case .squareMeter, .tsubo, .jo:
            .area
        default:
            .length
        }
    }

    var baseFactor: Double {
        switch self {
        case .meter: 1
        case .centimeter: 0.01
        case .millimeter: 0.001
        case .shaku: 0.303030303
        case .sun: 0.0303030303
        case .inch: 0.0254
        case .feet: 0.3048
        case .squareMeter: 1
        case .tsubo: 3.305785
        case .jo: 1.62
        }
    }
}

struct MeasurementNote: Identifiable, Codable, Hashable {
    var id = UUID()
    var siteName: String
    var title: String
    var value: String
    var memo: String
    var tag: String = "未分類"
    var createdAt = Date()

    init(
        id: UUID = UUID(),
        siteName: String,
        title: String,
        value: String,
        memo: String,
        tag: String = "未分類",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.siteName = siteName
        self.title = title
        self.value = value
        self.memo = memo
        self.tag = tag
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        siteName = try container.decodeIfPresent(String.self, forKey: .siteName) ?? "現場名未設定"
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "測定"
        value = try container.decodeIfPresent(String.self, forKey: .value) ?? ""
        memo = try container.decodeIfPresent(String.self, forKey: .memo) ?? ""
        tag = try container.decodeIfPresent(String.self, forKey: .tag) ?? "未分類"
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }
}

struct ChecklistItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var isDone: Bool
}

struct SiteTemplate: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var checklistItems: [String]
    var angleTolerance: Double
    var levelTolerance: Double
    var materialLoss: Double
}

struct ConversionFavorite: Identifiable, Codable, Hashable {
    var id = UUID()
    var title: String
    var kind: ConverterKind
    var from: CraftUnit
    var to: CraftUnit
}

enum MaterialKind: String, CaseIterable, Identifiable, Codable {
    case flooring = "床材"
    case wallpaper = "壁紙"
    case paint = "塗料"

    var id: String { rawValue }
}

struct MaterialPrice: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var kind: MaterialKind
    var unitPrice: Int
    var unitCoverage: Double
}

enum TolerancePreset: String, CaseIterable, Identifiable {
    case rough = "ざっくり確認"
    case standard = "通常施工"
    case precise = "精密仕上げ"

    var id: String { rawValue }

    var angle: Double {
        switch self {
        case .rough: 2.0
        case .standard: 0.8
        case .precise: 0.3
        }
    }

    var level: Double {
        switch self {
        case .rough: 1.5
        case .standard: 0.7
        case .precise: 0.3
        }
    }
}

enum NoteTag: String, CaseIterable, Identifiable, Codable {
    case floor = "床"
    case wall = "壁"
    case drain = "排水"
    case base = "下地"
    case finish = "仕上げ"
    case material = "材料"
    case photo = "写真"
    case other = "その他"

    var id: String { rawValue }
}

struct SiteStamp: Codable, Hashable {
    var angleOK = false
    var levelOK = false
    var photoDone = false
    var reportDone = false

    var doneCount: Int {
        [angleOK, levelOK, photoDone, reportDone].filter { $0 }.count
    }
}
