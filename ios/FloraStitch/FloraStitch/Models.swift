import CoreGraphics
import Foundation
import SwiftUI

struct StitchDesign: Identifiable {
    let id = UUID()
    let seed: Int
    let size: CGSize
    let palette: [EmbroideryColor]
    let elements: [DesignElement]
    let stitchPlan: StitchPlan
}

struct EmbroideryColor: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let hex: String

    var color: Color {
        Color(hex: hex)
    }
}

enum DesignElement: Identifiable {
    case vine(VineElement)
    case leaf(LeafElement)
    case flower(FlowerElement)
    case berry(BerryElement)
    case importedVector(ImportedVectorElement)
    case bird(BirdElement)
    case curl(CurlElement)

    var id: UUID {
        switch self {
        case .vine(let item): item.id
        case .leaf(let item): item.id
        case .flower(let item): item.id
        case .berry(let item): item.id
        case .importedVector(let item): item.id
        case .bird(let item): item.id
        case .curl(let item): item.id
        }
    }
}

struct VineElement {
    let id = UUID()
    let points: [CGPoint]
    let color: EmbroideryColor
    let width: CGFloat
}

struct LeafElement {
    let id = UUID()
    let center: CGPoint
    let size: CGSize
    let angle: CGFloat
    let color: EmbroideryColor
    let veinColor: EmbroideryColor
}

struct FlowerElement {
    let id = UUID()
    let center: CGPoint
    let radius: CGFloat
    let kind: FlowerKind
    let petals: Int
    let angle: CGFloat
    let fill: EmbroideryColor
    let centerColor: EmbroideryColor
}

struct BerryElement {
    let id = UUID()
    let center: CGPoint
    let radius: CGFloat
    let kind: BerryKind
    let angle: CGFloat
    let color: EmbroideryColor
}

struct VectorTemplate {
    let outlines: [[CGPoint]]
}

struct ImportedVectorElement {
    let id = UUID()
    let center: CGPoint
    let size: CGSize
    let angle: CGFloat
    let color: EmbroideryColor
    let outlines: [[CGPoint]]
}

struct BirdElement {
    let id = UUID()
    let center: CGPoint
    let size: CGFloat
    let angle: CGFloat
    let kind: BirdKind
    let bodyColor: EmbroideryColor
    let wingColor: EmbroideryColor
    let accentColor: EmbroideryColor
}

enum FlowerKind: String, CaseIterable {
    case daisy
    case forgetMeNot
    case poppy
    case tulip
    case rose
    case bell
    case clover
    case starflower
    case lavender
    case bud
    case cosmos
    case anemone
}

enum BerryKind: String, CaseIterable {
    case round
    case ovalBud
    case teardrop
    case twinCherry
    case beadCluster
    case wheat
    case seedPod
    case roseHip
}

enum BirdKind: String, CaseIterable {
    case swallow
    case sparrow
    case dove
    case finch
    case hummingbird
    case crane
    case robin
    case wren
    case kingfisher
    case lark
    case gull
    case owl
}

struct CurlElement {
    let id = UUID()
    let center: CGPoint
    let radius: CGFloat
    let turns: CGFloat
    let direction: CGFloat
    let color: EmbroideryColor
}

struct StitchPlan {
    let colors: [EmbroideryColor]
    let blocks: [StitchBlock]

    var stitchCount: Int {
        blocks.reduce(0) { $0 + $1.points.count }
    }
}

struct StitchBlock {
    let color: EmbroideryColor
    let points: [StitchPoint]
}

struct StitchPoint {
    let x: Double
    let y: Double
    let jump: Bool
}

struct GeneratorSettings: Equatable {
    var widthInches: Double = 5.0
    var heightInches: Double = 1.15
    var density: Double = 0.62
    var flowerMix: Double = 0.58
    var curls: Bool = true
    var birds: Bool = false
    var paletteIndex: Int = 0

    var canvasSize: CGSize {
        CGSize(width: CGFloat(widthInches * 240.0), height: CGFloat(heightInches * 240.0))
    }
}

struct SeededRandomGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: Int) {
        state = UInt64(bitPattern: Int64(seed == 0 ? 1 : seed))
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
        value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
        return value ^ (value >> 31)
    }

    mutating func double(_ range: ClosedRange<Double>) -> Double {
        let unit = Double(next() >> 11) / Double(1 << 53)
        return range.lowerBound + (range.upperBound - range.lowerBound) * unit
    }

    mutating func int(_ range: ClosedRange<Int>) -> Int {
        Int(double(Double(range.lowerBound)...Double(range.upperBound + 1)).rounded(.down))
    }

    mutating func bool(_ probability: Double = 0.5) -> Bool {
        double(0...1) < probability
    }
}

extension Color {
    init(hex: String) {
        let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: clean).scanHexInt64(&value)
        let red = Double((value >> 16) & 0xFF) / 255.0
        let green = Double((value >> 8) & 0xFF) / 255.0
        let blue = Double(value & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}
