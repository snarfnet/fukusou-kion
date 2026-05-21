import CoreGraphics
import Foundation

enum MoriPack: String, CaseIterable, Identifiable {
    case free
    case morimoriPack1
    case morimoriPack2

    var id: String { rawValue }

    var title: String {
        switch self {
        case .free: "無料"
        case .morimoriPack1: "盛り盛りパック1"
        case .morimoriPack2: "盛り盛りパック2"
        }
    }

    var productID: String? {
        switch self {
        case .free: nil
        case .morimoriPack1: "com.tokyonasu.morimoriphotomaker.pack1"
        case .morimoriPack2: "com.tokyonasu.morimoriphotomaker.pack2"
        }
    }
}

enum MoriCategory: String, CaseIterable, Identifiable {
    case hair = "髪型"
    case brows = "まゆげ"
    case shadow = "アイシャドウ"
    case blush = "頬紅"
    case lipstick = "口紅"
    case glasses = "メガネ"
    case earrings = "イヤリング"
    case nosePierce = "鼻ピアス"
    case background = "背景"
    case animatedBackground = "キラキラアニメ"
    case parts = "パーツ"

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

    var isBackground: Bool { asset.isBackground }
}

struct AngleValue: Hashable {
    var degrees: Double

    static let zero = AngleValue(degrees: 0)
}

