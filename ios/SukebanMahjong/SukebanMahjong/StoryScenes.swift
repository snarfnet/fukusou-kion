import Foundation

struct StoryLine {
    let speaker: String
    let text: String
    let chapterNumber: Int?
    let chapterTitle: String?
    let featuredCharacterIDs: [Int]

    init(
        speaker: String,
        text: String,
        chapterNumber: Int? = nil,
        chapterTitle: String? = nil,
        featuredCharacterIDs: [Int] = []
    ) {
        self.speaker = speaker
        self.text = text
        self.chapterNumber = chapterNumber
        self.chapterTitle = chapterTitle
        self.featuredCharacterIDs = featuredCharacterIDs
    }
}

enum StoryScenes {
    static let allChapters: [StoryLine] = StoryChapterData.all
    static let prologue: [StoryLine] = chapterRange(1...6)

    static func intro(for girl: Sukeban) -> [StoryLine] {
        guard (1...5).contains(girl.id) else {
            return [.init(speaker: "朱莉", text: "紅天女学院、火神朱莉。牌で話をつけよう。")]
        }
        let first = 7 + (girl.id - 1) * 12
        return chapterRange(first...(first + 5))
    }

    static func outro(for girl: Sukeban) -> [StoryLine] {
        guard (1...5).contains(girl.id) else {
            return [.init(speaker: girl.name, text: "この借りは、いつか返す。")]
        }
        let first = 13 + (girl.id - 1) * 12
        return chapterRange(first...(first + 5))
    }

    static let epilogue: [String] = [
        "白鷺麗華は家の船を買い戻し、冬だけ紅天女の臨時講師になった。",
        "九十九蘭は姉と再会し、六校の文化祭で千個のたこ焼きを焼いた。",
        "伊集院紫苑の漫画『雀華番長』は、新人賞の最終候補へ残った。",
        "鬼塚虎子は親友の車椅子を改造し、二人で赤城の頂上へ登った。",
        "皇千鶴は黒薔薇の髪飾りを外さず、生徒会選挙へ立候補した。",
        "火神朱莉は祖母の雀荘へ百人分の名札を飾った。全国制覇は、皆の始まりになった。"
    ]

    static func unlockedChapterCount(clearedSchoolCount: Int) -> Int {
        min(66, max(0, 6 + max(0, clearedSchoolCount - 1) * 12))
    }

    private static func chapterRange(_ range: ClosedRange<Int>) -> [StoryLine] {
        allChapters.filter { line in
            guard let number = line.chapterNumber else { return false }
            return range.contains(number)
        }
    }
}
