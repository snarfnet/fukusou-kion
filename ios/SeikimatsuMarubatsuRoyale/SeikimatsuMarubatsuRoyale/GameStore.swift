import SwiftUI

@MainActor
final class GameStore: ObservableObject {
    @Published var phase: AppPhase = .title
    @Published var storyIndex = 0
    @Published var board: [BoardCell] = []
    @Published var currentPlayer = 0
    @Published var winner: Player?
    @Published var message = "STARTを押せ。荒野が待っている。"
    @Published var scraps = 600
    @Published var gasGauge = 0
    @Published var rewards: [GachaReward] = []
    @Published var turnCount = 0
    @Published var aiHandMove: AIHandMove?

    private let storySeenKey = "seikimatsu.storySeen"

    let story = [
        "20XX年。文明は崩壊した。",
        "水も、食料も、ガソリンも足りない。",
        "荒野の女戦士たちは、古代の戦争ゲームを掘り起こした。",
        "その名は、マルバツ。ただし、爆発する。",
        "5つ並べろ。裏切られる前に。"
    ]

    let players = [
        Player(id: 0, name: "赤の戦士", symbol: "○", color: .red, line: "水は渡さねぇ"),
        Player(id: 1, name: "青のメカ少女", symbol: "×", color: .cyan, line: "破壊ルート、確定"),
        Player(id: 2, name: "黄の女王", symbol: "○", color: .yellow, line: "ひざまずけ"),
        Player(id: 3, name: "緑のチャンプ", symbol: "×", color: .green, line: "盤面ごと殴る")
    ]

    var storySeen: Bool {
        UserDefaults.standard.bool(forKey: storySeenKey)
    }

    var current: Player {
        players[currentPlayer]
    }

    var isHumanTurn: Bool {
        phase == .battle && currentPlayer == 0 && winner == nil
    }

    func startTapped() {
        if storySeen {
            phase = .menu
        } else {
            storyIndex = 0
            phase = .story
        }
    }

    func replayStory() {
        storyIndex = 0
        phase = .story
    }

    func nextStory() {
        if storyIndex >= story.count - 1 {
            finishStory()
        } else {
            storyIndex += 1
        }
    }

    func finishStory() {
        UserDefaults.standard.set(true, forKey: storySeenKey)
        phase = .menu
    }

    func startBattle() {
        board = (0..<100).map { BoardCell(id: $0, owner: nil, hasMine: false, hasGas: false, contaminatedTurns: 0) }
        winner = nil
        currentPlayer = 0
        gasGauge = 0
        turnCount = 0
        aiHandMove = nil
        message = "赤の戦士のターン。5つ並べろ。"

        for id in Array(0..<100).shuffled().prefix(10) {
            board[id].hasMine = true
        }
        for id in Array(0..<100).shuffled().prefix(8) where !board[id].hasMine {
            board[id].hasGas = true
        }

        phase = .battle
    }

    func tapCell(_ id: Int) {
        guard isHumanTurn, board.indices.contains(id), board[id].owner == nil else { return }
        aiHandMove = nil
        place(playerID: 0, at: id)
    }

    func bikeCharge() {
        guard isHumanTurn, gasGauge >= 3 else { return }
        gasGauge -= 3
        let rowScores = (0..<10).map { row in
            (row, (0..<10).filter { board[row * 10 + $0].owner != nil }.count)
        }
        let row = rowScores.max(by: { $0.1 < $1.1 })?.0 ?? Int.random(in: 0..<10)
        for col in 0..<10 {
            board[row * 10 + col].owner = nil
        }
        message = "ヒャッハー！！ バイク突撃で横一列を吹き飛ばした。"
        advanceTurn()
    }

    func openGacha() {
        phase = .gacha
    }

    func pullGacha() {
        guard scraps >= 300 else {
            message = "スクラップが足りない。勝って奪え。"
            return
        }
        scraps -= 300
        grantGachaReward()
    }

    func pullRewardedGacha() {
        grantGachaReward()
    }

    private func grantGachaReward() {
        let pool = [
            GachaReward(name: "ガスマスク女", rarity: "R"),
            GachaReward(name: "モヒカン女王", rarity: "SR"),
            GachaReward(name: "改造メカ少女", rarity: "SSR"),
            GachaReward(name: "爆炎勝利演出", rarity: "SR"),
            GachaReward(name: "ヒャッハーボイス", rarity: "R"),
            GachaReward(name: "錆びた盤面テーマ", rarity: "N")
        ]
        let reward = pool.randomElement()!
        rewards.insert(reward, at: 0)
        message = "\(reward.rarity) \(reward.name) を入手。"
    }

