import Foundation

enum MeldKind: String, Codable {
    case chi, pon, openKan, closedKan, addedKan
}

struct CalledMeld: Identifiable, Codable {
    let id: UUID
    var kind: MeldKind
    var tiles: [SpaceTile]

    init(id: UUID = UUID(), kind: MeldKind, tiles: [SpaceTile]) {
        self.id = id
        self.kind = kind
        self.tiles = tiles
    }

    var isOpen: Bool { kind != .closedKan }
    var isTriplet: Bool { kind != .chi }
}

struct YakuValue: Equatable {
    let name: String
    let han: Int
}

struct HandScore: Equatable {
    let yaku: [YakuValue]
    let han: Int
    let fu: Int
    let points: Int

    var summary: String {
        let names = yaku.map(\.name).joined(separator: " • ")
        return "\(han) HAN • \(fu) FU • \(points) PTS\n\(names)"
    }
}

struct WinContext {
    let riichi: Bool
    let selfDraw: Bool
    let winningTile: SpaceTile
    let seatWind: Int
    let roundWind: Int
    let doraIndicators: [SpaceTile]
    let rinshan: Bool
}

enum RiichiRules {
    private struct Shape {
        struct Unit { let code: Int; let triplet: Bool }
        let pair: Int
        let units: [Unit]
    }

    static func isWinning(_ tiles: [SpaceTile], melds: [CalledMeld]) -> Bool {
        scoreShapes(tiles, meldCount: melds.count).isEmpty == false ||
        (melds.isEmpty && (isSevenPairs(tiles) || isThirteenOrphans(tiles)))
    }

    static func waits(for tiles: [SpaceTile], melds: [CalledMeld]) -> Set<Int> {
        let expected = 13 - melds.count * 3
        guard tiles.count == expected else { return [] }
        let counts = counts(tiles)
        return Set((0..<34).filter { code in
            counts[code] < 4 && isWinning(tiles + [tile(code)], melds: melds)
        })
    }

    static func isDiscardFuriten(hand: [SpaceTile], melds: [CalledMeld], discards: [SpaceTile]) -> Bool {
        let waiting = waits(for: hand, melds: melds)
        return discards.contains { waiting.contains(MahjongHandEvaluator.index(of: $0)) }
    }

    static func chiOptions(called: SpaceTile, hand: [SpaceTile]) -> [[SpaceTile]] {
        guard called.suit != .honors else { return [] }
        let patterns = [[called.rank - 2, called.rank - 1],
                        [called.rank - 1, called.rank + 1],
                        [called.rank + 1, called.rank + 2]]
        return patterns.filter { $0.allSatisfy { (1...9).contains($0) } }.compactMap { ranks in
            var available = hand
            var result: [SpaceTile] = []
            for rank in ranks {
                guard let index = available.firstIndex(where: { $0.suit == called.suit && $0.rank == rank }) else { return nil }
                result.append(available.remove(at: index))
            }
            return result
        }
    }

    static func matchingTiles(_ called: SpaceTile, in hand: [SpaceTile]) -> [SpaceTile] {
        hand.filter { MahjongHandEvaluator.index(of: $0) == MahjongHandEvaluator.index(of: called) }
    }

    static func closedKanCode(in hand: [SpaceTile]) -> Int? {
        Dictionary(grouping: hand) { MahjongHandEvaluator.index(of: $0) }
            .first(where: { $0.value.count == 4 })?.key
    }

    static func addedKanOption(hand: [SpaceTile], melds: [CalledMeld]) -> (Int, SpaceTile)? {
        for (index, meld) in melds.enumerated() where meld.kind == .pon {
            guard let first = meld.tiles.first,
                  let tile = hand.first(where: { MahjongHandEvaluator.index(of: $0) == MahjongHandEvaluator.index(of: first) })
            else { continue }
            return (index, tile)
        }
        return nil
    }

    static func doraCode(after indicator: SpaceTile) -> Int {
        switch indicator.suit {
        case .characters, .circles, .bamboo:
            return MahjongHandEvaluator.index(of: SpaceTile(suit: indicator.suit, rank: indicator.rank == 9 ? 1 : indicator.rank + 1))
        case .honors:
            let next = indicator.rank <= 4 ? (indicator.rank == 4 ? 1 : indicator.rank + 1) : (indicator.rank == 7 ? 5 : indicator.rank + 1)
            return MahjongHandEvaluator.index(of: SpaceTile(suit: .honors, rank: next))
        }
    }

