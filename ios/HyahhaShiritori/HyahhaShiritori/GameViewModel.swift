import Foundation

final class GameViewModel: ObservableObject {
    @Published var state: BattleState = .title
    @Published var difficulty: Difficulty = .beginner
    @Published var opponentIndex = 0
    @Published var promptWord = "りんご"
    @Published var cards: [WordCard] = []
    @Published var combo = 0
    @Published var misses = 0
    @Published var timeLeft = 24
    @Published var message = "荒野の鐘が鳴っている。"
    @Published var logs: [BattleLog] = []

    private let factory = CardFactory()
    private let defaults = UserDefaults.standard
    private let unlockKey = "hyahha.unlockedDifficulty"
    private let clearedKey = "hyahha.clearedOpponent"
    private var didExpireCurrentTurn = false

    var opponents: [Opponent] { GameData.opponents }
    var opponent: Opponent { opponents[min(opponentIndex, opponents.count - 1)] }

    var maxUnlockedDifficulty: Difficulty {
        Difficulty(rawValue: defaults.integer(forKey: unlockKey)) ?? .beginner
    }

    var progressText: String {
        "\(opponentIndex + 1) / \(opponents.count)"
    }

    var requiredKana: String {
        ShiritoriEngine.lastKana(of: promptWord)
    }

    var dangerText: String {
        switch misses {
        case 0: "地下牢警報なし"
        case 1: "警報灯、点灯"
        case 2: "あと1ミスで地下行き"
        default: "連行準備完了"
        }
    }

    var canContinue: Bool {
        state == .roundWon || state == .roundLost || state == .cleared
    }

    init() {
        opponentIndex = min(defaults.integer(forKey: clearedKey), GameData.opponents.count - 1)
        difficulty = maxUnlockedDifficulty
        prepareTitle()
    }

    func prepareTitle() {
        state = .title
        message = "水も食料も、語尾で奪い取れ。"
    }

    func chooseDifficulty(_ newValue: Difficulty) {
        guard newValue.rawValue <= maxUnlockedDifficulty.rawValue else {
            message = "\(newValue.title)はまだ封鎖中だ。まず前の難易度を制覇しろ。"
            return
        }

        difficulty = newValue
        message = "\(newValue.title)ルールに切り替えた。"
    }

    func startBattle() {
        combo = 0
        misses = 0
        logs = []
        state = .playing
        promptWord = nextSafePrompt()
        message = opponent.quote
        resetTurn()
        addLog("\(opponent.name)「\(promptWord)」")
    }

    func choose(_ card: WordCard) {
        guard state == .playing else { return }

        switch card.kind {
        case .correct:
            handleCorrect(card.word)
        case .wrong:
            handleWrong(card.word)
        case .trap:
            handleTrap(card.word)
        }
    }

    func tick() {
        guard state == .playing, timeLeft > 0 else { return }
        timeLeft -= 1

        if timeLeft == 0, !didExpireCurrentTurn {
            didExpireCurrentTurn = true
            misses += 1
            addLog("時間切れ。語尾が砂に消えた。")

            if misses >= 3 {
                state = .roundLost
                message = "警報灯が真っ赤に回った。語彙力不足、地下行き。"
            } else {
                message = "時間切れ。次は迷うな。"
                resetTurn(keepPrompt: true)
            }
        }
    }

    func next() {
        switch state {
        case .roundWon:
            advanceOpponent()
        case .roundLost:
            startBattle()
        case .cleared:
            prepareTitle()
        case .title, .playing:
            break
        }
    }

    func restartFromBeginning() {
        opponentIndex = 0
        defaults.set(0, forKey: clearedKey)
        prepareTitle()
    }

    private func handleCorrect(_ word: String) {
        combo += 1
        promptWord = word
        addLog("接続成功: \(word)")

        if combo >= difficulty.targetCombo {
            state = .roundWon
            message = "\(opponent.name)が一歩下がった。コロニー通過だ。"
            saveProgressIfNeeded()
            return
        }

        message = comboMessage
        resetTurn()
    }

    private func handleWrong(_ word: String) {
        misses += 1
        addLog("ミス: \(word)")

        if misses >= 3 {
            state = .roundLost
            message = "語尾が切れた。地下牢のエレベーターが開く。"
        } else {
            message = "つながっていない。フェンスの向こうがざわつく。"
            resetTurn(keepPrompt: true)
        }
    }

    private func handleTrap(_ word: String) {
        misses = 3
        addLog("禁断の「ん」: \(word)")
        state = .roundLost
        message = "終わりの文字を踏んだ。荒野が一瞬だけ静かになった。"
    }

    private func resetTurn(keepPrompt: Bool = false) {
        didExpireCurrentTurn = false
        timeLeft = difficulty.timeLimit

        if !keepPrompt, ShiritoriEngine.isNTrap(promptWord) {
            promptWord = nextSafePrompt()
        }

        cards = factory.cards(after: promptWord, difficulty: difficulty, combo: combo)
    }

    private func nextSafePrompt() -> String {
        let safeWords = opponent.firstWords.filter { !ShiritoriEngine.isNTrap($0) }
        return safeWords.randomElement() ?? "りんご"
    }

    private func advanceOpponent() {
        if opponentIndex + 1 >= opponents.count {
            unlockNextDifficultyIfNeeded()
            state = .cleared
            message = "\(difficulty.title)を制覇。語彙の楽園の門が少し開いた。"
            return
        }

        opponentIndex += 1
        defaults.set(opponentIndex, forKey: clearedKey)
        startBattle()
    }

    private func saveProgressIfNeeded() {
        defaults.set(max(defaults.integer(forKey: clearedKey), opponentIndex), forKey: clearedKey)
    }

    private func unlockNextDifficultyIfNeeded() {
        let nextRaw = min(difficulty.rawValue + 1, Difficulty.hard.rawValue)
        defaults.set(max(defaults.integer(forKey: unlockKey), nextRaw), forKey: unlockKey)
    }

    private var comboMessage: String {
        switch combo {
        case 0...2: "つながった。まだ荒野は静かだ。"
        case 3...4: "語彙コンボ。鉄板に火花が走る。"
        case 5...7: "しりとり無双。観客がフェンスを叩く。"
        default: "語尾支配者。相手の笑みが消えた。"
        }
    }

    private func addLog(_ text: String) {
        logs.insert(BattleLog(text: text), at: 0)
        if logs.count > 6 {
            logs.removeLast()
        }
    }
}
