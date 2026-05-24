import CoreGraphics
import Foundation

enum MoriPack: String, CaseIterable, Identifiable {
    case free
    case morimoriPack1
    case morimoriPack2
    case seriousPack
    case yankeeDecoPack
    case bubbleDecoPack
    case kyunNekoPack
    case mofuUsaPack
    case koreanHairPack
    case himeMoriPack
    case hairArrangeGotsumoriPack
    case hairArrangeGotsumoriPack2
    case vividReptilePack
    case varietyPack
    case cabaretNailPack
    case emotionPack

    var id: String { rawValue }

    var title: String {
        switch self {
        case .free: "無料"
        case .morimoriPack1: "盛り盛りパック1"
        case .morimoriPack2: "盛り盛りパック2"
        case .seriousPack: "真面目パック"
        case .yankeeDecoPack: "ヤンキーデコパック"
        case .bubbleDecoPack: "昭和バブルデコパック"
        case .kyunNekoPack: "キュンネコパック"
        case .mofuUsaPack: "モフモフうさちゃんパック"
        case .koreanHairPack: "韓国ヘアパック"
        case .himeMoriPack: "姫盛りパック"
        case .hairArrangeGotsumoriPack: "ヘアアレごつ盛りパック"
        case .hairArrangeGotsumoriPack2: "ヘアアレごつ盛りパック2"
        case .vividReptilePack: "鮮やか爬虫類パック"
        case .varietyPack: "バラエティーパック"
        case .cabaretNailPack: "キャバ嬢ネイルパック"
        case .emotionPack: "感情パック"
        }
    }

    var productID: String? {
        switch self {
        case .free: nil
        case .morimoriPack1: "com.tokyonasu.morimoriphotomaker.pack1"
        case .morimoriPack2: "com.tokyonasu.morimoriphotomaker.pack2"
        case .seriousPack: "com.tokyonasu.morimoriphotomaker.serious"
        case .yankeeDecoPack: "com.tokyonasu.morimoriphotomaker.yankee.deco"
        case .bubbleDecoPack: "com.tokyonasu.morimoriphotomaker.bubble.deco"
        case .kyunNekoPack: "com.tokyonasu.morimoriphotomaker.kyun.neko"
        case .mofuUsaPack: "com.tokyonasu.morimoriphotomaker.mofu.usa"
        case .koreanHairPack: "com.tokyonasu.morimoriphotomaker.korean.hair"
        case .himeMoriPack: "com.tokyonasu.morimoriphotomaker.hime.mori"
        case .hairArrangeGotsumoriPack: "com.tokyonasu.morimoriphotomaker.hairarrange.gotsumori"
        case .hairArrangeGotsumoriPack2: "com.tokyonasu.morimoriphotomaker.hairarrange.gotsumori2"
        case .vividReptilePack: "com.tokyonasu.morimoriphotomaker.vivid.reptile"
        case .varietyPack: "com.tokyonasu.morimoriphotomaker.variety"
        case .cabaretNailPack: "com.tokyonasu.morimoriphotomaker.cabaret.nail"
        case .emotionPack: "com.tokyonasu.morimoriphotomaker.emotion"
        }
    }
}

enum MoriCategory: String, CaseIterable, Identifiable {
    case hair = "髪型"
    case hairAccessory = "髪飾り"
    case brows = "まゆげ"
    case shadow = "アイシャドウ"
    case blush = "チーク"
    case lipstick = "口紅"
    case lashes = "つけまつげ"
    case glasses = "メガネ"
    case earrings = "イヤリング"
    case nosePierce = "鼻ピアス"
    case nail = "ネイル"
    case background = "フレーム"
    case animatedBackground = "アニメ背景"
    case parts = "アイテム"
    case plush = "ぬいぐるみ"
    case emotion = "感情"

    var id: String { rawValue }
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
    let pack: MoriPack
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
    static let assets: [MoriAsset] = freeAssets + paidAssets

