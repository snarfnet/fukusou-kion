import AVFoundation
import CoreGraphics
import Foundation
import SwiftUI

struct PersonTrackPoint: Identifiable, Codable, Equatable {
    var id = UUID()
    var time: Double
    var boundingBox: CGRect
    var confidence: Float
}

enum GhostStyle: String, CaseIterable, Identifiable, Codable {
    case paleWoman
    case shadowCrawler
    case redMask
    case staticNoise

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .paleWoman: "白い影"
        case .shadowCrawler: "黒い追跡者"
        case .redMask: "赤い面"
        case .staticNoise: "ノイズ霊"
        }
    }

    var productID: String? {
        switch self {
        case .paleWoman: nil
        case .shadowCrawler: "com.tokyonasu.ghostfollower.pack.shadow"
        case .redMask: "com.tokyonasu.ghostfollower.pack.redmask"
        case .staticNoise: "com.tokyonasu.ghostfollower.pack.staticnoise"
        }
    }

    var isIncluded: Bool { productID == nil }

    var tint: Color {
        switch self {
        case .paleWoman: Color(red: 0.82, green: 0.94, blue: 0.92)
        case .shadowCrawler: Color(red: 0.04, green: 0.05, blue: 0.06)
        case .redMask: Color(red: 0.78, green: 0.04, blue: 0.08)
        case .staticNoise: Color(red: 0.67, green: 0.82, blue: 1.0)
        }
    }
}

struct GhostSettings: Codable, Equatable {
    var style: GhostStyle = .paleWoman
    var facing: GhostFacing = .front
    var opacity: Double = 0.86
    var scale: Double = 1.18
    var horizontalOffset: Double = -0.52
    var verticalOffset: Double = -0.08
    var jitter: Double = 0.04
}

enum GhostFacing: String, CaseIterable, Identifiable, Codable {
    case front
    case side

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .front: "正面"
        case .side: "横向き"
        }
    }
}

struct AnalysisSummary: Equatable {
    var duration: Double = 0
    var processedFrames: Int = 0
    var detectedFrames: Int = 0

    var hitRateText: String {
        guard processedFrames > 0 else { return "未解析" }
        let rate = Double(detectedFrames) / Double(processedFrames)
        return "\(Int(rate * 100))%"
    }
}

enum EditorPhase: Equatable {
    case empty
    case loading
    case ready
    case analyzing(Double)
    case analyzed
    case exporting(Double)
    case exported(URL)
    case failed(String)

    var isBusy: Bool {
        switch self {
        case .loading, .analyzing, .exporting: true
        default: false
        }
    }
}
