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
        .init(id: 8, stage: .rubedo, title: "完成を閉じない", sourceIdea: "変容の循環は、完成を固定せず、次の素材へ戻る動きとして読めます。", reflection: "今日の終わりを、次の始まりに変える一文は何ですか。", practice: "明日の自分へ、短い指示を一つ残す。")
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