    static func score(tiles: [SpaceTile], melds: [CalledMeld], context: WinContext) -> HandScore? {
        guard isWinning(tiles, melds: melds) else { return nil }
        let closed = melds.allSatisfy { !$0.isOpen }
        let allTiles = tiles + melds.flatMap(\.tiles)

        if melds.isEmpty && isThirteenOrphans(tiles) {
            return HandScore(yaku: [.init(name: "Thirteen Orphans", han: 13)], han: 13, fu: 0, points: context.seatWind == 1 ? 48_000 : 32_000)
        }

        let tripletCodes = Set(melds.filter(\.isTriplet).compactMap { meld in
            meld.tiles.first.map { MahjongHandEvaluator.index(of: $0) }
        })
        let concealedCounts = counts(tiles)
        let combinedTriplets = tripletCodes.union((0..<34).filter { concealedCounts[$0] >= 3 })
        let kanCount = melds.filter { [.openKan, .closedKan, .addedKan].contains($0.kind) }.count
        if kanCount == 4 {
            return HandScore(yaku: [.init(name: "Four Kans", han: 13)], han: 13, fu: 0, points: context.seatWind == 1 ? 48_000 : 32_000)
        }
        if (31...33).allSatisfy({ combinedTriplets.contains($0) }) {
            return HandScore(yaku: [.init(name: "Big Three Dragons", han: 13)], han: 13, fu: 0, points: context.seatWind == 1 ? 48_000 : 32_000)
        }
        if allTiles.allSatisfy({ $0.suit == .honors }) {
            return HandScore(yaku: [.init(name: "All Honors", han: 13)], han: 13, fu: 0, points: context.seatWind == 1 ? 48_000 : 32_000)
        }
        if allTiles.allSatisfy({ $0.suit != .honors && ($0.rank == 1 || $0.rank == 9) }) {
            return HandScore(yaku: [.init(name: "All Terminals", han: 13)], han: 13, fu: 0, points: context.seatWind == 1 ? 48_000 : 32_000)
        }

        let shapes = scoreShapes(tiles, meldCount: melds.count)
        var candidates: [HandScore] = []
        if melds.isEmpty && isSevenPairs(tiles) {
            var yaku = baseYaku(allTiles: allTiles, closed: true, context: context)
            yaku.append(.init(name: "Seven Pairs", han: 2))
            addFlushYaku(allTiles, closed: true, to: &yaku)
            if hasRealYaku(yaku), let result = finish(yaku: yaku, fu: 25, allTiles: allTiles, indicators: context.doraIndicators, dealer: context.seatWind == 1) {
                candidates.append(result)
            }
        }

        for shape in shapes {
            var yaku = baseYaku(allTiles: allTiles, closed: closed, context: context)
            let concealedUnits = shape.units
            let openTriplets = melds.filter(\.isTriplet).compactMap { meld in
                meld.tiles.first.map { MahjongHandEvaluator.index(of: $0) }
            }
            let triplets = concealedUnits.filter(\.triplet).map(\.code) + openTriplets
            let sequences = concealedUnits.filter { !$0.triplet }.map(\.code) +
                melds.filter { $0.kind == .chi }.compactMap { $0.tiles.map(MahjongHandEvaluator.index(of:)).min() }

            let dragonHan = triplets.filter { $0 >= 31 }.count
            let seat = 27 + max(1, min(4, context.seatWind)) - 1
            let round = 27 + max(1, min(4, context.roundWind)) - 1
            let windHan = (triplets.contains(seat) ? 1 : 0) + (triplets.contains(round) ? 1 : 0)
            if dragonHan + windHan > 0 { yaku.append(.init(name: "Value Tiles", han: dragonHan + windHan)) }
            let dragonPair = (31...33).contains(shape.pair)
            if dragonHan == 2 && dragonPair { yaku.append(.init(name: "Little Three Dragons", han: 2)) }
            if triplets.count == 4 { yaku.append(.init(name: "All Triplets", han: 2)) }

            if closed {
                let pairs = Dictionary(grouping: sequences, by: { $0 }).values.filter { $0.count >= 2 }.count
                if pairs > 0 { yaku.append(.init(name: pairs >= 2 ? "Twice Pure Double Sequence" : "Pure Double Sequence", han: pairs >= 2 ? 3 : 1)) }
            }
            if (0...6).contains(where: { rank in [rank, 9 + rank, 18 + rank].allSatisfy(sequences.contains) }) {
                yaku.append(.init(name: "Mixed Triple Sequence", han: closed ? 2 : 1))
            }
            if (0...8).contains(where: { rank in [rank, 9 + rank, 18 + rank].allSatisfy(triplets.contains) }) {
                yaku.append(.init(name: "Triple Triplets", han: 2))
            }
            if [0, 9, 18].contains(where: { base in [base, base + 3, base + 6].allSatisfy(sequences.contains) }) {
                yaku.append(.init(name: "Pure Straight", han: closed ? 2 : 1))
            }
            if closed, sequences.count == 4, !isValuePair(shape.pair, context: context), isRyanmen(shape, winCode: MahjongHandEvaluator.index(of: context.winningTile)) {
                yaku.append(.init(name: "Pinfu", han: 1))
            }
            let concealedTriplets = concealedUnits.filter(\.triplet).count + melds.filter { $0.kind == .closedKan }.count
            if concealedTriplets >= 3 { yaku.append(.init(name: "Three Concealed Triplets", han: 2)) }
            if kanCount >= 3 { yaku.append(.init(name: "Three Kans", han: 2)) }
            if allTiles.allSatisfy({ $0.suit == .honors || $0.rank == 1 || $0.rank == 9 }) {
                yaku.append(.init(name: "All Terminals and Honors", han: 2))
            }
            addFlushYaku(allTiles, closed: closed, to: &yaku)

            guard hasRealYaku(yaku) else { continue }
            let pinfu = yaku.contains { $0.name == "Pinfu" }
            let fu = calculateFu(shape: shape, melds: melds, closed: closed, context: context, pinfu: pinfu)
            if let result = finish(yaku: yaku, fu: fu, allTiles: allTiles, indicators: context.doraIndicators, dealer: context.seatWind == 1) {
                candidates.append(result)
            }
        }
        return candidates.max { ($0.points, $0.han, $0.fu) < ($1.points, $1.han, $1.fu) }
    }

