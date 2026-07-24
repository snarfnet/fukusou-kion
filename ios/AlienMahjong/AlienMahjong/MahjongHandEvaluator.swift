import Foundation

enum MahjongHandEvaluator {
    static func index(of tile: SpaceTile) -> Int {
        switch tile.suit {
        case .characters: return tile.rank - 1
        case .circles: return 9 + tile.rank - 1
        case .bamboo: return 18 + tile.rank - 1
        case .honors: return 27 + tile.rank - 1
        }
    }

    static func isWinning(_ tiles: [SpaceTile]) -> Bool {
        guard tiles.count == 14 else { return false }
        var counts = tileCounts(tiles)
        if isSevenPairs(counts) || isThirteenOrphans(counts) { return true }

        for pair in 0..<34 where counts[pair] >= 2 {
            counts[pair] -= 2
            if canFormMelds(&counts, from: 0) { return true }
            counts[pair] += 2
        }
        return false
    }

    static func isTenpai(removing tile: SpaceTile, from tiles: [SpaceTile]) -> Bool {
        guard let index = tiles.firstIndex(where: { $0.id == tile.id }) else { return false }
        var thirteen = tiles
        thirteen.remove(at: index)
        return waits(for: thirteen).isEmpty == false
    }

    static func waits(for tiles: [SpaceTile]) -> [Int] {
        guard tiles.count == 13 else { return [] }
        let counts = tileCounts(tiles)
        return (0..<34).filter { candidate in
            guard counts[candidate] < 4 else { return false }
            var trial = counts
            trial[candidate] += 1
            return isWinningCounts(trial)
        }
    }

    static func waitCount(afterDiscarding tile: SpaceTile, from tiles: [SpaceTile]) -> Int {
        guard let index = tiles.firstIndex(where: { $0.id == tile.id }) else { return 0 }
        var thirteen = tiles
        thirteen.remove(at: index)
        return waits(for: thirteen).count
    }

    private static func tileCounts(_ tiles: [SpaceTile]) -> [Int] {
        var counts = Array(repeating: 0, count: 34)
        for tile in tiles { counts[index(of: tile)] += 1 }
        return counts
    }

    private static func isWinningCounts(_ counts: [Int]) -> Bool {
        guard counts.reduce(0, +) == 14 else { return false }
        if isSevenPairs(counts) || isThirteenOrphans(counts) { return true }
        var mutable = counts
        for pair in 0..<34 where mutable[pair] >= 2 {
            mutable[pair] -= 2
            if canFormMelds(&mutable, from: 0) { return true }
            mutable[pair] += 2
        }
        return false
    }

    private static func canFormMelds(_ counts: inout [Int], from start: Int) -> Bool {
        guard let first = (start..<34).first(where: { counts[$0] > 0 }) else { return true }

        if counts[first] >= 3 {
            counts[first] -= 3
            if canFormMelds(&counts, from: first) { return true }
            counts[first] += 3
        }

        if first < 27, first % 9 <= 6, counts[first + 1] > 0, counts[first + 2] > 0 {
            counts[first] -= 1
            counts[first + 1] -= 1
            counts[first + 2] -= 1
            if canFormMelds(&counts, from: first) { return true }
            counts[first] += 1
            counts[first + 1] += 1
            counts[first + 2] += 1
        }

        return false
    }

    private static func isSevenPairs(_ counts: [Int]) -> Bool {
        counts.filter { $0 == 2 }.count == 7
    }

    private static func isThirteenOrphans(_ counts: [Int]) -> Bool {
        let terminalsAndHonors = [0, 8, 9, 17, 18, 26] + Array(27...33)
        guard terminalsAndHonors.allSatisfy({ counts[$0] >= 1 }) else { return false }
        return terminalsAndHonors.contains { counts[$0] >= 2 }
    }
}
