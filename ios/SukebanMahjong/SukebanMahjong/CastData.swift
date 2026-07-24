import Foundation

extension StoryData {
    static let supporting: [Sukeban] = {
        prefectureSeeds.enumerated().flatMap { prefectureIndex, seed in
            (0..<2).map { partnerIndex in
                let index = prefectureIndex * 2 + partnerIndex
                let hair = HairStyle.allCases[index % HairStyle.allCases.count]
                let palette = CharacterPalette.allCases[
                    (index + prefectureIndex) % CharacterPalette.allCases.count
                ]
                let name = partnerIndex == 0 ? seed.firstName : seed.secondName
                let isSumire = name == "九十九 菫"
                let role = partnerIndex == 0 ? "表番" : "裏番"
                let action = partnerIndex == 0
                    ? "仲間の先頭に立ち、\(seed.cause)を守る署名を集めている"
                    : "目立つ相棒を陰で支えながら、\(seed.cause)を次の世代へ残そうとしている"
                let dream = personalDreams[index % personalDreams.count]

                return Sukeban(
                    id: index + 6,
                    name: name,
                    alias: "\(seed.region)の\(seed.motif)\(role)",
                    school: seed.school,
                    region: seed.region,
                    hair: hair,
                    palette: palette,
                    catchphrase: partnerIndex == 0
                        ? "この町の名前、牌に刻んで持っていきな"
                        : "二番手を甘く見ると、待ち牌を見失うよ",
                    appearance: appearance(
                        hair: hair,
                        motif: seed.motif,
                        partnerIndex: partnerIndex
                    ),
                    story: isSumire
                        ? "蘭の姉。失踪を装って黒薔薇会へ潜り込み、行き場を失った生徒の名簿を守ってきた。妹へ危険が及ばないよう無言電話だけを残した。"
                        : "\(seed.school)の女子番長。\(action)。全国連盟へ加わるのは、勝ち名乗りより故郷の居場所を守るため。",
                    secret: isSumire
                        ? "潜入が終わったら蘭と同じ鉄板に立ち、百人分のたこ焼きを焼きたい。"
                        : "誰にも言っていない夢は「\(dream)」。旅が終わったら最初の一歩を踏み出すつもりだ。",
                    specialty: specialties[index % specialties.count]
                )
            }
        }
    }()

    static let allCharacters: [Sukeban] = heroines + supporting

    private static func appearance(
        hair: HairStyle,
        motif: String,
        partnerIndex: Int
    ) -> String {
        let hairText: String
        switch hair {
        case .pompadour: hairText = "短く高く固めたリーゼント"
        case .perm: hairText = "肩まで広がる大きなソバージュ"
        case .sidePony: hairText = "太いリボンで結んだサイドポニー"
        case .wolf: hairText = "襟足を残した荒いウルフカット"
        case .long: hairText = "腰まで伸ばした重いワンレン"
        case .beehive: hairText = "塔のように盛った蜂の巣ヘア"
        }
        let uniform = partnerIndex == 0 ? "刺繍入りの長ラン" : "足首まで届く改造セーラー服"
        return "\(hairText)に\(uniform)。胸元へ\(motif)の小さなワッペンを縫い付けた昭和風の装い。"
    }

    private static let personalDreams = [
        "夜間高校の先生になる", "家の食堂を継ぐ", "女性だけの整備工場を開く",
        "児童向け漫画を描く", "町の映画館を復活させる", "保護猫の診療所を作る",
        "ローカル線の車掌になる", "祭りの太鼓を教える", "海辺で喫茶店を開く",
        "母の旅館を建て直す", "女子野球部を作る", "自分のラジオ番組を持つ",
        "伝統工芸の職人になる", "小さな本屋を開く", "山岳救助隊へ入る",
        "給食の料理人になる", "写真で故郷を残す", "手話通訳者になる",
        "移動図書館を走らせる", "動物保護施設を作る", "商店街で洋裁店を開く",
        "港の船長になる", "地域の看護師になる", "全国を回る歌手になる"
    ]

    private static let specialties = [
        "字牌を絞る守備", "速いタンヤオ", "七対子の待ち替え", "役牌の仕掛け",
        "門前リーチ", "混一色の染め手", "三色同順", "一気通貫",
        "対々和の押し", "終盤の回し打ち", "カンの勝負勘", "平和の両面待ち"
    ]

    private struct PrefectureSeed {
        let region: String
        let school: String
        let firstName: String
        let secondName: String
        let cause: String
        let motif: String
    }

