import XCTest
@testable import AlienMahjong

final class RiichiRulesTests: XCTestCase {
    func testChiPonAndKanOptions() {
        let called = tile(.characters, 3)
        let hand = [
            tile(.characters, 1), tile(.characters, 2),
            tile(.characters, 3), tile(.characters, 3), tile(.characters, 3)
        ]
        XCTAssertEqual(RiichiRules.chiOptions(called: called, hand: hand).count, 1)
        XCTAssertEqual(RiichiRules.matchingTiles(called, in: hand).count, 3)
        XCTAssertEqual(RiichiRules.closedKanCode(in: hand), nil)

        let four = hand + [tile(.characters, 3)]
        XCTAssertEqual(RiichiRules.closedKanCode(in: four), 2)
    }

    func testDiscardFuritenWhenOwnRiverContainsAWait() {
        let tenpai = tiles([
            (.characters, 1), (.characters, 2), (.characters, 3),
            (.characters, 4), (.characters, 5), (.characters, 6),
            (.circles, 2), (.circles, 3), (.circles, 4),
            (.bamboo, 7), (.bamboo, 7), (.bamboo, 7),
            (.honors, 1)
        ])
        XCTAssertTrue(RiichiRules.waits(for: tenpai, melds: []).contains(27))
        XCTAssertTrue(RiichiRules.isDiscardFuriten(
            hand: tenpai,
            melds: [],
            discards: [tile(.honors, 1)]
        ))
    }

    func testRiichiPinfuTsumoScoreIncludesDora() {
        let hand = tiles([
            (.characters, 1), (.characters, 2), (.characters, 3),
            (.characters, 4), (.characters, 5), (.characters, 6),
            (.circles, 2), (.circles, 3), (.circles, 4),
            (.bamboo, 3), (.bamboo, 4), (.bamboo, 5),
            (.circles, 7), (.circles, 7)
        ])
        let winning = hand[11]
        let result = RiichiRules.score(
            tiles: hand,
            melds: [],
            context: .init(
                riichi: true,
                selfDraw: true,
                winningTile: winning,
                seatWind: 1,
                roundWind: 1,
                doraIndicators: [tile(.circles, 6)],
                rinshan: false
            )
        )
        XCTAssertNotNil(result)
        XCTAssertTrue(result?.yaku.contains(where: { $0.name == "Riichi" }) == true)
        XCTAssertTrue(result?.yaku.contains(where: { $0.name == "Menzen Tsumo" }) == true)
        XCTAssertTrue(result?.yaku.contains(where: { $0.name == "Dora" }) == true)
        XCTAssertGreaterThanOrEqual(result?.han ?? 0, 3)
    }

    func testOpenDragonPonProvidesYakuAndFu() {
        let redDragons = [tile(.honors, 5), tile(.honors, 5), tile(.honors, 5)]
        let meld = CalledMeld(kind: .pon, tiles: redDragons)
        let concealed = tiles([
            (.characters, 1), (.characters, 2), (.characters, 3),
            (.circles, 2), (.circles, 3), (.circles, 4),
            (.bamboo, 4), (.bamboo, 5), (.bamboo, 6),
            (.honors, 1), (.honors, 1)
        ])
        let result = RiichiRules.score(
            tiles: concealed,
            melds: [meld],
            context: .init(
                riichi: false,
                selfDraw: false,
                winningTile: concealed[8],
                seatWind: 1,
                roundWind: 1,
                doraIndicators: [],
                rinshan: false
            )
        )
        XCTAssertNotNil(result)
        XCTAssertTrue(result?.yaku.contains(where: { $0.name == "Value Tiles" }) == true)
        XCTAssertGreaterThanOrEqual(result?.fu ?? 0, 30)
    }

    func testManganAndLimitPointCalculation() {
        XCTAssertEqual(RiichiRules.points(han: 5, fu: 30), 8_000)
        XCTAssertEqual(RiichiRules.points(han: 8, fu: 30), 16_000)
        XCTAssertEqual(RiichiRules.points(han: 13, fu: 0), 32_000)
    }

    private func tile(_ suit: TileSuit, _ rank: Int) -> SpaceTile {
        SpaceTile(suit: suit, rank: rank)
    }

    private func tiles(_ values: [(TileSuit, Int)]) -> [SpaceTile] {
        values.map { tile($0.0, $0.1) }
    }
}
