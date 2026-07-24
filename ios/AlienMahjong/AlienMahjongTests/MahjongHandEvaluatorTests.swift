import XCTest
@testable import AlienMahjong

final class MahjongHandEvaluatorTests: XCTestCase {
    func testStandardFourMeldsAndPairWins() {
        let hand = tiles([
            (.characters, 1), (.characters, 2), (.characters, 3),
            (.characters, 4), (.characters, 5), (.characters, 6),
            (.circles, 2), (.circles, 3), (.circles, 4),
            (.bamboo, 7), (.bamboo, 7), (.bamboo, 7),
            (.honors, 1), (.honors, 1)
        ])
        XCTAssertTrue(MahjongHandEvaluator.isWinning(hand))
    }

    func testSevenPairsWins() {
        let pairs: [(TileSuit, Int)] = [
            (.characters, 1), (.characters, 9), (.circles, 2),
            (.circles, 8), (.bamboo, 3), (.honors, 1), (.honors, 5)
        ]
        XCTAssertTrue(MahjongHandEvaluator.isWinning(pairs.flatMap { [SpaceTile(suit: $0.0, rank: $0.1), SpaceTile(suit: $0.0, rank: $0.1)] }))
    }

    func testThirteenOrphansWins() {
        let orphans: [(TileSuit, Int)] = [
            (.characters, 1), (.characters, 9), (.circles, 1), (.circles, 9),
            (.bamboo, 1), (.bamboo, 9), (.honors, 1), (.honors, 2),
            (.honors, 3), (.honors, 4), (.honors, 5), (.honors, 6), (.honors, 7)
        ]
        var hand = tiles(orphans)
        hand.append(SpaceTile(suit: .honors, rank: 7))
        XCTAssertTrue(MahjongHandEvaluator.isWinning(hand))
    }

    func testIncompleteHandDoesNotWin() {
        let hand = tiles([
            (.characters, 1), (.characters, 2), (.characters, 4),
            (.characters, 4), (.characters, 5), (.characters, 6),
            (.circles, 2), (.circles, 3), (.circles, 4),
            (.bamboo, 7), (.bamboo, 7), (.bamboo, 7),
            (.honors, 1), (.honors, 1)
        ])
        XCTAssertFalse(MahjongHandEvaluator.isWinning(hand))
    }

    private func tiles(_ values: [(TileSuit, Int)]) -> [SpaceTile] {
        values.map { SpaceTile(suit: $0.0, rank: $0.1) }
    }
}
