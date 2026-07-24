import XCTest
@testable import SukebanMahjong

final class MahjongEngineTests: XCTestCase {
    func testDealerReceivesFourteenTilesAndActsFirst() {
        let playerDealer = MatchRules.startingHandSizes(playerIsDealer: true)
        XCTAssertEqual(playerDealer.player, 14)
        XCTAssertEqual(playerDealer.enemy, 13)

        let enemyDealer = MatchRules.startingHandSizes(playerIsDealer: false)
        XCTAssertEqual(enemyDealer.player, 13)
        XCTAssertEqual(enemyDealer.enemy, 14)
    }

    func testStandardFourMeldsAndPairWins() {
        let hand = tiles("123m", "123p", "123s", "777z", "55m")
        XCTAssertTrue(MahjongRules.isWinning(hand))
    }

    func testSevenPairsWins() {
        let hand = tiles("1122m", "3344p", "5566s", "77z")
        XCTAssertTrue(MahjongRules.isWinning(hand))
        XCTAssertTrue(MahjongRules.result(for: hand, riichi: false, turn: 8)?.yaku.contains {
            $0.name == "七対子" && $0.han == 2
        } == true)
    }

    func testStandardShapeOutscoresAmbiguousSevenPairsShape() {
        let hand = tiles("11223344556677m")
        let result = MahjongRules.result(
            for: hand,
            riichi: false,
            turn: 8,
            selfDraw: false
        )

        XCTAssertTrue(result?.yaku.contains { $0.name == "二盃口" } == true)
        XCTAssertTrue(result?.yaku.contains { $0.name == "清一色" } == true)
        XCTAssertFalse(result?.yaku.contains { $0.name == "七対子" } == true)
        XCTAssertEqual(result?.han, 9)
    }

    func testIncompleteHandDoesNotWin() {
        let hand = tiles("124m", "123p", "123s", "777z", "55m")
        XCTAssertFalse(MahjongRules.isWinning(hand))
        XCTAssertNil(MahjongRules.result(for: hand, riichi: false, turn: 8))
    }

    func testTanyaoAndRiichiAreScored() {
        let hand = tiles("234m", "234p", "345s", "666p", "22s")
        let result = MahjongRules.result(for: hand, riichi: true, turn: 8)
        XCTAssertNotNil(result)
        XCTAssertTrue(result?.yaku.contains { $0.name == "断么九" } == true)
        XCTAssertTrue(result?.yaku.contains { $0.name == "立直" } == true)
        XCTAssertEqual(result?.han, 3)
        XCTAssertEqual(result?.points, 3900)
    }

    func testWallContainsFourOfEveryTile() {
        let wall = MahjongRules.makeWall()
        XCTAssertEqual(wall.count, 136)
        let groups = Dictionary(grouping: wall, by: MahjongRules.code)
        XCTAssertEqual(groups.count, 34)
        XCTAssertTrue(groups.values.allSatisfy { $0.count == 4 })
    }

    func testDoraIsAddedToHan() {
        let hand = tiles("123m", "123p", "123s", "777z", "55m")
        let indicator = MahjongTile(suit: .man, value: 4)
        let result = MahjongRules.result(
            for: hand,
            riichi: false,
            turn: 8,
            doraIndicators: [indicator]
        )
        XCTAssertTrue(result?.yaku.contains { $0.name == "ドラ" && $0.han == 2 } == true)
    }

    func testDoraWrapsWithinNumberWindsAndDragons() {
        XCTAssertEqual(
            MahjongRules.doraCode(after: MahjongTile(suit: .man, value: 9)),
            MahjongRules.code(MahjongTile(suit: .man, value: 1))
        )
        XCTAssertEqual(
            MahjongRules.doraCode(after: MahjongTile(suit: .honor, value: 4)),
            MahjongRules.code(MahjongTile(suit: .honor, value: 1))
        )
        XCTAssertEqual(
            MahjongRules.doraCode(after: MahjongTile(suit: .honor, value: 7)),
            MahjongRules.code(MahjongTile(suit: .honor, value: 5))
        )
    }

