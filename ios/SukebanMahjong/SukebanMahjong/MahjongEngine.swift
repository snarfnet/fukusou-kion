import Foundation

struct YakuResult: Equatable, Codable {
    let name: String
    let han: Int
}

struct HandResult: Equatable, Codable {
    let yaku: [YakuResult]
    let han: Int
    let fu: Int
    let points: Int
}

enum OpenMeldKind: Equatable, Codable {
    case chi
    case pon
    case openKan
    case closedKan
    case addedKan
}

struct OpenMeld: Equatable, Codable {
    let kind: OpenMeldKind
    let tiles: [MahjongTile]

    var isTriplet: Bool { kind != .chi }
    var breaksClosedHand: Bool { kind != .closedKan }
}

struct AddedKanOption {
    let meldIndex: Int
    let tile: MahjongTile
}

struct MatchConclusion: Equatable {
    let playerPoints: Int
    let enemyPoints: Int
    let playerWon: Bool
    let riichiPotWentToPlayer: Bool?
}

enum MatchRules {
    static func startingHandSizes(playerIsDealer: Bool) -> (player: Int, enemy: Int) {
        playerIsDealer ? (14, 13) : (13, 14)
    }

    static func settledPoints(base: Int, winnerIsDealer: Bool, honba: Int) -> Int {
        let dealerAdjusted: Int
        if winnerIsDealer {
            dealerAdjusted = Int(ceil(Double(base) * 1.5 / 100.0)) * 100
        } else {
            dealerAdjusted = base
        }
        return dealerAdjusted + honba * 300
    }

    static func dealerRepeats(winnerIsDealer: Bool?, dealerTenpaiOnDraw: Bool) -> Bool {
        if let winnerIsDealer { return winnerIsDealer }
        return dealerTenpaiOnDraw
    }

    static func winnerGain(
        base: Int,
        winnerIsDealer: Bool,
        honba: Int,
        riichiPot: Int
    ) -> Int {
        settledPoints(base: base, winnerIsDealer: winnerIsDealer, honba: honba)
            + max(0, riichiPot)
    }

    static func playerReceivesFinalRiichiPot(playerPoints: Int, enemyPoints: Int) -> Bool {
        playerPoints > enemyPoints
    }

    static func conclusionIfNeeded(
        playerPoints: Int,
        enemyPoints: Int,
        round: Int,
        dealerRepeats: Bool,
        riichiPot: Int
    ) -> MatchConclusion? {
        let shouldEnd = playerPoints <= 0
            || enemyPoints <= 0
            || (round >= 4 && !dealerRepeats)
        guard shouldEnd else { return nil }

        var finalPlayerPoints = playerPoints
        var finalEnemyPoints = enemyPoints
        let validPot = max(0, riichiPot)
        let potRecipient: Bool?
        if validPot == 0 {
            potRecipient = nil
        } else if playerReceivesFinalRiichiPot(
            playerPoints: playerPoints,
            enemyPoints: enemyPoints
        ) {
            finalPlayerPoints += validPot
            potRecipient = true
        } else {
            finalEnemyPoints += validPot
            potRecipient = false
        }

        return MatchConclusion(
            playerPoints: finalPlayerPoints,
            enemyPoints: finalEnemyPoints,
            playerWon: finalPlayerPoints > finalEnemyPoints,
            riichiPotWentToPlayer: potRecipient
        )
    }

    static func canRon(
        isDiscardFuriten: Bool,
        isTemporaryFuriten: Bool,
        isRiichiPassFuriten: Bool
    ) -> Bool {
        !isDiscardFuriten && !isTemporaryFuriten && !isRiichiPassFuriten
    }
}

enum MahjongRules {
    static func makeWall() -> [MahjongTile] {
        var wall: [MahjongTile] = []
        for suit in [TileSuit.man, .pin, .sou] {
            for value in 1...9 {
                for _ in 0..<4 { wall.append(MahjongTile(suit: suit, value: value)) }
            }
        }
        for value in 1...7 {
            for _ in 0..<4 { wall.append(MahjongTile(suit: .honor, value: value)) }
        }
        return wall.shuffled()
    }