    func backToMenu() {
        phase = .menu
    }

    func backToTitle() {
        phase = .title
    }

    private func place(playerID: Int, at id: Int) {
        guard board.indices.contains(id), winner == nil else { return }
        let player = players[playerID]

        if board[id].hasMine {
            explode(center: id)
            message = "\(player.name)が地雷を踏んだ。周囲が消し飛んだ。"
            advanceTurn()
            return
        }

        board[id].owner = playerID
        if board[id].hasGas {
            board[id].hasGas = false
            if playerID == 0 {
                gasGauge += 1
                scraps += 20
            }
            message = "\(player.name)がガソリン缶を拾った。"
        } else {
            message = "\(player.name)：\(player.line)"
        }

        if checkWin(for: playerID) {
            winner = player
            scraps += playerID == 0 ? 120 : 30
            phase = .result
            message = playerID == 0 ? "勝利。スクラップを奪い取った。" : "\(player.name)に領地を奪われた。参加報酬だけ持ち帰れ。"
            return
        }

        advanceTurn()
    }

    private func advanceTurn() {
        guard phase == .battle, winner == nil else { return }
        decayContamination()
        turnCount += 1
        if turnCount.isMultiple(of: 5) {
            contaminateRandomCells()
        }
        if board.allSatisfy({ $0.owner != nil || $0.hasMine }) {
            phase = .result
            message = "盤面が埋まった。荒野に勝者はいない。"
            return
        }

        currentPlayer = (currentPlayer + 1) % players.count
        if currentPlayer == 0 {
            message = "赤の戦士のターン。"
        } else {
            let delay = 0.55 + Double(currentPlayer) * 0.15
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                Task { @MainActor in
                    self?.cpuMove()
                }
            }
        }
    }

    private func cpuMove() {
        guard phase == .battle, currentPlayer != 0, winner == nil else { return }
        let playerID = currentPlayer
        guard let id = chooseMove(for: playerID) else { return }
        aiHandMove = AIHandMove(playerID: playerID, targetCell: id)
        message = "\(players[playerID].name)縺悟虚縺上・"

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.82) { [weak self] in
            Task { @MainActor in
                guard let self,
                      self.phase == .battle,
                      self.currentPlayer == playerID,
                      self.winner == nil else { return }
                self.aiHandMove = nil
                self.place(playerID: playerID, at: id)
            }
        }
    }

    private func chooseMove(for playerID: Int) -> Int? {
        if let win = winningMove(for: playerID) { return win }
        if let block = winningMove(for: 0) { return block }
        let candidates = board.filter { $0.owner == nil && !$0.hasMine }.map(\.id)
        return candidates.randomElement() ?? board.filter({ $0.owner == nil }).map(\.id).randomElement()
    }

    private func winningMove(for playerID: Int) -> Int? {
        for cell in board where cell.owner == nil && !cell.hasMine {
            var copy = board
            copy[cell.id].owner = playerID
            if checkWin(for: playerID, in: copy) {
                return cell.id
            }
        }
        return nil
    }

    private func explode(center: Int) {
        let row = center / 10
        let col = center % 10
        for dr in -1...1 {
            for dc in -1...1 {
                let nr = row + dr
                let nc = col + dc
                guard (0..<10).contains(nr), (0..<10).contains(nc) else { continue }
                let idx = nr * 10 + nc
                board[idx].owner = nil
                board[idx].hasMine = false
                board[idx].hasGas = false
                board[idx].contaminatedTurns = 0
            }
        }
    }

    private func contaminateRandomCells() {
        for id in board.indices.shuffled().prefix(4) {
            board[id].contaminatedTurns = 2
        }
        message = "汚染エリア発生。紫のマスは腐る。"
    }

    private func decayContamination() {
        for index in board.indices where board[index].contaminatedTurns > 0 {
            board[index].contaminatedTurns -= 1
            if board[index].contaminatedTurns == 0 {
                board[index].owner = nil
            }
        }
    }

    private func checkWin(for playerID: Int) -> Bool {
        checkWin(for: playerID, in: board)
    }

    private func checkWin(for playerID: Int, in board: [BoardCell]) -> Bool {
        let directions = [(1, 0), (0, 1), (1, 1), (1, -1)]
        for row in 0..<10 {
            for col in 0..<10 {
                for direction in directions {
                    var matched = true
                    for step in 0..<5 {
                        let nr = row + direction.0 * step
                        let nc = col + direction.1 * step
                        if !(0..<10).contains(nr) || !(0..<10).contains(nc) || board[nr * 10 + nc].owner != playerID {
                            matched = false
                            break
                        }
                    }
                    if matched { return true }
                }
            }
        }
        return false
    }
}