    func testDiscardedWaitCreatesFuriten() {
        let waitingHand = tiles("123m", "123p", "123s", "777z", "5m")
        XCTAssertTrue(MahjongRules.isFuriten(waitingHand, discards: tiles("5m")))
        XCTAssertFalse(MahjongRules.isFuriten(waitingHand, discards: tiles("6m")))
    }

    func testRiichiLegalityDoesNotPeekAtHiddenWall() {
        let hand = tiles("123m", "123p", "123s", "777z", "5m", "9p")
        let candidates = MahjongRules.riichiDiscardCodes(hand, wall: [])

        XCTAssertTrue(candidates.contains(MahjongRules.code(MahjongTile(suit: .pin, value: 9))))
    }

    func testWaitingCodesNeverInventsAFifthCopy() {
        let impossibleWait = tiles("1111m", "123p", "123s", "777z")
        let waits = MahjongRules.waitingCodes(impossibleWait)

        XCTAssertFalse(waits.contains(MahjongRules.code(MahjongTile(suit: .man, value: 1))))
        XCTAssertTrue(waits.isEmpty)
    }

    func testWinningShapeRejectsFiveIdenticalTiles() {
        let invalidHand = tiles("11111m", "123p", "123s", "777z")
        XCTAssertFalse(MahjongRules.isWinning(invalidHand))
    }

    func testSmartDiscardDoesNotPeekAtWallContents() {
        let hand = tiles("123m", "123p", "123s", "777z", "5m", "9p")
        let emptyWallChoice = MahjongRules.bestDiscardIndex(in: hand, wall: [])
        let misleadingWallChoice = MahjongRules.bestDiscardIndex(
            in: hand,
            wall: tiles("9999p")
        )

        XCTAssertEqual(emptyWallChoice, misleadingWallChoice)
    }

    func testPassingRonDuringRiichiBlocksLaterRon() {
        XCTAssertTrue(
            MatchRules.canRon(
                isDiscardFuriten: false,
                isTemporaryFuriten: false,
                isRiichiPassFuriten: false
            )
        )
        XCTAssertFalse(
            MatchRules.canRon(
                isDiscardFuriten: true,
                isTemporaryFuriten: false,
                isRiichiPassFuriten: false
            )
        )
        XCTAssertFalse(
            MatchRules.canRon(
                isDiscardFuriten: false,
                isTemporaryFuriten: false,
                isRiichiPassFuriten: true
            )
        )
        XCTAssertFalse(
            MatchRules.canRon(
                isDiscardFuriten: false,
                isTemporaryFuriten: true,
                isRiichiPassFuriten: false
            )
        )
    }

    func testRinshanDoesNotAlsoAwardHaitei() {
        let hand = tiles("123m", "123p", "123s", "777z", "55m")
        let result = MahjongRules.result(
            for: hand,
            riichi: false,
            turn: 8,
            selfDraw: true,
            rinshan: true,
            lastTile: true
        )

        XCTAssertTrue(result?.yaku.contains { $0.name == "嶺上開花" } == true)
        XCTAssertFalse(result?.yaku.contains { $0.name == "海底摸月" } == true)
    }

    func testChankanDoesNotAlsoAwardHoutei() {
        let hand = tiles("123m", "123p", "123s", "777z", "55m")
        let result = MahjongRules.result(
            for: hand,
            riichi: false,
            turn: 8,
            selfDraw: false,
            lastDiscard: true,
            robbingKan: true
        )

        XCTAssertTrue(result?.yaku.contains { $0.name == "槍槓" } == true)
        XCTAssertFalse(result?.yaku.contains { $0.name == "河底撈魚" } == true)
    }

    func testRonRequiresYaku() {
        let noYakuHand = tiles("123m", "234p", "456s", "789m", "55p")
        XCTAssertNil(MahjongRules.result(
            for: noYakuHand,
            riichi: false,
            turn: 8,
            selfDraw: false
        ))
        XCTAssertNotNil(MahjongRules.result(
            for: noYakuHand,
            riichi: true,
            turn: 8,
            selfDraw: false
        ))
    }

