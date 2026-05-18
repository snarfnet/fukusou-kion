import SwiftUI

@MainActor
final class GameStore: ObservableObject {
    static let boardSize = 8
    static let winLength = 4
    static let boardCellCount = boardSize * boardSize

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
    @Published var selectedCharacterID = "gasmask"
    @Published var unlockedCharacterIDs: Set<String> = ["gasmask"]
    @Published var abilityUsesLeft = 0
    @Published var shieldPlates = 0
    @Published var abilityCutIn: AbilityCutIn?

    private let storySeenKey = "seikimatsu.storySeen"
    private let scrapsKey = "seikimatsu.scraps"
    private let selectedCharacterKey = "seikimatsu.selectedCharacter"
    private let unlockedCharactersKey = "seikimatsu.unlockedCharacters"

    let story = [
        "20XX年。文明は崩壊した。",
        "水も、食料も、ガソリンも足りない。",
        "荒野の女戦士たちは、古代の戦争ゲームを掘り起こした。",
        "その名は、マルバツ。ただし、爆発する。",
        "5つ並べろ。奪われる前に。"
    ]

    let characters: [BattleCharacter] = [
        BattleCharacter(
            id: "rustaxe",
            name: "錆び斧ガール",
            title: "荒削り",
            rarity: .n,
            imageName: "CharacterGasmask",
            abilityName: "釘ばらまき",
            abilityKind: .mineScatter,
            maxUses: 1,
            line: "まだ倒れない"
        ),
        BattleCharacter(
            id: "gasmask",
            name: "ガスマスク女",
            title: "腐食ガス",
            rarity: .r,
            imageName: "CharacterGasmask",
            abilityName: "毒霧散布",
            abilityKind: .mineScatter,
            maxUses: 1,
            line: "水は渡さねぇ"
        ),
        BattleCharacter(
            id: "mohawk",
            name: "モヒカン女王",
            title: "荒野の支配者",
            rarity: .sr,
            imageName: "CharacterMohawk",
            abilityName: "略奪号令",
            abilityKind: .bikeCharge,
            maxUses: 1,
            line: "そこ置くとか雑魚？"
        ),
        BattleCharacter(
            id: "flame",
            name: "火炎放射ギャル",
            title: "火炎一掃",
            rarity: .ssr,
            imageName: "CharacterFlame",
            abilityName: "火炎放射",
            abilityKind: .flameThrower,
            maxUses: 2,
            line: "ヒャハハハ！！燃えろ！"
        ),
        BattleCharacter(
            id: "mech",
            name: "改造メカ少女",
            title: "電子制圧",
            rarity: .ur,
            imageName: "CharacterMech",
            abilityName: "EMP爆弾",
            abilityKind: .empBomb,
            maxUses: 2,
            line: "終わりだな"
        ),
        BattleCharacter(
            id: "champ",
            name: "地下闘技場チャンプ",
            title: "連打破壊",
            rarity: .sr,
            imageName: "CharacterChampion",
            abilityName: "鉄拳ラッシュ",
            abilityKind: .overdrive,
            maxUses: 1,
            line: "裏切ったな！？"
        )
    ]

    let players = [
        Player(id: 0, name: "主人公", symbol: "○", color: .red, line: "ここは私の領地だ"),
        Player(id: 1, name: "メカ少女", symbol: "×", color: .cyan, line: "破壊ルート、確定"),
        Player(id: 2, name: "女王", symbol: "○", color: .yellow, line: "ひれ伏しな"),
        Player(id: 3, name: "火炎ギャル", symbol: "×", color: .green, line: "燃やして進む")
    ]

    init() {
        let savedScraps = UserDefaults.standard.integer(forKey: scrapsKey)
        if savedScraps > 0 {
            scraps = savedScraps
        }
        if let savedSelected = UserDefaults.standard.string(forKey: selectedCharacterKey) {
            selectedCharacterID = savedSelected
        }
        if let savedUnlocked = UserDefaults.standard.stringArray(forKey: unlockedCharactersKey) {
            unlockedCharacterIDs = Set(savedUnlocked)
            unlockedCharacterIDs.insert("gasmask")
        }
        if !unlockedCharacterIDs.contains(selectedCharacterID) {
            selectedCharacterID = "gasmask"
        }
    }

    var storySeen: Bool {
        UserDefaults.standard.bool(forKey: storySeenKey)
    }

    var current: Player {
        players[currentPlayer]
    }