    static func points(han: Int, fu: Int, dealer: Bool = false) -> Int {
        let multiplier = dealer ? 1.5 : 1.0
        if han >= 13 { return dealer ? 48_000 : 32_000 }
        if han >= 11 { return dealer ? 36_000 : 24_000 }
        if han >= 8 { return dealer ? 24_000 : 16_000 }
        if han >= 6 { return dealer ? 18_000 : 12_000 }
        if han >= 5 { return dealer ? 12_000 : 8_000 }
        let base = fu * (1 << (han + 2))
        if base >= 2_000 { return dealer ? 12_000 : 8_000 }
        return Int(ceil((Double(base * 4) * multiplier) / 100)) * 100
    }

    private static func baseYaku(allTiles: [SpaceTile], closed: Bool, context: WinContext) -> [YakuValue] {
        var yaku: [YakuValue] = []
        if context.riichi && closed { yaku.append(.init(name: "Riichi", han: 1)) }
        if context.selfDraw && closed { yaku.append(.init(name: "Menzen Tsumo", han: 1)) }
        if context.rinshan { yaku.append(.init(name: "After a Kan", han: 1)) }
        if allTiles.allSatisfy({ $0.suit != .honors && $0.rank != 1 && $0.rank != 9 }) {
            yaku.append(.init(name: "All Simples", han: 1))
        }
        return yaku
    }

    private static func addFlushYaku(_ tiles: [SpaceTile], closed: Bool, to yaku: inout [YakuValue]) {
        let suits = Set(tiles.filter { $0.suit != .honors }.map(\.suit))
        guard suits.count == 1 else { return }
        let hasHonors = tiles.contains { $0.suit == .honors }
        yaku.append(.init(name: hasHonors ? "Half Flush" : "Full Flush", han: hasHonors ? (closed ? 3 : 2) : (closed ? 6 : 5)))
    }

    private static func hasRealYaku(_ yaku: [YakuValue]) -> Bool {
        yaku.contains { $0.name != "Dora" }
    }

    private static func finish(yaku: [YakuValue], fu: Int, allTiles: [SpaceTile], indicators: [SpaceTile], dealer: Bool) -> HandScore? {
        var final = yaku
        let doraCodes = indicators.map(doraCode(after:))
        let dora = allTiles.reduce(0) { total, tile in
            total + doraCodes.filter { $0 == MahjongHandEvaluator.index(of: tile) }.count
        }
        if dora > 0 { final.append(.init(name: "Dora", han: dora)) }
        let han = final.reduce(0) { $0 + $1.han }
        return HandScore(yaku: final, han: han, fu: fu, points: points(han: han, fu: fu, dealer: dealer))
    }