    func testDealerScoreIsOneAndHalfTimesRoundedToHundred() {
        XCTAssertEqual(MatchRules.settledPoints(base: 3900, winnerIsDealer: true, honba: 0), 5900)
        XCTAssertEqual(MatchRules.settledPoints(base: 8000, winnerIsDealer: true, honba: 0), 12000)
    }

    func testHonbaAddsThreeHundredPoints() {
        XCTAssertEqual(MatchRules.settledPoints(base: 2000, winnerIsDealer: false, honba: 2), 2600)
        XCTAssertEqual(MatchRules.settledPoints(base: 2000, winnerIsDealer: true, honba: 2), 3600)
    }

    func testWinnerCollectsCarriedRiichiSticks() {
        XCTAssertEqual(
            MatchRules.winnerGain(
                base: 2000,
                winnerIsDealer: false,
                honba: 1,
                riichiPot: 2000
            ),
            4300
        )
        XCTAssertEqual(
            MatchRules.winnerGain(
                base: 2000,
                winnerIsDealer: true,
                honba: 0,
                riichiPot: 1000
            ),
            4000
        )
    }

    func testFinalRiichiPotGoesToCurrentLeader() {
        XCTAssertTrue(
            MatchRules.playerReceivesFinalRiichiPot(playerPoints: 13000, enemyPoints: 11000)
        )
        XCTAssertFalse(
            MatchRules.playerReceivesFinalRiichiPot(playerPoints: 12000, enemyPoints: 12000)
        )
    }

    func testMatchConclusionHonorsFinalRoundRepeatAndBankruptcy() {
        XCTAssertNil(MatchRules.conclusionIfNeeded(
            playerPoints: 13000,
            enemyPoints: 11000,
            round: 3,
            dealerRepeats: false,
            riichiPot: 0
        ))
        XCTAssertNil(MatchRules.conclusionIfNeeded(
            playerPoints: 13000,
            enemyPoints: 11000,
            round: 4,
            dealerRepeats: true,
            riichiPot: 0
        ))

        let finalRound = MatchRules.conclusionIfNeeded(
            playerPoints: 13000,
            enemyPoints: 11000,
            round: 4,
            dealerRepeats: false,
            riichiPot: 1000
        )
        XCTAssertEqual(finalRound?.playerPoints, 14000)
        XCTAssertEqual(finalRound?.enemyPoints, 11000)
        XCTAssertEqual(finalRound?.playerWon, true)
        XCTAssertEqual(finalRound?.riichiPotWentToPlayer, true)

        let bankruptcy = MatchRules.conclusionIfNeeded(
            playerPoints: 0,
            enemyPoints: 23000,
            round: 2,
            dealerRepeats: true,
            riichiPot: 1000
        )
        XCTAssertEqual(bankruptcy?.enemyPoints, 24000)
        XCTAssertEqual(bankruptcy?.playerWon, false)
    }

    func testTiedFinalScoreAwardsPotToOpponent() {
        let conclusion = MatchRules.conclusionIfNeeded(
            playerPoints: 11000,
            enemyPoints: 11000,
            round: 4,
            dealerRepeats: false,
            riichiPot: 2000
        )

        XCTAssertEqual(conclusion?.playerPoints, 11000)
        XCTAssertEqual(conclusion?.enemyPoints, 13000)
        XCTAssertEqual(conclusion?.riichiPotWentToPlayer, false)
        XCTAssertEqual(conclusion?.playerWon, false)
    }