    static func sort(_ tiles: [MahjongTile]) -> [MahjongTile] {
        tiles.sorted { code($0) < code($1) }
    }

    static func isWinning(_ tiles: [MahjongTile], openMeldCount: Int = 0) -> Bool {
        guard (0...4).contains(openMeldCount),
              tiles.count == 14 - openMeldCount * 3 else { return false }
        var counts = Array(repeating: 0, count: 34)
        tiles.forEach { counts[code($0)] += 1 }
        guard counts.allSatisfy({ $0 <= 4 }) else { return false }

        if openMeldCount == 0, isThirteenOrphans(counts) { return true }
        if openMeldCount == 0, counts.filter({ $0 == 2 }).count == 7 { return true }

        for pair in 0..<34 where counts[pair] >= 2 {
            var rest = counts
            rest[pair] -= 2
            if canFormMelds(&rest, from: 0) { return true }
        }
        return false
    }

    static func result(
        for tiles: [MahjongTile],
        riichi: Bool,
        turn: Int,
        selfDraw: Bool = true,
        rinshan: Bool = false,
        lastTile: Bool = false,
        lastDiscard: Bool = false,
        robbingKan: Bool = false,
        ippatsu: Bool = false,
        doubleRiichi: Bool = false,
        seatWind: Int = 1,
        roundWind: Int = 1,
        winningTile: MahjongTile? = nil,
        doraIndicators: [MahjongTile] = [],
        openMelds: [OpenMeld] = []
    ) -> HandResult? {
        guard isWinning(tiles, openMeldCount: openMelds.count) else { return nil }
        let counts = tileCounts(tiles)
        let shapes = winningShapes(
            counts,
            requiredMeldCount: 4 - openMelds.count
        )
        let allTiles = tiles + openMelds.flatMap(\.tiles)
        let isClosed = openMelds.allSatisfy { !$0.breaksClosedHand }
        if isClosed, isThirteenOrphans(counts) {
            return HandResult(
                yaku: [.init(name: "国士無双", han: 13)],
                han: 13,
                fu: 0,
                points: 32000
            )
        }

        let openTripletCodes = openMelds.compactMap { meld -> Int? in
            guard meld.isTriplet, let first = meld.tiles.first else { return nil }
            return code(first)
        }
        let concealedTripletCodes = Set((0..<34).filter { counts[$0] >= 3 })
        let tripletCodes = concealedTripletCodes.union(openTripletCodes)
        let totalKanCount = openMelds.filter {
            $0.kind == .openKan || $0.kind == .closedKan || $0.kind == .addedKan
        }.count
        var yakuman: [YakuResult] = []
        if totalKanCount == 4 {
            yakuman.append(.init(name: "四槓子", han: 13))
        }
        if (31...33).allSatisfy({ tripletCodes.contains($0) }) {
            yakuman.append(.init(name: "大三元", han: 13))
        }
        let windTriplets = (27...30).filter { tripletCodes.contains($0) }
        if windTriplets.count == 4 {
            yakuman.append(.init(name: "大四喜", han: 13))
        } else if windTriplets.count == 3,
                  (27...30).contains(where: { counts[$0] == 2 }) {
            yakuman.append(.init(name: "小四喜", han: 13))
        }
        if allTiles.allSatisfy({ $0.suit == .honor }) {
            yakuman.append(.init(name: "字一色", han: 13))
        }
        if allTiles.allSatisfy({ $0.suit != .honor && ($0.value == 1 || $0.value == 9) }) {
            yakuman.append(.init(name: "清老頭", han: 13))
        }
        let closedKanCount = openMelds.filter { $0.kind == .closedKan }.count
        let winCode = winningTile.map(code)
        let hasFourConcealedTripletShape = shapes.contains { candidate in
            candidate.melds.allSatisfy(\.isTriplet)
                && candidate.melds.count + closedKanCount == 4
                && (selfDraw || winCode == candidate.pairCode)
        }
        if isClosed, hasFourConcealedTripletShape {
            yakuman.append(.init(name: "四暗刻", han: 13))
        }
        if !yakuman.isEmpty {
            let han = yakuman.reduce(0) { $0 + $1.han }
            return HandResult(yaku: yakuman, han: han, fu: 0, points: 32000 * yakuman.count)
        }

        var yaku: [YakuResult] = []

        if riichi, isClosed {
            yaku.append(.init(name: doubleRiichi ? "ダブル立直" : "立直", han: doubleRiichi ? 2 : 1))
        }
        if riichi, isClosed, ippatsu { yaku.append(.init(name: "一発", han: 1)) }
        if selfDraw, isClosed { yaku.append(.init(name: "門前清自摸和", han: 1)) }
        if selfDraw, rinshan { yaku.append(.init(name: "嶺上開花", han: 1)) }
        if selfDraw, lastTile, !rinshan { yaku.append(.init(name: "海底摸月", han: 1)) }
        if !selfDraw, lastDiscard, !robbingKan { yaku.append(.init(name: "河底撈魚", han: 1)) }
        if !selfDraw, robbingKan { yaku.append(.init(name: "槍槓", han: 1)) }
        if allTiles.allSatisfy({ $0.suit != .honor && $0.value != 1 && $0.value != 9 }) {
            yaku.append(.init(name: "断么九", han: 1))
        }
        let baseYaku = yaku
        let doraCount = doraIndicators.reduce(0) { total, indicator in
            let dora = doraCode(after: indicator)
            return total + allTiles.filter { code($0) == dora }.count
        }
        let numberedSuits = Set(allTiles.filter { $0.suit != .honor }.map(\.suit))
        let hasHonors = allTiles.contains { $0.suit == .honor }

        func evaluatedResult(
            shape candidateShape: WinningShape?,
            isSevenPairs: Bool
        ) -> HandResult? {
            var candidateYaku = baseYaku
            if isSevenPairs {
                candidateYaku.append(.init(name: "七対子", han: 2))
            } else if let candidateShape {
                if candidateShape.melds.allSatisfy(\.isTriplet),
                   openMelds.allSatisfy(\.isTriplet) {
                    candidateYaku.append(.init(name: "対々和", han: 2))
                }
                let dragonTriplets = (31...33).filter {
                    tripletCodes.contains($0)
                }.count
                let roundWindCode = 27 + max(1, min(4, roundWind)) - 1
                let seatWindCode = 27 + max(1, min(4, seatWind)) - 1
                let windHan = (tripletCodes.contains(roundWindCode) ? 1 : 0)
                    + (tripletCodes.contains(seatWindCode) ? 1 : 0)
                let yakuhaiHan = dragonTriplets + windHan
                if yakuhaiHan > 0 {
                    candidateYaku.append(.init(name: "役牌", han: yakuhaiHan))
                }
                let dragonPairs = (31...33).filter { counts[$0] == 2 }.count
                if dragonTriplets == 2, dragonPairs == 1 {
                    candidateYaku.append(.init(name: "小三元", han: 2))
                }
                addCompositionYaku(
                    to: &candidateYaku,
                    shape: candidateShape,
                    openMelds: openMelds,
                    isClosed: isClosed,
                    seatWind: seatWind,
                    roundWind: roundWind,
                    winningTile: winningTile,
                    selfDraw: selfDraw,
                    totalKanCount: totalKanCount
                )
            }

            if allTiles.allSatisfy({
                $0.suit == .honor || $0.value == 1 || $0.value == 9
            }) {
                candidateYaku.append(.init(name: "混老頭", han: 2))
            }
            if numberedSuits.count == 1 {
                let han = hasHonors ? (isClosed ? 3 : 2) : (isClosed ? 6 : 5)
                candidateYaku.append(
                    .init(name: hasHonors ? "混一色" : "清一色", han: han)
                )
            }

            // ドラだけでは和了できない。
            guard candidateYaku.reduce(0, { $0 + $1.han }) > 0 else {
                return nil
            }
            if doraCount > 0 {
                candidateYaku.append(.init(name: "ドラ", han: doraCount))
            }
            let han = candidateYaku.reduce(0) { $0 + $1.han }
            let fu = calculateFu(
                shape: candidateShape,
                openMelds: openMelds,
                isSevenPairs: isSevenPairs,
                isClosed: isClosed,
                selfDraw: selfDraw,
                seatWind: seatWind,
                roundWind: roundWind,
                winningTile: winningTile,
                hasPinfu: candidateYaku.contains { $0.name == "平和" }
            )
            return HandResult(
                yaku: candidateYaku,
                han: han,
                fu: fu,
                points: calculatedPoints(han: han, fu: fu)
            )
        }

        var candidates = shapes.compactMap {
            evaluatedResult(shape: $0, isSevenPairs: false)
        }
        if isClosed, counts.filter({ $0 == 2 }).count == 7,
           let sevenPairs = evaluatedResult(shape: nil, isSevenPairs: true) {
            candidates.append(sevenPairs)
        }
        return candidates.max {
            ($0.points, $0.han, $0.fu) < ($1.points, $1.han, $1.fu)
        }
    }

