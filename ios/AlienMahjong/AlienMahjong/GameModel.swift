import Foundation
import Combine

enum TileSuit: String, CaseIterable, Codable, Hashable {
    case characters = "CHARACTERS"
    case circles = "CIRCLES"
    case bamboo = "BAMBOO"
    case honors = "HONORS"
}

struct SpaceTile: Identifiable, Equatable, Codable {
    let id: UUID
    let suit: TileSuit
    let rank: Int

    init(id: UUID = UUID(), suit: TileSuit, rank: Int) {
        self.id = id
        self.suit = suit
        self.rank = rank
    }

    var glyph: String {
        let codePoint: Int
        switch suit {
        case .characters: codePoint = 0x1F007 + rank - 1
        case .bamboo: codePoint = 0x1F010 + rank - 1
        case .circles: codePoint = 0x1F019 + rank - 1
        case .honors:
            codePoint = [0x1F000, 0x1F001, 0x1F002, 0x1F003, 0x1F004, 0x1F005, 0x1F006][rank - 1]
        }
        return UnicodeScalar(codePoint).map(String.init) ?? "?"
    }

    var spokenName: String {
        if suit == .honors {
            return ["East wind", "South wind", "West wind", "North wind", "Red dragon", "Green dragon", "White dragon"][rank - 1]
        }
        return "\(rank) of \(suit.rawValue.lowercased())"
    }
}

struct AlienOpponent {
    let name: String
    let species: String
    let assetName: String
    let threat: String
    let defeatLine: String
}

@MainActor
final class GameModel: ObservableObject {
    enum Phase: Equatable { case briefing, playerTurn, alienTurn, callDecision, won, lost, exhaustiveDraw }

    @Published private(set) var hand: [SpaceTile] = []
    @Published private(set) var playerDiscards: [SpaceTile] = []
    @Published private(set) var alienDiscards: [SpaceTile] = []
    @Published private(set) var playerMelds: [CalledMeld] = []
    @Published private(set) var alienMelds: [CalledMeld] = []
    @Published private(set) var doraIndicators: [SpaceTile] = []
    @Published private(set) var phase: Phase = .briefing
    @Published private(set) var message = "First contact. Their challenge: riichi mahjong."
    @Published private(set) var turns = 0
    @Published private(set) var opponentIndex = 0
    @Published private(set) var playerRiichi = false
    @Published private(set) var alienRiichi = false
    @Published private(set) var riichiPending = false
    @Published private(set) var lastScore: HandScore?

    private var wall: [SpaceTile] = []
    private var alienHand: [SpaceTile] = []
    private var lastDrawnTileID: UUID?
    private var lastDrawWasRinshan = false
    private var pendingAlienDiscard: SpaceTile?
    private var temporaryFuriten = false
    private var riichiPassFuriten = false
    private var alienTemporaryFuriten = false

    let opponents = [
        AlienOpponent(name: "XEN-7", species: "THE GREY ENVOY", assetName: "GreyAlien", threat: "A legal hand decides the first verdict.", defeatLine: "The Grey envoy folds. A second signal arrives."),
        AlienOpponent(name: "VARAK", species: "REPTILIAN WARLORD", assetName: "ReptilianAlien", threat: "No weapons. No mercy. Riichi.", defeatLine: "Varak yields the table. The Hive sends its strategist."),
        AlienOpponent(name: "SIX-EYES", species: "MANTIS STRATEGIST", assetName: "MantisAlien", threat: "I calculated every wait but one.", defeatLine: "The Hive calculation fails. The final sovereign wakes."),
        AlienOpponent(name: "THE PRISM", species: "CRYSTAL SOVEREIGN", assetName: "CrystalAlien", threat: "One hand decides whether humanity continues.", defeatLine: "The verdict is sealed. Humanity survives.")
    ]