    func testFourKansIsYakuman() {
        let pair = tiles("55p")
        let melds = [
            OpenMeld(kind: .closedKan, tiles: tiles("1111m")),
            OpenMeld(kind: .openKan, tiles: tiles("2222m")),
            OpenMeld(kind: .addedKan, tiles: tiles("3333p")),
            OpenMeld(kind: .closedKan, tiles: tiles("4444s"))
        ]
        let result = MahjongRules.result(
            for: pair,
            riichi: false,
            turn: 8,
            openMelds: melds
        )

        XCTAssertTrue(result?.yaku.contains { $0.name == "四槓子" && $0.han == 13 } == true)
        XCTAssertEqual(result?.points, 32000)
    }

    func testDealerRepeatsAfterWinOrTenpaiDraw() {
        XCTAssertTrue(MatchRules.dealerRepeats(winnerIsDealer: true, dealerTenpaiOnDraw: false))
        XCTAssertFalse(MatchRules.dealerRepeats(winnerIsDealer: false, dealerTenpaiOnDraw: true))
        XCTAssertTrue(MatchRules.dealerRepeats(winnerIsDealer: nil, dealerTenpaiOnDraw: true))
        XCTAssertFalse(MatchRules.dealerRepeats(winnerIsDealer: nil, dealerTenpaiOnDraw: false))
    }

    func testOpenPonReducesRequiredConcealedMeldCount() {
        let concealed = tiles("123m", "123p", "123s", "55m")
        let redDragonPon = OpenMeld(kind: .pon, tiles: tiles("777z"))
        XCTAssertTrue(MahjongRules.isWinning(concealed, openMeldCount: 1))

        let result = MahjongRules.result(
            for: concealed,
            riichi: false,
            turn: 8,
            selfDraw: true,
            openMelds: [redDragonPon]
        )
        XCTAssertTrue(result?.yaku.contains { $0.name == "役牌" && $0.han == 1 } == true)
        XCTAssertFalse(result?.yaku.contains { $0.name == "門前清自摸和" } == true)
    }

    func testOpenHandStillNeedsAYaku() {
        let concealed = tiles("123m", "123p", "789s", "55m")
        let openPon = OpenMeld(kind: .pon, tiles: tiles("222s"))
        XCTAssertTrue(MahjongRules.isWinning(concealed, openMeldCount: 1))
        XCTAssertNil(MahjongRules.result(
            for: concealed,
            riichi: false,
            turn: 8,
            selfDraw: true,
            openMelds: [openPon]
        ))
    }

    func testOpenChinitsuIsFiveHan() {
        let concealed = tiles("123m", "456m", "789m", "55m")
        let openPon = OpenMeld(kind: .pon, tiles: tiles("222m"))
        let result = MahjongRules.result(
            for: concealed,
            riichi: false,
            turn: 8,
            selfDraw: true,
            openMelds: [openPon]
        )
        XCTAssertTrue(result?.yaku.contains { $0.name == "清一色" && $0.han == 5 } == true)
    }

    func testChiOptionsFindAllLegalSequences() {
        let hand = tiles("12245m", "123p", "789s", "55z")
        let called = MahjongTile(suit: .man, value: 3)
        let options = MahjongRules.chiOptions(for: called, in: hand)
        let values = Set(options.map { $0.map(\.value).sorted().map { String($0) }.joined() })
        XCTAssertEqual(values, Set(["12", "24", "45"]))
        XCTAssertTrue(MahjongRules.chiOptions(
            for: MahjongTile(suit: .honor, value: 1),
            in: hand
        ).isEmpty)
    }

    func testClosedKanCandidateRequiresAllFourCopies() {
        let hand = tiles("1111m", "222p", "345s", "77z", "89m")
        let candidates = MahjongRules.closedKanCodes(in: hand)
        XCTAssertTrue(candidates.contains(MahjongRules.code(MahjongTile(suit: .man, value: 1))))
        XCTAssertFalse(candidates.contains(MahjongRules.code(MahjongTile(suit: .pin, value: 2))))
    }

