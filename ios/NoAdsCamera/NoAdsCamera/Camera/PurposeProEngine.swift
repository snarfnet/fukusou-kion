import Foundation

enum PurposeProPreset: String, CaseIterable, Identifiable {
    case marketplace = "メルカリ"
    case nail = "ネイル"
    case food = "料理"
    case storeAd = "店舗広告"
    case snsIcon = "SNSアイコン"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .marketplace:
            "shippingbox.fill"
        case .nail:
            "hand.raised.fill"
        case .food:
            "fork.knife"
        case .storeAd:
            "storefront.fill"
        case .snsIcon:
            "person.crop.circle.fill"
        }
    }
}

struct PurposeProGuide {
    let preset: PurposeProPreset
    let targetAspect: String
    let primaryGuide: String
    let secondaryGuide: String
    let exposurePriority: ExposurePriority
    let ispPreset: ISPPreset
    let checklist: [String]
}

struct PurposeProAssessment {
    let score: Int
    let message: String
}

final class PurposeProEngine: ObservableObject {
    @Published var selectedPreset: PurposeProPreset = .marketplace

    var currentGuide: PurposeProGuide {
        guide(for: selectedPreset)
    }

    func guide(for preset: PurposeProPreset) -> PurposeProGuide {
        switch preset {
        case .marketplace:
            return PurposeProGuide(
                preset: preset,
                targetAspect: "1:1",
                primaryGuide: "商品を中央に置いてください",
                secondaryGuide: "背景をシンプルに。影は少なめ。",
                exposurePriority: .product,
                ispPreset: .product,
                checklist: ["中央", "明るい", "正方形", "背景整理"]
            )
        case .nail:
            return PurposeProGuide(
                preset: preset,
                targetAspect: "4:5",
                primaryGuide: "爪先にピントを合わせます",
                secondaryGuide: "手を少し斜めに。反射は抑えめ。",
                exposurePriority: .product,
                ispPreset: .portrait,
                checklist: ["爪先ピント", "肌色自然", "反射少なめ", "手の角度"]
            )
        case .food:
            return PurposeProGuide(
                preset: preset,
                targetAspect: "4:5",
                primaryGuide: "斜め45度から狙いましょう",
                secondaryGuide: "皿の白飛びを抑えて、ツヤを残します。",
                exposurePriority: .skySafe,
                ispPreset: .food,
                checklist: ["45度", "暖色", "皿を飛ばさない", "ツヤ"]
            )
        case .storeAd:
            return PurposeProGuide(
                preset: preset,
                targetAspect: "16:9",
                primaryGuide: "看板と入口を入れてください",
                secondaryGuide: "文字入れ用の余白を片側に残します。",
                exposurePriority: .document,
                ispPreset: .neutral,
                checklist: ["入口", "看板", "清潔感", "余白"]
            )
        case .snsIcon:
            return PurposeProGuide(
                preset: preset,
                targetAspect: "1:1",
                primaryGuide: "顔を明るく、中央少し上へ",
                secondaryGuide: "丸型で切れても見える余白を残します。",
                exposurePriority: .face,
                ispPreset: .portrait,
                checklist: ["顔明るい", "目線", "背景ぼけ", "丸型余白"]
            )
        }
    }

    func assess(highlightRatio: Double, shadowRatio: Double, shakeLevel: Double, horizonTilt: Double, bestShotScore: Double) -> PurposeProAssessment {
        var score = Int(bestShotScore * 100)
        var message = currentGuide.primaryGuide

        if shakeLevel > 0.18 {
            score -= 18
            message = "少し止まって撮りましょう"
        } else if abs(horizonTilt) > 0.10 {
            score -= 10
            message = "水平を少し直しましょう"
        } else if highlightRatio > highlightLimit(for: selectedPreset) {
            score -= 14
            message = highlightMessage(for: selectedPreset)
        } else if shadowRatio > shadowLimit(for: selectedPreset) {
            score -= 12
            message = "少し明るくしましょう"
        } else if score > 82 {
            message = "今が撮りどきです"
        }

        return PurposeProAssessment(score: max(0, min(100, score)), message: message)
    }

    private func highlightLimit(for preset: PurposeProPreset) -> Double {
        switch preset {
        case .food, .nail:
            0.045
        case .marketplace:
            0.06
        case .storeAd:
            0.08
        case .snsIcon:
            0.07
        }
    }

    private func shadowLimit(for preset: PurposeProPreset) -> Double {
        switch preset {
        case .marketplace, .storeAd:
            0.12
        case .food:
            0.16
        case .nail, .snsIcon:
            0.14
        }
    }

    private func highlightMessage(for preset: PurposeProPreset) -> String {
        switch preset {
        case .food:
            "皿が白飛びしています"
        case .nail:
            "爪の反射を少し抑えましょう"
        case .marketplace:
            "商品が明るすぎます"
        case .storeAd:
            "看板の文字が飛びそうです"
        case .snsIcon:
            "顔の明るい部分を抑えます"
        }
    }
}