    var currentOpponent: AlienOpponent { opponents[opponentIndex] }
    var isFinalOpponent: Bool { opponentIndex == opponents.count - 1 }
    var campaignProgress: String { "\(opponentIndex + 1)/\(opponents.count)" }
    var wallCount: Int { wall.count }
    var currentDora: String { doraIndicators.map(\.glyph).joined(separator: " ") }
    var canTsumo: Bool { playerScore(selfDraw: true, winningTile: hand.last) != nil }
    var isFuriten: Bool {
        RiichiRules.isDiscardFuriten(hand: hand, melds: playerMelds, discards: playerDiscards) ||
        temporaryFuriten || riichiPassFuriten
    }
    var canRon: Bool {
        guard phase == .callDecision, !isFuriten, let tile = pendingAlienDiscard else { return false }
        return playerScore(selfDraw: false, winningTile: tile, tiles: hand + [tile]) != nil
    }
    var canPon: Bool {
        guard phase == .callDecision, !playerRiichi, let tile = pendingAlienDiscard else { return false }
        return RiichiRules.matchingTiles(tile, in: hand).count >= 2
    }
    var canChi: Bool {
        guard phase == .callDecision, !playerRiichi, let tile = pendingAlienDiscard else { return false }
        return !RiichiRules.chiOptions(called: tile, hand: hand).isEmpty
    }
    var canOpenKan: Bool {
        guard phase == .callDecision, !playerRiichi, let tile = pendingAlienDiscard else { return false }
        return RiichiRules.matchingTiles(tile, in: hand).count >= 3
    }
    var canDeclareKan: Bool {
        phase == .playerTurn && (RiichiRules.closedKanCode(in: hand) != nil ||
        RiichiRules.addedKanOption(hand: hand, melds: playerMelds) != nil)
    }
    var canDeclareRiichi: Bool {
        phase == .playerTurn && !playerRiichi && playerMelds.allSatisfy { !$0.isOpen } &&
        hand.count == 14 - playerMelds.count * 3 &&
        hand.contains { tile in
            var reduced = hand
            reduced.removeAll { $0.id == tile.id }
            return !RiichiRules.waits(for: reduced, melds: playerMelds).isEmpty
        }
    }

    var statusLabel: String {
        switch phase {
        case .briefing: return "TRANSMISSION FOUND"
        case .playerTurn: return playerRiichi ? "RIICHI // DISCARD" : "YOUR DISCARD"
        case .alienTurn: return alienRiichi ? "ALIEN RIICHI" : "ALIEN THINKING"
        case .callDecision: return isFuriten ? "CALL OR PASS" : "RON / CALL / PASS"
        case .won: return "WINNING HAND"
        case .lost: return "ALIEN WINS"
        case .exhaustiveDraw: return "EXHAUSTIVE DRAW"
        }
    }

    func start() { opponentIndex = 0; startRound() }
    func retryRound() { startRound() }
    func playAgain() { start() }
    func advanceOpponent() {
        guard phase == .won, !isFinalOpponent else { return }
        opponentIndex += 1
        startRound()
    }

    func toggleRiichi() {
        guard canDeclareRiichi || riichiPending else { return }
        riichiPending.toggle()
        message = riichiPending ? "Choose a discard that leaves tenpai." : "Riichi cancelled."
    }

    func canDiscard(_ tile: SpaceTile) -> Bool {
        guard phase == .playerTurn, hand.count == 14 - playerMelds.count * 3 else { return false }
        if playerRiichi { return tile.id == lastDrawnTileID }
        if riichiPending {
            var reduced = hand
            reduced.removeAll { $0.id == tile.id }
            return !RiichiRules.waits(for: reduced, melds: playerMelds).isEmpty
        }
        return true
    }

    func discard(_ tile: SpaceTile) {
        guard canDiscard(tile) else { return }
        hand.removeAll { $0.id == tile.id }
        playerDiscards.append(tile)
        turns += 1
        if riichiPending {
            playerRiichi = true
            riichiPending = false
            message = "RIICHI. Your hand is locked."
        } else {
            message = "You discarded \(tile.spokenName)."
        }

        if canAlienRon(tile) {
            loseRound(reason: "\(currentOpponent.name) calls RON.", score: alienScore(selfDraw: false, winningTile: tile, tiles: alienHand + [tile]))
            return
        }
        if tryAlienCall(tile) { return }
        beginAlienDraw()
    }

    func declareTsumo() {
        guard let tile = hand.first(where: { $0.id == lastDrawnTileID }),
              let score = playerScore(selfDraw: true, winningTile: tile) else { return }
        winRound(reason: "TSUMO.", score: score)
    }

    func declareKan() {
        guard canDeclareKan else { return }
        if let (meldIndex, tile) = RiichiRules.addedKanOption(hand: hand, melds: playerMelds) {
            hand.removeAll { $0.id == tile.id }
            playerMelds[meldIndex].kind = .addedKan
            playerMelds[meldIndex].tiles.append(tile)
        } else if let code = RiichiRules.closedKanCode(in: hand) {
            let tiles = hand.filter { MahjongHandEvaluator.index(of: $0) == code }
            hand.removeAll { MahjongHandEvaluator.index(of: $0) == code }
            playerMelds.append(.init(kind: .closedKan, tiles: tiles))
        }
        revealDora()
        drawForPlayer(rinshan: true)
        message = "KAN. A new dora indicator is revealed."
    }