    func testClosedKanKeepsHandClosed() {
        let concealed = tiles("123m", "123p", "123s", "55m")
        let closedKan = OpenMeld(kind: .closedKan, tiles: tiles("2222s"))
        let result = MahjongRules.result(
            for: concealed,
            riichi: true,
            turn: 8,
            selfDraw: true,
            openMelds: [closedKan]
        )
        XCTAssertTrue(result?.yaku.contains { $0.name == "立直" } == true)
        XCTAssertTrue(result?.yaku.contains { $0.name == "門前清自摸和" } == true)
    }

    func testMultipleDoraIndicatorsAccumulate() {
        let hand = tiles("123m", "123p", "123s", "777z", "55m")
        let result = MahjongRules.result(
            for: hand,
            riichi: false,
            turn: 8,
            doraIndicators: [
                MahjongTile(suit: .man, value: 4),
                MahjongTile(suit: .honor, value: 6)
            ]
        )
        XCTAssertTrue(result?.yaku.contains { $0.name == "ドラ" && $0.han == 5 } == true)
    }

    func testOpenHandCanWinByRinshan() {
        let concealed = tiles("123m", "123p", "789s", "55m")
        let openKan = OpenMeld(kind: .openKan, tiles: tiles("2222s"))
        let result = MahjongRules.result(
            for: concealed,
            riichi: false,
            turn: 8,
            selfDraw: true,
            rinshan: true,
            openMelds: [openKan]
        )
        XCTAssertTrue(result?.yaku.contains { $0.name == "嶺上開花" && $0.han == 1 } == true)
    }

    func testAddedKanCandidateMatchesExistingPon() {
        let hand = tiles("5m", "123p", "456s", "77z", "89m")
        let pon = OpenMeld(kind: .pon, tiles: tiles("555m"))
        let chi = OpenMeld(kind: .chi, tiles: tiles("456p"))
        let options = MahjongRules.addedKanOptions(hand: hand, melds: [pon, chi])
        XCTAssertEqual(options.count, 1)
        XCTAssertEqual(options.first?.meldIndex, 0)
        XCTAssertEqual(options.first.map { MahjongRules.code($0.tile) }, MahjongRules.code(MahjongTile(suit: .man, value: 5)))
    }

    func testRobbingKanProvidesAYaku() {
        let noOtherYaku = tiles("123m", "123p", "123s", "789m", "55p")
        let result = MahjongRules.result(
            for: noOtherYaku,
            riichi: false,
            turn: 8,
            selfDraw: false,
            robbingKan: true
        )
        XCTAssertTrue(result?.yaku.contains { $0.name == "槍槓" && $0.han == 1 } == true)
    }

    func testThirteenOrphansIsYakuman() {
        let hand = tiles("119m", "19p", "19s", "1234567z")
        let result = MahjongRules.result(for: hand, riichi: false, turn: 8)
        XCTAssertTrue(MahjongRules.isWinning(hand))
        XCTAssertEqual(result?.yaku.first?.name, "国士無双")
        XCTAssertEqual(result?.yaku.first?.han, 13)
        XCTAssertEqual(result?.points, 32000)
    }

    func testBigThreeDragonsIsYakuman() {
        let hand = tiles("555z", "666z", "777z", "123m", "55p")
        let result = MahjongRules.result(for: hand, riichi: false, turn: 8)
        XCTAssertTrue(result?.yaku.contains { $0.name == "大三元" && $0.han == 13 } == true)
    }

    func testFourConcealedTripletsIsYakumanOnTsumo() {
        let hand = tiles("111m", "222m", "333p", "444s", "55z")
        let result = MahjongRules.result(for: hand, riichi: false, turn: 8)
        XCTAssertTrue(result?.yaku.contains { $0.name == "四暗刻" && $0.han == 13 } == true)
    }

    func testAllHonorsAndAllTerminalsAreYakuman() {
        let honors = MahjongRules.result(
            for: tiles("111z", "222z", "333z", "444z", "55z"),
            riichi: false,
            turn: 8
        )
        let terminals = MahjongRules.result(
            for: tiles("111m", "999m", "111p", "999p", "11s"),
            riichi: false,
            turn: 8
        )
        XCTAssertTrue(honors?.yaku.contains { $0.name == "字一色" } == true)
        XCTAssertTrue(terminals?.yaku.contains { $0.name == "清老頭" } == true)
    }

