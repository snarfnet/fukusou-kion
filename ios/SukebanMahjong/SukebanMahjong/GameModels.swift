import Foundation

struct Sukeban: Identifiable, Hashable {
    let id: Int
    let name: String
    let alias: String
    let school: String
    let region: String
    let hair: HairStyle
    let palette: CharacterPalette
    let catchphrase: String
    let appearance: String
    let story: String
    let secret: String
    let specialty: String

    var tactics: OpponentTactics {
        OpponentTactics.forCharacter(id)
    }

    var favoriteFood: String {
        CharacterPreferences.foods[id % CharacterPreferences.foods.count]
    }

    var favoriteType: String {
        CharacterPreferences.types[(id * 7 + 3) % CharacterPreferences.types.count]
    }

    var favoriteMotorcycle: String {
        CharacterPreferences.motorcycles[(id * 11 + 1) % CharacterPreferences.motorcycles.count]
    }

    var favoriteCar: String {
        CharacterPreferences.cars[(id * 13 + 2) % CharacterPreferences.cars.count]
    }
}

private enum CharacterPreferences {
    static let foods = [
        "喫茶店のナポリタン", "クリームソーダ", "屋台の焼きそば", "カツ丼",
        "鉄板ナポリタン", "たこ焼き", "あんパンと牛乳", "しょうゆラーメン",
        "オムライス", "お好み焼き", "肉まん", "コロッケパン",
        "プリン・ア・ラ・モード", "赤いウインナー", "鯖のみそ煮", "豚骨ラーメン",
        "五目チャーハン", "カレーライス", "みたらし団子", "いちごのショートケーキ",
        "焼きとうもろこし", "きつねうどん", "チキンライス", "ソースカツ丼",
        "明太子のおにぎり"
    ]

    static let types = [
        "筋を通す人", "弱い者を放っておけない人", "無口でも約束を守る人", "笑うと目が細くなる人",
        "自分の夢を持っている人", "喧嘩より話し合いを選べる人", "家族を大事にする人", "一緒に馬鹿をやれる人",
        "料理が得意な人", "動物に優しい人", "背中で語る人", "負けても言い訳しない人",
        "手紙をまめにくれる人", "機械に強い人", "歌がうまい人", "静かに隣を歩ける人",
        "照れ屋だけど正直な人", "髪型を褒めてくれる人", "麻雀で正々堂々勝負する人", "どんな時も仲間を売らない人"
    ]

    static let motorcycles = [
        "ホンダ CB400FOUR", "カワサキ Z400FX", "ヤマハ RZ250", "スズキ GS400",
        "ホンダ CBX400F", "カワサキ Z1", "ヤマハ XJ400", "スズキ GT380",
        "ホンダ ホークII", "カワサキ KH400", "ヤマハ SR400", "スズキ GSX400E",
        "ホンダ CB750F", "カワサキ Z400GP", "ヤマハ GX400", "スズキ RG250Γ",
        "ホンダ モンキー", "カワサキ 750RS", "ヤマハ RZ350", "スズキ GSX750S刀"
    ]

    static let cars = [
        "日産 スカイライン2000GT-R", "トヨタ セリカXX", "マツダ サバンナRX-7", "日産 フェアレディZ",
        "トヨタ ソアラ", "三菱 スタリオン", "いすゞ 117クーペ", "トヨタ カローラレビン",
        "日産 シルビア", "ホンダ プレリュード", "トヨタ クラウン", "日産 セドリック",
        "マツダ コスモ", "三菱 ギャランGTO", "トヨタ スプリンタートレノ", "日産 ブルーバード",
        "ホンダ シティ", "スバル レオーネ", "ダイハツ ミラ", "スズキ ジムニー"
    ]
}

struct OpponentTactics: Equatable {
    let smartDiscardChance: Int
    let callChance: Int
    let kanChance: Int

    static func forCharacter(_ id: Int) -> OpponentTactics {
        switch id {
        case 1:
            return .init(smartDiscardChance: 2, callChance: 1, kanChance: 1)
        case 2:
            return .init(smartDiscardChance: 3, callChance: 6, kanChance: 2)
        case 3:
            return .init(smartDiscardChance: 4, callChance: 1, kanChance: 2)
        case 4:
            return .init(smartDiscardChance: 5, callChance: 3, kanChance: 6)
        case 5:
            return .init(smartDiscardChance: 6, callChance: 5, kanChance: 5)
        default:
            return .init(smartDiscardChance: 1, callChance: 1, kanChance: 1)
        }
    }
}