    private static let prefectureSeeds: [PrefectureSeed] = [
        .init(region: "北海道", school: "石狩雪華女学園", firstName: "工藤 雪乃", secondName: "相馬 知床", cause: "閉鎖寸前の流氷資料館", motif: "雪梟"),
        .init(region: "青森", school: "津軽林檎女子高", firstName: "葛西 林檎", secondName: "三上 ねぶた", cause: "台風で傷んだりんご園", motif: "跳人"),
        .init(region: "岩手", school: "北上不来方女学院", firstName: "及川 遠野", secondName: "千葉 琥珀", cause: "山あいの分校と民話文庫", motif: "座敷童"),
        .init(region: "宮城", school: "青葉伊達女子高", firstName: "大友 青葉", secondName: "庄司 七夕", cause: "津波で失った吹奏楽部室", motif: "三日月"),
        .init(region: "秋田", school: "男鹿撫子女学館", firstName: "佐々木 稲穂", secondName: "畠山 小町", cause: "後継者のいない米蔵", motif: "なまはげ"),
        .init(region: "山形", school: "出羽紅花女子高", firstName: "安達 紅花", secondName: "志田 さくらん", cause: "廃線予定の通学列車", motif: "雪兎"),
        .init(region: "福島", school: "会津白虎女学院", firstName: "国分 磐梯", secondName: "星 桃花", cause: "閉山した町の共同浴場", motif: "赤べこ"),
        .init(region: "茨城", school: "水戸梅香女子高", firstName: "塚原 千波", secondName: "菊池 納緒", cause: "商店街の納豆工房", motif: "梅鉢"),
        .init(region: "栃木", school: "日光苺女子学園", firstName: "宇賀神 苺", secondName: "黒崎 華厳", cause: "山道の小さな診療所", motif: "眠猫"),
        .init(region: "群馬", school: "上州風雷女学院", firstName: "新井 榛名", secondName: "茂木 かかあ", cause: "母たちの織物工場", motif: "達磨"),
        .init(region: "埼玉", school: "秩父夜祭女子高", firstName: "新藤 秩父", secondName: "蓮見 彩湖", cause: "団地の子ども食堂", motif: "山車"),
        .init(region: "千葉", school: "房総潮風女学館", firstName: "成田 潮", secondName: "小湊 菜花", cause: "漁港の朝市と保育所", motif: "落花生"),
        .init(region: "東京", school: "浅草雷門女子高", firstName: "神田 粋", secondName: "柴又 寅美", cause: "取り壊し予定の名画座", motif: "雷門"),
        .init(region: "神奈川", school: "湘南波切女学院", firstName: "葉山 渚", secondName: "鶴見 灯", cause: "港町の無料学習室", motif: "海燕"),
        .init(region: "新潟", school: "越後雪椿女子高", firstName: "長岡 花火", secondName: "笹川 朱鷺", cause: "豪雪地の移動図書館", motif: "雪椿"),
        .init(region: "富山", school: "立山薬師女学院", firstName: "室井 蛍", secondName: "氷見 鰤子", cause: "置き薬を届ける山道", motif: "雷鳥"),
        .init(region: "石川", school: "加賀金箔女子高", firstName: "前田 箔", secondName: "輪島 漆", cause: "職人街の共同工房", motif: "金獅子"),
        .init(region: "福井", school: "越前水仙女学園", firstName: "朝倉 水仙", secondName: "鯖江 鏡", cause: "眼鏡職人の実習校", motif: "恐竜"),
        .init(region: "山梨", school: "甲斐葡萄女子高", firstName: "武川 葡萄", secondName: "富士野 湖", cause: "家族経営のぶどう畑", motif: "風林火山"),
        .init(region: "長野", school: "信州白樺女学院", firstName: "真田 杏", secondName: "諏訪 梓", cause: "山村の分校と天文台", motif: "六文銭"),
        .init(region: "岐阜", school: "飛騨匠女子高", firstName: "白川 結", secondName: "長良 鵜美", cause: "古い木造校舎と工房", motif: "合掌"),
        .init(region: "静岡", school: "駿河茶摘女学園", firstName: "焼津 鰹", secondName: "伊豆 葵", cause: "茶畑を走る通学バス", motif: "富士波"),
        .init(region: "愛知", school: "尾張金鯱女子高", firstName: "矢場 味噌乃", secondName: "常滑 朱泥", cause: "町工場の夜間学級", motif: "金鯱"),
        .init(region: "三重", school: "伊勢真珠女学院", firstName: "鳥羽 真珠", secondName: "熊野 那智", cause: "海女小屋と海辺の保健室", motif: "八咫烏"),
        .init(region: "滋賀", school: "琵琶湖水鳥女子高", firstName: "近江 葦", secondName: "彦根 朱音", cause: "湖岸の水鳥保護区", motif: "白鷺"),
        .init(region: "京都", school: "洛中舞妓女学館", firstName: "嵯峨 竹乃", secondName: "丹後 織", cause: "西陣の小さな織物教室", motif: "舞扇"),
        .init(region: "大阪", school: "河内だんじり女子高", firstName: "九十九 菫", secondName: "堺 刃", cause: "市場の共同炊事場", motif: "だんじり"),
        .init(region: "兵庫", school: "神戸港灯女学院", firstName: "明石 玉子", secondName: "但馬 玄", cause: "震災後に建てた集会所", motif: "港灯"),
        .init(region: "奈良", school: "大和若草女子高", firstName: "橿原 茜", secondName: "吉野 千本", cause: "山寺の寺子屋と鹿苑", motif: "若鹿"),
        .init(region: "和歌山", school: "紀州蜜柑女学園", firstName: "有田 蜜", secondName: "高野 凛", cause: "みかん山の共同選果場", motif: "八朔"),
        .init(region: "鳥取", school: "因幡砂丘女子高", firstName: "因幡 白兎", secondName: "境港 澪", cause: "砂丘近くの児童図書室", motif: "白兎"),
        .init(region: "島根", school: "出雲神楽女学院", firstName: "石見 神楽", secondName: "隠岐 碧", cause: "離島の寄宿舎と診療船", motif: "大蛇"),
        .init(region: "岡山", school: "吉備桃花女子高", firstName: "倉敷 藍", secondName: "備前 桃", cause: "水害に遭った染物工房", motif: "鬼面"),
        .init(region: "広島", school: "安芸紅葉女学館", firstName: "呉 錨", secondName: "尾道 坂乃", cause: "坂道の移動購買車", motif: "紅葉"),
        .init(region: "山口", school: "長州河豚女子高", firstName: "萩 夏蜜", secondName: "下関 潮路", cause: "港の定時制教室", motif: "白狐"),
        .init(region: "徳島", school: "阿波藍舞女学院", firstName: "鳴門 渦", secondName: "祖谷 かずら", cause: "山村へ薬を運ぶ吊り橋", motif: "阿波踊"),
        .init(region: "香川", school: "讃岐白波女子高", firstName: "琴平 麦", secondName: "小豆島 オリヴ", cause: "島の給食センター", motif: "銭形"),
        .init(region: "愛媛", school: "伊予蜜柑女学院", firstName: "道後 椿", secondName: "宇和島 珠", cause: "閉館予定の公衆浴場", motif: "坊ちゃん"),
        .init(region: "高知", school: "土佐黒潮女子高", firstName: "桂浜 龍", secondName: "四万十 清", cause: "川沿いの分校と渡し船", motif: "鳴子"),
        .init(region: "福岡", school: "博多山笠女学園", firstName: "天神 祭", secondName: "柳川 雛", cause: "炭鉱町の共同食堂", motif: "山笠"),
        .init(region: "佐賀", school: "有田炎彩女子高", firstName: "鍋島 焔", secondName: "唐津 曳子", cause: "窯元の見習い教室", motif: "赤獅子"),
        .init(region: "長崎", school: "出島鐘楼女学院", firstName: "平戸 碧", secondName: "島原 灯里", cause: "離島を結ぶ学習船", motif: "南蛮船"),
        .init(region: "熊本", school: "阿蘇火輪女子高", firstName: "肥後 椿", secondName: "天草 真珠", cause: "火山麓の牧場と分校", motif: "火の国"),
        .init(region: "大分", school: "別府湯煙女学院", firstName: "由布 湯花", secondName: "国東 磨崖", cause: "温泉街の母子寮", motif: "地獄煙"),
        .init(region: "宮崎", school: "日向神話女子高", firstName: "高千穂 舞", secondName: "青島 波", cause: "台風で壊れた神楽殿", motif: "天岩戸"),
        .init(region: "鹿児島", school: "薩摩黒潮女学館", firstName: "指宿 砂楽", secondName: "屋久島 縄", cause: "離島の寄宿舎と連絡船", motif: "桜島"),
        .init(region: "沖縄", school: "琉球紅型女子高", firstName: "首里 朱", secondName: "八重山 珊瑚", cause: "台風で傷んだ共同工房", motif: "守礼門")
    ]
}