    func testDoubleRiichiAndIppatsuAreCounted() {
        let hand = tiles("123m", "123p", "123s", "789m", "55p")
        let result = MahjongRules.result(
            for: hand,
            riichi: true,
            turn: 6,
            ippatsu: true,
            doubleRiichi: true
        )
        XCTAssertTrue(result?.yaku.contains { $0.name == "ダブル立直" && $0.han == 2 } == true)
        XCTAssertTrue(result?.yaku.contains { $0.name == "一発" && $0.han == 1 } == true)
    }

    func testLastDiscardProvidesHouteiYaku() {
        let hand = tiles("123m", "123p", "123s", "789m", "55p")
        let result = MahjongRules.result(
            for: hand,
            riichi: false,
            turn: 12,
            selfDraw: false,
            lastDiscard: true
        )
        XCTAssertTrue(result?.yaku.contains { $0.name == "河底撈魚" && $0.han == 1 } == true)
    }

    func testLittleThreeDragonsAndHonroutou() {
        let littleThree = MahjongRules.result(
            for: tiles("555z", "666z", "77z", "123m", "123p"),
            riichi: false,
            turn: 8
        )
        let honroutou = MahjongRules.result(
            for: tiles("1199m", "1199p", "1199s", "11z"),
            riichi: false,
            turn: 8
        )
        XCTAssertTrue(littleThree?.yaku.contains { $0.name == "小三元" && $0.han == 2 } == true)
        XCTAssertTrue(honroutou?.yaku.contains { $0.name == "混老頭" && $0.han == 2 } == true)
    }

    func testRoundAndSeatWindCanStack() {
        let hand = tiles("111z", "123m", "123p", "123s", "55m")
        let dealer = MahjongRules.result(
            for: hand,
            riichi: false,
            turn: 8,
            seatWind: 1,
            roundWind: 1
        )
        let southSeat = MahjongRules.result(
            for: hand,
            riichi: false,
            turn: 8,
            seatWind: 2,
            roundWind: 1
        )
        XCTAssertTrue(dealer?.yaku.contains { $0.name == "役牌" && $0.han == 2 } == true)
        XCTAssertTrue(southSeat?.yaku.contains { $0.name == "役牌" && $0.han == 1 } == true)
    }

    func testBigAndLittleFourWindsAreYakuman() {
        let big = MahjongRules.result(
            for: tiles("111z", "222z", "333z", "444z", "55m"),
            riichi: false,
            turn: 8
        )
        let little = MahjongRules.result(
            for: tiles("111z", "222z", "333z", "44z", "123m"),
            riichi: false,
            turn: 8
        )
        XCTAssertTrue(big?.yaku.contains { $0.name == "大四喜" } == true)
        XCTAssertTrue(little?.yaku.contains { $0.name == "小四喜" } == true)
    }

    func testStraightAndMixedTripleSequence() {
        let straight = MahjongRules.result(
            for: tiles("123m", "456m", "789m", "123p", "55s"),
            riichi: false,
            turn: 8
        )
        let mixed = MahjongRules.result(
            for: tiles("123m", "123p", "123s", "789m", "55p"),
            riichi: false,
            turn: 8
        )
        XCTAssertTrue(straight?.yaku.contains { $0.name == "一気通貫" && $0.han == 2 } == true)
        XCTAssertTrue(mixed?.yaku.contains { $0.name == "三色同順" && $0.han == 2 } == true)
    }

    func testOneAndTwoSetsOfIdenticalSequences() {
        let one = MahjongRules.result(
            for: tiles("123m", "123m", "456p", "789s", "55p"),
            riichi: false,
            turn: 8
        )
        let two = MahjongRules.result(
            for: tiles("123m", "123m", "456p", "456p", "55s"),
            riichi: false,
            turn: 8
        )
        XCTAssertTrue(one?.yaku.contains { $0.name == "一盃口" && $0.han == 1 } == true)
        XCTAssertTrue(two?.yaku.contains { $0.name == "二盃口" && $0.han == 3 } == true)
        XCTAssertFalse(two?.yaku.contains { $0.name == "一盃口" } == true)
    }

