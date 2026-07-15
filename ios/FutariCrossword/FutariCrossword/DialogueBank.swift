import Foundation

enum DialogueBank {
    static func line(for event: DialogueEvent, size: Int, streak: Int, excluding recent: Set<String>) -> CompanionLine {
        let lines = candidates(for: event, size: size, streak: streak)
        return lines.filter { !recent.contains($0.text) }.randomElement() ?? lines.randomElement()!
    }

    private static func candidates(for event: DialogueEvent, size: Int, streak: Int) -> [CompanionLine] {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeGreeting = hour < 11 ? "おはよう。今日も一緒に解こっか" : hour < 18 ? "ちょうどいいところ。少し一緒に遊ぼう？" : "こんばんは。ゆっくりしていってね"
        switch event {
        case .launch:
            return lines(event, .gentle, [timeGreeting, "来てくれたんだ。今日はどの大きさにする？", "席、取っておいたよ。コーヒーも頼む？", "今日も会えたね。のんびり解こうよ"])
        case .generated:
            let special = size >= 18 ? "\(size)×\(size)？ 長居になりそうだね。最後まで付き合うよ" : size <= 5 ? "\(size)×\(size)なら、コーヒーが冷める前に解けるかな" : "\(size)×\(size)、ちょうど楽しそう"
            return lines(event, .delighted, [special, "新しい問題、できたよ。どこから見ようか", "今回はどんな言葉が隠れてるんだろう", "いい盤面だね。焦らずいこう", "最初の一問、一緒に探そっか"])
        case .selected:
            return lines(event, .thinking, ["うん、そこ気になるよね", "交差する言葉も見てみようか", "声に出して読むと浮かぶかも", "知ってる言葉のような気がする", "少しだけ考える時間にしよ", "答えの長さも手がかりだよ"])
        case .correct:
            return lines(event, .delighted, ["正解！ 私もそれだと思ってた", "ぴったり。気持ちいいね", "さすが。迷いがなかったね", "当たり。次もこの調子", "うれしい、ひとつ埋まったね", "その答えで合ってるよ"])
        case .incorrect:
            return lines(event, .worried, ["惜しい。交差する文字を見直してみよ", "うーん、少し違うみたい", "大丈夫。別の言葉から戻ってこよう", "ここは一度置いておいてもいいよ", "あと少しな気がするんだけどな", "私も一緒に考え直すね"])
        case .hint:
            return lines(event, .proud, ["じゃあ、ひと文字だけね", "こっそり手がかりを置いておくね", "ここが分かれば進みそう", "ヒントを使うのも作戦だよ", "この文字から考えてみて", "答えは言わない。約束だからね"])
        case .streak:
            return lines(event, .surprised, ["\(streak)問連続？ 今日は冴えてるね", "すごい、止まらないね", "私の出番、なくなっちゃうかも", "その調子。見てるだけで楽しい", "息が合ってきた気がする"])
        case .completed:
            return lines(event, .shy, ["全部解けたね。もう少し一緒にいたかったな", "完成！ 今日も楽しかった", "最後まで一緒に解けてうれしい", "おつかれさま。次も隣にいていい？", "きれいに埋まったね。記念に眺めておこ"])
        case .idle:
            return lines(event, .cheering, ["難しい？ 急がなくていいよ", "コーヒー、冷めちゃうね", "ひと休みしてから続けよっか", "私はここにいるから、ゆっくりで大丈夫", "別の問題から見てもいいんだよ", "窓の外を見てた？ 戻ってきたら続きをしよ"])
        }
    }

    private static func lines(_ event: DialogueEvent, _ expression: CompanionExpression, _ texts: [String]) -> [CompanionLine] {
        texts.map { CompanionLine(event: event, expression: expression, text: $0) }
    }
}