enum HairStyle: CaseIterable, Hashable {
    case pompadour, perm, sidePony, wolf, long, beehive
}

enum CharacterPalette: String, CaseIterable, Hashable {
    case crimson
    case ice
    case gold
    case violet
    case tiger
    case blackRose
}

enum StoryData {
    static let heroines: [Sukeban] = [
        .init(id: 0, name: "火神 朱莉", alias: "紅蓮のジュリ", school: "私立・紅天女学院", region: "神奈川", hair: .pompadour,
              palette: .crimson, catchphrase: "牌で決めな。口より早いよ",
              appearance: "短く立てた赤いリーゼントに、紅い長ランとさらし。左眉の小さな剃り込みが火神家の印。",
              story: "港町の小さな雀荘で祖母に育てられた。全国制覇を目指すのは、廃校寸前の紅天女学院を救うため。勝って名を上げ、生徒を呼び戻す。",
              secret: "敵の前では強気だが、捨て猫を七匹飼っている。", specialty: "速攻のタンヤオ"),
        .init(id: 1, name: "白鷺 麗華", alias: "北海の銀狼", school: "北斗白銀高校", region: "北海道", hair: .perm,
              palette: .ice, catchphrase: "凍るのは卓か、あんたの指か",
              appearance: "銀色のソバージュに白いマフラー。青いロングスカートの裾へ、故郷の流氷を刺繍している。",
              story: "漁師の家に生まれ、吹雪で父を失った。家族の借金を背負いながら、賞金付き全国大会に挑む。無口だが仲間は見捨てない。",
              secret: "編み物が得意。朱莉のために赤い手袋を編んでいる。", specialty: "守備と七対子"),
        .init(id: 2, name: "九十九 蘭", alias: "浪花の金獅子", school: "通天閣商業", region: "大阪", hair: .sidePony,
              palette: .gold, catchphrase: "負けても泣くな。うちが笑うたる",
              appearance: "大きな桃色リボンのサイドポニー。金ボタンだらけの改造セーラー服と、豹柄の巾着が目印。",
              story: "潰れかけた実家のたこ焼き屋を立て直す看板娘。明るさの裏で、行方をくらませた姉の足取りを追っている。姉が残した麻雀牌が手掛かりだ。",
              secret: "実は極度の高所恐怖症。", specialty: "鳴き仕掛け"),
        .init(id: 3, name: "伊集院 紫苑", alias: "薩摩の紫電", school: "桜島女塾", region: "鹿児島", hair: .long,
              palette: .violet, catchphrase: "退くなら今。次は雷が落ちる",
              appearance: "腰まで伸ばした黒紫のワンレン。紫の長いセーラー服を隙なく着こなし、片耳だけ稲妻のイヤリングを着ける。",
              story: "名家の跡取りとして完璧を求められてきた。家の決めた進路を蹴り、自分の道を選ぶため全国大会へ。朱莉との勝負で初めて本音を口にする。",
              secret: "少女漫画家を目指し、別名で投稿を続けている。", specialty: "高打点の門前"),
        .init(id: 4, name: "鬼塚 虎子", alias: "上州の喧嘩虎", school: "赤城工業女子部", region: "群馬", hair: .wolf,
              palette: .tiger, catchphrase: "そのリーチ、根性入ってんのか",
              appearance: "荒く切ったウルフヘアと頬の白い絆創膏。制服の上へ橙色の刺繍入りスカジャンを羽織る。",
              story: "バイク工場を営む母と二人暮らし。事故で乗れなくなった親友との約束を胸に、二人の夢だった全国制覇を目指す。",
              secret: "機械いじりと同じくらいピアノが好き。", specialty: "豪快なリーチ"),
        .init(id: 5, name: "皇 千鶴", alias: "帝都の黒薔薇", school: "聖帝華学園", region: "東京", hair: .beehive,
              palette: .blackRose, catchphrase: "全国は私の庭。あなたは迷子よ",
              appearance: "塔のように高い黒髪の盛り髪と黒薔薇の髪飾り。漆黒のロングドレス風制服に桃色の裏地を忍ばせる。",
              story: "全国の不良校を裏で束ねる『黒薔薇会』総長。勝利だけを信じてきたが、孤独な王座に疲れている。朱莉のまっすぐさを試す最後の壁。",
              secret: "黒薔薇会を解散し、普通の卒業旅行へ行きたい。", specialty: "読みと三色同順")
    ]
}