    func callRon() {
        guard canRon, let tile = pendingAlienDiscard,
              let score = playerScore(selfDraw: false, winningTile: tile, tiles: hand + [tile]) else { return }
        pendingAlienDiscard = nil
        winRound(reason: "RON.", score: score)
    }

    func callPon() { callMeld(kind: .pon) }
    func callChi() { callMeld(kind: .chi) }
    func callOpenKan() { callMeld(kind: .openKan) }

    func passCall() {
        if canRon {
            if playerRiichi { riichiPassFuriten = true } else { temporaryFuriten = true }
        }
        pendingAlienDiscard = nil
        drawForPlayer()
    }

    private func callMeld(kind: MeldKind) {
        guard let called = pendingAlienDiscard else { return }
        let consumed: [SpaceTile]
        switch kind {
        case .chi:
            guard let option = RiichiRules.chiOptions(called: called, hand: hand).first else { return }
            consumed = option
        case .pon:
            guard canPon else { return }
            consumed = Array(RiichiRules.matchingTiles(called, in: hand).prefix(2))
        case .openKan:
            guard canOpenKan else { return }
            consumed = Array(RiichiRules.matchingTiles(called, in: hand).prefix(3))
        default: return
        }
        let ids = Set(consumed.map(\.id))
        hand.removeAll { ids.contains($0.id) }
        playerMelds.append(.init(kind: kind, tiles: consumed + [called]))
        pendingAlienDiscard = nil
        temporaryFuriten = false
        if kind == .openKan {
            revealDora()
            drawForPlayer(rinshan: true)
        } else {
            phase = .playerTurn
            lastDrawnTileID = nil
            message = "\(kind.rawValue.uppercased()). Choose a discard."
        }
    }

    private func startRound() {
        turns = 0
        playerRiichi = false; alienRiichi = false; riichiPending = false
        temporaryFuriten = false; riichiPassFuriten = false; alienTemporaryFuriten = false
        playerDiscards = []; alienDiscards = []; playerMelds = []; alienMelds = []
        lastScore = nil; pendingAlienDiscard = nil
        wall = Self.makeWall().shuffled()
        doraIndicators = [wall.removeLast()]
        hand = (0..<13).compactMap { _ in wall.popLast() }
        alienHand = (0..<13).compactMap { _ in wall.popLast() }
        sort(&hand); sort(&alienHand)
        drawForPlayer()
        message = currentOpponent.threat
    }

    private func beginAlienDraw() {
        phase = .alienTurn
        Task {
            try? await Task.sleep(for: .milliseconds(550))
            alienMove(draw: true)
        }
    }

    private func alienMove(draw: Bool) {
        guard phase == .alienTurn else { return }
        if draw {
            guard let tile = wall.popLast() else { exhaustiveDraw(); return }
            alienHand.append(tile)
            alienTemporaryFuriten = false
            if let score = alienScore(selfDraw: true, winningTile: tile) {
                loseRound(reason: "\(currentOpponent.name) calls TSUMO.", score: score)
                return
            }
        }
        let discard: SpaceTile
        if alienRiichi, let drawn = alienHand.last {
            discard = drawn
        } else {
            let legalRiichi = alienMelds.allSatisfy { !$0.isOpen }
            let options = alienHand.filter { tile in
                var reduced = alienHand
                reduced.removeAll { $0.id == tile.id }
                return !RiichiRules.waits(for: reduced, melds: alienMelds).isEmpty
            }
            if legalRiichi, !alienRiichi, let tile = options.first {
                alienRiichi = true
                discard = tile
            } else {
                discard = bestAlienDiscard()
            }
        }
        alienHand.removeAll { $0.id == discard.id }
        alienDiscards.append(discard)
        pendingAlienDiscard = discard
        phase = .callDecision
        let hasChoice = canRon || canPon || canChi || canOpenKan
        if hasChoice {
            message = "\(currentOpponent.name) discarded \(discard.spokenName)."
        } else {
            pendingAlienDiscard = nil
            drawForPlayer()
        }
    }

