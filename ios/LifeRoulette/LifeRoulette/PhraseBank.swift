import Foundation

struct NumberStoryBank {
    static let shared = NumberStoryBank()

    struct Story {
        let title: String
        let message: String
        let hint: String
    }

    private let stories: [Int: Story] = [
        1: Story(
            title: "はじまりの数字",
            message: "小さく始めるほど、今日は流れに乗れます。完璧に整うのを待たず、まず一歩だけ置いてみてください。",
            hint: "最初の5分だけ動く"
        ),
        2: Story(
            title: "つながる数字",
            message: "誰かとのやり取りに答えがありそうです。一人で抱えず、短い一言で相談してみると空気が変わります。",
            hint: "短い連絡を送る"
        ),
        3: Story(
            title: "ひらめきの数字",
            message: "正解を探すより、試して反応を見る日です。軽く作って、軽く直す。そのリズムが味方になります。",
            hint: "案を3つ書く"
        ),
        4: Story(
            title: "土台を整える数字",
            message: "派手な動きより、足元を整えると進みます。予定、持ち物、作業場所を一つだけ片づけましょう。",
            hint: "机の上を整える"
        ),
        5: Story(
            title: "変化の数字",
            message: "予定通りでなくても大丈夫です。少し道を変えると、今の自分に合う答えが見えてきます。",
            hint: "いつもと違う順番にする"
        ),
        6: Story(
            title: "やさしさの数字",
            message: "人にも自分にも、少し甘くしていい日です。無理を減らすほど、大事なことに力を使えます。",
            hint: "休む時間を先に入れる"
        ),
        7: Story(
            title: "深く見る数字",
            message: "急いで決めるより、静かに観察すると見えてきます。違和感があるなら、その感覚を信じてください。",
            hint: "10分だけ考える"
        ),
        8: Story(
            title: "形にする数字",
            message: "考えを外に出す力が強い日です。大きな目標を、今日終わる作業まで小さくしてみましょう。",
            hint: "締切を一つ決める"
        ),
        9: Story(
            title: "手放す数字",
            message: "終わらせることで、新しい余白が生まれます。もう合わない予定や考えを、一つ軽くしましょう。",
            hint: "やめるものを決める"
        )
    ]

    func story(for number: Int, theme: NumberTheme) -> Story {
        let base = stories[number] ?? stories[9]!

        switch theme {
        case .today:
            return base
        case .name:
            return Story(
                title: base.title,
                message: "名前から見ると、\(base.message)",
                hint: base.hint
            )
        case .choice:
            return Story(
                title: base.title,
                message: "迷った時の合図としては、\(base.message)",
                hint: base.hint
            )
        case .custom:
            return Story(
                title: base.title,
                message: "入力した数字や言葉から見ると、\(base.message)",
                hint: base.hint
            )
        }
    }
}
