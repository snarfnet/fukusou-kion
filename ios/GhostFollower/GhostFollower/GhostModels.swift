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
    case wetWoman
    case facelessWoman
    case monk
    case paleWoman
    case child

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .wetWoman: "濡れ女"
        case .facelessWoman: "顔なし女"
        case .monk: "亡霊僧"
        case .paleWoman: "白装束"
        case .child: "童霊"
        }
    }

    var shortName: String {
        switch self {
        case .wetWoman: "濡"
        case .facelessWoman: "無"
        case .monk: "僧"
        case .paleWoman: "白"
        case .child: "童"
        }
    }

    var productID: String? { nil }

    func assetName(for facing: GhostFacing) -> String {
        let suffix = facing == .front ? "front" : "side"
        switch self {
        case .wetWoman: "ghost_wet_\(suffix)"
        case .facelessWoman: "ghost_faceless_\(suffix)"
        case .monk: "ghost_monk_\(suffix)"
        case .paleWoman: "ghost_pale_\(suffix)"
        case .child: "ghost_child_\(suffix)"
        }
    }
}

struct GhostSettings: Codable, Equatable {
    var style: GhostStyle = .wetWoman
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