    static func riichiDiscardCodes(_ tiles: [MahjongTile], wall _: [MahjongTile]) -> Set<Int> {
        guard tiles.count == 14 else { return [] }
        var result: Set<Int> = []
        for tile in tiles {
            var reduced = tiles
            if let index = reduced.firstIndex(of: tile) { reduced.remove(at: index) }
            if !waitingCodes(reduced).isEmpty { result.insert(code(tile)) }
        }
        return result
    }

    static func chiOptions(for calledTile: MahjongTile, in hand: [MahjongTile]) -> [[MahjongTile]] {
        guard calledTile.suit != .honor else { return [] }
        let value = calledTile.value
        let patterns = [
            [value - 2, value - 1],
            [value - 1, value + 1],
            [value + 1, value + 2]
        ].filter { $0.allSatisfy { (1...9).contains($0) } }

        return patterns.compactMap { values in
            var available = hand
            var pair: [MahjongTile] = []
            for needed in values {
                guard let index = available.firstIndex(where: {
                    $0.suit == calledTile.suit && $0.value == needed
                }) else { return nil }
                pair.append(available.remove(at: index))
            }
            return pair
        }
    }

    static func closedKanCodes(in hand: [MahjongTile]) -> Set<Int> {
        let groups = Dictionary(grouping: hand, by: code)
        return Set(groups.compactMap { $0.value.count == 4 ? $0.key : nil })
    }