    private static let freeAssets: [MoriAsset] = [
        MoriAsset(id: "blush-candy-sparkle", name: "キャンディチーク", category: .blush, filename: "blush-candy-sparkle.png", defaultWidth: 0.42, defaultPosition: CGPoint(x: 0.50, y: 0.55), defaultZ: 44, isBackground: false, pack: .free),
        MoriAsset(id: "blush-coral-stripe", name: "コーラル斜線", category: .blush, filename: "blush-coral-stripe.png", defaultWidth: 0.42, defaultPosition: CGPoint(x: 0.50, y: 0.55), defaultZ: 44, isBackground: false, pack: .free),
        MoriAsset(id: "blush-gold-freckles", name: "金そばかす", category: .blush, filename: "blush-gold-freckles.png", defaultWidth: 0.42, defaultPosition: CGPoint(x: 0.50, y: 0.55), defaultZ: 44, isBackground: false, pack: .free),
        MoriAsset(id: "blush-heart-stamp", name: "ハートチーク", category: .blush, filename: "blush-heart-stamp.png", defaultWidth: 0.42, defaultPosition: CGPoint(x: 0.50, y: 0.55), defaultZ: 44, isBackground: false, pack: .free),
        MoriAsset(id: "blush-purple-star", name: "紫スター", category: .blush, filename: "blush-purple-star.png", defaultWidth: 0.42, defaultPosition: CGPoint(x: 0.50, y: 0.55), defaultZ: 44, isBackground: false, pack: .free),
        MoriAsset(id: "brows-arch", name: "強めまゆ", category: .brows, filename: "brows-arch.png", defaultWidth: 0.34, defaultPosition: CGPoint(x: 0.50, y: 0.37), defaultZ: 45, isBackground: false, pack: .free),
        MoriAsset(id: "brows-caramel-fluffy", name: "キャラメル太まゆ", category: .brows, filename: "brows-caramel-fluffy.png", defaultWidth: 0.34, defaultPosition: CGPoint(x: 0.50, y: 0.37), defaultZ: 45, isBackground: false, pack: .free),
        MoriAsset(id: "brows-gold-lightning", name: "金イナズマ", category: .brows, filename: "brows-gold-lightning.png", defaultWidth: 0.34, defaultPosition: CGPoint(x: 0.50, y: 0.37), defaultZ: 45, isBackground: false, pack: .free),
        MoriAsset(id: "brows-pink-heart", name: "ピンクハート", category: .brows, filename: "brows-pink-heart.png", defaultWidth: 0.34, defaultPosition: CGPoint(x: 0.50, y: 0.37), defaultZ: 45, isBackground: false, pack: .free),
        MoriAsset(id: "brows-purple-moon", name: "紫ムーン", category: .brows, filename: "brows-purple-moon.png", defaultWidth: 0.34, defaultPosition: CGPoint(x: 0.50, y: 0.37), defaultZ: 45, isBackground: false, pack: .free),
        MoriAsset(id: "brows-villain-arch", name: "悪役アーチ", category: .brows, filename: "brows-villain-arch.png", defaultWidth: 0.34, defaultPosition: CGPoint(x: 0.50, y: 0.37), defaultZ: 45, isBackground: false, pack: .free),
        MoriAsset(id: "burst-frame", name: "派手フレーム", category: .background, filename: "burst-frame.png", defaultWidth: 1.00, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 12, isBackground: false, pack: .free),
        MoriAsset(id: "burst-leopard-lightning", name: "ヒョウ柄ピカ盛り", category: .parts, filename: "burst-leopard-lightning.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .free),
        MoriAsset(id: "earrings-gothic-cross", name: "ゴシック十字", category: .earrings, filename: "earrings-gothic-cross.png", defaultWidth: 0.54, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 42, isBackground: false, pack: .free),
        MoriAsset(id: "earrings-heart-chandelier", name: "ハートシャンデリア", category: .earrings, filename: "earrings-heart-chandelier.png", defaultWidth: 0.54, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 42, isBackground: false, pack: .free),
        MoriAsset(id: "earrings-neon-hoop", name: "ネオンフープ", category: .earrings, filename: "earrings-neon-hoop.png", defaultWidth: 0.54, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 42, isBackground: false, pack: .free),
        MoriAsset(id: "emotion-anger-mark", name: "怒りマーク", category: .emotion, filename: "emotion_anger_mark.png", defaultWidth: 0.26, defaultPosition: CGPoint(x: 0.30, y: 0.25), defaultZ: 70, isBackground: false, pack: .free),
        MoriAsset(id: "emotion-sweat-surprise", name: "びっくり汗", category: .emotion, filename: "emotion_sweat_surprise.png", defaultWidth: 0.26, defaultPosition: CGPoint(x: 0.30, y: 0.25), defaultZ: 70, isBackground: false, pack: .free),
        MoriAsset(id: "emotion-tears-blue", name: "涙ブルー", category: .emotion, filename: "emotion_tears_blue.png", defaultWidth: 0.26, defaultPosition: CGPoint(x: 0.30, y: 0.25), defaultZ: 70, isBackground: false, pack: .free),
        MoriAsset(id: "eyes-cat-glitter", name: "猫目ラメ", category: .parts, filename: "eyes-cat-glitter.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .free),
        MoriAsset(id: "glasses-black-cateye", name: "黒キャットアイ", category: .glasses, filename: "glasses-black-cateye.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 58, isBackground: false, pack: .free),
        MoriAsset(id: "glasses-heart-rhinestone", name: "ハートデカメガネ", category: .glasses, filename: "glasses-heart-rhinestone.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 58, isBackground: false, pack: .free),
        MoriAsset(id: "glasses-star-holo", name: "星ホロメガネ", category: .glasses, filename: "glasses-star-holo.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 58, isBackground: false, pack: .free),
        MoriAsset(id: "hair-fire-lion", name: "炎ライオン", category: .hair, filename: "hair-fire-lion.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .free),
        MoriAsset(id: "hair-glam", name: "盛り髪", category: .hair, filename: "hair-glam.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .free),
        MoriAsset(id: "hair-gothic-drill", name: "ゴシックドリル", category: .hair, filename: "hair-gothic-drill.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .free),
        MoriAsset(id: "hair-neon-twintails", name: "ネオンツイン", category: .hair, filename: "hair-neon-twintails.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .free),
        MoriAsset(id: "hair-rainbow-puffs", name: "虹ふわパフ", category: .hair, filename: "hair-rainbow-puffs.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .free),
        MoriAsset(id: "hair-silver-hime", name: "銀姫カット", category: .hair, filename: "hair-silver-hime.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .free),
        MoriAsset(id: "halo-sparkle", name: "キラ盛り", category: .background, filename: "halo-sparkle.png", defaultWidth: 1.00, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 12, isBackground: false, pack: .free),
        MoriAsset(id: "item-heart-mirror", name: "ハートミラー", category: .parts, filename: "item_heart_mirror.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .free),
        MoriAsset(id: "item-meerkat-plush", name: "ミーアキャットぬいぐるみ", category: .plush, filename: "item_meerkat_plush.png", defaultWidth: 0.36, defaultPosition: CGPoint(x: 0.26, y: 0.72), defaultZ: 62, isBackground: false, pack: .free),
        MoriAsset(id: "item-strawberry-parfait", name: "いちごパフェ", category: .parts, filename: "item_strawberry_parfait.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .free),
        MoriAsset(id: "kirakira-max-bg", name: "キラキラMAX", category: .animatedBackground, filename: "kirakira-max-bg.gif", defaultWidth: 1.00, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 1, isBackground: true, pack: .free),
        MoriAsset(id: "kirakira-pop-bg", name: "ポップきらめき", category: .animatedBackground, filename: "kirakira-pop-bg.gif", defaultWidth: 1.00, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 1, isBackground: true, pack: .free),
        MoriAsset(id: "lips-gloss", name: "ぷるグロス", category: .lipstick, filename: "lips-gloss.png", defaultWidth: 0.24, defaultPosition: CGPoint(x: 0.50, y: 0.59), defaultZ: 47, isBackground: false, pack: .free),
        MoriAsset(id: "lipstick-black-chrome", name: "黒クローム", category: .lipstick, filename: "lipstick-black-chrome.png", defaultWidth: 0.24, defaultPosition: CGPoint(x: 0.50, y: 0.59), defaultZ: 47, isBackground: false, pack: .free),
        MoriAsset(id: "lipstick-gold-foil", name: "金箔リップ", category: .lipstick, filename: "lipstick-gold-foil.png", defaultWidth: 0.24, defaultPosition: CGPoint(x: 0.50, y: 0.59), defaultZ: 47, isBackground: false, pack: .free),
        MoriAsset(id: "lipstick-icy-blue", name: "氷ブルー", category: .lipstick, filename: "lipstick-icy-blue.png", defaultWidth: 0.24, defaultPosition: CGPoint(x: 0.50, y: 0.59), defaultZ: 47, isBackground: false, pack: .free),
        MoriAsset(id: "lipstick-neon-fuchsia", name: "ネオンピンク", category: .lipstick, filename: "lipstick-neon-fuchsia.png", defaultWidth: 0.24, defaultPosition: CGPoint(x: 0.50, y: 0.59), defaultZ: 47, isBackground: false, pack: .free),
        MoriAsset(id: "lipstick-red-heart", name: "赤ハート", category: .lipstick, filename: "lipstick-red-heart.png", defaultWidth: 0.24, defaultPosition: CGPoint(x: 0.50, y: 0.59), defaultZ: 47, isBackground: false, pack: .free),
        MoriAsset(id: "nail-lavender-holo-star", name: "ラベンダーネイル", category: .nail, filename: "nail_lavender_holo_star.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .free),
        MoriAsset(id: "nail-pink-heart-pearl", name: "ピンクハートネイル", category: .nail, filename: "nail_pink_heart_pearl.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .free),
        MoriAsset(id: "nail-red-black-gold", name: "赤黒ゴールドネイル", category: .nail, filename: "nail_red_black_gold.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .free),
        MoriAsset(id: "nose-pierce-diamond-stud", name: "ダイヤ鼻ピ", category: .nosePierce, filename: "nose-pierce-diamond-stud.png", defaultWidth: 0.14, defaultPosition: CGPoint(x: 0.52, y: 0.51), defaultZ: 59, isBackground: false, pack: .free),
        MoriAsset(id: "nose-pierce-mix-set", name: "鼻ピアスセット", category: .nosePierce, filename: "nose-pierce-mix-set.png", defaultWidth: 0.14, defaultPosition: CGPoint(x: 0.52, y: 0.51), defaultZ: 59, isBackground: false, pack: .free),
        MoriAsset(id: "nose-pierce-septum-pink", name: "ピンクセプタム", category: .nosePierce, filename: "nose-pierce-septum-pink.png", defaultWidth: 0.14, defaultPosition: CGPoint(x: 0.52, y: 0.51), defaultZ: 59, isBackground: false, pack: .free),
        MoriAsset(id: "shadow-blue-lightning", name: "青イナズマ", category: .shadow, filename: "shadow-blue-lightning.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 46, isBackground: false, pack: .free),
        MoriAsset(id: "shadow-gothic-crystal", name: "黒赤クリスタル", category: .shadow, filename: "shadow-gothic-crystal.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 46, isBackground: false, pack: .free),
        MoriAsset(id: "shadow-pink-pearl", name: "ピンク真珠", category: .shadow, filename: "shadow-pink-pearl.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 46, isBackground: false, pack: .free),
        MoriAsset(id: "shadow-rainbow-prism", name: "虹プリズム", category: .shadow, filename: "shadow-rainbow-prism.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 46, isBackground: false, pack: .free),
        MoriAsset(id: "shadow-sunset-butterfly", name: "夕焼け蝶", category: .shadow, filename: "shadow-sunset-butterfly.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 46, isBackground: false, pack: .free),
        MoriAsset(id: "hair-accessory-sparkle", name: "キラ髪飾り", category: .hairAccessory, filename: "halo-sparkle.png", defaultWidth: 0.58, defaultPosition: CGPoint(x: 0.50, y: 0.28), defaultZ: 61, isBackground: false, pack: .free),
        MoriAsset(id: "hair-accessory-heart", name: "ハート髪ピン", category: .hairAccessory, filename: "earrings-heart-chandelier.png", defaultWidth: 0.35, defaultPosition: CGPoint(x: 0.35, y: 0.32), defaultZ: 61, isBackground: false, pack: .free),
        MoriAsset(id: "hair-accessory-star", name: "星ヘア飾り", category: .hairAccessory, filename: "glasses-star-holo.png", defaultWidth: 0.30, defaultPosition: CGPoint(x: 0.65, y: 0.31), defaultZ: 61, isBackground: false, pack: .free)
    ]

    private static let paidAssets: [MoriAsset] = [
        MoriAsset(id: "pack1_hair_rose_wave", name: "ローズウェーブ", category: .hair, filename: "pack1_hair_rose_wave.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .morimoriPack1),
        MoriAsset(id: "pack1_hair_caramel_halfup", name: "キャラメルハーフアップ", category: .hair, filename: "pack1_hair_caramel_halfup.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .morimoriPack1),
        MoriAsset(id: "pack1_hair_black_ribbon_twin", name: "黒リボンツイン", category: .hair, filename: "pack1_hair_black_ribbon_twin.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .morimoriPack1),
        MoriAsset(id: "pack1_hair_milk_tea_bob", name: "ミルクティーボブ", category: .hair, filename: "pack1_hair_milk_tea_bob.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .morimoriPack1),
        MoriAsset(id: "pack1_hair_party_up", name: "夜会アップ", category: .hair, filename: "pack1_hair_party_up.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .morimoriPack1),
        MoriAsset(id: "pack1_brows_soft_arch", name: "ふんわりアーチ", category: .brows, filename: "pack1_brows_soft_arch.png", defaultWidth: 0.34, defaultPosition: CGPoint(x: 0.50, y: 0.37), defaultZ: 45, isBackground: false, pack: .morimoriPack1),
        MoriAsset(id: "pack1_brows_glitter_gold", name: "金ラメ眉", category: .brows, filename: "pack1_brows_glitter_gold.png", defaultWidth: 0.34, defaultPosition: CGPoint(x: 0.50, y: 0.37), defaultZ: 45, isBackground: false, pack: .morimoriPack1),
        MoriAsset(id: "pack1_shadow_sakura_lame", name: "桜ラメシャドウ", category: .shadow, filename: "pack1_shadow_sakura_lame.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 46, isBackground: false, pack: .morimoriPack1),
        MoriAsset(id: "pack1_shadow_brown_smoky", name: "ブラウン盛り", category: .shadow, filename: "pack1_shadow_brown_smoky.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 46, isBackground: false, pack: .morimoriPack1),
        MoriAsset(id: "pack1_shadow_purple_cat", name: "紫キャット", category: .shadow, filename: "pack1_shadow_purple_cat.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 46, isBackground: false, pack: .morimoriPack1),
        MoriAsset(id: "pack1_blush_peach_heart", name: "桃ハート頬", category: .blush, filename: "pack1_blush_peach_heart.png", defaultWidth: 0.42, defaultPosition: CGPoint(x: 0.50, y: 0.55), defaultZ: 44, isBackground: false, pack: .morimoriPack1),
        MoriAsset(id: "pack1_blush_rhinestone", name: "ラインストーン頬", category: .blush, filename: "pack1_blush_rhinestone.png", defaultWidth: 0.42, defaultPosition: CGPoint(x: 0.50, y: 0.55), defaultZ: 44, isBackground: false, pack: .morimoriPack1),
        MoriAsset(id: "pack1_lip_coral_gloss", name: "コーラルぷるん", category: .lipstick, filename: "pack1_lip_coral_gloss.png", defaultWidth: 0.24, defaultPosition: CGPoint(x: 0.50, y: 0.59), defaultZ: 47, isBackground: false, pack: .morimoriPack1),
        MoriAsset(id: "pack1_lip_berry_gloss", name: "ベリーグロス", category: .lipstick, filename: "pack1_lip_berry_gloss.png", defaultWidth: 0.24, defaultPosition: CGPoint(x: 0.50, y: 0.59), defaultZ: 47, isBackground: false, pack: .morimoriPack1),
        MoriAsset(id: "pack1_glasses_pink_rim", name: "ピンク細フレーム", category: .glasses, filename: "pack1_glasses_pink_rim.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 58, isBackground: false, pack: .morimoriPack1),
        MoriAsset(id: "pack1_glasses_clear_heart", name: "透明ハートメガネ", category: .glasses, filename: "pack1_glasses_clear_heart.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 58, isBackground: false, pack: .morimoriPack1),
        MoriAsset(id: "pack1_earring_pearl_drop", name: "パールドロップ", category: .earrings, filename: "pack1_earring_pearl_drop.png", defaultWidth: 0.54, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 42, isBackground: false, pack: .morimoriPack1),
        MoriAsset(id: "pack1_earring_heart_chain", name: "ハートチェーン", category: .earrings, filename: "pack1_earring_heart_chain.png", defaultWidth: 0.54, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 42, isBackground: false, pack: .morimoriPack1),
        MoriAsset(id: "pack1_nose_pink_gem", name: "ピンク宝石鼻ピ", category: .nosePierce, filename: "pack1_nose_pink_gem.png", defaultWidth: 0.14, defaultPosition: CGPoint(x: 0.52, y: 0.51), defaultZ: 59, isBackground: false, pack: .morimoriPack1),
        MoriAsset(id: "pack1_frame_rose_pearl", name: "ローズパール枠", category: .background, filename: "pack1_frame_rose_pearl.png", defaultWidth: 1.00, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 12, isBackground: false, pack: .morimoriPack1),
        MoriAsset(id: "pack1_frame_lace_heart", name: "レースハート枠", category: .background, filename: "pack1_frame_lace_heart.png", defaultWidth: 1.00, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 12, isBackground: false, pack: .morimoriPack1),
        MoriAsset(id: "pack1_anim_pink_sparkle", name: "ピンク流れ星", category: .animatedBackground, filename: "pack1_anim_pink_sparkle.gif", defaultWidth: 1.00, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 1, isBackground: true, pack: .morimoriPack1),
        MoriAsset(id: "pack1_anim_heart_bokeh", name: "ハートぼかし", category: .animatedBackground, filename: "pack1_anim_heart_bokeh.gif", defaultWidth: 1.00, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 1, isBackground: true, pack: .morimoriPack1),
        MoriAsset(id: "pack1_part_tiara", name: "姫ティアラ", category: .hairAccessory, filename: "pack1_part_tiara.png", defaultWidth: 0.44, defaultPosition: CGPoint(x: 0.50, y: 0.27), defaultZ: 61, isBackground: false, pack: .morimoriPack1),
        MoriAsset(id: "pack1_part_ribbon_clip", name: "リボンクリップ", category: .hairAccessory, filename: "pack1_part_ribbon_clip.png", defaultWidth: 0.44, defaultPosition: CGPoint(x: 0.50, y: 0.27), defaultZ: 61, isBackground: false, pack: .morimoriPack1),
        MoriAsset(id: "pack1_part_perfume", name: "香水きらめき", category: .parts, filename: "pack1_part_perfume.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .morimoriPack1),
        MoriAsset(id: "pack1_part_heart_balloon", name: "ハートバルーン", category: .parts, filename: "pack1_part_heart_balloon.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .morimoriPack1),
        MoriAsset(id: "pack1_part_pearl_chain", name: "パールチェーン", category: .hairAccessory, filename: "pack1_part_pearl_chain.png", defaultWidth: 0.44, defaultPosition: CGPoint(x: 0.50, y: 0.27), defaultZ: 61, isBackground: false, pack: .morimoriPack1),
        MoriAsset(id: "pack1_part_glitter_tears", name: "きら涙", category: .parts, filename: "pack1_part_glitter_tears.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .morimoriPack1),
        MoriAsset(id: "pack1_part_star_sticker", name: "星ステッカー", category: .parts, filename: "pack1_part_star_sticker.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .morimoriPack1),
        MoriAsset(id: "pack1_lashes_doll_volume", name: "盛りドールつけま", category: .lashes, filename: "pack1_lashes_doll_volume.png", defaultWidth: 0.40, defaultPosition: CGPoint(x: 0.50, y: 0.42), defaultZ: 48, isBackground: false, pack: .morimoriPack1),
        MoriAsset(id: "pack1_lashes_pink_rhinestone", name: "ピンクきらつけま", category: .lashes, filename: "pack1_lashes_pink_rhinestone.png", defaultWidth: 0.40, defaultPosition: CGPoint(x: 0.50, y: 0.42), defaultZ: 48, isBackground: false, pack: .morimoriPack1),
        MoriAsset(id: "pack2_hair_ash_layer", name: "アッシュレイヤー", category: .hair, filename: "pack2_hair_ash_layer.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .morimoriPack2),
        MoriAsset(id: "pack2_hair_blue_black_long", name: "ブルーブラックロング", category: .hair, filename: "pack2_hair_blue_black_long.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .morimoriPack2),
        MoriAsset(id: "pack2_hair_hime_wolf", name: "姫ウルフ", category: .hair, filename: "pack2_hair_hime_wolf.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .morimoriPack2),
        MoriAsset(id: "pack2_hair_platinum_bob", name: "プラチナボブ", category: .hair, filename: "pack2_hair_platinum_bob.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .morimoriPack2),
        MoriAsset(id: "pack2_hair_high_pony", name: "高めポニー", category: .hair, filename: "pack2_hair_high_pony.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .morimoriPack2),
        MoriAsset(id: "pack2_brows_straight_k", name: "韓国ストレート眉", category: .brows, filename: "pack2_brows_straight_k.png", defaultWidth: 0.34, defaultPosition: CGPoint(x: 0.50, y: 0.37), defaultZ: 45, isBackground: false, pack: .morimoriPack2),
        MoriAsset(id: "pack2_brows_dark_mode", name: "黒強め眉", category: .brows, filename: "pack2_brows_dark_mode.png", defaultWidth: 0.34, defaultPosition: CGPoint(x: 0.50, y: 0.37), defaultZ: 45, isBackground: false, pack: .morimoriPack2),
        MoriAsset(id: "pack2_shadow_neon_blue", name: "ネオンブルー", category: .shadow, filename: "pack2_shadow_neon_blue.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 46, isBackground: false, pack: .morimoriPack2),
        MoriAsset(id: "pack2_shadow_silver_cut", name: "シルバー切開", category: .shadow, filename: "pack2_shadow_silver_cut.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 46, isBackground: false, pack: .morimoriPack2),
        MoriAsset(id: "pack2_shadow_devil_red", name: "小悪魔レッド", category: .shadow, filename: "pack2_shadow_devil_red.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 46, isBackground: false, pack: .morimoriPack2),
        MoriAsset(id: "pack2_blush_under_eye", name: "目下チーク", category: .blush, filename: "pack2_blush_under_eye.png", defaultWidth: 0.42, defaultPosition: CGPoint(x: 0.50, y: 0.55), defaultZ: 44, isBackground: false, pack: .morimoriPack2),
        MoriAsset(id: "pack2_blush_cool_pink", name: "青みピンク頬", category: .blush, filename: "pack2_blush_cool_pink.png", defaultWidth: 0.42, defaultPosition: CGPoint(x: 0.50, y: 0.55), defaultZ: 44, isBackground: false, pack: .morimoriPack2),
        MoriAsset(id: "pack2_lip_mauve", name: "モーヴリップ", category: .lipstick, filename: "pack2_lip_mauve.png", defaultWidth: 0.24, defaultPosition: CGPoint(x: 0.50, y: 0.59), defaultZ: 47, isBackground: false, pack: .morimoriPack2),
        MoriAsset(id: "pack2_lip_cherry_tint", name: "チェリーティント", category: .lipstick, filename: "pack2_lip_cherry_tint.png", defaultWidth: 0.24, defaultPosition: CGPoint(x: 0.50, y: 0.59), defaultZ: 47, isBackground: false, pack: .morimoriPack2),
        MoriAsset(id: "pack2_glasses_silver_thin", name: "銀細メガネ", category: .glasses, filename: "pack2_glasses_silver_thin.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 58, isBackground: false, pack: .morimoriPack2),
        MoriAsset(id: "pack2_glasses_y2k_shield", name: "Y2Kシールド", category: .glasses, filename: "pack2_glasses_y2k_shield.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 58, isBackground: false, pack: .morimoriPack2),
        MoriAsset(id: "pack2_earring_chrome_hoop", name: "クロームフープ", category: .earrings, filename: "pack2_earring_chrome_hoop.png", defaultWidth: 0.54, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 42, isBackground: false, pack: .morimoriPack2),
        MoriAsset(id: "pack2_earring_black_heart", name: "黒ハートピアス", category: .earrings, filename: "pack2_earring_black_heart.png", defaultWidth: 0.54, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 42, isBackground: false, pack: .morimoriPack2),
        MoriAsset(id: "pack2_nose_chain", name: "鼻チェーン", category: .nosePierce, filename: "pack2_nose_chain.png", defaultWidth: 0.14, defaultPosition: CGPoint(x: 0.52, y: 0.51), defaultZ: 59, isBackground: false, pack: .morimoriPack2),
        MoriAsset(id: "pack2_frame_neon_city", name: "ネオンシティ枠", category: .background, filename: "pack2_frame_neon_city.png", defaultWidth: 1.00, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 12, isBackground: false, pack: .morimoriPack2),
        MoriAsset(id: "pack2_frame_chrome_stars", name: "クロームスター枠", category: .background, filename: "pack2_frame_chrome_stars.png", defaultWidth: 1.00, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 12, isBackground: false, pack: .morimoriPack2),
        MoriAsset(id: "pack2_anim_neon_rain", name: "ネオン雨", category: .animatedBackground, filename: "pack2_anim_neon_rain.gif", defaultWidth: 1.00, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 1, isBackground: true, pack: .morimoriPack2),
        MoriAsset(id: "pack2_anim_chrome_flash", name: "クローム閃光", category: .animatedBackground, filename: "pack2_anim_chrome_flash.gif", defaultWidth: 1.00, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 1, isBackground: true, pack: .morimoriPack2),
        MoriAsset(id: "pack2_part_cat_ears", name: "小悪魔猫耳", category: .hairAccessory, filename: "pack2_part_cat_ears.png", defaultWidth: 0.44, defaultPosition: CGPoint(x: 0.50, y: 0.27), defaultZ: 61, isBackground: false, pack: .morimoriPack2),
        MoriAsset(id: "pack2_part_black_ribbon", name: "黒リボン", category: .hairAccessory, filename: "pack2_part_black_ribbon.png", defaultWidth: 0.44, defaultPosition: CGPoint(x: 0.50, y: 0.27), defaultZ: 61, isBackground: false, pack: .morimoriPack2),
        MoriAsset(id: "pack2_part_chrome_crown", name: "クローム王冠", category: .hairAccessory, filename: "pack2_part_chrome_crown.png", defaultWidth: 0.44, defaultPosition: CGPoint(x: 0.50, y: 0.27), defaultZ: 61, isBackground: false, pack: .morimoriPack2),
        MoriAsset(id: "pack2_part_music_note", name: "音符きらめき", category: .parts, filename: "pack2_part_music_note.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .morimoriPack2),
        MoriAsset(id: "pack2_part_moon_charm", name: "月チャーム", category: .parts, filename: "pack2_part_moon_charm.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .morimoriPack2),
        MoriAsset(id: "pack2_part_glossy_stars", name: "ぷっくり星", category: .parts, filename: "pack2_part_glossy_stars.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .morimoriPack2),
        MoriAsset(id: "pack2_part_light_streak", name: "光ライン", category: .parts, filename: "pack2_part_light_streak.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .morimoriPack2),
        MoriAsset(id: "serious_hair_straight_long", name: "清楚ストレート", category: .hair, filename: "serious_hair_straight_long.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_hair_one_curl", name: "内巻きワンカール", category: .hair, filename: "serious_hair_one_curl.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_hair_layer_medium", name: "レイヤーミディアム", category: .hair, filename: "serious_hair_layer_medium.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_hair_short_bob", name: "ショートボブ", category: .hair, filename: "serious_hair_short_bob.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_hair_center_part", name: "センターパート", category: .hair, filename: "serious_hair_center_part.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_hair_low_pony", name: "低めポニー", category: .hair, filename: "serious_hair_low_pony.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_hair_halfup", name: "控えめハーフアップ", category: .hair, filename: "serious_hair_halfup.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_hair_natural_wolf", name: "ナチュラルウルフ", category: .hair, filename: "serious_hair_natural_wolf.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_hair_bang_sheer", name: "シースルーバング", category: .hair, filename: "serious_hair_bang_sheer.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_hair_no_bang", name: "前髪なしロング", category: .hair, filename: "serious_hair_no_bang.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_brows_natural", name: "自然眉", category: .brows, filename: "serious_brows_natural.png", defaultWidth: 0.34, defaultPosition: CGPoint(x: 0.50, y: 0.37), defaultZ: 45, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_brows_straight", name: "きちんと眉", category: .brows, filename: "serious_brows_straight.png", defaultWidth: 0.34, defaultPosition: CGPoint(x: 0.50, y: 0.37), defaultZ: 45, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_brows_soft", name: "やわらか眉", category: .brows, filename: "serious_brows_soft.png", defaultWidth: 0.34, defaultPosition: CGPoint(x: 0.50, y: 0.37), defaultZ: 45, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_shadow_beige", name: "ベージュシャドウ", category: .shadow, filename: "serious_shadow_beige.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 46, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_shadow_brown", name: "ブラウンシャドウ", category: .shadow, filename: "serious_shadow_brown.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 46, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_shadow_pink_brown", name: "ピンクブラウン", category: .shadow, filename: "serious_shadow_pink_brown.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 46, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_blush_natural", name: "自然チーク", category: .blush, filename: "serious_blush_natural.png", defaultWidth: 0.42, defaultPosition: CGPoint(x: 0.50, y: 0.55), defaultZ: 44, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_blush_soft_peach", name: "薄桃チーク", category: .blush, filename: "serious_blush_soft_peach.png", defaultWidth: 0.42, defaultPosition: CGPoint(x: 0.50, y: 0.55), defaultZ: 44, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_lip_nude_pink", name: "ヌードピンク", category: .lipstick, filename: "serious_lip_nude_pink.png", defaultWidth: 0.24, defaultPosition: CGPoint(x: 0.50, y: 0.59), defaultZ: 47, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_lip_calm_red", name: "落ち着きレッド", category: .lipstick, filename: "serious_lip_calm_red.png", defaultWidth: 0.24, defaultPosition: CGPoint(x: 0.50, y: 0.59), defaultZ: 47, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_glasses_round", name: "丸メガネ", category: .glasses, filename: "serious_glasses_round.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 58, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_glasses_square", name: "スクエアメガネ", category: .glasses, filename: "serious_glasses_square.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 58, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_glasses_brown", name: "ブラウン細メガネ", category: .glasses, filename: "serious_glasses_brown.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 58, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_background_library", name: "図書館背景", category: .background, filename: "serious_background_library.png", defaultWidth: 1.00, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 12, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_background_greenery", name: "自然光グリーン背景", category: .background, filename: "serious_background_greenery.png", defaultWidth: 1.00, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 12, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_background_office", name: "明るいオフィス", category: .background, filename: "serious_background_office.png", defaultWidth: 1.00, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 12, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_background_white", name: "白背景", category: .background, filename: "serious_background_white.png", defaultWidth: 1.00, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 12, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_background_beige", name: "ベージュ背景", category: .background, filename: "serious_background_beige.png", defaultWidth: 1.00, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 12, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_background_school", name: "教室背景", category: .background, filename: "serious_background_school.png", defaultWidth: 1.00, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 12, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_background_cafe", name: "カフェ背景", category: .background, filename: "serious_background_cafe.png", defaultWidth: 1.00, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 12, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_frame_simple_white", name: "白シンプル枠", category: .background, filename: "serious_frame_simple_white.png", defaultWidth: 1.00, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 12, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_frame_soft_pink", name: "薄桃シンプル枠", category: .background, filename: "serious_frame_soft_pink.png", defaultWidth: 1.00, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 12, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_part_hairpin", name: "細ヘアピン", category: .hairAccessory, filename: "serious_part_hairpin.png", defaultWidth: 0.44, defaultPosition: CGPoint(x: 0.50, y: 0.27), defaultZ: 61, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_part_small_ribbon", name: "小リボン", category: .hairAccessory, filename: "serious_part_small_ribbon.png", defaultWidth: 0.44, defaultPosition: CGPoint(x: 0.50, y: 0.27), defaultZ: 61, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_part_light", name: "自然光", category: .parts, filename: "serious_part_light.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_part_soft_sparkle", name: "控えめきらめき", category: .parts, filename: "serious_part_soft_sparkle.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_part_name_plate", name: "名札風プレート", category: .parts, filename: "serious_part_name_plate.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_part_flower", name: "小花", category: .parts, filename: "serious_part_flower.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_part_book", name: "本アイコン", category: .parts, filename: "serious_part_book.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_part_laptop", name: "PCアイコン", category: .parts, filename: "serious_part_laptop.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_part_pencil", name: "ペンアイコン", category: .parts, filename: "serious_part_pencil.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_part_cardigan", name: "肩掛け風", category: .parts, filename: "serious_part_cardigan.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_part_soft_shadow", name: "自然影", category: .parts, filename: "serious_part_soft_shadow.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_part_eye_light", name: "瞳ハイライト", category: .parts, filename: "serious_part_eye_light.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_part_skin_glow", name: "肌つや", category: .parts, filename: "serious_part_skin_glow.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_part_clean_filter", name: "清潔感フィルター", category: .parts, filename: "serious_part_clean_filter.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_part_resume_frame", name: "証明写真風枠", category: .background, filename: "serious_part_resume_frame.png", defaultWidth: 1.00, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 12, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_part_school_ribbon", name: "制服リボン", category: .hairAccessory, filename: "serious_part_school_ribbon.png", defaultWidth: 0.44, defaultPosition: CGPoint(x: 0.50, y: 0.27), defaultZ: 61, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_part_simple_tiara", name: "控えめティアラ", category: .hairAccessory, filename: "serious_part_simple_tiara.png", defaultWidth: 0.44, defaultPosition: CGPoint(x: 0.50, y: 0.27), defaultZ: 61, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_part_glass_reflection", name: "メガネ反射", category: .parts, filename: "serious_part_glass_reflection.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_lashes_natural_office", name: "自然オフィスつけま", category: .lashes, filename: "serious_lashes_natural_office.png", defaultWidth: 0.40, defaultPosition: CGPoint(x: 0.50, y: 0.42), defaultZ: 48, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "serious_lashes_brown_half", name: "ブラウン半つけま", category: .lashes, filename: "serious_lashes_brown_half.png", defaultWidth: 0.40, defaultPosition: CGPoint(x: 0.50, y: 0.42), defaultZ: 48, isBackground: false, pack: .seriousPack),
        MoriAsset(id: "yankee_hair_blonde_suji", name: "金髪スジ盛り", category: .hair, filename: "yankee_hair_blonde_suji.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .yankeeDecoPack),
        MoriAsset(id: "yankee_hair_black_pompadour", name: "黒髪リーゼント", category: .hair, filename: "yankee_hair_black_pompadour.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .yankeeDecoPack),
        MoriAsset(id: "yankee_hair_mesha_long", name: "メッシュロング", category: .hair, filename: "yankee_hair_mesha_long.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .yankeeDecoPack),
        MoriAsset(id: "yankee_hair_high_side_pony", name: "高めサイドポニー", category: .hair, filename: "yankee_hair_high_side_pony.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .yankeeDecoPack),
        MoriAsset(id: "yankee_hair_short_wolf", name: "強めウルフ", category: .hair, filename: "yankee_hair_short_wolf.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .yankeeDecoPack),
        MoriAsset(id: "yankee_hair_accessory_sunglass_head", name: "頭サングラス", category: .hairAccessory, filename: "yankee_hair_accessory_sunglass_head.png", defaultWidth: 0.44, defaultPosition: CGPoint(x: 0.50, y: 0.27), defaultZ: 61, isBackground: false, pack: .yankeeDecoPack),
        MoriAsset(id: "yankee_hair_accessory_gold_pin", name: "金ピンセット", category: .hairAccessory, filename: "yankee_hair_accessory_gold_pin.png", defaultWidth: 0.44, defaultPosition: CGPoint(x: 0.50, y: 0.27), defaultZ: 61, isBackground: false, pack: .yankeeDecoPack),
        MoriAsset(id: "yankee_brows_sharp", name: "剃り込み眉", category: .brows, filename: "yankee_brows_sharp.png", defaultWidth: 0.34, defaultPosition: CGPoint(x: 0.50, y: 0.37), defaultZ: 45, isBackground: false, pack: .yankeeDecoPack),
        MoriAsset(id: "yankee_brows_thin_arch", name: "細つり眉", category: .brows, filename: "yankee_brows_thin_arch.png", defaultWidth: 0.34, defaultPosition: CGPoint(x: 0.50, y: 0.37), defaultZ: 45, isBackground: false, pack: .yankeeDecoPack),
        MoriAsset(id: "yankee_shadow_black_gold", name: "黒金シャドウ", category: .shadow, filename: "yankee_shadow_black_gold.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 46, isBackground: false, pack: .yankeeDecoPack),
        MoriAsset(id: "yankee_shadow_red_flame", name: "赤炎シャドウ", category: .shadow, filename: "yankee_shadow_red_flame.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 46, isBackground: false, pack: .yankeeDecoPack),
        MoriAsset(id: "yankee_blush_tan", name: "日焼けチーク", category: .blush, filename: "yankee_blush_tan.png", defaultWidth: 0.42, defaultPosition: CGPoint(x: 0.50, y: 0.55), defaultZ: 44, isBackground: false, pack: .yankeeDecoPack),
        MoriAsset(id: "yankee_blush_star_stamp", name: "星スタンプ頬", category: .blush, filename: "yankee_blush_star_stamp.png", defaultWidth: 0.42, defaultPosition: CGPoint(x: 0.50, y: 0.55), defaultZ: 44, isBackground: false, pack: .yankeeDecoPack),
        MoriAsset(id: "yankee_lip_deep_red", name: "深紅リップ", category: .lipstick, filename: "yankee_lip_deep_red.png", defaultWidth: 0.24, defaultPosition: CGPoint(x: 0.50, y: 0.59), defaultZ: 47, isBackground: false, pack: .yankeeDecoPack),
        MoriAsset(id: "yankee_lip_nude_gloss", name: "ヌーディグロス", category: .lipstick, filename: "yankee_lip_nude_gloss.png", defaultWidth: 0.24, defaultPosition: CGPoint(x: 0.50, y: 0.59), defaultZ: 47, isBackground: false, pack: .yankeeDecoPack),
        MoriAsset(id: "yankee_glasses_gold_sunglasses", name: "金縁サングラス", category: .glasses, filename: "yankee_glasses_gold_sunglasses.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 58, isBackground: false, pack: .yankeeDecoPack),
        MoriAsset(id: "yankee_glasses_clear_yellow", name: "黄クリアメガネ", category: .glasses, filename: "yankee_glasses_clear_yellow.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 58, isBackground: false, pack: .yankeeDecoPack),
        MoriAsset(id: "yankee_earring_gold_hoop", name: "金フープ", category: .earrings, filename: "yankee_earring_gold_hoop.png", defaultWidth: 0.54, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 42, isBackground: false, pack: .yankeeDecoPack),
        MoriAsset(id: "yankee_earring_chain_cross", name: "十字チェーン", category: .earrings, filename: "yankee_earring_chain_cross.png", defaultWidth: 0.54, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 42, isBackground: false, pack: .yankeeDecoPack),
        MoriAsset(id: "yankee_nose_gold_stud", name: "金鼻ピ", category: .nosePierce, filename: "yankee_nose_gold_stud.png", defaultWidth: 0.14, defaultPosition: CGPoint(x: 0.52, y: 0.51), defaultZ: 59, isBackground: false, pack: .yankeeDecoPack),
        MoriAsset(id: "yankee_frame_leopard_gold", name: "豹柄ゴールド枠", category: .background, filename: "yankee_frame_leopard_gold.png", defaultWidth: 1.00, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 12, isBackground: false, pack: .yankeeDecoPack),
        MoriAsset(id: "yankee_frame_deco_truck", name: "デコトラ枠", category: .background, filename: "yankee_frame_deco_truck.png", defaultWidth: 1.00, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 12, isBackground: false, pack: .yankeeDecoPack),
        MoriAsset(id: "yankee_anim_neon_fire", name: "ネオン炎", category: .animatedBackground, filename: "yankee_anim_neon_fire.gif", defaultWidth: 1.00, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 1, isBackground: true, pack: .yankeeDecoPack),
        MoriAsset(id: "yankee_anim_gold_flash", name: "金フラッシュ", category: .animatedBackground, filename: "yankee_anim_gold_flash.gif", defaultWidth: 1.00, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 1, isBackground: true, pack: .yankeeDecoPack),
        MoriAsset(id: "yankee_part_gold_chain", name: "金チェーン", category: .parts, filename: "yankee_part_gold_chain.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .yankeeDecoPack),
        MoriAsset(id: "yankee_part_smoke", name: "スモーク", category: .parts, filename: "yankee_part_smoke.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .yankeeDecoPack),
        MoriAsset(id: "yankee_part_flame_sticker", name: "炎ステッカー", category: .parts, filename: "yankee_part_flame_sticker.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .yankeeDecoPack),
        MoriAsset(id: "yankee_part_kira_text", name: "夜露死苦プレート", category: .parts, filename: "yankee_part_kira_text.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .yankeeDecoPack),
        MoriAsset(id: "yankee_part_tiger", name: "虎ステッカー", category: .parts, filename: "yankee_part_tiger.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .yankeeDecoPack),
        MoriAsset(id: "yankee_part_chrome_heart", name: "クロームハート", category: .parts, filename: "yankee_part_chrome_heart.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .yankeeDecoPack),
        MoriAsset(id: "yankee_lashes_spiky_wing", name: "強めハネつけま", category: .lashes, filename: "yankee_lashes_spiky_wing.png", defaultWidth: 0.40, defaultPosition: CGPoint(x: 0.50, y: 0.42), defaultZ: 48, isBackground: false, pack: .yankeeDecoPack),
        MoriAsset(id: "yankee_lashes_black_gold", name: "黒金つけま", category: .lashes, filename: "yankee_lashes_black_gold.png", defaultWidth: 0.40, defaultPosition: CGPoint(x: 0.50, y: 0.42), defaultZ: 48, isBackground: false, pack: .yankeeDecoPack),
        MoriAsset(id: "bubble_hair_sotohane_long", name: "外ハネロング", category: .hair, filename: "bubble_hair_sotohane_long.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .bubbleDecoPack),
        MoriAsset(id: "bubble_hair_volume_perm", name: "ボリュームパーマ", category: .hair, filename: "bubble_hair_volume_perm.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .bubbleDecoPack),
        MoriAsset(id: "bubble_hair_one_length", name: "ワンレンロング", category: .hair, filename: "bubble_hair_one_length.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .bubbleDecoPack),
        MoriAsset(id: "bubble_hair_feather_bob", name: "フェザーボブ", category: .hair, filename: "bubble_hair_feather_bob.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .bubbleDecoPack),
        MoriAsset(id: "bubble_hair_party_up", name: "バブル夜会巻き", category: .hair, filename: "bubble_hair_party_up.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .bubbleDecoPack),
        MoriAsset(id: "bubble_hair_accessory_big_bow", name: "大きめサテンリボン", category: .hairAccessory, filename: "bubble_hair_accessory_big_bow.png", defaultWidth: 0.44, defaultPosition: CGPoint(x: 0.50, y: 0.27), defaultZ: 61, isBackground: false, pack: .bubbleDecoPack),
        MoriAsset(id: "bubble_hair_accessory_pearl_barrette", name: "真珠バレッタ", category: .hairAccessory, filename: "bubble_hair_accessory_pearl_barrette.png", defaultWidth: 0.44, defaultPosition: CGPoint(x: 0.50, y: 0.27), defaultZ: 61, isBackground: false, pack: .bubbleDecoPack),
        MoriAsset(id: "bubble_brows_bold_arch", name: "太アーチ眉", category: .brows, filename: "bubble_brows_bold_arch.png", defaultWidth: 0.34, defaultPosition: CGPoint(x: 0.50, y: 0.37), defaultZ: 45, isBackground: false, pack: .bubbleDecoPack),
        MoriAsset(id: "bubble_brows_soft_brown", name: "茶色ふと眉", category: .brows, filename: "bubble_brows_soft_brown.png", defaultWidth: 0.34, defaultPosition: CGPoint(x: 0.50, y: 0.37), defaultZ: 45, isBackground: false, pack: .bubbleDecoPack),
        MoriAsset(id: "bubble_shadow_blue_pearl", name: "ブルーパールシャドウ", category: .shadow, filename: "bubble_shadow_blue_pearl.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 46, isBackground: false, pack: .bubbleDecoPack),
        MoriAsset(id: "bubble_shadow_gold_brown", name: "金ブラウンシャドウ", category: .shadow, filename: "bubble_shadow_gold_brown.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 46, isBackground: false, pack: .bubbleDecoPack),
        MoriAsset(id: "bubble_blush_diagonal", name: "斜めチーク", category: .blush, filename: "bubble_blush_diagonal.png", defaultWidth: 0.42, defaultPosition: CGPoint(x: 0.50, y: 0.55), defaultZ: 44, isBackground: false, pack: .bubbleDecoPack),
        MoriAsset(id: "bubble_blush_rose", name: "ローズ頬", category: .blush, filename: "bubble_blush_rose.png", defaultWidth: 0.42, defaultPosition: CGPoint(x: 0.50, y: 0.55), defaultZ: 44, isBackground: false, pack: .bubbleDecoPack),
        MoriAsset(id: "bubble_lip_fuchsia", name: "フューシャリップ", category: .lipstick, filename: "bubble_lip_fuchsia.png", defaultWidth: 0.24, defaultPosition: CGPoint(x: 0.50, y: 0.59), defaultZ: 47, isBackground: false, pack: .bubbleDecoPack),
        MoriAsset(id: "bubble_lip_red_gloss", name: "赤グロス", category: .lipstick, filename: "bubble_lip_red_gloss.png", defaultWidth: 0.24, defaultPosition: CGPoint(x: 0.50, y: 0.59), defaultZ: 47, isBackground: false, pack: .bubbleDecoPack),
        MoriAsset(id: "bubble_glasses_gold_frame", name: "金縁メガネ", category: .glasses, filename: "bubble_glasses_gold_frame.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 58, isBackground: false, pack: .bubbleDecoPack),
        MoriAsset(id: "bubble_glasses_smoke_sunglasses", name: "スモークサングラス", category: .glasses, filename: "bubble_glasses_smoke_sunglasses.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 58, isBackground: false, pack: .bubbleDecoPack),
        MoriAsset(id: "bubble_earring_big_pearl", name: "大粒パール", category: .earrings, filename: "bubble_earring_big_pearl.png", defaultWidth: 0.54, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 42, isBackground: false, pack: .bubbleDecoPack),
        MoriAsset(id: "bubble_earring_gold_disc", name: "ゴールドディスク", category: .earrings, filename: "bubble_earring_gold_disc.png", defaultWidth: 0.54, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 42, isBackground: false, pack: .bubbleDecoPack),
        MoriAsset(id: "bubble_nose_tiny_diamond", name: "小粒ダイヤ鼻ピ", category: .nosePierce, filename: "bubble_nose_tiny_diamond.png", defaultWidth: 0.14, defaultPosition: CGPoint(x: 0.52, y: 0.51), defaultZ: 59, isBackground: false, pack: .bubbleDecoPack),
        MoriAsset(id: "bubble_frame_gold_city", name: "金夜景フレーム", category: .background, filename: "bubble_frame_gold_city.png", defaultWidth: 1.00, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 12, isBackground: false, pack: .bubbleDecoPack),
        MoriAsset(id: "bubble_frame_disco_mirror", name: "ディスコミラー枠", category: .background, filename: "bubble_frame_disco_mirror.png", defaultWidth: 1.00, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 12, isBackground: false, pack: .bubbleDecoPack),
        MoriAsset(id: "bubble_anim_mirror_ball", name: "ミラーボール", category: .animatedBackground, filename: "bubble_anim_mirror_ball.gif", defaultWidth: 1.00, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 1, isBackground: true, pack: .bubbleDecoPack),
        MoriAsset(id: "bubble_anim_city_sparkle", name: "夜景きらめき", category: .animatedBackground, filename: "bubble_anim_city_sparkle.gif", defaultWidth: 1.00, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 1, isBackground: true, pack: .bubbleDecoPack),
        MoriAsset(id: "bubble_part_fan", name: "扇子", category: .parts, filename: "bubble_part_fan.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .bubbleDecoPack),
        MoriAsset(id: "bubble_part_champagne", name: "シャンパン", category: .parts, filename: "bubble_part_champagne.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .bubbleDecoPack),
        MoriAsset(id: "bubble_part_gold_chain", name: "太ゴールドチェーン", category: .parts, filename: "bubble_part_gold_chain.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .bubbleDecoPack),
        MoriAsset(id: "bubble_part_pearl_necklace", name: "パールネックレス", category: .parts, filename: "bubble_part_pearl_necklace.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .bubbleDecoPack),
        MoriAsset(id: "bubble_part_money_confetti", name: "札束コンフェティ", category: .parts, filename: "bubble_part_money_confetti.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .bubbleDecoPack),
        MoriAsset(id: "bubble_part_neon_lip", name: "ネオンリップ", category: .parts, filename: "bubble_part_neon_lip.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .bubbleDecoPack),
        MoriAsset(id: "bubble_lashes_fan_glam", name: "バブル扇つけま", category: .lashes, filename: "bubble_lashes_fan_glam.png", defaultWidth: 0.40, defaultPosition: CGPoint(x: 0.50, y: 0.42), defaultZ: 48, isBackground: false, pack: .bubbleDecoPack),
        MoriAsset(id: "bubble_lashes_pearl_glam", name: "パール盛りつけま", category: .lashes, filename: "bubble_lashes_pearl_glam.png", defaultWidth: 0.40, defaultPosition: CGPoint(x: 0.50, y: 0.42), defaultZ: 48, isBackground: false, pack: .bubbleDecoPack),
        MoriAsset(id: "kyun_neko_plush_milk", name: "ミルクねこ", category: .plush, filename: "kyun_neko_plush_milk.png", defaultWidth: 0.36, defaultPosition: CGPoint(x: 0.26, y: 0.72), defaultZ: 62, isBackground: false, pack: .kyunNekoPack),
        MoriAsset(id: "kyun_neko_plush_sakura", name: "さくらねこ", category: .plush, filename: "kyun_neko_plush_sakura.png", defaultWidth: 0.36, defaultPosition: CGPoint(x: 0.26, y: 0.72), defaultZ: 62, isBackground: false, pack: .kyunNekoPack),
        MoriAsset(id: "kyun_neko_plush_calico", name: "みけねこ", category: .plush, filename: "kyun_neko_plush_calico.png", defaultWidth: 0.36, defaultPosition: CGPoint(x: 0.26, y: 0.72), defaultZ: 62, isBackground: false, pack: .kyunNekoPack),
        MoriAsset(id: "kyun_neko_plush_black", name: "くろねこ", category: .plush, filename: "kyun_neko_plush_black.png", defaultWidth: 0.36, defaultPosition: CGPoint(x: 0.26, y: 0.72), defaultZ: 62, isBackground: false, pack: .kyunNekoPack),
        MoriAsset(id: "kyun_neko_plush_ribbon", name: "リボンねこ", category: .plush, filename: "kyun_neko_plush_ribbon.png", defaultWidth: 0.36, defaultPosition: CGPoint(x: 0.26, y: 0.72), defaultZ: 62, isBackground: false, pack: .kyunNekoPack),
        MoriAsset(id: "kyun_neko_plush_sleepy", name: "ねむねこ", category: .plush, filename: "kyun_neko_plush_sleepy.png", defaultWidth: 0.36, defaultPosition: CGPoint(x: 0.26, y: 0.72), defaultZ: 62, isBackground: false, pack: .kyunNekoPack),
        MoriAsset(id: "kyun_neko_plush_angel", name: "天使ねこ", category: .plush, filename: "kyun_neko_plush_angel.png", defaultWidth: 0.36, defaultPosition: CGPoint(x: 0.26, y: 0.72), defaultZ: 62, isBackground: false, pack: .kyunNekoPack),
        MoriAsset(id: "kyun_neko_plush_strawberry", name: "いちごねこ", category: .plush, filename: "kyun_neko_plush_strawberry.png", defaultWidth: 0.36, defaultPosition: CGPoint(x: 0.26, y: 0.72), defaultZ: 62, isBackground: false, pack: .kyunNekoPack),
        MoriAsset(id: "kyun_neko_plush_star", name: "星ねこ", category: .plush, filename: "kyun_neko_plush_star.png", defaultWidth: 0.36, defaultPosition: CGPoint(x: 0.26, y: 0.72), defaultZ: 62, isBackground: false, pack: .kyunNekoPack),
        MoriAsset(id: "kyun_neko_plush_tiny", name: "ちびねこ", category: .plush, filename: "kyun_neko_plush_tiny.png", defaultWidth: 0.36, defaultPosition: CGPoint(x: 0.26, y: 0.72), defaultZ: 62, isBackground: false, pack: .kyunNekoPack),
        MoriAsset(id: "mofu_usa_plush_white", name: "しろうさ", category: .plush, filename: "mofu_usa_plush_white.png", defaultWidth: 0.36, defaultPosition: CGPoint(x: 0.26, y: 0.72), defaultZ: 62, isBackground: false, pack: .mofuUsaPack),
        MoriAsset(id: "mofu_usa_plush_pink", name: "ももいろうさ", category: .plush, filename: "mofu_usa_plush_pink.png", defaultWidth: 0.36, defaultPosition: CGPoint(x: 0.26, y: 0.72), defaultZ: 62, isBackground: false, pack: .mofuUsaPack),
        MoriAsset(id: "mofu_usa_plush_lop", name: "たれ耳うさ", category: .plush, filename: "mofu_usa_plush_lop.png", defaultWidth: 0.36, defaultPosition: CGPoint(x: 0.26, y: 0.72), defaultZ: 62, isBackground: false, pack: .mofuUsaPack),
        MoriAsset(id: "mofu_usa_plush_gray", name: "グレーうさ", category: .plush, filename: "mofu_usa_plush_gray.png", defaultWidth: 0.36, defaultPosition: CGPoint(x: 0.26, y: 0.72), defaultZ: 62, isBackground: false, pack: .mofuUsaPack),
        MoriAsset(id: "mofu_usa_plush_ribbon", name: "リボンうさ", category: .plush, filename: "mofu_usa_plush_ribbon.png", defaultWidth: 0.36, defaultPosition: CGPoint(x: 0.26, y: 0.72), defaultZ: 62, isBackground: false, pack: .mofuUsaPack),
        MoriAsset(id: "mofu_usa_plush_strawberry", name: "いちごうさ", category: .plush, filename: "mofu_usa_plush_strawberry.png", defaultWidth: 0.36, defaultPosition: CGPoint(x: 0.26, y: 0.72), defaultZ: 62, isBackground: false, pack: .mofuUsaPack),
        MoriAsset(id: "mofu_usa_plush_sleepy", name: "ねむうさ", category: .plush, filename: "mofu_usa_plush_sleepy.png", defaultWidth: 0.36, defaultPosition: CGPoint(x: 0.26, y: 0.72), defaultZ: 62, isBackground: false, pack: .mofuUsaPack),
        MoriAsset(id: "mofu_usa_plush_angel", name: "天使うさ", category: .plush, filename: "mofu_usa_plush_angel.png", defaultWidth: 0.36, defaultPosition: CGPoint(x: 0.26, y: 0.72), defaultZ: 62, isBackground: false, pack: .mofuUsaPack),
        MoriAsset(id: "mofu_usa_plush_star", name: "星うさ", category: .plush, filename: "mofu_usa_plush_star.png", defaultWidth: 0.36, defaultPosition: CGPoint(x: 0.26, y: 0.72), defaultZ: 62, isBackground: false, pack: .mofuUsaPack),
        MoriAsset(id: "mofu_usa_plush_tiny", name: "ちびうさ", category: .plush, filename: "mofu_usa_plush_tiny.png", defaultWidth: 0.36, defaultPosition: CGPoint(x: 0.26, y: 0.72), defaultZ: 62, isBackground: false, pack: .mofuUsaPack),
        MoriAsset(id: "korean_hair_c_curl_long", name: "韓国Cカールロング", category: .hair, filename: "korean_hair_c_curl_long.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .koreanHairPack),
        MoriAsset(id: "korean_hair_tassel_bob", name: "韓国タッセルボブ", category: .hair, filename: "korean_hair_tassel_bob.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .koreanHairPack),
        MoriAsset(id: "korean_hair_glass_long", name: "韓国グラスロング", category: .hair, filename: "korean_hair_glass_long.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .koreanHairPack),
        MoriAsset(id: "korean_hair_milktea_wave", name: "韓国ミルクティーウェーブ", category: .hair, filename: "korean_hair_milktea_wave.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .koreanHairPack),
        MoriAsset(id: "korean_hair_ash_short_bob", name: "韓国アッシュショート", category: .hair, filename: "korean_hair_ash_short_bob.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .koreanHairPack),
        MoriAsset(id: "korean_hair_hush_wolf", name: "韓国ハッシュウルフ", category: .hair, filename: "korean_hair_hush_wolf.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .koreanHairPack),
        MoriAsset(id: "korean_hair_high_pony", name: "韓国ハイポニー", category: .hair, filename: "korean_hair_high_pony.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .koreanHairPack),
        MoriAsset(id: "korean_hair_low_bun", name: "韓国ロウバン", category: .hair, filename: "korean_hair_low_bun.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .koreanHairPack),
        MoriAsset(id: "korean_hair_halfup_wave", name: "韓国ハーフアップ", category: .hair, filename: "korean_hair_halfup_wave.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .koreanHairPack),
        MoriAsset(id: "korean_hair_low_twintail", name: "韓国ローツイン", category: .hair, filename: "korean_hair_low_twintail.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .koreanHairPack),
        MoriAsset(id: "korean_lashes_idol_natural", name: "韓国アイドルつけま", category: .lashes, filename: "korean_lashes_idol_natural.png", defaultWidth: 0.40, defaultPosition: CGPoint(x: 0.50, y: 0.42), defaultZ: 48, isBackground: false, pack: .koreanHairPack),
        MoriAsset(id: "korean_lashes_soft_cat", name: "韓国キャットつけま", category: .lashes, filename: "korean_lashes_soft_cat.png", defaultWidth: 0.40, defaultPosition: CGPoint(x: 0.50, y: 0.42), defaultZ: 48, isBackground: false, pack: .koreanHairPack),
        MoriAsset(id: "hime_hair_blonde_curl", name: "姫ブロンド盛り", category: .hair, filename: "hime_hair_blonde_curl.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .himeMoriPack),
        MoriAsset(id: "hime_hair_rose_halfup", name: "姫ローズハーフ", category: .hair, filename: "hime_hair_rose_halfup.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .himeMoriPack),
        MoriAsset(id: "hime_hair_black_himecut", name: "黒髪姫カット", category: .hair, filename: "hime_hair_black_himecut.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .himeMoriPack),
        MoriAsset(id: "hime_hair_pink_high_pony", name: "姫ピンクポニー", category: .hair, filename: "hime_hair_pink_high_pony.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .himeMoriPack),
        MoriAsset(id: "hime_hair_milktea_bob", name: "姫ミルクティーボブ", category: .hair, filename: "hime_hair_milktea_bob.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .himeMoriPack),
        MoriAsset(id: "hime_hair_tiara_heart", name: "ハートティアラ", category: .hairAccessory, filename: "hime_hair_tiara_heart.png", defaultWidth: 0.44, defaultPosition: CGPoint(x: 0.50, y: 0.27), defaultZ: 61, isBackground: false, pack: .himeMoriPack),
        MoriAsset(id: "hime_hair_gold_crown", name: "小さな王冠", category: .hairAccessory, filename: "hime_hair_gold_crown.png", defaultWidth: 0.44, defaultPosition: CGPoint(x: 0.50, y: 0.27), defaultZ: 61, isBackground: false, pack: .himeMoriPack),
        MoriAsset(id: "hime_hair_satin_bow", name: "姫サテンリボン", category: .hairAccessory, filename: "hime_hair_satin_bow.png", defaultWidth: 0.44, defaultPosition: CGPoint(x: 0.50, y: 0.27), defaultZ: 61, isBackground: false, pack: .himeMoriPack),
        MoriAsset(id: "hime_hair_lace_headband", name: "レースカチューシャ", category: .hairAccessory, filename: "hime_hair_lace_headband.png", defaultWidth: 0.44, defaultPosition: CGPoint(x: 0.50, y: 0.27), defaultZ: 61, isBackground: false, pack: .himeMoriPack),
        MoriAsset(id: "hime_hair_chain_heart", name: "ハート髪チェーン", category: .hairAccessory, filename: "hime_hair_chain_heart.png", defaultWidth: 0.44, defaultPosition: CGPoint(x: 0.50, y: 0.27), defaultZ: 61, isBackground: false, pack: .himeMoriPack),
        MoriAsset(id: "hime_brows_princess_arch", name: "姫アーチ眉", category: .brows, filename: "hime_brows_princess_arch.png", defaultWidth: 0.34, defaultPosition: CGPoint(x: 0.50, y: 0.37), defaultZ: 45, isBackground: false, pack: .himeMoriPack),
        MoriAsset(id: "hime_brows_doll_soft", name: "姫ドール眉", category: .brows, filename: "hime_brows_doll_soft.png", defaultWidth: 0.34, defaultPosition: CGPoint(x: 0.50, y: 0.37), defaultZ: 45, isBackground: false, pack: .himeMoriPack),
        MoriAsset(id: "hime_shadow_pink_pearl", name: "ピンクパール姫シャドウ", category: .shadow, filename: "hime_shadow_pink_pearl.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 46, isBackground: false, pack: .himeMoriPack),
        MoriAsset(id: "hime_shadow_lavender_royal", name: "ラベンダー姫シャドウ", category: .shadow, filename: "hime_shadow_lavender_royal.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 46, isBackground: false, pack: .himeMoriPack),
        MoriAsset(id: "hime_shadow_champagne_gold", name: "シャンパン姫シャドウ", category: .shadow, filename: "hime_shadow_champagne_gold.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 46, isBackground: false, pack: .himeMoriPack),
        MoriAsset(id: "hime_blush_heart_pearl", name: "姫ハートチーク", category: .blush, filename: "hime_blush_heart_pearl.png", defaultWidth: 0.42, defaultPosition: CGPoint(x: 0.50, y: 0.55), defaultZ: 44, isBackground: false, pack: .himeMoriPack),
        MoriAsset(id: "hime_blush_rose_round", name: "姫ローズチーク", category: .blush, filename: "hime_blush_rose_round.png", defaultWidth: 0.42, defaultPosition: CGPoint(x: 0.50, y: 0.55), defaultZ: 44, isBackground: false, pack: .himeMoriPack),
        MoriAsset(id: "hime_lip_princess_pink", name: "姫ピンクリップ", category: .lipstick, filename: "hime_lip_princess_pink.png", defaultWidth: 0.24, defaultPosition: CGPoint(x: 0.50, y: 0.59), defaultZ: 47, isBackground: false, pack: .himeMoriPack),
        MoriAsset(id: "hime_lip_rose_red", name: "姫ローズリップ", category: .lipstick, filename: "hime_lip_rose_red.png", defaultWidth: 0.24, defaultPosition: CGPoint(x: 0.50, y: 0.59), defaultZ: 47, isBackground: false, pack: .himeMoriPack),
        MoriAsset(id: "hime_glasses_heart_jewel", name: "姫ハートメガネ", category: .glasses, filename: "hime_glasses_heart_jewel.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 58, isBackground: false, pack: .himeMoriPack),
        MoriAsset(id: "hime_frame_lace_pearl", name: "姫レースフレーム", category: .background, filename: "hime_frame_lace_pearl.png", defaultWidth: 1.00, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 12, isBackground: false, pack: .himeMoriPack),
        MoriAsset(id: "hime_frame_royal_gold", name: "王宮ゴールドフレーム", category: .background, filename: "hime_frame_royal_gold.png", defaultWidth: 1.00, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 12, isBackground: false, pack: .himeMoriPack),
        MoriAsset(id: "hime_frame_castle_window", name: "お城窓フレーム", category: .background, filename: "hime_frame_castle_window.png", defaultWidth: 1.00, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 12, isBackground: false, pack: .himeMoriPack),
        MoriAsset(id: "hime_frame_lavender_moon", name: "月夜の姫フレーム", category: .background, filename: "hime_frame_lavender_moon.png", defaultWidth: 1.00, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 12, isBackground: false, pack: .himeMoriPack),
        MoriAsset(id: "hime_part_sparkle_veil", name: "姫きらめきヴェール", category: .parts, filename: "hime_part_sparkle_veil.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .himeMoriPack),
        MoriAsset(id: "hime_part_magic_wand", name: "姫ステッキ", category: .parts, filename: "hime_part_magic_wand.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .himeMoriPack),
        MoriAsset(id: "hime_part_perfume_bottle", name: "姫香水ボトル", category: .parts, filename: "hime_part_perfume_bottle.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .himeMoriPack),
        MoriAsset(id: "hime_part_heart_charm", name: "姫ハートチャーム", category: .parts, filename: "hime_part_heart_charm.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .himeMoriPack),
        MoriAsset(id: "hime_part_rose_petals", name: "姫ローズ花びら", category: .parts, filename: "hime_part_rose_petals.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .himeMoriPack),
        MoriAsset(id: "hime_part_pearl_choker", name: "姫パールチョーカー", category: .parts, filename: "hime_part_pearl_choker.png", defaultWidth: 0.38, defaultPosition: CGPoint(x: 0.50, y: 0.58), defaultZ: 60, isBackground: false, pack: .himeMoriPack),
        MoriAsset(id: "hime_lashes_pearl_doll", name: "姫パールドールつけま", category: .lashes, filename: "hime_lashes_pearl_doll.png", defaultWidth: 0.40, defaultPosition: CGPoint(x: 0.50, y: 0.42), defaultZ: 48, isBackground: false, pack: .himeMoriPack),
        MoriAsset(id: "hime_lashes_royal_wing", name: "姫ロイヤルつけま", category: .lashes, filename: "hime_lashes_royal_wing.png", defaultWidth: 0.40, defaultPosition: CGPoint(x: 0.50, y: 0.42), defaultZ: 48, isBackground: false, pack: .himeMoriPack),
        MoriAsset(id: "hairarrange_hair_ribbon_pearl_twins", name: "リボンパールツイン", category: .hair, filename: "hairarrange_hair_ribbon_pearl_twins.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .hairArrangeGotsumoriPack),
        MoriAsset(id: "hairarrange_hair_red_black_bow_twins", name: "赤黒リボンツイン", category: .hair, filename: "hairarrange_hair_red_black_bow_twins.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .hairArrangeGotsumoriPack),
        MoriAsset(id: "hairarrange_hair_gold_black_rose_twins", name: "金黒ローズツイン", category: .hair, filename: "hairarrange_hair_gold_black_rose_twins.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .hairArrangeGotsumoriPack),
        MoriAsset(id: "hairarrange_hair_blue_blonde_twins", name: "青ブロンドツイン", category: .hair, filename: "hairarrange_hair_blue_blonde_twins.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .hairArrangeGotsumoriPack),
        MoriAsset(id: "hairarrange_hair_rose_bow_twins", name: "ローズリボンツイン", category: .hair, filename: "hairarrange_hair_rose_bow_twins.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .hairArrangeGotsumoriPack),
        MoriAsset(id: "hairarrange_hair_black_bow_sidepony", name: "黒リボンサイドポニー", category: .hair, filename: "hairarrange_hair_black_bow_sidepony.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .hairArrangeGotsumoriPack),
        MoriAsset(id: "hairarrange_hair_lace_veil_twins", name: "レースヴェールツイン", category: .hair, filename: "hairarrange_hair_lace_veil_twins.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .hairArrangeGotsumoriPack),
        MoriAsset(id: "hairarrange_hair_rainbow_pearl_twins", name: "虹リボンパールツイン", category: .hair, filename: "hairarrange_hair_rainbow_pearl_twins.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .hairArrangeGotsumoriPack),
        MoriAsset(id: "hairarrange_hair_heart_balloon_buns", name: "ハートバルーンお団子", category: .hair, filename: "hairarrange_hair_heart_balloon_buns.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .hairArrangeGotsumoriPack),
        MoriAsset(id: "hairarrange_hair_silver_twin_drills", name: "シルバードリルツイン", category: .hair, filename: "hairarrange_hair_silver_twin_drills.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .hairArrangeGotsumoriPack),
        MoriAsset(id: "hairarrange_accessory_glitter_pink_bow", name: "ごつピンクリボン", category: .hairAccessory, filename: "hairarrange_accessory_glitter_pink_bow.png", defaultWidth: 0.44, defaultPosition: CGPoint(x: 0.50, y: 0.27), defaultZ: 61, isBackground: false, pack: .hairArrangeGotsumoriPack),
        MoriAsset(id: "hairarrange_accessory_pearl_ribbon_chain", name: "リボンパールチェーン", category: .hairAccessory, filename: "hairarrange_accessory_pearl_ribbon_chain.png", defaultWidth: 0.44, defaultPosition: CGPoint(x: 0.50, y: 0.27), defaultZ: 61, isBackground: false, pack: .hairArrangeGotsumoriPack),
        MoriAsset(id: "hairarrange_accessory_red_black_bows", name: "赤黒リボン連なり", category: .hairAccessory, filename: "hairarrange_accessory_red_black_bows.png", defaultWidth: 0.44, defaultPosition: CGPoint(x: 0.50, y: 0.27), defaultZ: 61, isBackground: false, pack: .hairArrangeGotsumoriPack),
        MoriAsset(id: "hairarrange_accessory_rose_crown", name: "ごつローズ冠", category: .hairAccessory, filename: "hairarrange_accessory_rose_crown.png", defaultWidth: 0.44, defaultPosition: CGPoint(x: 0.50, y: 0.27), defaultZ: 61, isBackground: false, pack: .hairArrangeGotsumoriPack),
        MoriAsset(id: "hairarrange_accessory_lace_plush_veil", name: "レースぬいチャーム", category: .hairAccessory, filename: "hairarrange_accessory_lace_plush_veil.png", defaultWidth: 0.44, defaultPosition: CGPoint(x: 0.26, y: 0.72), defaultZ: 61, isBackground: false, pack: .hairArrangeGotsumoriPack),
        MoriAsset(id: "hairarrange_hair_side_pony_pearl", name: "片側パール盛り", category: .hair, filename: "hairarrange_hair_side_pony_pearl.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .hairArrangeGotsumoriPack),
        MoriAsset(id: "hairarrange_hair_lace_side_updo", name: "レース片寄せアップ", category: .hair, filename: "hairarrange_hair_lace_side_updo.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .hairArrangeGotsumoriPack),
        MoriAsset(id: "hairarrange2_hair_01", name: "編み込みクラウン", category: .hair, filename: "hairarrange2_hair_01.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .hairArrangeGotsumoriPack2),
        MoriAsset(id: "hairarrange2_hair_02", name: "スター盛りポニー", category: .hair, filename: "hairarrange2_hair_02.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .hairArrangeGotsumoriPack2),
        MoriAsset(id: "hairarrange2_hair_03", name: "レースサイドお団子", category: .hair, filename: "hairarrange2_hair_03.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .hairArrangeGotsumoriPack2),
        MoriAsset(id: "hairarrange2_hair_04", name: "ふわリボンボブ", category: .hair, filename: "hairarrange2_hair_04.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .hairArrangeGotsumoriPack2),
        MoriAsset(id: "hairarrange2_hair_05", name: "宝石サイド三つ編み", category: .hair, filename: "hairarrange2_hair_05.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .hairArrangeGotsumoriPack2),
        MoriAsset(id: "hairarrange2_hair_06", name: "黒リボンヴェール", category: .hair, filename: "hairarrange2_hair_06.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .hairArrangeGotsumoriPack2),
        MoriAsset(id: "hairarrange2_hair_07", name: "ゴールドトップアップ", category: .hair, filename: "hairarrange2_hair_07.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .hairArrangeGotsumoriPack2),
        MoriAsset(id: "hairarrange2_hair_08", name: "ピンクストレート盛り", category: .hair, filename: "hairarrange2_hair_08.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .hairArrangeGotsumoriPack2),
        MoriAsset(id: "hairarrange2_hair_09", name: "フェザーウルフ", category: .hair, filename: "hairarrange2_hair_09.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .hairArrangeGotsumoriPack2),
        MoriAsset(id: "hairarrange2_hair_10", name: "ローズ低めお団子", category: .hair, filename: "hairarrange2_hair_10.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .hairArrangeGotsumoriPack2),
        MoriAsset(id: "hairarrange2_hair_11", name: "ロック盛りポニー", category: .hair, filename: "hairarrange2_hair_11.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .hairArrangeGotsumoriPack2),
        MoriAsset(id: "hairarrange2_hair_12", name: "クリスタル編みハーフ", category: .hair, filename: "hairarrange2_hair_12.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .hairArrangeGotsumoriPack2),
        MoriAsset(id: "hairarrange2_accessory_01", name: "星パールヘッドチェーン", category: .hairAccessory, filename: "hairarrange2_accessory_01.png", defaultWidth: 0.44, defaultPosition: CGPoint(x: 0.50, y: 0.27), defaultZ: 61, isBackground: false, pack: .hairArrangeGotsumoriPack2),
        MoriAsset(id: "hairarrange2_accessory_02", name: "黒レースローズリボン", category: .hairAccessory, filename: "hairarrange2_accessory_02.png", defaultWidth: 0.44, defaultPosition: CGPoint(x: 0.50, y: 0.27), defaultZ: 61, isBackground: false, pack: .hairArrangeGotsumoriPack2),
        MoriAsset(id: "hairarrange2_accessory_03", name: "ゼリーバタフライピン", category: .hairAccessory, filename: "hairarrange2_accessory_03.png", defaultWidth: 0.44, defaultPosition: CGPoint(x: 0.50, y: 0.27), defaultZ: 61, isBackground: false, pack: .hairArrangeGotsumoriPack2),
        MoriAsset(id: "hairarrange2_accessory_04", name: "ゴールド王冠コーム", category: .hairAccessory, filename: "hairarrange2_accessory_04.png", defaultWidth: 0.44, defaultPosition: CGPoint(x: 0.50, y: 0.27), defaultZ: 61, isBackground: false, pack: .hairArrangeGotsumoriPack2),
        MoriAsset(id: "hairarrange2_accessory_05", name: "カラフルリボンガーランド", category: .hairAccessory, filename: "hairarrange2_accessory_05.png", defaultWidth: 0.44, defaultPosition: CGPoint(x: 0.50, y: 0.27), defaultZ: 61, isBackground: false, pack: .hairArrangeGotsumoriPack2),
        MoriAsset(id: "vivid_reptile_plush_chameleon", name: "ビビッドカメレオン", category: .plush, filename: "vivid_reptile_plush_chameleon.png", defaultWidth: 0.36, defaultPosition: CGPoint(x: 0.26, y: 0.72), defaultZ: 62, isBackground: false, pack: .vividReptilePack),
        MoriAsset(id: "vivid_reptile_plush_gecko", name: "ターコイズヤモリ", category: .plush, filename: "vivid_reptile_plush_gecko.png", defaultWidth: 0.36, defaultPosition: CGPoint(x: 0.26, y: 0.72), defaultZ: 62, isBackground: false, pack: .vividReptilePack),
        MoriAsset(id: "vivid_reptile_plush_bearded_dragon", name: "ピンクフトアゴ", category: .plush, filename: "vivid_reptile_plush_bearded_dragon.png", defaultWidth: 0.36, defaultPosition: CGPoint(x: 0.26, y: 0.72), defaultZ: 62, isBackground: false, pack: .vividReptilePack),
        MoriAsset(id: "vivid_reptile_plush_snake", name: "むらさきヘビ", category: .plush, filename: "vivid_reptile_plush_snake.png", defaultWidth: 0.36, defaultPosition: CGPoint(x: 0.26, y: 0.72), defaultZ: 62, isBackground: false, pack: .vividReptilePack),
        MoriAsset(id: "vivid_reptile_plush_turtle", name: "レインボーかめ", category: .plush, filename: "vivid_reptile_plush_turtle.png", defaultWidth: 0.36, defaultPosition: CGPoint(x: 0.26, y: 0.72), defaultZ: 62, isBackground: false, pack: .vividReptilePack),
        MoriAsset(id: "vivid_reptile_plush_iguana", name: "コーラルイグアナ", category: .plush, filename: "vivid_reptile_plush_iguana.png", defaultWidth: 0.36, defaultPosition: CGPoint(x: 0.26, y: 0.72), defaultZ: 62, isBackground: false, pack: .vividReptilePack),
        MoriAsset(id: "vivid_reptile_plush_rainbow_skink", name: "虹色スキンク", category: .plush, filename: "vivid_reptile_plush_rainbow_skink.png", defaultWidth: 0.36, defaultPosition: CGPoint(x: 0.26, y: 0.72), defaultZ: 62, isBackground: false, pack: .vividReptilePack),
        MoriAsset(id: "vivid_reptile_plush_crocodile", name: "むらさきワニ", category: .plush, filename: "vivid_reptile_plush_crocodile.png", defaultWidth: 0.36, defaultPosition: CGPoint(x: 0.26, y: 0.72), defaultZ: 62, isBackground: false, pack: .vividReptilePack),
        MoriAsset(id: "vivid_reptile_plush_crested_gecko", name: "オレンジクレス", category: .plush, filename: "vivid_reptile_plush_crested_gecko.png", defaultWidth: 0.36, defaultPosition: CGPoint(x: 0.26, y: 0.72), defaultZ: 62, isBackground: false, pack: .vividReptilePack),
        MoriAsset(id: "vivid_reptile_plush_leopard_gecko", name: "レモンレオパ", category: .plush, filename: "vivid_reptile_plush_leopard_gecko.png", defaultWidth: 0.36, defaultPosition: CGPoint(x: 0.26, y: 0.72), defaultZ: 62, isBackground: false, pack: .vividReptilePack),
        MoriAsset(id: "variety_glowing_eyes_blue", name: "Variety Glowing Eyes Blue", category: .shadow, filename: "variety_glowing_eyes_blue.png", defaultWidth: 0.40, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 46, isBackground: false, pack: .varietyPack),
        MoriAsset(id: "variety_glowing_eyes_pink", name: "光る目2", category: .shadow, filename: "variety_glowing_eyes_pink.png", defaultWidth: 0.40, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 46, isBackground: false, pack: .varietyPack),
        MoriAsset(id: "variety_glowing_eyes_vampire", name: "光る目3", category: .shadow, filename: "variety_glowing_eyes_vampire.png", defaultWidth: 0.40, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 46, isBackground: false, pack: .varietyPack),
        MoriAsset(id: "variety_pop_glasses", name: "Variety Pop Glasses", category: .glasses, filename: "variety_pop_glasses.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 58, isBackground: false, pack: .varietyPack),
        MoriAsset(id: "variety_rainbow_brows", name: "Variety Rainbow Brows", category: .brows, filename: "variety_rainbow_brows.png", defaultWidth: 0.34, defaultPosition: CGPoint(x: 0.50, y: 0.37), defaultZ: 45, isBackground: false, pack: .varietyPack),
        MoriAsset(id: "variety_open_mouth", name: "Variety Open Mouth", category: .lipstick, filename: "variety_open_mouth.png", defaultWidth: 0.24, defaultPosition: CGPoint(x: 0.50, y: 0.60), defaultZ: 47, isBackground: false, pack: .varietyPack),
        MoriAsset(id: "variety_drool", name: "Variety Drool", category: .parts, filename: "variety_drool.png", defaultWidth: 0.22, defaultPosition: CGPoint(x: 0.53, y: 0.61), defaultZ: 60, isBackground: false, pack: .varietyPack),
        MoriAsset(id: "variety_vampire_fangs", name: "Variety Vampire Fangs", category: .lipstick, filename: "variety_vampire_fangs.png", defaultWidth: 0.24, defaultPosition: CGPoint(x: 0.50, y: 0.60), defaultZ: 47, isBackground: false, pack: .varietyPack),
        MoriAsset(id: "variety_milk_bottle_glasses", name: "Variety Milk Bottle Glasses", category: .glasses, filename: "variety_milk_bottle_glasses.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 58, isBackground: false, pack: .varietyPack),
        MoriAsset(id: "variety_nose_bandage", name: "Variety Nose Bandage", category: .nosePierce, filename: "variety_nose_bandage.png", defaultWidth: 0.14, defaultPosition: CGPoint(x: 0.52, y: 0.51), defaultZ: 59, isBackground: false, pack: .varietyPack),
        MoriAsset(id: "variety_manga_meat", name: "Variety Manga Meat", category: .parts, filename: "variety_manga_meat.png", defaultWidth: 0.34, defaultPosition: CGPoint(x: 0.72, y: 0.72), defaultZ: 60, isBackground: false, pack: .varietyPack),
        MoriAsset(id: "variety_big_rice", name: "Variety Big Rice", category: .parts, filename: "variety_big_rice.png", defaultWidth: 0.34, defaultPosition: CGPoint(x: 0.72, y: 0.72), defaultZ: 60, isBackground: false, pack: .varietyPack),
        MoriAsset(id: "cabaret_nail_01", name: "黒金ハートネイル", category: .nail, filename: "cabaret_nail_01.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_02", name: "クリスタル姫ネイル", category: .nail, filename: "cabaret_nail_02.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_03", name: "赤バラ女王ネイル", category: .nail, filename: "cabaret_nail_03.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_04", name: "ピンクリボンネイル", category: .nail, filename: "cabaret_nail_04.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_05", name: "紫ジュエルネイル", category: .nail, filename: "cabaret_nail_05.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_06", name: "マリンブルーネイル", category: .nail, filename: "cabaret_nail_06.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_07", name: "白花パールネイル", category: .nail, filename: "cabaret_nail_07.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_08", name: "オレンジ宝石ネイル", category: .nail, filename: "cabaret_nail_08.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_09", name: "透明シルバーネイル", category: .nail, filename: "cabaret_nail_09.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_10", name: "深紅ゴールドネイル", category: .nail, filename: "cabaret_nail_10.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_11", name: "ワインビジューネイル", category: .nail, filename: "cabaret_nail_11.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_12", name: "黒レースネイル", category: .nail, filename: "cabaret_nail_12.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_13", name: "ローズゴールドネイル", category: .nail, filename: "cabaret_nail_13.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_14", name: "ピンクレオパネイル", category: .nail, filename: "cabaret_nail_14.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_15", name: "白レースネイル", category: .nail, filename: "cabaret_nail_15.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_16", name: "ブルーサファイアネイル", category: .nail, filename: "cabaret_nail_16.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_17", name: "エメラルドネイル", category: .nail, filename: "cabaret_nail_17.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_18", name: "紫オーロラネイル", category: .nail, filename: "cabaret_nail_18.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_19", name: "金チェーンネイル", category: .nail, filename: "cabaret_nail_19.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_20", name: "クリスタルロングネイル", category: .nail, filename: "cabaret_nail_20.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_21", name: "ネオンピンクネイル", category: .nail, filename: "cabaret_nail_21.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_22", name: "赤黒ヴァンパイアネイル", category: .nail, filename: "cabaret_nail_22.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_23", name: "ミルキーパールネイル", category: .nail, filename: "cabaret_nail_23.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_24", name: "マーメイドネイル", category: .nail, filename: "cabaret_nail_24.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_25", name: "シャンパン四角ネイル", category: .nail, filename: "cabaret_nail_25.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_26", name: "フューシャリボンネイル", category: .nail, filename: "cabaret_nail_26.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_27", name: "紫ギャラクシーネイル", category: .nail, filename: "cabaret_nail_27.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_28", name: "金レオパネイル", category: .nail, filename: "cabaret_nail_28.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_29", name: "氷ブルーネイル", category: .nail, filename: "cabaret_nail_29.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_30", name: "大粒ピンクネイル", category: .nail, filename: "cabaret_nail_30.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_31", name: "桜クリスタルネイル", category: .nail, filename: "cabaret_nail_31.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_32", name: "黒ダイヤネイル", category: .nail, filename: "cabaret_nail_32.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_33", name: "白オパールネイル", category: .nail, filename: "cabaret_nail_33.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_34", name: "ルビークロムネイル", category: .nail, filename: "cabaret_nail_34.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_35", name: "虹オーロラネイル", category: .nail, filename: "cabaret_nail_35.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_36", name: "ベージュパールチェーンネイル", category: .nail, filename: "cabaret_nail_36.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_37", name: "ネオンイエローネイル", category: .nail, filename: "cabaret_nail_37.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_38", name: "深緑エメラルドネイル", category: .nail, filename: "cabaret_nail_38.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_39", name: "銀蝶ネイル", category: .nail, filename: "cabaret_nail_39.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_40", name: "ホットピンクゼブラネイル", category: .nail, filename: "cabaret_nail_40.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_41", name: "黒金ハートクイーンネイル", category: .nail, filename: "cabaret_nail_41.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_42", name: "シャンパンヌードネイル", category: .nail, filename: "cabaret_nail_42.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_43", name: "赤ローズチャームネイル", category: .nail, filename: "cabaret_nail_43.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_44", name: "ピンク姫ストーンネイル", category: .nail, filename: "cabaret_nail_44.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_45", name: "紫クロムジュエルネイル", category: .nail, filename: "cabaret_nail_45.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_46", name: "青オーシャンネイル", category: .nail, filename: "cabaret_nail_46.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_47", name: "白パールレースネイル", category: .nail, filename: "cabaret_nail_47.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_48", name: "夕焼けグリッターネイル", category: .nail, filename: "cabaret_nail_48.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_49", name: "ガラスクリスタルネイル", category: .nail, filename: "cabaret_nail_49.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "cabaret_nail_50", name: "バーガンディ女王ネイル", category: .nail, filename: "cabaret_nail_50.png", defaultWidth: 0.88, defaultPosition: CGPoint(x: 0.50, y: 0.82), defaultZ: 70, isBackground: false, pack: .cabaretNailPack),
        MoriAsset(id: "emotion_pack_anim_01", name: "動く怒りポップ", category: .emotion, filename: "emotion_pack_anim_01.gif", defaultWidth: 0.26, defaultPosition: CGPoint(x: 0.30, y: 0.25), defaultZ: 70, isBackground: false, pack: .emotionPack),
        MoriAsset(id: "emotion_pack_anim_02", name: "動く涙だばだば", category: .emotion, filename: "emotion_pack_anim_02.gif", defaultWidth: 0.26, defaultPosition: CGPoint(x: 0.30, y: 0.25), defaultZ: 70, isBackground: false, pack: .emotionPack),
        MoriAsset(id: "emotion_pack_anim_03", name: "動くショック爆発", category: .emotion, filename: "emotion_pack_anim_03.gif", defaultWidth: 0.26, defaultPosition: CGPoint(x: 0.30, y: 0.25), defaultZ: 70, isBackground: false, pack: .emotionPack),
        MoriAsset(id: "emotion_pack_anim_04", name: "動く鼓動ハート", category: .emotion, filename: "emotion_pack_anim_04.gif", defaultWidth: 0.26, defaultPosition: CGPoint(x: 0.30, y: 0.25), defaultZ: 70, isBackground: false, pack: .emotionPack),
        MoriAsset(id: "emotion_pack_anim_05", name: "動く汗ぽたぽた", category: .emotion, filename: "emotion_pack_anim_05.gif", defaultWidth: 0.26, defaultPosition: CGPoint(x: 0.30, y: 0.25), defaultZ: 70, isBackground: false, pack: .emotionPack),
        MoriAsset(id: "emotion_pack_anim_06", name: "動くぐるぐる混乱", category: .emotion, filename: "emotion_pack_anim_06.gif", defaultWidth: 0.26, defaultPosition: CGPoint(x: 0.30, y: 0.25), defaultZ: 70, isBackground: false, pack: .emotionPack),
        MoriAsset(id: "emotion_pack_anim_07", name: "動く燃えるイライラ", category: .emotion, filename: "emotion_pack_anim_07.gif", defaultWidth: 0.26, defaultPosition: CGPoint(x: 0.30, y: 0.25), defaultZ: 70, isBackground: false, pack: .emotionPack),
        MoriAsset(id: "emotion_pack_anim_08", name: "動くブルブル震え", category: .emotion, filename: "emotion_pack_anim_08.gif", defaultWidth: 0.26, defaultPosition: CGPoint(x: 0.30, y: 0.25), defaultZ: 70, isBackground: false, pack: .emotionPack),
        MoriAsset(id: "emotion_pack_anim_09", name: "動くきらめき興奮", category: .emotion, filename: "emotion_pack_anim_09.gif", defaultWidth: 0.26, defaultPosition: CGPoint(x: 0.30, y: 0.25), defaultZ: 70, isBackground: false, pack: .emotionPack),
        MoriAsset(id: "emotion_pack_anim_10", name: "動く危険ビリビリ", category: .emotion, filename: "emotion_pack_anim_10.gif", defaultWidth: 0.26, defaultPosition: CGPoint(x: 0.30, y: 0.25), defaultZ: 70, isBackground: false, pack: .emotionPack),
        MoriAsset(id: "emotion_pack_static_01", name: "もくもく考え中", category: .emotion, filename: "emotion_pack_static_01.png", defaultWidth: 0.26, defaultPosition: CGPoint(x: 0.30, y: 0.25), defaultZ: 70, isBackground: false, pack: .emotionPack),
        MoriAsset(id: "emotion_pack_static_02", name: "失恋ハート", category: .emotion, filename: "emotion_pack_static_02.png", defaultWidth: 0.26, defaultPosition: CGPoint(x: 0.30, y: 0.25), defaultZ: 70, isBackground: false, pack: .emotionPack),
        MoriAsset(id: "emotion_pack_static_03", name: "照れライン", category: .emotion, filename: "emotion_pack_static_03.png", defaultWidth: 0.26, defaultPosition: CGPoint(x: 0.30, y: 0.25), defaultZ: 70, isBackground: false, pack: .emotionPack),
        MoriAsset(id: "emotion_pack_static_04", name: "ふきだし雲", category: .emotion, filename: "emotion_pack_static_04.png", defaultWidth: 0.26, defaultPosition: CGPoint(x: 0.30, y: 0.25), defaultZ: 70, isBackground: false, pack: .emotionPack),
        MoriAsset(id: "emotion_pack_static_05", name: "びっくり爆発", category: .emotion, filename: "emotion_pack_static_05.png", defaultWidth: 0.26, defaultPosition: CGPoint(x: 0.30, y: 0.25), defaultZ: 70, isBackground: false, pack: .emotionPack),
        MoriAsset(id: "emotion_pack_static_06", name: "ハッピー花", category: .emotion, filename: "emotion_pack_static_06.png", defaultWidth: 0.26, defaultPosition: CGPoint(x: 0.30, y: 0.25), defaultZ: 70, isBackground: false, pack: .emotionPack),
        MoriAsset(id: "emotion_pack_static_07", name: "しょんぼり雨雲", category: .emotion, filename: "emotion_pack_static_07.png", defaultWidth: 0.26, defaultPosition: CGPoint(x: 0.30, y: 0.25), defaultZ: 70, isBackground: false, pack: .emotionPack),
        MoriAsset(id: "emotion_pack_static_08", name: "嫉妬オーラ", category: .emotion, filename: "emotion_pack_static_08.png", defaultWidth: 0.26, defaultPosition: CGPoint(x: 0.30, y: 0.25), defaultZ: 70, isBackground: false, pack: .emotionPack),
        MoriAsset(id: "emotion_pack_static_09", name: "緊張の汗", category: .emotion, filename: "emotion_pack_static_09.png", defaultWidth: 0.26, defaultPosition: CGPoint(x: 0.30, y: 0.25), defaultZ: 70, isBackground: false, pack: .emotionPack),
        MoriAsset(id: "emotion_pack_static_10", name: "王冠よろこび", category: .emotion, filename: "emotion_pack_static_10.png", defaultWidth: 0.26, defaultPosition: CGPoint(x: 0.30, y: 0.25), defaultZ: 70, isBackground: false, pack: .emotionPack),
        MoriAsset(id: "emotion_pack_static_11", name: "星ぐるぐる", category: .emotion, filename: "emotion_pack_static_11.png", defaultWidth: 0.26, defaultPosition: CGPoint(x: 0.30, y: 0.25), defaultZ: 70, isBackground: false, pack: .emotionPack),
        MoriAsset(id: "emotion_pack_static_12", name: "照れ雲", category: .emotion, filename: "emotion_pack_static_12.png", defaultWidth: 0.26, defaultPosition: CGPoint(x: 0.30, y: 0.25), defaultZ: 70, isBackground: false, pack: .emotionPack),
        MoriAsset(id: "emotion_pack_static_13", name: "ラブ矢ハート", category: .emotion, filename: "emotion_pack_static_13.png", defaultWidth: 0.26, defaultPosition: CGPoint(x: 0.30, y: 0.25), defaultZ: 70, isBackground: false, pack: .emotionPack),
        MoriAsset(id: "emotion_pack_static_14", name: "漫画インパクト", category: .emotion, filename: "emotion_pack_static_14.png", defaultWidth: 0.26, defaultPosition: CGPoint(x: 0.30, y: 0.25), defaultZ: 70, isBackground: false, pack: .emotionPack),
        MoriAsset(id: "emotion_pack_static_15", name: "ため息ふう", category: .emotion, filename: "emotion_pack_static_15.png", defaultWidth: 0.26, defaultPosition: CGPoint(x: 0.30, y: 0.25), defaultZ: 70, isBackground: false, pack: .emotionPack)
    ]
}