    private static func calculateFu(shape: Shape, melds: [CalledMeld], closed: Bool, context: WinContext, pinfu: Bool) -> Int {
        if pinfu { return context.selfDraw ? 20 : 30 }
        var fu = 20
        if closed && !context.selfDraw { fu += 10 }
        if context.selfDraw { fu += 2 }
        if shape.pair >= 31 { fu += 2 }
        if shape.pair == 27 + context.seatWind - 1 { fu += 2 }
        if shape.pair == 27 + context.roundWind - 1 { fu += 2 }
        for unit in shape.units where unit.triplet {
            let terminal = isTerminalOrHonor(unit.code)
            fu += terminal ? 8 : 4
        }
        for meld in melds {
            guard let first = meld.tiles.first else { continue }
            let terminal = isTerminalOrHonor(MahjongHandEvaluator.index(of: first))
            switch meld.kind {
            case .chi: break
            case .pon: fu += terminal ? 4 : 2
            case .openKan, .addedKan: fu += terminal ? 16 : 8
            case .closedKan: fu += terminal ? 32 : 16
            }
        }
        let win = MahjongHandEvaluator.index(of: context.winningTile)
        if win == shape.pair || !isRyanmen(shape, winCode: win) { fu += 2 }
        if !closed && !context.selfDraw && fu == 20 { return 30 }
        return Int(ceil(Double(fu) / 10)) * 10
    }

    private static func isRyanmen(_ shape: Shape, winCode: Int) -> Bool {
        shape.units.contains { unit in
            guard !unit.triplet, (unit.code...(unit.code + 2)).contains(winCode) else { return false }
            let start = unit.code % 9
            return winCode != unit.code + 1 && !(winCode == unit.code && start == 6) && !(winCode == unit.code + 2 && start == 0)
        }
    }

    private static func isValuePair(_ code: Int, context: WinContext) -> Bool {
        code >= 31 || code == 27 + context.seatWind - 1 || code == 27 + context.roundWind - 1
    }

    private static func isTerminalOrHonor(_ code: Int) -> Bool {
        code >= 27 || code % 9 == 0 || code % 9 == 8
    }

    private static func scoreShapes(_ tiles: [SpaceTile], meldCount: Int) -> [Shape] {
        guard tiles.count == 14 - meldCount * 3 else { return [] }
        let original = counts(tiles)
        var result: [Shape] = []
        for pair in 0..<34 where original[pair] >= 2 {
            var rest = original
            rest[pair] -= 2
            for units in extract(&rest, from: 0) where units.count == 4 - meldCount {
                result.append(.init(pair: pair, units: units))
            }
        }
        return result
    }

    private static func extract(_ counts: inout [Int], from start: Int) -> [[Shape.Unit]] {
        guard let first = (start..<34).first(where: { counts[$0] > 0 }) else { return [[]] }
        var result: [[Shape.Unit]] = []
        if counts[first] >= 3 {
            counts[first] -= 3
            result += extract(&counts, from: first).map { [.init(code: first, triplet: true)] + $0 }
            counts[first] += 3
        }
        if first < 27, first % 9 <= 6, counts[first + 1] > 0, counts[first + 2] > 0 {
            counts[first] -= 1; counts[first + 1] -= 1; counts[first + 2] -= 1
            result += extract(&counts, from: first).map { [.init(code: first, triplet: false)] + $0 }
            counts[first] += 1; counts[first + 1] += 1; counts[first + 2] += 1
        }
        return result
    }

    private static func counts(_ tiles: [SpaceTile]) -> [Int] {
        var result = Array(repeating: 0, count: 34)
        tiles.forEach { result[MahjongHandEvaluator.index(of: $0)] += 1 }
        return result
    }

    private static func isSevenPairs(_ tiles: [SpaceTile]) -> Bool {
        tiles.count == 14 && counts(tiles).filter { $0 == 2 }.count == 7
    }

    private static func isThirteenOrphans(_ tiles: [SpaceTile]) -> Bool {
        guard tiles.count == 14 else { return false }
        let values = counts(tiles)
        let required = [0, 8, 9, 17, 18, 26] + Array(27...33)
        return required.allSatisfy { values[$0] > 0 } && required.contains { values[$0] > 1 }
    }

    private static func tile(_ code: Int) -> SpaceTile {
        switch code {
        case 0..<9: return .init(suit: .characters, rank: code + 1)
        case 9..<18: return .init(suit: .circles, rank: code - 8)
        case 18..<27: return .init(suit: .bamboo, rank: code - 17)
        default: return .init(suit: .honors, rank: code - 26)
        }
    }
}