    static func addedKanOptions(hand: [MahjongTile], melds: [OpenMeld]) -> [AddedKanOption] {
        melds.enumerated().compactMap { index, meld in
            guard meld.kind == .pon, let first = meld.tiles.first else { return nil }
            guard let tile = hand.first(where: { code($0) == code(first) }) else { return nil }
            return AddedKanOption(meldIndex: index, tile: tile)
        }
    }

    static func waitingCodes(_ tiles: [MahjongTile], openMeldCount: Int = 0) -> Set<Int> {
        guard tiles.count == 13 - openMeldCount * 3 else { return [] }
        let counts = tileCounts(tiles)
        return Set((0..<34).filter { candidate in
            counts[candidate] < 4
                && isWinning(tiles + [tile(from: candidate)], openMeldCount: openMeldCount)
        })
    }

    static func isFuriten(_ tiles: [MahjongTile], discards: [MahjongTile], openMeldCount: Int = 0) -> Bool {
        let waits = waitingCodes(tiles, openMeldCount: openMeldCount)
        return discards.contains { waits.contains(code($0)) }
    }

    static func bestDiscardIndex(
        in tiles: [MahjongTile],
        wall _: [MahjongTile],
        openMeldCount: Int = 0
    ) -> Int {
        guard !tiles.isEmpty else { return 0 }
        let candidates = tiles.indices.map { index -> (Int, Int) in
            var reduced = tiles
            reduced.remove(at: index)
            let waits = waitingCodes(reduced, openMeldCount: openMeldCount).count
            let duplicates = reduced.filter { code($0) == code(tiles[index]) }.count
            return (waits * 10 - duplicates, index)
        }
        return candidates.max { $0.0 < $1.0 }?.1 ?? tiles.startIndex
    }