    private func tryAlienCall(_ tile: SpaceTile) -> Bool {
        guard !alienRiichi else { return false }
        let matching = RiichiRules.matchingTiles(tile, in: alienHand)
        if matching.count >= 3, turns.isMultiple(of: 3) {
            let used = Array(matching.prefix(3))
            remove(used, from: &alienHand)
            alienMelds.append(.init(kind: .openKan, tiles: used + [tile]))
            revealDora()
            phase = .alienTurn
            Task {
                try? await Task.sleep(for: .milliseconds(450))
                alienMove(draw: true)
            }
            return true
        }
        if matching.count >= 2, turns.isMultiple(of: 2) {
            let used = Array(matching.prefix(2))
            remove(used, from: &alienHand)
            alienMelds.append(.init(kind: .pon, tiles: used + [tile]))
            phase = .alienTurn
            Task {
                try? await Task.sleep(for: .milliseconds(450))
                alienMove(draw: false)
            }
            return true
        }
        return false
    }

    private func drawForPlayer(rinshan: Bool = false) {
        guard let tile = wall.popLast() else { exhaustiveDraw(); return }
        hand.append(tile)
        lastDrawnTileID = tile.id
        lastDrawWasRinshan = rinshan
        temporaryFuriten = false
        sort(&hand)
        phase = .playerTurn
        if canTsumo { message = "Winning hand. Call TSUMO." }
    }

    private func revealDora() {
        if let indicator = wall.popLast() { doraIndicators.append(indicator) }
    }

    private func playerScore(selfDraw: Bool, winningTile: SpaceTile?, tiles: [SpaceTile]? = nil) -> HandScore? {
        guard let winningTile else { return nil }
        return RiichiRules.score(
            tiles: tiles ?? hand,
            melds: playerMelds,
            context: .init(riichi: playerRiichi, selfDraw: selfDraw, winningTile: winningTile,
                           seatWind: 1, roundWind: 1, doraIndicators: doraIndicators, rinshan: lastDrawWasRinshan)
        )
    }

    private func alienScore(selfDraw: Bool, winningTile: SpaceTile, tiles: [SpaceTile]? = nil) -> HandScore? {
        RiichiRules.score(
            tiles: tiles ?? alienHand,
            melds: alienMelds,
            context: .init(riichi: alienRiichi, selfDraw: selfDraw, winningTile: winningTile,
                           seatWind: 2, roundWind: 1, doraIndicators: doraIndicators, rinshan: false)
        )
    }

    private func canAlienRon(_ tile: SpaceTile) -> Bool {
        let discardFuriten = RiichiRules.isDiscardFuriten(hand: alienHand, melds: alienMelds, discards: alienDiscards)
        return !discardFuriten && !alienTemporaryFuriten &&
        alienScore(selfDraw: false, winningTile: tile, tiles: alienHand + [tile]) != nil
    }

    private func bestAlienDiscard() -> SpaceTile {
        alienHand.max { left, right in
            var leftHand = alienHand; leftHand.removeAll { $0.id == left.id }
            var rightHand = alienHand; rightHand.removeAll { $0.id == right.id }
            return RiichiRules.waits(for: leftHand, melds: alienMelds).count <
                   RiichiRules.waits(for: rightHand, melds: alienMelds).count
        } ?? alienHand.last!
    }

    private func winRound(reason: String, score: HandScore) {
        lastScore = score
        phase = .won
        message = "\(reason) \(score.summary)\n\(currentOpponent.defeatLine)"
    }

    private func loseRound(reason: String, score: HandScore?) {
        lastScore = score
        phase = .lost
        message = score.map { "\(reason) \($0.summary)" } ?? reason
    }

    private func exhaustiveDraw() {
        phase = .exhaustiveDraw
        message = "The wall is empty. The hand ends in a draw."
    }

    private func sort(_ tiles: inout [SpaceTile]) {
        tiles.sort { MahjongHandEvaluator.index(of: $0) < MahjongHandEvaluator.index(of: $1) }
    }

    private func remove(_ tiles: [SpaceTile], from hand: inout [SpaceTile]) {
        let ids = Set(tiles.map(\.id))
        hand.removeAll { ids.contains($0.id) }
    }

    static func makeWall() -> [SpaceTile] {
        TileSuit.allCases.flatMap { suit in
            let ranks = suit == .honors ? 1...7 : 1...9
            return ranks.flatMap { rank in (0..<4).map { _ in SpaceTile(suit: suit, rank: rank) } }
        }
    }
}
