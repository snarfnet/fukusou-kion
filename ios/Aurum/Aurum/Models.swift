import Foundation
import Combine

private func localized(_ key: String, comment: String) -> String {
    let value = NSLocalizedString(key, comment: comment)
    if Bundle.main.preferredLocalizations.first?.hasPrefix("ja") == true { return value }
    guard value == key,
          let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
          let english = Bundle(path: path) else { return value }
    return english.localizedString(forKey: key, value: key, table: nil)
}

struct Wisdom: Identifiable, Hashable {
    let id: Int
    let stage: Stage
    private let titleKey: String
    private let sourceIdeaKey: String
    private let reflectionKey: String
    private let practiceKey: String

    init(id: Int, stage: Stage, title: String, sourceIdea: String, reflection: String, practice: String) {
        self.id = id
        self.stage = stage
        titleKey = title
        sourceIdeaKey = sourceIdea
        reflectionKey = reflection
        practiceKey = practice
    }

    var title: String { localized(titleKey, comment: "Wisdom title") }
    var sourceIdea: String { localized(sourceIdeaKey, comment: "Source idea") }
    var reflection: String { localized(reflectionKey, comment: "Reflection prompt") }
    var practice: String { localized(practiceKey, comment: "Practice instruction") }
}

enum Stage: String, CaseIterable, Codable {
    case nigredo, albedo, citrinitas, rubedo

    var displayName: String {
        switch self {
        case .nigredo: localized("黒化", comment: "Alchemy stage")
        case .albedo: localized("白化", comment: "Alchemy stage")
        case .citrinitas: localized("黄化", comment: "Alchemy stage")
        case .rubedo: localized("赤化", comment: "Alchemy stage")
        }
    }

    var subtitle: String {
        switch self {
        case .nigredo: localized("ほどく", comment: "Stage action")
        case .albedo: localized("澄ませる", comment: "Stage action")
        case .citrinitas: localized("見いだす", comment: "Stage action")
        case .rubedo: localized("結び直す", comment: "Stage action")
        }
    }

    var mark: String {
        switch self {
        case .nigredo: "moon.haze.fill"
        case .albedo: "drop.fill"
        case .citrinitas: "sun.horizon.fill"
        case .rubedo: "flame.fill"
        }
    }
}

struct PracticeEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let wisdomID: Int
    let stage: Stage
    let note: String
}

