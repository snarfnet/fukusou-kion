import Foundation

enum SleepMode: String, CaseIterable, Identifiable {
    case three
    case ten
    case thirty
    case infinite

    var id: String { rawValue }

    var title: String {
        switch self {
        case .three:
            return "3分"
        case .ten:
            return "10分"
        case .thirty:
            return "30分"
        case .infinite:
            return "無限"
        }
    }

    var duration: TimeInterval? {
        switch self {
        case .three:
            return 180
        case .ten:
            return 600
        case .thirty:
            return 1_800
        case .infinite:
            return nil
        }
    }
}

enum SoundLayer: String, CaseIterable, Identifiable {
    case chant
    case mokugyo
    case bell
    case rain
    case noise
    case drone

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chant:
            return "読経"
        case .mokugyo:
            return "木魚"
        case .bell:
            return "鐘"
        case .rain:
            return "雨音"
        case .noise:
            return "ノイズ"
        case .drone:
            return "低音"
        }
    }

    var fileName: String {
        switch self {
        case .chant:
            return "okyo_low"
        case .mokugyo:
            return "mokugyo"
        case .bell:
            return "bell"
        case .rain:
            return "rain"
        case .noise:
            return "pink_noise"
        case .drone:
            return "drone"
        }
    }

    var defaultVolume: Float {
        switch self {
        case .chant:
            return 0.56
        case .mokugyo:
            return 0.28
        case .bell:
            return 0.20
        case .rain:
            return 0.44
        case .noise:
            return 0.24
        case .drone:
            return 0.30
        }
    }
}

struct MixerSettings: Equatable {
    var chantVolume: Float
    var mokugyoVolume: Float
    var bellVolume: Float
    var rainVolume: Float
    var noiseVolume: Float
    var droneVolume: Float
    var fadeOutEnabled: Bool
    var extraDarkEnabled: Bool

    static let standard = MixerSettings(
        chantVolume: SoundLayer.chant.defaultVolume,
        mokugyoVolume: SoundLayer.mokugyo.defaultVolume,
        bellVolume: SoundLayer.bell.defaultVolume,
        rainVolume: SoundLayer.rain.defaultVolume,
        noiseVolume: SoundLayer.noise.defaultVolume,
        droneVolume: SoundLayer.drone.defaultVolume,
        fadeOutEnabled: true,
        extraDarkEnabled: true
    )

    func volume(for layer: SoundLayer) -> Float {
        switch layer {
        case .chant:
            return chantVolume
        case .mokugyo:
            return mokugyoVolume
        case .bell:
            return bellVolume
        case .rain:
            return rainVolume
        case .noise:
            return noiseVolume
        case .drone:
            return droneVolume
        }
    }
}