    func testMixedTripleTripletsAndOutsideHands() {
        let triple = MahjongRules.result(
            for: tiles("111m", "111p", "111s", "789m", "55p"),
            riichi: false,
            turn: 8
        )
        let pureOutside = MahjongRules.result(
            for: tiles("123m", "789m", "123p", "999s", "11p"),
            riichi: false,
            turn: 8
        )
        let mixedOutside = MahjongRules.result(
            for: tiles("123m", "789m", "123p", "999s", "11z"),
            riichi: false,
            turn: 8
        )
        XCTAssertTrue(triple?.yaku.contains { $0.name == "三色同刻" && $0.han == 2 } == true)
        XCTAssertTrue(pureOutside?.yaku.contains { $0.name == "純全帯么九" && $0.han == 3 } == true)
        XCTAssertTrue(mixedOutside?.yaku.contains { $0.name == "混全帯么九" && $0.han == 2 } == true)
    }

    func testPinfuRequiresRyanmenAndUsesTwentyFuOnTsumo() {
        let hand = tiles("123m", "456m", "234p", "678s", "55p")
        let ryanmen = MahjongRules.result(
            for: hand,
            riichi: false,
            turn: 8,
            winningTile: MahjongTile(suit: .man, value: 6)
        )
        let kanchan = MahjongRules.result(
            for: hand,
            riichi: false,
            turn: 8,
            winningTile: MahjongTile(suit: .man, value: 5)
        )
        XCTAssertTrue(ryanmen?.yaku.contains { $0.name == "平和" } == true)
        XCTAssertEqual(ryanmen?.fu, 20)
        XCTAssertEqual(ryanmen?.points, 1300)
        XCTAssertFalse(kanchan?.yaku.contains { $0.name == "平和" } == true)
    }

    func testSevenPairsUsesTwentyFiveFu() {
        let result = MahjongRules.result(
            for: tiles("1122m", "3344p", "5566s", "77z"),
            riichi: false,
            turn: 8
        )
        XCTAssertEqual(result?.fu, 25)
    }

    func testOpenYakuhaiRonUsesThirtyFuAndOneThousandPoints() {
        let concealed = tiles("123m", "456m", "789p", "55s")
        let redDragonPon = OpenMeld(kind: .pon, tiles: tiles("777z"))
        let result = MahjongRules.result(
            for: concealed,
            riichi: false,
            turn: 8,
            selfDraw: false,
            winningTile: MahjongTile(suit: .sou, value: 5),
            openMelds: [redDragonPon]
        )
        XCTAssertEqual(result?.fu, 30)
        XCTAssertEqual(result?.han, 1)
        XCTAssertEqual(result?.points, 1000)
    }

    func testThreeConcealedTripletsAndRonCompletedTriplet() {
        let hand = tiles("111m", "222m", "333p", "456s", "55p")
        let tsumo = MahjongRules.result(
            for: hand,
            riichi: false,
            turn: 8,
            winningTile: MahjongTile(suit: .pin, value: 3)
        )
        let ron = MahjongRules.result(
            for: hand,
            riichi: true,
            turn: 8,
            selfDraw: false,
            winningTile: MahjongTile(suit: .pin, value: 3)
        )
        XCTAssertTrue(tsumo?.yaku.contains { $0.name == "三暗刻" } == true)
        XCTAssertFalse(ron?.yaku.contains { $0.name == "三暗刻" } == true)
    }

