import SwiftUI
import UIKit

enum ReelTone: String, CaseIterable, Identifiable {
    case trend
    case surprise
    case premium
    case daily

    var id: String { rawValue }

    var title: String {
        switch self {
        case .trend: "流行りそう"
        case .surprise: "発見した感"
        case .premium: "上品に推す"
        case .daily: "日常で使える"
        }
    }

    var captions: [String] {
        switch self {
        case .trend:
            [
                "これから流行るかも?!", "{name}、もうチェックした?", "見つけた瞬間ほしくなる",
                "この質感、かなり良い。", "次に来るのはこれ", "{name}で雰囲気変わる。",
                "先取りするならこれ", "{name}、じわじわ来そう。", "タイムラインで目立つやつ"
            ]
        case .surprise:
            [
                "すごいの見つけた!", "{name}、想像以上。", "え、これ便利すぎない?",
                "写真で伝わるこの存在感。", "一回見てほしい", "使う前から気分が上がる。",
                "思ってたより良い", "{name}、これは驚いた。", "え、こういうの欲しかった"
            ]
        case .premium:
            [
                "大人っぽく選ぶなら", "{name}がちょうどいい。", "派手すぎないのに印象的",
                "細部まできれいに見える。", "毎日に少しだけ特別感", "このまとまり、かなり上品。",
                "上品に目立つ", "{name}で印象が変わる。", "落ち着いているのに華がある"
            ]
        case .daily:
            [
                "今日から使えるやつ", "{name}、出番多そう。", "置くだけで気分が変わる",
                "普段使いにちょうどいい。", "迷ったらこれでいい", "ちゃんと使えて、ちゃんと映える。",
                "毎日使いたくなる", "{name}、かなり実用的。", "日常にちょうどいい"
            ]
        }
    }
}

struct ReelScene: Identifiable {
    let id = UUID()
    var image: UIImage
    var caption: String
    var textStickers: [PlacedTextSticker] = []
    var motionStickers: [PlacedMotionSticker] = []
}

struct TextSticker: Identifiable {
    let id: String
    let text: String
    let colors: [Color]
    let tilt: Double
    let shape: StickerShape
}

struct MotionSticker: Identifiable {
    let id: String
    let name: String
    let color: Color
    let kind: MotionKind
}

struct PlacedTextSticker: Identifiable {
    let id = UUID()
    var sticker: TextSticker
    var position: LayerPosition
    var scale: CGFloat
}

struct PlacedMotionSticker: Identifiable {
    let id = UUID()
    var sticker: MotionSticker
    var position: LayerPosition
    var scale: CGFloat
}

enum LayerPosition: String, CaseIterable, Identifiable {
    case topLeft
    case topRight
    case center
    case bottomLeft
    case bottomRight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .topLeft: "左上"
        case .topRight: "右上"
        case .center: "中央"
        case .bottomLeft: "左下"
        case .bottomRight: "右下"
        }
    }

    var unitPoint: UnitPoint {
        switch self {
        case .topLeft: UnitPoint(x: 0.28, y: 0.2)
        case .topRight: UnitPoint(x: 0.72, y: 0.2)
        case .center: UnitPoint(x: 0.5, y: 0.42)
        case .bottomLeft: UnitPoint(x: 0.3, y: 0.62)
        case .bottomRight: UnitPoint(x: 0.7, y: 0.62)
        }
    }
}

enum StickerShape: CaseIterable {
    case burst
    case ribbon
    case cloud
    case ticket
    case bubble
}

enum MotionKind: CaseIterable {
    case sparkle
    case hearts
    case ring
    case confetti
    case flash
}

enum ReelLibrary {
    static let textStickers: [TextSticker] = [
        "え?!\n何これ", "新商品\n発売", "面白い\nかも", "これ\nバズる?", "見つけた\n人勝ち",
        "保存\n推奨", "想像以上", "今っぽい", "数量\n限定", "チェック\nして",
        "すごすぎ", "推し\n確定", "買って\n正解", "これ\n便利", "高見え",
        "神\nアイテム", "即カゴ", "今日の\n主役", "迷ったら\nコレ", "じわる",
        "可愛\nすぎ", "使える", "早い者\n勝ち", "話題に\nなりそう", "これは\nアリ",
        "クセに\nなる", "いい\n感じ", "目立つ", "新発見", "本気で\n推す"
    ].enumerated().map { index, text in
        let palettes: [[Color]] = [
            [.red, .orange], [.pink, .purple], [.cyan, .blue], [.mint, .green], [.yellow, .orange]
        ]
        return TextSticker(
            id: "promo-\(index)",
            text: text,
            colors: palettes[index % palettes.count],
            tilt: [-8, 6, -4, 5, -7, 3][index % 6],
            shape: StickerShape.allCases[index % StickerShape.allCases.count]
        )
    }

    static let motionStickers: [MotionSticker] = [
        "キラッと登場", "星が降る", "金色バーン", "ピンクきらめき", "青フラッシュ",
        "ハート火花", "白赤グリッター", "ネオンリング", "光線シャイン", "ポップ紙吹雪",
        "ハート満開", "リボンポップ", "キャンディ星", "パールきらり", "ミント泡",
        "ラブシャワー", "レース光", "いちごバーン", "パステル紙吹雪", "天使グロー",
        "かわいい閃光", "夢リング", "キラハート", "泡スター", "レモンポップ",
        "ピンク雨", "ミントリング", "ハッピー火花", "小さなリボン", "スイートオーラ"
    ].enumerated().map { index, name in
        let colors: [Color] = [.yellow, .pink, .cyan, .mint, .orange, .purple]
        return MotionSticker(
            id: "motion-\(index)",
            name: name,
            color: colors[index % colors.count],
            kind: MotionKind.allCases[index % MotionKind.allCases.count]
        )
    }
}
