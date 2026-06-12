import Foundation

enum CameraMode: String, CaseIterable, Identifiable {
    case auto = "Auto"
    case customISP = "自前ISP"
    case aiDevelop = "AI現像"
    case semanticExposure = "意味露出"
    case purposePro = "目的別Pro"
    case motionSubject = "動体別処理"
    case privacyCheck = "投稿前チェック"
    case rawMaterial = "Pro素材"
    case manual = "Manual"
    case hdrBracket = "HDR"
    case nightStack = "Night"
    case depth = "Depth"
    case dual = "Dual"
    case sound = "音シャッター"
    case director = "カメラ監督"
    case zen = "Zen"
    case ghostAlign = "Ghost"
    case document = "Doc"
    case strongShake = "最強手ブレ"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .auto:
            "Auto"
        case .customISP:
            AppText.pick(ja: "自前ISP", en: "Custom ISP")
        case .aiDevelop:
            AppText.pick(ja: "AI現像", en: "AI Develop")
        case .semanticExposure:
            AppText.pick(ja: "意味露出", en: "Smart Exposure")
        case .purposePro:
            AppText.pick(ja: "目的別Pro", en: "Purpose Pro")
        case .motionSubject:
            AppText.pick(ja: "動体別処理", en: "Motion Split")
        case .privacyCheck:
            AppText.pick(ja: "投稿前チェック", en: "Privacy Check")
        case .rawMaterial:
            AppText.pick(ja: "Pro素材", en: "RAW Material")
        case .manual:
            "Manual"
        case .hdrBracket:
            "HDR"
        case .nightStack:
            "Night"
        case .depth:
            "Depth"
        case .dual:
            "Dual"
        case .sound:
            AppText.pick(ja: "音シャッター", en: "Sound Shot")
        case .director:
            AppText.pick(ja: "カメラ監督", en: "Director")
        case .zen:
            "Zen"
        case .ghostAlign:
            "Ghost"
        case .document:
            "Doc"
        case .strongShake:
            AppText.pick(ja: "最強手ブレ", en: "Stability")
        }
    }

    var caption: String {
        switch self {
        case .auto:
            AppText.pick(ja: "速く撮る", en: "Fast capture")
        case .customISP:
            AppText.pick(ja: "別カメラの絵", en: "Own color")
        case .aiDevelop:
            AppText.pick(ja: "被写体別補正", en: "Subject tuned")
        case .semanticExposure:
            AppText.pick(ja: "写したい物優先", en: "Target first")
        case .purposePro:
            AppText.pick(ja: "用途別プロ判断", en: "Use-case guide")
        case .motionSubject:
            AppText.pick(ja: "動く部分だけ補正", en: "Moving areas")
        case .privacyCheck:
            AppText.pick(ja: "写り込み警告", en: "Leak warning")
        case .rawMaterial:
            AppText.pick(ja: "RAW+JPEG保存", en: "RAW+JPEG")
        case .manual:
            AppText.pick(ja: "固定して撮る", en: "Lock values")
        case .hdrBracket:
            AppText.pick(ja: "逆光に強く", en: "Backlight")
        case .nightStack:
            AppText.pick(ja: "暗所を重ねる", en: "Low light")
        case .depth:
            AppText.pick(ja: "奥行き素材", en: "Depth data")
        case .dual:
            AppText.pick(ja: "前後同時", en: "Dual camera")
        case .sound:
            AppText.pick(ja: "声や音で撮る", en: "Voice trigger")
        case .director:
            AppText.pick(ja: "撮影指示", en: "Shot advice")
        case .zen:
            AppText.pick(ja: "通知も迷いも消す", en: "Clean screen")
        case .ghostAlign:
            AppText.pick(ja: "前の構図に重ねる", en: "Match framing")
        case .document:
            AppText.pick(ja: "文字をまっすぐ", en: "Straight text")
        case .strongShake:
            AppText.pick(ja: "揺れが止まる瞬間を狙う", en: "Steady moment")
        }
    }
}