    func testThreeKansAreRecognized() {
        let concealed = tiles("123m", "55p")
        let melds = [
            OpenMeld(kind: .openKan, tiles: tiles("1111p")),
            OpenMeld(kind: .closedKan, tiles: tiles("2222s")),
            OpenMeld(kind: .addedKan, tiles: tiles("5555z"))
        ]
        let result = MahjongRules.result(
            for: concealed,
            riichi: false,
            turn: 8,
            rinshan: true,
            openMelds: melds
        )
        XCTAssertTrue(result?.yaku.contains { $0.name == "三槓子" && $0.han == 2 } == true)
    }

    func testFourConcealedTripletsCanRonOnPairWait() {
        let hand = tiles("111m", "222m", "333p", "444s", "55z")
        let result = MahjongRules.result(
            for: hand,
            riichi: false,
            turn: 8,
            selfDraw: false,
            winningTile: MahjongTile(suit: .honor, value: 5)
        )
        XCTAssertTrue(result?.yaku.contains { $0.name == "四暗刻" } == true)
    }

    func testAmbiguousShapeStillRecognizesFourConcealedTripletsPairWait() {
        // 222333444p can also be read as three copies of the 234p sequence.
        let hand = tiles("999m", "22233344455p")
        let result = MahjongRules.result(
            for: hand,
            riichi: false,
            turn: 8,
            selfDraw: false,
            winningTile: MahjongTile(suit: .pin, value: 5)
        )

        XCTAssertTrue(result?.yaku.contains { $0.name == "四暗刻" } == true)
        XCTAssertEqual(result?.points, 32000)
    }

    func testAmbiguousStandardShapeChoosesHighestScoringInterpretation() {
        let hand = tiles("44455667777p", "777s")
        let result = MahjongRules.result(
            for: hand,
            riichi: false,
            turn: 8,
            selfDraw: false,
            winningTile: MahjongTile(suit: .pin, value: 7)
        )

        XCTAssertTrue(result?.yaku.contains { $0.name == "断么九" } == true)
        XCTAssertTrue(result?.yaku.contains { $0.name == "一盃口" } == true)
        XCTAssertEqual(result?.han, 2)
        XCTAssertEqual(result?.points, 2600)
    }

    func testRonCompletedTripletUsesOpenTripletFu() {
        let hand = tiles("111m", "222p", "333s", "456m", "55p")
        let result = MahjongRules.result(
            for: hand,
            riichi: true,
            turn: 8,
            selfDraw: false,
            winningTile: MahjongTile(suit: .sou, value: 3)
        )
        XCTAssertEqual(result?.fu, 50)
    }

    func testFuHanPointTableAndLimits() {
        XCTAssertEqual(MahjongRules.calculatedPoints(han: 1, fu: 30), 1000)
        XCTAssertEqual(MahjongRules.calculatedPoints(han: 2, fu: 30), 2000)
        XCTAssertEqual(MahjongRules.calculatedPoints(han: 3, fu: 30), 3900)
        XCTAssertEqual(MahjongRules.calculatedPoints(han: 4, fu: 30), 7700)
        XCTAssertEqual(MahjongRules.calculatedPoints(han: 4, fu: 40), 8000)
        XCTAssertEqual(MahjongRules.calculatedPoints(han: 5, fu: 30), 8000)
        XCTAssertEqual(MahjongRules.calculatedPoints(han: 6, fu: 30), 12000)
        XCTAssertEqual(MahjongRules.calculatedPoints(han: 8, fu: 30), 16000)
        XCTAssertEqual(MahjongRules.calculatedPoints(han: 11, fu: 30), 24000)
        XCTAssertEqual(MahjongRules.calculatedPoints(han: 13, fu: 30), 32000)
    }

    private func tiles(_ groups: String...) -> [MahjongTile] {
        groups.flatMap { group -> [MahjongTile] in
            guard let suffix = group.last else { return [] }
            let suit: TileSuit
            switch suffix {
            case "m": suit = .man
            case "p": suit = .pin
            case "s": suit = .sou
            default: suit = .honor
            }
            return group.dropLast().compactMap { character in
                character.wholeNumberValue.map { MahjongTile(suit: suit, value: $0) }
            }
        }
    }
}
