import CoreGraphics
import Foundation
import UIKit

enum StickerEffect: String, CaseIterable, Identifiable {
    case pop = "Pop"
    case shake = "Shake"
    case bounce = "Bounce"
    case float = "Float"
    case sparkle = "Sparkle"
    case heart = "Heart"
    case confetti = "Confetti"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .pop:
            return "circle.grid.cross"
        case .shake:
            return "waveform.path"
        case .bounce:
            return "arrow.up.and.down"
        case .float:
            return "wind"
        case .sparkle:
            return "sparkles"
        case .heart:
            return "heart.fill"
        case .confetti:
            return "party.popper.fill"
        }
    }

    var shortNote: String {
        switch self {
        case .pop:
            return "中心から元気に拡大します"
        case .shake:
            return "左右に小さく揺れます"
        case .bounce:
            return "上下に跳ねます"
        case .float:
            return "ふわっと浮きます"
        case .sparkle:
            return "光を重ねます"
        case .heart:
            return "ハートを散らします"
        case .confetti:
            return "紙吹雪を重ねます"
        }
    }
}

struct StickerSettings: Equatable {
    var effect: StickerEffect = .pop
    var strength: Double = 0.72
    var speed: Double = 1.0
    var frameCount: Int = 12
    var loops: Int = 1
    var background: StickerBackground = .transparent
}

enum StickerBackground: String, CaseIterable, Identifiable {
    case transparent = "Transparent"
    case softWhite = "Soft white"
    case paleBlue = "Pale blue"

    var id: String { rawValue }

    var color: UIColor {
        switch self {
        case .transparent:
            return .clear
        case .softWhite:
            return UIColor(red: 0.98, green: 0.97, blue: 0.94, alpha: 1)
        case .paleBlue:
            return UIColor(red: 0.91, green: 0.96, blue: 1.0, alpha: 1)
        }
    }
}

struct ExportResult: Identifiable {
    let id = UUID()
    let url: URL
    let byteCount: Int
    let frameCount: Int
    let duration: Double

    var sizeText: String {
        ByteCountFormatter.string(fromByteCount: Int64(byteCount), countStyle: .file)
    }
}

struct SpecCheck: Identifiable {
    let title: String
    let isPassing: Bool

    var id: String { title }
}

enum StudioError: LocalizedError, Identifiable {
    case imageLoadFailed
    case renderFailed
    case exportFailed(String)

    var id: String { localizedDescription }

    var errorDescription: String? {
        switch self {
        case .imageLoadFailed:
            return "画像を読み込めませんでした。別のPNGまたは写真を選んでください。"
        case .renderFailed:
            return "フレームを作成できませんでした。画像サイズを変えて試してください。"
        case .exportFailed(let message):
            return "APNGを書き出せませんでした。\(message)"
        }
    }
}

struct LineStickerSpec {
    static let canvasSize = CGSize(width: 320, height: 270)
    static let minFrames = 5
    static let maxFrames = 20
    static let maxDuration = 4.0

    static func report(settings: StickerSettings) -> [SpecCheck] {
        let duration = APNGStickerRenderer.duration(settings: settings)
        return [
            SpecCheck(title: "320 x 270px", isPassing: true),
            SpecCheck(title: "5-20 frames", isPassing: (minFrames...maxFrames).contains(settings.frameCount)),
            SpecCheck(title: "4 seconds or less", isPassing: duration <= maxDuration),
            SpecCheck(title: "Transparent background ready", isPassing: settings.background == .transparent),
            SpecCheck(title: "RGB / 8-bit APNG", isPassing: true)
        ]
    }
}