    private static func addCompositionYaku(
        to yaku: inout [YakuResult],
        shape: WinningShape,
        openMelds: [OpenMeld],
        isClosed: Bool,
        seatWind: Int,
        roundWind: Int,
        winningTile: MahjongTile?,
        selfDraw: Bool,
        totalKanCount: Int
    ) {
        let concealedSequences = shape.melds.filter { !$0.isTriplet }.map(\.code)
        let openSequences = openMelds.compactMap { meld -> Int? in
            guard meld.kind == .chi else { return nil }
            return meld.tiles.map(code).min()
        }
        let allSequences = concealedSequences + openSequences

        if isClosed {
            let duplicateSequencePairs = Dictionary(grouping: concealedSequences, by: { $0 })
                .values.filter { $0.count >= 2 }.count
            if duplicateSequencePairs >= 2 {
                yaku.append(.init(name: "二盃口", han: 3))
            } else if duplicateSequencePairs == 1 {
                yaku.append(.init(name: "一盃口", han: 1))
            }
        }

        if (0...6).contains(where: { rank in
            [rank, 9 + rank, 18 + rank].allSatisfy { allSequences.contains($0) }
        }) {
            yaku.append(.init(name: "三色同順", han: isClosed ? 2 : 1))
        }
        if [0, 9, 18].contains(where: { base in
            [base, base + 3, base + 6].allSatisfy { allSequences.contains($0) }
        }) {
            yaku.append(.init(name: "一気通貫", han: isClosed ? 2 : 1))
        }

        let concealedTriplets = shape.melds.filter(\.isTriplet).map(\.code)
        let openTriplets: [Int] = openMelds.compactMap { meld -> Int? in
            guard meld.isTriplet, let first = meld.tiles.first else { return nil }
            return code(first)
        }
        let allTriplets = concealedTriplets + openTriplets
        if (0...8).contains(where: { rank in
            [rank, 9 + rank, 18 + rank].allSatisfy { allTriplets.contains($0) }
        }) {
            yaku.append(.init(name: "三色同刻", han: 2))
        }
        let ronCode: Int? = selfDraw ? nil : winningTile.map(code)
        let concealedTripletCount = shape.melds.filter { meld in
            guard meld.isTriplet else { return false }
            return ronCode.map { $0 != meld.code } ?? true
        }.count + openMelds.filter { $0.kind == .closedKan }.count
        if concealedTripletCount >= 3 {
            yaku.append(.init(name: "三暗刻", han: 2))
        }
        if totalKanCount >= 3 {
            yaku.append(.init(name: "三槓子", han: 2))
        }

        let pairHasTerminalOrHonor = isTerminalOrHonor(code: shape.pairCode)
        let concealedQualify = shape.melds.allSatisfy { meldContainsTerminalOrHonor($0) }
        let openQualify = openMelds.allSatisfy { meldContainsTerminalOrHonor($0) }
        let hasSequence = !allSequences.isEmpty
        if pairHasTerminalOrHonor, concealedQualify, openQualify, hasSequence {
            let hasHonor = shape.pairCode >= 27
                || shape.melds.contains { $0.code >= 27 }
                || openMelds.contains { $0.tiles.contains { $0.suit == .honor } }
            yaku.append(.init(
                name: hasHonor ? "混全帯么九" : "純全帯么九",
                han: hasHonor ? (isClosed ? 2 : 1) : (isClosed ? 3 : 2)
            ))
        }

        let valuePair = isValuePair(
            shape.pairCode,
            seatWind: seatWind,
            roundWind: roundWind
        )
        if isClosed,
           shape.melds.allSatisfy({ !$0.isTriplet }),
           !valuePair,
           isRyanmen(shape: shape, winningTile: winningTile) {
            yaku.append(.init(name: "平和", han: 1))
        }
    }