enum MoriLibrary {
    static let assets: [MoriAsset] = [
        MoriAsset(id: "hair", name: "盛り髪", category: .hair, filename: "hair-glam.png", defaultWidth: 0.62, defaultPosition: CGPoint(x: 0.50, y: 0.23), defaultZ: 30, isBackground: false, pack: .free),
        MoriAsset(id: "hair-neon-twintails", name: "ネオンツイン", category: .hair, filename: "hair-neon-twintails.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .free),
        MoriAsset(id: "hair-silver-hime", name: "銀ハ姫カット", category: .hair, filename: "hair-silver-hime.png", defaultWidth: 0.64, defaultPosition: CGPoint(x: 0.50, y: 0.25), defaultZ: 30, isBackground: false, pack: .free),
        MoriAsset(id: "hair-fire-lion", name: "炎ライオン", category: .hair, filename: "hair-fire-lion.png", defaultWidth: 0.68, defaultPosition: CGPoint(x: 0.50, y: 0.25), defaultZ: 30, isBackground: false, pack: .free),
        MoriAsset(id: "hair-gothic-drill", name: "ゴシックドリル", category: .hair, filename: "hair-gothic-drill.png", defaultWidth: 0.66, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .free),
        MoriAsset(id: "hair-rainbow-puffs", name: "虹ふわパフ", category: .hair, filename: "hair-rainbow-puffs.png", defaultWidth: 0.68, defaultPosition: CGPoint(x: 0.50, y: 0.24), defaultZ: 30, isBackground: false, pack: .free),
        MoriAsset(id: "brows", name: "強めまゆ", category: .brows, filename: "brows-arch.png", defaultWidth: 0.33, defaultPosition: CGPoint(x: 0.50, y: 0.37), defaultZ: 45, isBackground: false, pack: .free),
        MoriAsset(id: "brows-villain-arch", name: "悪役アーチ", category: .brows, filename: "brows-villain-arch.png", defaultWidth: 0.33, defaultPosition: CGPoint(x: 0.50, y: 0.37), defaultZ: 45, isBackground: false, pack: .free),
        MoriAsset(id: "brows-caramel-fluffy", name: "キャラメル太眉", category: .brows, filename: "brows-caramel-fluffy.png", defaultWidth: 0.34, defaultPosition: CGPoint(x: 0.50, y: 0.37), defaultZ: 45, isBackground: false, pack: .free),
        MoriAsset(id: "brows-gold-lightning", name: "金イナズマ", category: .brows, filename: "brows-gold-lightning.png", defaultWidth: 0.35, defaultPosition: CGPoint(x: 0.50, y: 0.37), defaultZ: 45, isBackground: false, pack: .free),
        MoriAsset(id: "brows-purple-moon", name: "紫ムーン", category: .brows, filename: "brows-purple-moon.png", defaultWidth: 0.35, defaultPosition: CGPoint(x: 0.50, y: 0.37), defaultZ: 45, isBackground: false, pack: .free),
        MoriAsset(id: "brows-pink-heart", name: "ピンクハート", category: .brows, filename: "brows-pink-heart.png", defaultWidth: 0.35, defaultPosition: CGPoint(x: 0.50, y: 0.37), defaultZ: 45, isBackground: false, pack: .free),
        MoriAsset(id: "eyes", name: "猫目ラメ", category: .shadow, filename: "eyes-cat-glitter.png", defaultWidth: 0.42, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 46, isBackground: false, pack: .free),
        MoriAsset(id: "shadow-blue-lightning", name: "青イナズマ", category: .shadow, filename: "shadow-blue-lightning.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 46, isBackground: false, pack: .free),
        MoriAsset(id: "shadow-sunset-butterfly", name: "夕焼け蝶", category: .shadow, filename: "shadow-sunset-butterfly.png", defaultWidth: 0.44, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 46, isBackground: false, pack: .free),
        MoriAsset(id: "shadow-gothic-crystal", name: "黒赤クリスタル", category: .shadow, filename: "shadow-gothic-crystal.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 46, isBackground: false, pack: .free),
        MoriAsset(id: "shadow-rainbow-prism", name: "虹プリズム", category: .shadow, filename: "shadow-rainbow-prism.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 46, isBackground: false, pack: .free),
        MoriAsset(id: "shadow-pink-pearl", name: "ピンク真珠", category: .shadow, filename: "shadow-pink-pearl.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 46, isBackground: false, pack: .free),
        MoriAsset(id: "blush-candy-sparkle", name: "キャンディ頬", category: .blush, filename: "blush-candy-sparkle.png", defaultWidth: 0.42, defaultPosition: CGPoint(x: 0.50, y: 0.55), defaultZ: 44, isBackground: false, pack: .free),
        MoriAsset(id: "blush-coral-stripe", name: "コーラル斜線", category: .blush, filename: "blush-coral-stripe.png", defaultWidth: 0.42, defaultPosition: CGPoint(x: 0.50, y: 0.55), defaultZ: 44, isBackground: false, pack: .free),
        MoriAsset(id: "blush-purple-star", name: "紫スター", category: .blush, filename: "blush-purple-star.png", defaultWidth: 0.42, defaultPosition: CGPoint(x: 0.50, y: 0.55), defaultZ: 44, isBackground: false, pack: .free),
        MoriAsset(id: "blush-heart-stamp", name: "ハート頬", category: .blush, filename: "blush-heart-stamp.png", defaultWidth: 0.42, defaultPosition: CGPoint(x: 0.50, y: 0.55), defaultZ: 44, isBackground: false, pack: .free),
        MoriAsset(id: "blush-gold-freckles", name: "金そばかす", category: .blush, filename: "blush-gold-freckles.png", defaultWidth: 0.42, defaultPosition: CGPoint(x: 0.50, y: 0.55), defaultZ: 44, isBackground: false, pack: .free),
        MoriAsset(id: "lips", name: "ぷる唇", category: .lipstick, filename: "lips-gloss.png", defaultWidth: 0.24, defaultPosition: CGPoint(x: 0.50, y: 0.59), defaultZ: 47, isBackground: false, pack: .free),
        MoriAsset(id: "lipstick-neon-fuchsia", name: "ネオンピンク", category: .lipstick, filename: "lipstick-neon-fuchsia.png", defaultWidth: 0.24, defaultPosition: CGPoint(x: 0.50, y: 0.59), defaultZ: 47, isBackground: false, pack: .free),
        MoriAsset(id: "lipstick-black-chrome", name: "黒クローム", category: .lipstick, filename: "lipstick-black-chrome.png", defaultWidth: 0.24, defaultPosition: CGPoint(x: 0.50, y: 0.59), defaultZ: 47, isBackground: false, pack: .free),
        MoriAsset(id: "lipstick-gold-foil", name: "金箔リップ", category: .lipstick, filename: "lipstick-gold-foil.png", defaultWidth: 0.24, defaultPosition: CGPoint(x: 0.50, y: 0.59), defaultZ: 47, isBackground: false, pack: .free),
        MoriAsset(id: "lipstick-red-heart", name: "赤ハート", category: .lipstick, filename: "lipstick-red-heart.png", defaultWidth: 0.24, defaultPosition: CGPoint(x: 0.50, y: 0.59), defaultZ: 47, isBackground: false, pack: .free),
        MoriAsset(id: "lipstick-icy-blue", name: "氷ブルー", category: .lipstick, filename: "lipstick-icy-blue.png", defaultWidth: 0.24, defaultPosition: CGPoint(x: 0.50, y: 0.59), defaultZ: 47, isBackground: false, pack: .free),
        MoriAsset(id: "glasses-heart-rhinestone", name: "ハートデカメガネ", category: .glasses, filename: "glasses-heart-rhinestone.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 58, isBackground: false, pack: .free),
        MoriAsset(id: "glasses-star-holo", name: "星ホロメガネ", category: .glasses, filename: "glasses-star-holo.png", defaultWidth: 0.43, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 58, isBackground: false, pack: .free),
        MoriAsset(id: "glasses-black-cateye", name: "黒キャットアイ", category: .glasses, filename: "glasses-black-cateye.png", defaultWidth: 0.42, defaultPosition: CGPoint(x: 0.50, y: 0.43), defaultZ: 58, isBackground: false, pack: .free),
        MoriAsset(id: "earrings-heart-chandelier", name: "ハートシャンデリア", category: .earrings, filename: "earrings-heart-chandelier.png", defaultWidth: 0.58, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 42, isBackground: false, pack: .free),
        MoriAsset(id: "earrings-neon-hoop", name: "ネオンフープ", category: .earrings, filename: "earrings-neon-hoop.png", defaultWidth: 0.54, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 42, isBackground: false, pack: .free),
        MoriAsset(id: "earrings-gothic-cross", name: "ゴシック十字", category: .earrings, filename: "earrings-gothic-cross.png", defaultWidth: 0.54, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 42, isBackground: false, pack: .free),
        MoriAsset(id: "nose-pierce-mix-set", name: "鼻ピアスセット", category: .nosePierce, filename: "nose-pierce-mix-set.png", defaultWidth: 0.16, defaultPosition: CGPoint(x: 0.50, y: 0.51), defaultZ: 59, isBackground: false, pack: .free),
        MoriAsset(id: "nose-pierce-septum-pink", name: "ピンクセプタム", category: .nosePierce, filename: "nose-pierce-septum-pink.png", defaultWidth: 0.14, defaultPosition: CGPoint(x: 0.50, y: 0.52), defaultZ: 59, isBackground: false, pack: .free),
        MoriAsset(id: "nose-pierce-diamond-stud", name: "ダイヤ鼻ピ", category: .nosePierce, filename: "nose-pierce-diamond-stud.png", defaultWidth: 0.09, defaultPosition: CGPoint(x: 0.54, y: 0.51), defaultZ: 59, isBackground: false, pack: .free),
        MoriAsset(id: "halo", name: "キラ盛り", category: .parts, filename: "halo-sparkle.png", defaultWidth: 0.90, defaultPosition: CGPoint(x: 0.50, y: 0.49), defaultZ: 60, isBackground: false, pack: .free),
        MoriAsset(id: "burst", name: "派手フレーム", category: .background, filename: "burst-frame.png", defaultWidth: 1.0, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 12, isBackground: false, pack: .free),
        MoriAsset(id: "burst-leopard-lightning", name: "豹柄ピカ盛り", category: .background, filename: "burst-leopard-lightning.png", defaultWidth: 1.0, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 12, isBackground: false, pack: .free),
        MoriAsset(id: "kirakira", name: "キラキラMAX", category: .animatedBackground, filename: "kirakira-max-bg.gif", defaultWidth: 1.0, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 1, isBackground: true, pack: .free),
        MoriAsset(id: "kirakira-pop", name: "ポップきらめき", category: .animatedBackground, filename: "kirakira-pop-bg.gif", defaultWidth: 1.0, defaultPosition: CGPoint(x: 0.50, y: 0.50), defaultZ: 1, isBackground: true, pack: .free),
    ]
}