enum Library {
    static let wisdom: [Wisdom] = [
        .init(id: 1, stage: .nigredo, title: "混沌に名を与える", sourceIdea: "錬金術文献では、変容は未分化な素材を見つめるところから始まります。", reflection: "いま、ひとまとめにして『問題』と呼んでいるものは何ですか。", practice: "紙に三つへ分けて書き、今日扱う一つだけに丸をつける。"),
        .init(id: 2, stage: .nigredo, title: "分解は破壊ではない", sourceIdea: "古い錬金術は、物質の変成を神学的・精神的な比喩としても語りました。", reflection: "手放せば、形を変えられる習慣はありますか。", practice: "役目を終えた小さな習慣を一日だけ休む。"),
        .init(id: 3, stage: .albedo, title: "器を洗う", sourceIdea: "器は、素材を受け止め、混ぜ、変化を待つための象徴です。", reflection: "余計な刺激を一つ減らすなら、何を選びますか。", practice: "三分間、机の上かホーム画面を静かに整える。"),
        .init(id: 4, stage: .albedo, title: "区別して観る", sourceIdea: "象徴は答えそのものではなく、考えるための鏡として働きます。", reflection: "事実と解釈が混ざっている箇所はどこですか。", practice: "一行を『見たこと』、次の一行を『感じたこと』として記す。"),
        .init(id: 5, stage: .citrinitas, title: "微かな光を育てる", sourceIdea: "金や太陽は、完成だけでなく、見え始めた理解の比喩にもなりました。", reflection: "最近、以前より少し分かるようになったことは何ですか。", practice: "その気づきを、明日も再現できる一つの動作にする。"),
        .init(id: 6, stage: .citrinitas, title: "上と下を結ぶ", sourceIdea: "ヘルメス思想は、異なる尺度のあいだに対応を見いだそうとしました。", reflection: "大きな願いを、今日の小さな動作にすると何になりますか。", practice: "五分以内で終わる最小の一歩を実行する。"),
        .init(id: 7, stage: .rubedo, title: "知を行いへ戻す", sourceIdea: "錬金術の図像は、言葉だけでは届かない変容を寓話として示しました。", reflection: "知っているのに、まだ行っていないことは何ですか。", practice: "誰にも見せなくてよい形で、一度だけ実行する。"),
        .init(id: 8, stage: .rubedo, title: "完成を閉じない", sourceIdea: "変容の循環は、完成を固定せず、次の素材へ戻る動きとして読めます。", reflection: "今日の終わりを、次の始まりに変える一文は何ですか。", practice: "明日の自分へ、短い指示を一つ残す。"),
        .init(id: 9, stage: .nigredo, title: "影を追い払わない", sourceIdea: "古い寓意図では、暗さは失敗ではなく、まだ形を持たない可能性として描かれました。", reflection: "避け続けることで、かえって力を与えている感情はありますか。", practice: "その感情を評価せず、身体のどこに感じるかを三行で記す。"),
        .init(id: 10, stage: .nigredo, title: "灰の中を調べる", sourceIdea: "灰は燃焼の終わりであると同時に、残った本質を確かめる素材でもありました。", reflection: "終わった出来事から、今も残っている大切なものは何ですか。", practice: "失ったものではなく、残ったものを三つ書く。"),
        .init(id: 11, stage: .albedo, title: "静けさを蒸留する", sourceIdea: "蒸留は、熱と冷却を繰り返しながら、混ざったものから微細な成分を取り出す操作です。", reflection: "騒がしさの奥で、繰り返し現れる考えは何ですか。", practice: "通知を十分間止め、最初と最後に浮かんだ言葉を記す。"),
        .init(id: 12, stage: .albedo, title: "水面を待つ", sourceIdea: "澄んだ水は、急いでかき混ぜず、沈殿を待つことで得られる明晰さの象徴です。", reflection: "今すぐ決めずに、一晩置いたほうがよいことはありますか。", practice: "結論を出さず、確かな事実だけを箇条書きにする。"),
        .init(id: 13, stage: .citrinitas, title: "兆しを集める", sourceIdea: "夜明けの黄は、完成前に訪れる理解の兆しとして錬金術の色彩に位置づけられました。", reflection: "望む方向へ進んでいると分かる、小さな兆候は何ですか。", practice: "今日見つけた前進の証拠を一つ保存する。"),
        .init(id: 14, stage: .citrinitas, title: "尺度を変える", sourceIdea: "古の自然哲学は、同じ秩序を天体、季節、身体、暮らしの異なる尺度に読み取りました。", reflection: "一年の課題として見るのと、今日の課題として見るのでは何が変わりますか。", practice: "課題を一年、一月、一日の三つの尺度で一行ずつ書く。"),
        .init(id: 15, stage: .rubedo, title: "相反するものを結ぶ", sourceIdea: "赤化は、対立する性質を消さずに、一つの働きへ統合する段階として語られました。", reflection: "どちらかを捨てずに両方を生かせる選択はありますか。", practice: "二つの望みを『そして』でつなぎ、新しい一文を作る。"),
        .init(id: 16, stage: .rubedo, title: "日常へ金を戻す", sourceIdea: "賢者の石は富そのものより、卑近な素材に価値を見いだす変容の象徴としても読めます。", reflection: "すでに持っているのに、価値を見落としているものは何ですか。", practice: "身近な一つを手入れし、使える状態に戻す。")
    ]
}

@MainActor
final class PracticeStore: ObservableObject {
    @Published private(set) var entries: [PracticeEntry] = []
    @Published private(set) var favoriteIDs: Set<Int> = []
    private let key = "aurum.entries.v1"
    private let favoritesKey = "aurum.favorites.v1"

    init() { load() }

    var streak: Int {
        let days = Set(entries.map { Calendar.current.startOfDay(for: $0.date) })
        var count = 0
        var day = Calendar.current.startOfDay(for: .now)
        while days.contains(day) {
            count += 1
            guard let previous = Calendar.current.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return count
    }

    var practicedDays: Int {
        Set(entries.map { Calendar.current.startOfDay(for: $0.date) }).count
    }

    var exportText: String {
        entries.map { entry in
            let title = wisdom(for: entry)?.title ?? NSLocalizedString("実践", comment: "Practice")
            let date = entry.date.formatted(date: .abbreviated, time: .omitted)
            return "\(date) | \(entry.stage.displayName) | \(title)\n\(entry.note)"
        }.joined(separator: "\n\n")
    }

    func save(wisdom: Wisdom, note: String) {
        let entry = PracticeEntry(id: UUID(), date: .now, wisdomID: wisdom.id, stage: wisdom.stage, note: note.trimmingCharacters(in: .whitespacesAndNewlines))
        entries.insert(entry, at: 0)
        persist()
    }

    func isFavorite(_ wisdom: Wisdom) -> Bool { favoriteIDs.contains(wisdom.id) }

    func toggleFavorite(_ wisdom: Wisdom) {
        if favoriteIDs.contains(wisdom.id) { favoriteIDs.remove(wisdom.id) }
        else { favoriteIDs.insert(wisdom.id) }
        UserDefaults.standard.set(Array(favoriteIDs), forKey: favoritesKey)
    }

    func delete(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) { entries.remove(at: index) }
        persist()
    }

    func wisdom(for entry: PracticeEntry) -> Wisdom? { Library.wisdom.first { $0.id == entry.wisdomID } }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: key), let decoded = try? JSONDecoder().decode([PracticeEntry].self, from: data) {
            entries = decoded
        }
        favoriteIDs = Set(UserDefaults.standard.array(forKey: favoritesKey) as? [Int] ?? [])
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}
