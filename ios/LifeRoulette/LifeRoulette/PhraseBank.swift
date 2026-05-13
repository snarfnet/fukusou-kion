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
            message: "今日は小さく始める日。完璧に整うのを待つより、最初の一歩を置くほうが流れに乗れます。",
            hint: "最初の5分だけ動く"
        ),
        2: Story(
            title: "つなぐ数字",
            message: "誰かとのやり取りに答えがありそうです。自分だけで抱えず、一言だけ相談してみてください。",
            hint: "短いメッセージを送る"
        ),
        3: Story(
            title: "ひらめきの数字",
            message: "少し遊びを入れると進みます。正しさだけで詰めず、試作品を出して反応を見ましょう。",
            hint: "案を3つ書く"
        ),
        4: Story(
            title: "土台の数字",
            message: "派手な動きより、足元を整える日です。机、予定、持ち物のどれかを片付けると気持ちも軽くなります。",
            hint: "ひとつだけ整える"
        ),
        5: Story(
            title: "変化の数字",
            message: "予定通りにいかなくても大丈夫。少し道を変えた先に、今の自分に合う答えがあります。",
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
            message: "結果を出す力が強い日です。大きな目標を、今日終わる作業まで小さくすると進みます。",
            hint: "締切をひとつ決める"
        ),
        9: Story(
            title: "手放す数字",
            message: "終わらせることで、新しい余白が生まれます。もう合わない予定や考えを、ひとつ軽くしましょう。",
            hint: "やめるものを決める"
        )
    ]

    func story(for number: Int, theme: NumberTheme) -> Story {
        let base = stories[number] ?? stories[9]!
        switch theme {
        case .today:
            return base
        case .name:
            return Story(title: base.title, message: "名前から見ると、\(base.message)", hint: base.hint)
        case .choice:
            return Story(title: base.title, message: "迷った時の合図としては、\(base.message)", hint: base.hint)
        case .custom:
            return Story(title: base.title, message: "入力した数字から見ると、\(base.message)", hint: base.hint)
        }
    }
}