    var selectedCharacter: BattleCharacter {
        characters.first { $0.id == selectedCharacterID } ?? characters[0]
    }

    var sortedCharacters: [BattleCharacter] {
        characters.sorted {
            if $0.rarity == $1.rarity { return $0.name < $1.name }
            return $0.rarity > $1.rarity
        }
    }

    var isHumanTurn: Bool {
        phase == .battle && currentPlayer == 0 && winner == nil && aiHandMove == nil && abilityCutIn == nil
    }

    var canUseAbility: Bool {
        isHumanTurn && abilityUsesLeft > 0
    }

    var hasHumanReach: Bool {
        phase == .battle && openLineScore(for: 0) >= Self.winLength - 1
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

    func selectCharacter(_ character: BattleCharacter) {
        guard unlockedCharacterIDs.contains(character.id) else { return }
        selectedCharacterID = character.id
        saveProgress()
        message = "\(character.name)を選んだ。\(character.abilityName)で荒野を荒らせ。"
    }

    func startBattle() {
        board = (0..<Self.boardCellCount).map {
            BoardCell(id: $0, owner: nil, hasMine: false, hasGas: false, hasScrapTrap: false, hasShield: false, shieldOwner: nil, contaminatedTurns: 0)
        }
        winner = nil
        currentPlayer = 0
        gasGauge = 0
        shieldPlates = 0
        turnCount = 0
        aiHandMove = nil
        abilityCutIn = nil
        abilityUsesLeft = selectedCharacter.maxUses
        message = "\(selectedCharacter.name)の出番。5つ並べろ。"

        let mineCount = 4
        let gasCount = 7
        let trapCount = 4
        let shieldCount = 5
        for id in emptyIDs().shuffled().prefix(mineCount) {
            board[id].hasMine = true
        }
        for id in emptyIDs().shuffled().prefix(gasCount) where !board[id].hasMine {
            board[id].hasGas = true
        }
        for id in emptyIDs().shuffled().prefix(trapCount) where !board[id].hasMine && !board[id].hasGas {
            board[id].hasScrapTrap = true
        }
        for id in emptyIDs().shuffled().prefix(shieldCount) {
            board[id].hasShield = true
        }

        phase = .battle
    }

    func tapCell(_ id: Int) {
        guard isHumanTurn, board.indices.contains(id), board[id].owner == nil else { return }
        aiHandMove = nil
        place(playerID: 0, at: id)
    }

    func useCharacterAbility() {
        guard canUseAbility else { return }
        abilityUsesLeft -= 1

        let cutIn = AbilityCutIn(
            character: selectedCharacter,
            title: selectedCharacter.abilityName,
            subtitle: selectedCharacter.line
        )
        abilityCutIn = cutIn

        switch selectedCharacter.abilityKind {
        case .mineScatter:
            scatterMinesNearEnemies()
            message = "\(selectedCharacter.abilityName)。敵の足元に地雷をばらまいた。"
        case .bikeCharge:
            destroyBestEnemyLine(radius: 0)
            gasGauge += 1
            message = "\(selectedCharacter.abilityName)。敵のリーチを1本へし折った。"
        case .flameThrower:
            burnBestLine()
            message = "火炎放射。敵の列が灰になった。"
        case .empBomb:
            empBestCluster()
            message = "EMP爆弾。敵の駒とギミックが沈黙した。"
        case .overdrive:
            destroyBestEnemyLine(radius: 1)
            message = "\(selectedCharacter.abilityName)。敵陣をまとめて殴り抜いた。"
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.18) { [weak self] in
            Task { @MainActor in
                guard let self, self.abilityCutIn?.id == cutIn.id else { return }
                self.abilityCutIn = nil
                self.advanceTurn()
            }
        }
    }

    func useShieldPlate() {
        guard isHumanTurn, shieldPlates > 0 else { return }
        shieldPlates -= 1
        let owned = board.filter { $0.owner == 0 && $0.shieldOwner == nil }.map(\.id)
        let line = bestLineTarget(preferHuman: true).filter { board[$0].owner == 0 && board[$0].shieldOwner == nil }
        let targets = Array((line.isEmpty ? owned : line).prefix(3))
        for id in targets {
            board[id].shieldOwner = 0
        }
        message = targets.isEmpty ? "守る駒がまだない。鉄板は温存した。" : "鉄板シールド。自分の駒を最大3つ守った。"
        if targets.isEmpty {
            shieldPlates += 1
        } else {
            advanceTurn()
        }
    }

    func bikeCharge() {
        guard isHumanTurn, gasGauge >= 3 else { return }
        gasGauge -= 3
        burnBestLine()
        message = "バイク突撃。一直線の駒を吹き飛ばした。"
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
        saveProgress()
        grantGachaReward()
    }

    func pullRewardedGacha() {
        grantGachaReward()
    }

    func backToMenu() {
        phase = .menu
    }

    func backToTitle() {
        phase = .title
    }

    private func grantGachaReward() {
        let character = rollCharacter()
        let isNew = !unlockedCharacterIDs.contains(character.id)
        unlockedCharacterIDs.insert(character.id)
        rewards.insert(GachaReward(character: character, isNew: isNew), at: 0)
        if isNew {
            selectedCharacterID = character.id
            message = "\(character.rarity.rawValue) \(character.name) 解放。スタート画面で選べる。"
        } else {
            let bonus = duplicateBonus(for: character.rarity)
            scraps += bonus
            message = "\(character.rarity.rawValue) \(character.name) は所持済み。\(bonus)スクラップに変換。"
        }
        saveProgress()
    }

    private func rollCharacter() -> BattleCharacter {
        let roll = Int.random(in: 1...100)
        let targetRarity: CharacterRarity
        switch roll {
        case 1...4:
            targetRarity = .ur
        case 5...16:
            targetRarity = .ssr
        case 17...42:
            targetRarity = .sr
        case 43...82:
            targetRarity = .r
        default:
            targetRarity = .n
        }
        return characters.filter { $0.rarity == targetRarity }.randomElement()
            ?? characters.filter { $0.rarity == .r }.randomElement()
            ?? characters[0]
    }

    private func duplicateBonus(for rarity: CharacterRarity) -> Int {
        switch rarity {
        case .n: 40
        case .r: 80
        case .sr: 160
        case .ssr: 300
        case .ur: 600
        }
    }

    private func place(playerID: Int, at id: Int) {
        guard board.indices.contains(id), winner == nil else { return }
        let player = players[playerID]

        if board[id].hasMine {
            if playerID == 0 && shieldPlates > 0 {
                shieldPlates -= 1
                board[id].hasMine = false
                message = "鉄板シールドが地雷を受け止めた。"
                advanceTurn()
                return
            }
            explode(center: id)
            message = "\(player.name)が地雷を踏んだ。周囲が吹き飛んだ。"
            advanceTurn()
            return
        }

        if board[id].hasScrapTrap {
            board[id].hasScrapTrap = false
            if playerID == 0 {
                scraps = max(0, scraps - 80)
                saveProgress()
            }
            message = "\(player.name)がジャンク罠に絡まった。"
            advanceTurn()
            return
        }

        board[id].owner = playerID
        if board[id].hasShield {
            board[id].hasShield = false
            if playerID == 0 {
                shieldPlates += 1
                saveProgress()
            }
            message = "\(player.name)が鉄板シールドを拾った。"
        } else if board[id].hasGas {
            board[id].hasGas = false
            if playerID == 0 {
                gasGauge += 1
                scraps += 20
                saveProgress()
            }
            message = "\(player.name)がガソリン缶を拾った。"
        } else {
            message = "\(player.name)「\(player.line)」"
        }

        if checkWin(for: playerID) {
            winner = player
            scraps += playerID == 0 ? winReward() : 30
            saveProgress()
            phase = .result
            message = playerID == 0 ? "勝利。スクラップを奪い取った。" : "\(player.name)に領地を奪われた。参加報酬だけ持ち帰れ。"
            return
        }

        advanceTurn()
    }

    private func winReward() -> Int {
        120 + selectedCharacter.rarity.rank * 35
    }

    private func advanceTurn() {
        guard phase == .battle, winner == nil else { return }
        decayContamination()
        turnCount += 1
        if turnCount.isMultiple(of: 6) {
            contaminateRandomCells()
        }
        if board.allSatisfy({ $0.owner != nil || $0.hasMine }) {
            phase = .result
            message = "盤面が埋まった。荒野に勝者はいない。"
            return
        }

        currentPlayer = (currentPlayer + 1) % players.count
        if currentPlayer == 0 {
            message = "\(selectedCharacter.name)のターン。"
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

        if shouldCPUUseSabotage(playerID: playerID) {
            cpuSabotage(playerID: playerID)
            advanceTurn()
            return
        }

        guard let id = chooseMove(for: playerID) else { return }
        aiHandMove = AIHandMove(playerID: playerID, targetCell: id)
        message = "\(players[playerID].name)が手を伸ばした。"

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

    private func shouldCPUUseSabotage(playerID: Int) -> Bool {
        guard turnCount > 6 else { return false }
        if openLineScore(for: 0) >= Self.winLength - 1 { return true }
        return Int.random(in: 0..<100) < 12 + playerID * 3
    }

    private func cpuSabotage(playerID: Int) {
        if openLineScore(for: 0) >= Self.winLength - 1 {
            destroyBestHumanLine()
            message = "\(players[playerID].name)が妨害。主人公のリーチを壊した。"
        } else if let target = board.filter({ $0.owner == 0 }).map(\.id).randomElement() {
            board[target].contaminatedTurns = 2
            message = "\(players[playerID].name)が汚染弾を撃ち込んだ。"
        }
    }

    private func chooseMove(for playerID: Int) -> Int? {
        if let win = winningMove(for: playerID) { return win }
        if let block = winningMove(for: 0) { return block }
        if let build = bestBuildMove(for: playerID) { return build }
        let candidates = board.filter { $0.owner == nil && !$0.hasMine && !$0.hasScrapTrap }.map(\.id)
        return candidates.randomElement() ?? board.filter({ $0.owner == nil }).map(\.id).randomElement()
    }

    private func winningMove(for playerID: Int) -> Int? {
        for cell in board where cell.owner == nil && !cell.hasMine && !cell.hasScrapTrap {
            var copy = board
            copy[cell.id].owner = playerID
            if checkWin(for: playerID, in: copy) {
                return cell.id
            }
        }
        return nil
    }

    private func bestBuildMove(for playerID: Int) -> Int? {
        board
            .filter { $0.owner == nil && !$0.hasMine && !$0.hasScrapTrap }
            .map { cell -> (Int, Int) in
                var copy = board
                copy[cell.id].owner = playerID
                return (cell.id, openLineScore(for: playerID, in: copy))
            }
            .max(by: { $0.1 < $1.1 })?
            .0
    }

    private func openLineScore(for playerID: Int, in board: [BoardCell]? = nil) -> Int {
        let board = board ?? self.board
        let directions = [(1, 0), (0, 1), (1, 1), (1, -1)]
        var best = 0
        for row in 0..<Self.boardSize {
            for col in 0..<Self.boardSize {
                for direction in directions {
                    var score = 0
                    var blocked = false
                    for step in 0..<Self.winLength {
                        let nr = row + direction.0 * step
                        let nc = col + direction.1 * step
                        guard (0..<Self.boardSize).contains(nr), (0..<Self.boardSize).contains(nc) else {
                            blocked = true
                            break
                        }
                        let owner = board[nr * Self.boardSize + nc].owner
                        if owner == playerID {
                            score += 1
                        } else if owner != nil {
                            blocked = true
                            break
                        }
                    }
                    if !blocked {
                        best = max(best, score)
                    }
                }
            }
        }
        return best
    }

    private func burnBestLine() {
        let line = bestLineTarget(preferHuman: false)
        for id in line {
            if board[id].owner != 0 {
                clearCell(id)
            }
        }
    }

    private func destroyBestEnemyLine(radius: Int) {
        let line = bestLineTarget(preferHuman: false)
        for id in line {
            if radius == 0 {
                if board[id].owner != 0 { clearCell(id) }
            } else {
                clearAround(id, protectHuman: true)
            }
        }
    }

    private func destroyBestHumanLine() {
        let line = bestLineTarget(preferHuman: true)
        for id in line where board[id].owner == 0 {
            clearCell(id)
            return
        }
    }

    private func empBestCluster() {
        let center = densestEnemyCell() ?? Int.random(in: 0..<Self.boardCellCount)
        clearAround(center, protectHuman: true)
        for id in neighbors(around: center, radius: 1) {
            board[id].hasMine = false
            board[id].hasGas = false
            board[id].hasScrapTrap = false
            board[id].contaminatedTurns = 0
        }
    }

    private func scatterMinesNearEnemies() {
        let targets = board.filter { ($0.owner ?? 0) != 0 && $0.owner != nil }.map(\.id).shuffled().prefix(3)
        for target in targets {
            for id in neighbors(around: target, radius: 1).shuffled() where board[id].owner == nil && !board[id].hasGas {
                board[id].hasMine = true
                break
            }
        }
    }

    private func bestLineTarget(preferHuman: Bool) -> [Int] {
        let targetOwner = preferHuman ? 0 : nil
        let directions = [(1, 0), (0, 1), (1, 1), (1, -1)]
        var bestLine: [Int] = []
        var bestScore = -1
        for row in 0..<Self.boardSize {
            for col in 0..<Self.boardSize {
                for direction in directions {
                    var line: [Int] = []
                    var score = 0
                    for step in 0..<Self.winLength {
                        let nr = row + direction.0 * step
                        let nc = col + direction.1 * step
                        guard (0..<Self.boardSize).contains(nr), (0..<Self.boardSize).contains(nc) else {
                            line.removeAll()
                            break
                        }
                        let id = nr * Self.boardSize + nc
                        line.append(id)
                        if preferHuman {
                            if board[id].owner == targetOwner { score += 1 }
                        } else if let owner = board[id].owner, owner != 0 {
                            score += 1
                        }
                    }
                    if score > bestScore && !line.isEmpty {
                        bestScore = score
                        bestLine = line
                    }
                }
            }
        }
        return bestLine
    }

    private func densestEnemyCell() -> Int? {
        board
            .filter { ($0.owner ?? 0) != 0 && $0.owner != nil }
            .map { cell in
                (cell.id, neighbors(around: cell.id, radius: 1).filter { (board[$0].owner ?? 0) != 0 && board[$0].owner != nil }.count)
            }
            .max(by: { $0.1 < $1.1 })?
            .0
    }

    private func explode(center: Int) {
        clearAround(center, protectHuman: false)
    }

    private func clearAround(_ center: Int, protectHuman: Bool) {
        for idx in neighbors(around: center, radius: 1) {
            if protectHuman && board[idx].owner == 0 { continue }
            clearCell(idx)
        }
    }

    private func clearCell(_ id: Int) {
        if let shieldOwner = board[id].shieldOwner {
            board[id].shieldOwner = nil
            message = shieldOwner == 0 ? "鉄板シールドが破壊を防いだ。" : message
            return
        }
        board[id].owner = nil
        board[id].hasMine = false
        board[id].hasGas = false
        board[id].hasScrapTrap = false
        board[id].hasShield = false
        board[id].shieldOwner = nil
        board[id].contaminatedTurns = 0
    }

    private func contaminateRandomCells() {
        for id in board.indices.shuffled().prefix(3) {
            board[id].contaminatedTurns = 2
        }
        message = "汚染エリア発生。紫のマスは腐る。"
    }

    private func decayContamination() {
        for index in board.indices where board[index].contaminatedTurns > 0 {
            board[index].contaminatedTurns -= 1
            if board[index].contaminatedTurns == 0 {
                if board[index].shieldOwner != nil {
                    board[index].shieldOwner = nil
                } else {
                    board[index].owner = nil
                }
            }
        }
    }

    private func checkWin(for playerID: Int) -> Bool {
        checkWin(for: playerID, in: board)
    }

    private func checkWin(for playerID: Int, in board: [BoardCell]) -> Bool {
        let directions = [(1, 0), (0, 1), (1, 1), (1, -1)]
        for row in 0..<Self.boardSize {
            for col in 0..<Self.boardSize {
                for direction in directions {
                    var matched = true
                    for step in 0..<Self.winLength {
                        let nr = row + direction.0 * step
                        let nc = col + direction.1 * step
                        if !(0..<Self.boardSize).contains(nr) || !(0..<Self.boardSize).contains(nc) || board[nr * Self.boardSize + nc].owner != playerID {
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

    private func neighbors(around center: Int, radius: Int) -> [Int] {
        let row = center / Self.boardSize
        let col = center % Self.boardSize
        var ids: [Int] = []
        for dr in -radius...radius {
            for dc in -radius...radius {
                let nr = row + dr
                let nc = col + dc
                guard (0..<Self.boardSize).contains(nr), (0..<Self.boardSize).contains(nc) else { continue }
                ids.append(nr * Self.boardSize + nc)
            }
        }
        return ids
    }

    private func emptyIDs() -> [Int] {
        board.indices.filter {
            board[$0].owner == nil && !board[$0].hasMine && !board[$0].hasGas && !board[$0].hasScrapTrap && !board[$0].hasShield
        }
    }

    private func saveProgress() {
        UserDefaults.standard.set(scraps, forKey: scrapsKey)
        UserDefaults.standard.set(selectedCharacterID, forKey: selectedCharacterKey)
        UserDefaults.standard.set(Array(unlockedCharacterIDs), forKey: unlockedCharactersKey)
    }
}