    private static func calculateFu(
        shape: WinningShape?,
        openMelds: [OpenMeld],
        isSevenPairs: Bool,
        isClosed: Bool,
        selfDraw: Bool,
        seatWind: Int,
        roundWind: Int,
        winningTile: MahjongTile?,
        hasPinfu: Bool
    ) -> Int {
        if isSevenPairs { return 25 }
        if hasPinfu { return selfDraw ? 20 : 30 }
        guard let shape else { return 20 }

        var fu = 20
        if isClosed, !selfDraw { fu += 10 }
        if selfDraw { fu += 2 }
        if shape.pairCode >= 31 { fu += 2 }
        if shape.pairCode == 27 + max(1, min(4, seatWind)) - 1 { fu += 2 }
        if shape.pairCode == 27 + max(1, min(4, roundWind)) - 1 { fu += 2 }

        for meld in shape.melds where meld.isTriplet {
            let completedByRon = !selfDraw && winningTile.map(code) == Optional(meld.code)
            if isTerminalOrHonor(code: meld.code) {
                fu += completedByRon ? 4 : 8
            } else {
                fu += completedByRon ? 2 : 4
            }
        }
        for meld in openMelds {
            guard let first = meld.tiles.first else { continue }
            let terminal = first.suit == .honor || first.value == 1 || first.value == 9
            switch meld.kind {
            case .chi: break
            case .pon: fu += terminal ? 4 : 2
            case .openKan, .addedKan: fu += terminal ? 16 : 8
            case .closedKan: fu += terminal ? 32 : 16
            }
        }

        if let winningTile {
            let winCode = code(winningTile)
            let sequenceWait = shape.melds.contains {
                !$0.isTriplet && ($0.code...($0.code + 2)).contains(winCode)
            }
            if winCode == shape.pairCode
                || (sequenceWait && !isRyanmen(shape: shape, winningTile: winningTile)) {
                fu += 2
            }
        }
        if !isClosed, !selfDraw, fu == 20 { return 30 }
        return Int(ceil(Double(fu) / 10.0)) * 10
    }

    static func calculatedPoints(han: Int, fu: Int) -> Int {
        if han >= 13 { return 32000 }
        if han >= 11 { return 24000 }
        if han >= 8 { return 16000 }
        if han >= 6 { return 12000 }
        if han >= 5 { return 8000 }

        let basic = fu * (1 << (han + 2))
        if basic >= 2000 { return 8000 }
        return Int(ceil(Double(basic * 4) / 100.0)) * 100
    }

    private static func isRyanmen(shape: WinningShape, winningTile: MahjongTile?) -> Bool {
        guard let winningTile else { return false }
        let winCode = code(winningTile)
        guard winCode != shape.pairCode else { return false }
        return shape.melds.contains { meld in
            guard !meld.isTriplet, (meld.code...(meld.code + 2)).contains(winCode) else {
                return false
            }
            let startRank = meld.code % 9
            if winCode == meld.code + 1 { return false }
            if winCode == meld.code, startRank == 6 { return false }
            if winCode == meld.code + 2, startRank == 0 { return false }
            return true
        }
    }

    private static func isValuePair(_ code: Int, seatWind: Int, roundWind: Int) -> Bool {
        if code >= 31 { return true }
        let seat = 27 + max(1, min(4, seatWind)) - 1
        let round = 27 + max(1, min(4, roundWind)) - 1
        return code == seat || code == round
    }

    private static func isTerminalOrHonor(code: Int) -> Bool {
        code >= 27 || code % 9 == 0 || code % 9 == 8
    }

    private static func meldContainsTerminalOrHonor(_ meld: Meld) -> Bool {
        if meld.isTriplet { return isTerminalOrHonor(code: meld.code) }
        let rank = meld.code % 9
        return rank == 0 || rank == 6
    }

    private static func meldContainsTerminalOrHonor(_ meld: OpenMeld) -> Bool {
        meld.tiles.contains {
            $0.suit == .honor || $0.value == 1 || $0.value == 9
        }
    }

