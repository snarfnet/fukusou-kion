import Foundation

enum PurposeProPreset: String, CaseIterable, Identifiable {
    case marketplace = "商品撮影"
    case nail = "ネイル"
    case food = "料理"
    case storeAd = "店舗広告"
    case snsIcon = "SNSアイコン"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .marketplace:
            AppText.pick(ja: "商品撮影", en: "Product Listing")
        case .nail:
            AppText.pick(ja: "ネイル", en: "Nails")
        case .food:
            AppText.pick(ja: "料理", en: "Food")
        case .storeAd:
            AppText.pick(ja: "店舗広告", en: "Store Ad")
        case .snsIcon:
            AppText.pick(ja: "SNSアイコン", en: "Profile")
        }
    }

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
                primaryGuide: AppText.pick(ja: "商品を中央に置いてください", en: "Place the product in the center"),
                secondaryGuide: AppText.pick(ja: "背景をシンプルに。影は少なめ。", en: "Keep the background simple and shadows soft."),
                exposurePriority: .product,
                ispPreset: .product,
                checklist: AppText.isJapanese ? ["中央", "明るい", "正方形", "背景整理"] : ["Centered", "Bright", "Square", "Clean background"]
            )
        case .nail:
            return PurposeProGuide(
                preset: preset,
                targetAspect: "4:5",
                primaryGuide: AppText.pick(ja: "爪先にピントを合わせます", en: "Focus on the nail tips"),
                secondaryGuide: AppText.pick(ja: "手を少し斜めに。反射は抑えめ。", en: "Angle the hand slightly and reduce glare."),
                exposurePriority: .product,
                ispPreset: .portrait,
                checklist: AppText.isJapanese ? ["爪先ピント", "肌色自然", "反射少なめ", "手の角度"] : ["Nail focus", "Natural skin", "Low glare", "Hand angle"]
            )
        case .food:
            return PurposeProGuide(
                preset: preset,
                targetAspect: "4:5",
                primaryGuide: AppText.pick(ja: "斜め45度から狙いましょう", en: "Shoot from a 45-degree angle"),
                secondaryGuide: AppText.pick(ja: "皿の白飛びを抑えて、ツヤを残します。", en: "Protect white plates while keeping shine."),
                exposurePriority: .skySafe,
                ispPreset: .food,
                checklist: AppText.isJapanese ? ["45度", "暖色", "皿を飛ばさない", "ツヤ"] : ["45 degrees", "Warm color", "Plate detail", "Shine"]
            )
        case .storeAd:
            return PurposeProGuide(
                preset: preset,
                targetAspect: "16:9",
                primaryGuide: AppText.pick(ja: "看板と入口を入れてください", en: "Include the sign and entrance"),
                secondaryGuide: AppText.pick(ja: "文字入れ用の余白を片側に残します。", en: "Leave space on one side for text."),
                exposurePriority: .document,
                ispPreset: .neutral,
                checklist: AppText.isJapanese ? ["入口", "看板", "清潔感", "余白"] : ["Entrance", "Sign", "Clean look", "Text space"]
            )
        case .snsIcon:
            return PurposeProGuide(
                preset: preset,
                targetAspect: "1:1",
                primaryGuide: AppText.pick(ja: "顔を明るく、中央少し上へ", en: "Keep the face bright and slightly high"),
                secondaryGuide: AppText.pick(ja: "丸型で切れても見える余白を残します。", en: "Leave safe space for circular crops."),
                exposurePriority: .face,
                ispPreset: .portrait,
                checklist: AppText.isJapanese ? ["顔明るい", "目線", "背景ぼけ", "丸型余白"] : ["Bright face", "Eye line", "Soft background", "Crop space"]
            )
        }
    }

    func assess(highlightRatio: Double, shadowRatio: Double, shakeLevel: Double, horizonTilt: Double, bestShotScore: Double) -> PurposeProAssessment {
        var score = Int(bestShotScore * 100)
        var message = currentGuide.primaryGuide

        if shakeLevel > 0.18 {
            score -= 18
            message = AppText.pick(ja: "少し止まって撮りましょう", en: "Hold still before shooting")
        } else if abs(horizonTilt) > 0.10 {
            score -= 10
            message = AppText.pick(ja: "水平を少し直しましょう", en: "Level the camera slightly")
        } else if highlightRatio > highlightLimit(for: selectedPreset) {
            score -= 14
            message = highlightMessage(for: selectedPreset)
        } else if shadowRatio > shadowLimit(for: selectedPreset) {
            score -= 12
            message = AppText.pick(ja: "少し明るくしましょう", en: "Make it a little brighter")
        } else if score > 82 {
            message = AppText.pick(ja: "今が撮りどきです", en: "Now is a good moment")
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
            AppText.pick(ja: "皿が白飛びしています", en: "The plate is overexposed")
        case .nail:
            AppText.pick(ja: "爪の反射を少し抑えましょう", en: "Reduce nail glare slightly")
        case .marketplace:
            AppText.pick(ja: "商品が明るすぎます", en: "The product is too bright")
        case .storeAd:
            AppText.pick(ja: "看板の文字が飛びそうです", en: "The sign text may blow out")
        case .snsIcon:
            AppText.pick(ja: "顔の明るい部分を抑えます", en: "Reduce bright areas on the face")
        }
    }
}
