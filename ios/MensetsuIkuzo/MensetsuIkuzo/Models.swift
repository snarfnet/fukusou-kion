import CoreGraphics
import Foundation
import SwiftUI

enum MoriCategory: String, CaseIterable, Identifiable {
    case hair = "髪型"
    case businessTop = "スーツ上"
    case businessBottom = "スーツ下"
    case casualTop = "カジュアル上"
    case casualBottom = "カジュアル下"
    case glasses = "メガネ"
    case accessory = "小物"
    case background = "背景"

    var id: String { rawValue }
}

enum GenderFilter: String, CaseIterable, Identifiable {
    case all = "全部"
    case women = "女性"
    case men = "男性"

    var id: String { rawValue }
}

enum AssetAudience: String, Hashable {
    case women
    case men
    case all

    func matches(_ filter: GenderFilter) -> Bool {
        switch filter {
        case .all:
            true
        case .women:
            self == .women || self == .all
        case .men:
            self == .men || self == .all
        }
    }
}

struct MoriAsset: Identifiable, Hashable {
    let id: String
    let name: String
    let category: MoriCategory
    let filename: String
    let defaultWidth: CGFloat
    let defaultPosition: CGPoint
    let defaultZ: Double
    let isBackground: Bool
    let audience: AssetAudience
}

struct MoriLayer: Identifiable, Hashable {
    var id = UUID()
    let asset: MoriAsset
    var position: CGPoint
    var widthRatio: CGFloat
    var rotation: AngleValue = .zero
    var opacity: CGFloat = 1
    var isFlipped = false
    var zIndex: Double
    var cropSide: MoriCropSide? = nil

    var isBackground: Bool { asset.isBackground }
}

enum MoriCropSide: Hashable {
    case left
    case right
}

struct AngleValue: Hashable {
    var degrees: Double

    static let zero = AngleValue(degrees: 0)
}

enum MoriLibrary {
    static let assets: [MoriAsset] = makeAssets()

    private static func makeAssets() -> [MoriAsset] {
        let categories: [(MoriCategory, Int, CGPoint, CGFloat, Double)] = [
            (.hair, 20, CGPoint(x: 0.50, y: 0.24), 0.92, 30),
            (.businessTop, 18, CGPoint(x: 0.50, y: 0.64), 1.28, 42),
            (.businessBottom, 12, CGPoint(x: 0.50, y: 0.82), 1.08, 38),
            (.casualTop, 16, CGPoint(x: 0.50, y: 0.64), 1.22, 42),
            (.casualBottom, 10, CGPoint(x: 0.50, y: 0.82), 1.04, 38),
            (.glasses, 10, CGPoint(x: 0.50, y: 0.43), 0.64, 58),
            (.accessory, 14, CGPoint(x: 0.66, y: 0.72), 0.50, 62)
        ]

        var result: [MoriAsset] = []
        var index = 1
        for entry in categories {
            for local in 1...entry.1 {
                let audience = audience(for: entry.0, localIndex: local)
                result.append(
                    MoriAsset(
                        id: "interview-item-\(String(format: "%03d", index))",
                        name: displayName(for: entry.0, localIndex: local, audience: audience),
                        category: entry.0,
                        filename: "interview_item_\(String(format: "%03d", index)).png",
                        defaultWidth: entry.3,
                        defaultPosition: adjustedPosition(category: entry.0, localIndex: local, base: entry.2),
                        defaultZ: entry.4,
                        isBackground: entry.0 == .background,
                        audience: audience
                    )
                )
                index += 1
            }
        }
        return result
    }

    private static func audience(for category: MoriCategory, localIndex: Int) -> AssetAudience {
        switch category {
        case .hair, .businessTop, .businessBottom, .casualTop, .casualBottom:
            localIndex.isMultiple(of: 2) ? .men : .women
        case .glasses, .accessory, .background:
            localIndex.isMultiple(of: 3) ? .all : (localIndex.isMultiple(of: 2) ? .men : .women)
        }
    }

    private static func adjustedPosition(category: MoriCategory, localIndex: Int, base: CGPoint) -> CGPoint {
        switch category {
        case .accessory:
            CGPoint(x: localIndex.isMultiple(of: 2) ? 0.32 : 0.68, y: 0.70 + CGFloat(localIndex % 3) * 0.035)
        case .background:
            CGPoint(x: 0.50, y: 0.50)
        default:
            base
        }
    }

    private static func displayName(for category: MoriCategory, localIndex: Int, audience: AssetAudience) -> String {
        let prefix: String
        switch audience {
        case .women:
            prefix = "女性"
        case .men:
            prefix = "男性"
        case .all:
            prefix = "共通"
        }

        switch category {
        case .hair:
            return "\(prefix)きちんと髪 \(localIndex)"
        case .businessTop:
            return "\(prefix)ビジネス上 \(localIndex)"
        case .businessBottom:
            return "\(prefix)ビジネス下 \(localIndex)"
        case .casualTop:
            return "\(prefix)カジュアル上 \(localIndex)"
        case .casualBottom:
            return "\(prefix)カジュアル下 \(localIndex)"
        case .glasses:
            return "\(prefix)メガネ \(localIndex)"
        case .accessory:
            return "\(prefix)小物 \(localIndex)"
        case .background:
            return "\(prefix)証明写真背景 \(localIndex)"
        }
    }
}
