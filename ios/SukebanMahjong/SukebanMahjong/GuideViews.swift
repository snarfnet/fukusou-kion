import SwiftUI

struct TutorialView: View {
    let completion: () -> Void
    @State private var page = 0

    private let pages: [(title: String, symbol: String, body: String)] = [
        ("全国を獲れ", "日 本", "全国五校の番長を麻雀で倒し、紅天女学院の廃校を止めろ。勝つたびに次の学校と物語が開く。"),
        ("牌をそろえろ", "四 面 子\n一 雀 頭", "同じ牌三枚の刻子か、同じ種類の連番三枚の順子を四組作る。最後に同じ牌二枚の雀頭を置けば和了形だ。"),
        ("捨て牌を選べ", "ツ モ → 打", "自分の番では一枚引き、十四枚から一枚を捨てる。黄色い枠が出た牌を切ればリーチできる。"),
        ("鳴きは決断", "チー ポン カン", "相手の捨て牌を使える時はボタンが出る。鳴くと早くそろうが、リーチや門前ツモは使えなくなる。"),
        ("東四局で決着", "12000 対 12000", "点棒とリーチ棒を局ごとに持ち越す。誰かがトビになるか、東四局で親が流れた時、点棒の多い方が勝者だ。残ったリーチ棒は最終順位の上位者が受け取り、同点なら防衛校の勝ちになる。")
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Text("遊び方　\(page + 1)/\(pages.count)")
                    .foregroundStyle(.yellow)
                    .accessibilityIdentifier("tutorial.page")
                Text(pages[page].symbol)
                    .font(.system(size: 34, weight: .black, design: .monospaced))
                    .minimumScaleFactor(0.65)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: 110)
                    .foregroundStyle(.red)
                    .background(Color.black)
                    .overlay(Rectangle().stroke(.white, lineWidth: 3))
                Text(pages[page].title).font(.title)
                Text(pages[page].body)
                    .lineSpacing(7)
                    .frame(maxWidth: 520)
                HStack {
                    if page > 0 {
                        Button("◀ 戻る") { page -= 1 }
                            .buttonStyle(PixelButtonStyle(color: .blue))
                    }
                    Button(page == pages.count - 1 ? "勝負へ" : "次へ ▶") {
                        if page == pages.count - 1 { completion() } else { page += 1 }
                    }
                    .buttonStyle(PixelButtonStyle(color: .red))
                }
            }
            .padding()
        }
        .foregroundStyle(.white)
        .pixelText()
        .background(Color(red: 0.035, green: 0.055, blue: 0.08).ignoresSafeArea())
    }
}

struct YakuReferenceView: View {
    @Environment(\.dismiss) private var dismiss

    private let groups: [(String, [(String, String)])] = [
        ("一翻", [
            ("立直", "門前でテンパイを宣言"),
            ("一発", "リーチ後、鳴きのない一巡以内"),
            ("門前清自摸和", "門前でツモ和了"),
            ("断么九", "2〜8の数牌だけ"),
            ("平和", "全て順子・役なし雀頭・両面待ち"),
            ("一盃口", "同じ順子を二組"),
            ("役牌", "三元牌、場風、自風の刻子"),
            ("海底摸月／河底撈魚", "最後のツモ／最後の捨て牌"),
            ("嶺上開花／槍槓", "カン後のツモ／加カン牌のロン")
        ]),
        ("二〜三翻", [
            ("三色同順", "三種類で同じ順子"),
            ("一気通貫", "同じ種類で123・456・789"),
            ("対々和", "四面子すべて刻子"),
            ("三暗刻", "暗刻を三組"),
            ("三色同刻", "三種類で同じ刻子"),
            ("三槓子", "槓子を三組"),
            ("七対子", "異なる対子を七組"),
            ("小三元", "三元牌の刻子二組と雀頭"),
            ("混老頭", "一・九・字牌だけ"),
            ("混全帯么九／純全帯么九", "全組に一・九・字牌／字牌なし"),
            ("二盃口", "一盃口を二組")
        ]),
        ("染め手", [
            ("混一色", "一種類の数牌と字牌"),
            ("清一色", "一種類の数牌だけ")
        ]),
        ("役満", [
            ("国士無双", "一・九・字牌十三種と対子"),
            ("四暗刻", "暗刻を四組"),
            ("大三元", "三元牌を全て刻子"),
            ("字一色", "字牌だけ"),
            ("清老頭", "一・九牌だけ"),
            ("小四喜／大四喜", "風牌三刻子＋雀頭／四刻子"),
            ("四槓子", "槓子を四組")
        ])
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(Array(groups.enumerated()), id: \.offset) { _, group in
                    Section(group.0) {
                        ForEach(Array(group.1.enumerated()), id: \.offset) { _, item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.0).foregroundStyle(.yellow)
                                Text(item.1).font(.caption).foregroundStyle(.white.opacity(0.75))
                            }
                            .listRowBackground(Color.black)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(red: 0.035, green: 0.055, blue: 0.08))
            .navigationTitle("役一覧")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
        .pixelText()
    }
}

struct GameSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("settings.sound") private var sound = true
    @AppStorage("settings.haptics") private var haptics = true
    @AppStorage("settings.confirmDiscard") private var confirmDiscard = false

    var body: some View {
        NavigationStack {
            Form {
                Section("演出") {
                    Toggle("8ビット効果音", isOn: $sound)
                    Toggle("振動", isOn: $haptics)
                }
                Section("操作") {
                    Toggle("リーチ中以外も打牌確認", isOn: $confirmDiscard)
                    Text("確認を有効にすると、誤って牌を切るのを防げます。")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("記録") {
                    Text("全国制覇の進行は端末内に自動保存されます。")
                        .font(.caption)
                }
            }
            .navigationTitle("設定")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
        .pixelText()
    }
}
