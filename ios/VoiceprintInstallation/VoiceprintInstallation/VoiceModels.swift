import SwiftUI

// MARK: - Voice Features

struct VoiceFeatures: Codable {
    var averageEnergy: Double
    var energyCurve: [Double]
    var waveform: [Double]
    var pitchCurve: [Double]
    var pitchRange: Double
    var rhythmDensity: Double

    static let empty = VoiceFeatures(
        averageEnergy: 0,
        energyCurve: Array(repeating: 0, count: 64),
        waveform: Array(repeating: 0, count: 64),
        pitchCurve: Array(repeating: 0, count: 64),
        pitchRange: 0,
        rhythmDensity: 0
    )
}

// MARK: - Artwork Palette

struct ArtworkPalette {
    var backgroundA: Color
    var backgroundB: Color
    var spark: Color
    var lineA: Color
    var lineB: Color

    static func from(features: VoiceFeatures, seed: UInt64) -> ArtworkPalette {
        var rng = SeededRandomNumberGenerator(seed: seed)
        let palettes: [ArtworkPalette] = [
            ArtworkPalette(backgroundA: Color(red: 0.02, green: 0.04, blue: 0.08),
                           backgroundB: Color(red: 0.06, green: 0.02, blue: 0.06),
                           spark: .cyan, lineA: .mint, lineB: .pink),
            ArtworkPalette(backgroundA: Color(red: 0.05, green: 0.01, blue: 0.02),
                           backgroundB: Color(red: 0.02, green: 0.01, blue: 0.06),
                           spark: .orange, lineA: .red, lineB: .yellow),
            ArtworkPalette(backgroundA: Color(red: 0.01, green: 0.04, blue: 0.03),
                           backgroundB: Color(red: 0.04, green: 0.06, blue: 0.02),
                           spark: .green, lineA: .teal, lineB: .cyan),
            ArtworkPalette(backgroundA: Color(red: 0.04, green: 0.01, blue: 0.06),
                           backgroundB: Color(red: 0.06, green: 0.01, blue: 0.04),
                           spark: .purple, lineA: .pink, lineB: .indigo),
            ArtworkPalette(backgroundA: Color(red: 0.02, green: 0.02, blue: 0.02),
                           backgroundB: Color(red: 0.05, green: 0.05, blue: 0.05),
                           spark: .white, lineA: .gray, lineB: .cyan),
        ]
        let index = Int(rng.next() % UInt64(palettes.count))
        return palettes[index]
    }
}

// MARK: - Artwork Style

enum StyleFamily: Int, Codable, CaseIterable {
    case bloom, aurora, topography, calligraphy, mist, nebula, figure, organism, spirit
}

struct ArtworkStyle: Codable {
    var family: StyleFamily
    var biomorphIndex: Int
    var symmetry: Int
    var strokeBias: Double
    var turbulence: Double

    static func from(features: VoiceFeatures, seed: UInt64) -> ArtworkStyle {
        var rng = SeededRandomNumberGenerator(seed: seed &+ 7919)
        let family = StyleFamily(rawValue: Int(rng.next() % UInt64(StyleFamily.allCases.count)))!
        return ArtworkStyle(
            family: family,
            biomorphIndex: Int(rng.next() % 100),
            symmetry: 2 + Int(rng.next() % 6),
            strokeBias: 0.6 + rng.double(in: 0...0.8),
            turbulence: 0.4 + rng.double(in: 0...1.2)
        )
    }
}

// MARK: - NFT Metadata

struct NFTMetadata: Codable {
    var name: String
    var description: String
    var attributes: [Attribute]
    var createdAt: Date

    struct Attribute: Codable {
        var traitType: String
        var value: String

        enum CodingKeys: String, CodingKey {
            case traitType = "trait_type"
            case value
        }
    }
}

// MARK: - Voice Artwork

struct VoiceArtwork: Identifiable, Codable {
    var id: UUID
    var features: VoiceFeatures
    var seed: UInt64
    var createdAt: Date
    var styleRaw: ArtworkStyle

    var style: ArtworkStyle { styleRaw }

    var palette: ArtworkPalette {
        ArtworkPalette.from(features: features, seed: seed)
    }

    var nftMetadata: NFTMetadata {
        NFTMetadata(
            name: "Voiceprint #\(seed % 10000)",
            description: "Generative artwork derived from voice analysis. Energy: \(String(format: "%.2f", features.averageEnergy)), Pitch range: \(String(format: "%.0f", features.pitchRange))Hz",
            attributes: [
                .init(traitType: "Style", value: "\(styleRaw.family)"),
                .init(traitType: "Energy", value: String(format: "%.2f", features.averageEnergy)),
                .init(traitType: "Pitch Range", value: "\(Int(features.pitchRange))Hz"),
                .init(traitType: "Rhythm Density", value: String(format: "%.2f", features.rhythmDensity)),
                .init(traitType: "Symmetry", value: "\(styleRaw.symmetry)"),
            ],
            createdAt: createdAt
        )
    }

    init(features: VoiceFeatures) {
        self.id = UUID()
        self.features = features
        self.seed = UInt64.random(in: 0...UInt64.max)
        self.createdAt = Date()
        self.styleRaw = ArtworkStyle.from(features: features, seed: seed)
    }

    init(id: UUID, features: VoiceFeatures, seed: UInt64, createdAt: Date, styleRaw: ArtworkStyle) {
        self.id = id
        self.features = features
        self.seed = seed
        self.createdAt = createdAt
        self.styleRaw = styleRaw
    }
}

// MARK: - Seeded RNG

struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        z = z ^ (z >> 31)
        return z
    }

    mutating func double(in range: ClosedRange<Double>) -> Double {
        let raw = Double(next()) / Double(UInt64.max)
        return range.lowerBound + raw * (range.upperBound - range.lowerBound)
    }
}

// MARK: - Gallery Storage

final class GalleryStore: ObservableObject {
    @Published var artworks: [VoiceArtwork] = []

    private let key = "voiceprint_gallery"

    init() { load() }

    func save(_ artwork: VoiceArtwork) {
        artworks.insert(artwork, at: 0)
        persist()
    }

    func delete(at offsets: IndexSet) {
        artworks.remove(atOffsets: offsets)
        persist()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(artworks) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let saved = try? JSONDecoder().decode([VoiceArtwork].self, from: data) else { return }
        artworks = saved
    }
}