    private static func canFormMelds(_ counts: inout [Int], from start: Int) -> Bool {
        guard let first = (start..<34).first(where: { counts[$0] > 0 }) else { return true }

        if counts[first] >= 3 {
            counts[first] -= 3
            if canFormMelds(&counts, from: first) { counts[first] += 3; return true }
            counts[first] += 3
        }

        let position = first % 9
        if first < 27, position <= 6, counts[first + 1] > 0, counts[first + 2] > 0 {
            counts[first] -= 1; counts[first + 1] -= 1; counts[first + 2] -= 1
            if canFormMelds(&counts, from: first) {
                counts[first] += 1; counts[first + 1] += 1; counts[first + 2] += 1
                return true
            }
            counts[first] += 1; counts[first + 1] += 1; counts[first + 2] += 1
        }
        return false
    }

    static func code(_ tile: MahjongTile) -> Int {
        switch tile.suit {
        case .man: return tile.value - 1
        case .pin: return 9 + tile.value - 1
        case .sou: return 18 + tile.value - 1
        case .honor: return 27 + tile.value - 1
        }
    }

    static func doraCode(after indicator: MahjongTile) -> Int {
        switch indicator.suit {
        case .man, .pin, .sou:
            return code(MahjongTile(suit: indicator.suit, value: indicator.value == 9 ? 1 : indicator.value + 1))
        case .honor:
            let next: Int
            if indicator.value <= 4 {
                next = indicator.value == 4 ? 1 : indicator.value + 1
            } else {
                next = indicator.value == 7 ? 5 : indicator.value + 1
            }
            return code(MahjongTile(suit: .honor, value: next))
        }
    }

    static func tileForCode(_ code: Int) -> MahjongTile {
        tile(from: code)
    }

    private struct Meld {
        let code: Int
        let isTriplet: Bool
    }

    private struct WinningShape {
        let pairCode: Int
        let melds: [Meld]
    }

    private static func tileCounts(_ tiles: [MahjongTile]) -> [Int] {
        var counts = Array(repeating: 0, count: 34)
        tiles.forEach { counts[code($0)] += 1 }
        return counts
    }

    private static func isThirteenOrphans(_ counts: [Int]) -> Bool {
        let required = [0, 8, 9, 17, 18, 26] + Array(27...33)
        guard required.allSatisfy({ counts[$0] >= 1 }) else { return false }
        return required.contains { counts[$0] >= 2 }
    }

    private static func tile(from code: Int) -> MahjongTile {
        switch code {
        case 0..<9: return MahjongTile(suit: .man, value: code + 1)
        case 9..<18: return MahjongTile(suit: .pin, value: code - 8)
        case 18..<27: return MahjongTile(suit: .sou, value: code - 17)
        default: return MahjongTile(suit: .honor, value: code - 26)
        }
    }

    private static func winningShapes(
        _ counts: [Int],
        requiredMeldCount: Int
    ) -> [WinningShape] {
        var shapes: [WinningShape] = []
        for pair in 0..<34 where counts[pair] >= 2 {
            var rest = counts
            rest[pair] -= 2
            for melds in extractAllMelds(&rest, from: 0)
            where melds.count == requiredMeldCount {
                shapes.append(WinningShape(pairCode: pair, melds: melds))
            }
        }
        return shapes
    }

    private static func extractAllMelds(
        _ counts: inout [Int],
        from start: Int
    ) -> [[Meld]] {
        guard let first = (start..<34).first(where: { counts[$0] > 0 }) else {
            return [[]]
        }
        var results: [[Meld]] = []
        if counts[first] >= 3 {
            counts[first] -= 3
            for rest in extractAllMelds(&counts, from: first) {
                results.append([.init(code: first, isTriplet: true)] + rest)
            }
            counts[first] += 3
        }
        let position = first % 9
        if first < 27, position <= 6, counts[first + 1] > 0, counts[first + 2] > 0 {
            counts[first] -= 1; counts[first + 1] -= 1; counts[first + 2] -= 1
            for rest in extractAllMelds(&counts, from: first) {
                results.append([.init(code: first, isTriplet: false)] + rest)
            }
            counts[first] += 1; counts[first + 1] += 1; counts[first + 2] += 1
        }
        return results
    }
}
