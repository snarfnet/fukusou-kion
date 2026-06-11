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
    case depth = "Depth"
    case dual = "Dual"
    case sound = "音シャッター"
    case director = "カメラ監督"
    case zen = "Zen"
    case ghostAlign = "Ghost"
    case document = "Doc"
    case strongShake = "最強手ブレ"

    var id: String { rawValue }

    var caption: String {
        switch self {
        case .auto:
            "速く撮る"
        case .customISP:
            "別カメラの絵"
        case .aiDevelop:
            "被写体別補正"
        case .semanticExposure:
            "写したい物優先"
        case .purposePro:
            "用途別プロ判断"
        case .motionSubject:
            "動く部分だけ補正"
        case .privacyCheck:
            "写り込み警告"
        case .rawMaterial:
            "RAW+JPEG保存"
        case .manual:
            "固定して撮る"
        case .hdrBracket:
            "逆光に強く"
        case .depth:
            "奥行き素材"
        case .dual:
            "前後同時"
        case .sound:
            "声や音で撮る"
        case .director:
            "撮影指示"
        case .zen:
            "通知も迷いも消す"
        case .ghostAlign:
            "前の構図に重ねる"
        case .document:
            "文字をまっすぐ"
        case .strongShake:
            "揺れが止まる瞬間を狙う"
        }
    }
}
