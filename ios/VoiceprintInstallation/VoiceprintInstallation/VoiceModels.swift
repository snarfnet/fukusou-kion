import Foundation
import SwiftUI

struct VoiceFeatures: Codable, Equatable {
    var duration: Double
    var averageEnergy: Double
    var peakEnergy: Double
    var averagePitch: Double
    var pitchRange: Double
    var rhythmDensity: Double
    var silenceRatio: Double
    var zeroCrossingRate: Double
    var waveform: [Double]
    var energyCurve: [Double]
    var pitchCurve: [Double]

    static let empty = VoiceFeatures(
        duration: 0,
        averageEnergy: 0,
        peakEnergy: 0,
        averagePitch: 0,
        pitchRange: 0,
        rhythmDensity: 0,
        silenceRatio: 0,
        zeroCrossingRate: 0,
        waveform: [],
        energyCurve: [],
        pitchCurve: []
    )
}

struct VoiceArtwork: Identifiable, Codable, Equatable {
    var id: UUID
    var createdAt: Date
    var title: String
    var seed: UInt64
    var features: VoiceFeatures

    var palette: ArtworkPalette {
        ArtworkPalette(seed: seed, features: features)
    }

    var nftMetadata: NFTMetadata {
        NFTMetadata(
            name: title,
            description: "Generated from a short voice recording. The audio is not stored; only abstract voice features are attached.",
            image: "ipfs://REPLACE_WITH_IMAGE_CID",
            attributes: [
                NFTAttribute(trait_type: "Duration", value: rounded(features.duration)),
                NFTAttribute(trait_type: "Voice Energy", value: rounded(features.averageEnergy * 100)),
                NFTAttribute(trait_type: "Peak Energy", value: rounded(features.peakEnergy * 100)),
                NFTAttribute(trait_type: "Pitch Range", value: rounded(features.pitchRange)),
                NFTAttribute(trait_type: "Rhythm Density", value: rounded(features.rhythmDensity * 100)),
                NFTAttribute(trait_type: "Silence Pattern", value: rounded(features.silenceRatio * 100)),
                NFTAttribute(trait_type: "Seed", value: Double(seed % 1_000_000))
            ]
        )
    }

    private func rounded(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }
}

struct NFTMetadata: Codable {
    var name: String
    var description: String
    var image: String
    var attributes: [NFTAttribute]
}

struct NFTAttribute: Codable {
    var trait_type: String
    var value: Double
}

struct ArtworkPalette {
    var backgroundA: Color
    var backgroundB: Color
    var lineA: Color
    var lineB: Color
    var spark: Color

    init(seed: UInt64, features: VoiceFeatures) {
        let baseHue = ((Double(seed % 360) / 360) + features.averagePitch / 900).truncatingRemainder(dividingBy: 1)
        let energy = max(0.35, min(0.95, features.averageEnergy * 4))
        let pitch = max(0.25, min(0.9, features.pitchRange / 280))

        backgroundA = Color(hue: baseHue, saturation: 0.62, brightness: 0.14 + energy * 0.16)
        backgroundB = Color(hue: (baseHue + 0.18).truncatingRemainder(dividingBy: 1), saturation: 0.48 + pitch * 0.26, brightness: 0.18)
        lineA = Color(hue: (baseHue + 0.41).truncatingRemainder(dividingBy: 1), saturation: 0.78, brightness: 0.92)
        lineB = Color(hue: (baseHue + 0.08).truncatingRemainder(dividingBy: 1), saturation: 0.86, brightness: 0.74)
        spark = Color(hue: (baseHue + 0.62).truncatingRemainder(dividingBy: 1), saturation: 0.92, brightness: 0.98)
    }
}

struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x1234abcd : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var value = state
        value = (value ^ (value >> 30)) &* 0xbf58476d1ce4e5b9
        value = (value ^ (value >> 27)) &* 0x94d049bb133111eb
        return value ^ (value >> 31)
    }

    mutating func double(in range: ClosedRange<Double>) -> Double {
        let unit = Double(next() % 10_000) / 10_000
        return range.lowerBound + (range.upperBound - range.lowerBound) * unit
    }
}

@MainActor
final class ArtworkGallery: ObservableObject {
    @Published private(set) var artworks: [VoiceArtwork] = []

    private let storageKey = "voiceprint.artworks"

    init() {
        load()
    }

    func add(_ artwork: VoiceArtwork) {
        artworks.insert(artwork, at: 0)
        artworks = Array(artworks.prefix(12))
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([VoiceArtwork].self, from: data) else {
            return
        }
        artworks = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(artworks) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
