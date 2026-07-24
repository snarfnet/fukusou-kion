import XCTest
import Foundation
@testable import SukebanMahjong

final class MatchSnapshotTests: XCTestCase {
    func testSnapshotRoundTripsThroughJSON() throws {
        let snapshot = sampleSnapshot()
        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(MatchSnapshot.self, from: data)
        XCTAssertEqual(decoded, snapshot)
        XCTAssertEqual(decoded.hand.first?.id, snapshot.hand.first?.id)
        XCTAssertEqual(decoded.lastDrawnID, snapshot.lastDrawnID)
        XCTAssertEqual(decoded.activeTileCount, 136)
        XCTAssertTrue(decoded.hasValidTileSet)
        XCTAssertTrue(decoded.hasValidState)
    }

    func testMatchStoreSavesLoadsAndClears() {
        let suiteName = "MatchSnapshotTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let snapshot = sampleSnapshot()
        MatchStore.save(snapshot, defaults: defaults)
        XCTAssertEqual(MatchStore.load(defaults: defaults), snapshot)
        MatchStore.clear(defaults: defaults)
        XCTAssertNil(MatchStore.load(defaults: defaults))
    }

    func testUnknownSnapshotVersionIsRejected() {
        let suiteName = "MatchSnapshotVersionTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        var snapshot = sampleSnapshot()
        snapshot = MatchSnapshot(
            version: 999,
            opponentID: snapshot.opponentID,
            hand: snapshot.hand,
            enemyHand: snapshot.enemyHand,
            wall: snapshot.wall,
            doraIndicators: snapshot.doraIndicators,
            discards: snapshot.discards,
            enemyDiscards: snapshot.enemyDiscards,
            discardHistory: snapshot.discardHistory,
            enemyDiscardHistory: snapshot.enemyDiscardHistory,
            openMelds: snapshot.openMelds,
            enemyOpenMelds: snapshot.enemyOpenMelds,
            pendingCall: snapshot.pendingCall,
            pendingRon: snapshot.pendingRon,
            playerPoints: snapshot.playerPoints,
            enemyPoints: snapshot.enemyPoints,
            riichiPot: snapshot.riichiPot,
            round: snapshot.round,
            honba: snapshot.honba,
            turn: snapshot.turn,
            message: snapshot.message,
            matchResult: snapshot.matchResult,
            handEnded: snapshot.handEnded,
            handResult: snapshot.handResult,
            settledPoints: snapshot.settledPoints,
            dealerRepeats: snapshot.dealerRepeats,
            isRiichi: snapshot.isRiichi,
            enemyRiichi: snapshot.enemyRiichi,
            playerIppatsu: snapshot.playerIppatsu,
            enemyIppatsu: snapshot.enemyIppatsu,
            playerDoubleRiichi: snapshot.playerDoubleRiichi,
            enemyDoubleRiichi: snapshot.enemyDoubleRiichi,
            playerTemporaryFuriten: snapshot.playerTemporaryFuriten,
            playerRiichiPassFuriten: snapshot.playerRiichiPassFuriten,
            riichiMode: snapshot.riichiMode,
            lastDrawnID: snapshot.lastDrawnID,
            lastDrawWasReplacement: snapshot.lastDrawWasReplacement
        )
        MatchStore.save(snapshot, defaults: defaults)
        XCTAssertNil(MatchStore.load(defaults: defaults))
    }

    func testSnapshotWithMissingTileIsRejected() throws {
        let suiteName = "MatchSnapshotTileCountTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let data = try JSONEncoder().encode(sampleSnapshot())
        var object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        var wall = try XCTUnwrap(object["wall"] as? [[String: Any]])
        wall.removeLast()
        object["wall"] = wall
        let damagedData = try JSONSerialization.data(withJSONObject: object)
        defaults.set(damagedData, forKey: "sukebanMahjong.activeMatch.v1")

        XCTAssertNil(MatchStore.load(defaults: defaults))
    }

    func testSnapshotWithDuplicateTileIdentityIsRejected() throws {
        let suiteName = "MatchSnapshotDuplicateIdentityTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        var object = try snapshotObject()
        var wall = try XCTUnwrap(object["wall"] as? [[String: Any]])
        wall[0]["id"] = wall[1]["id"]
        object["wall"] = wall
        defaults.set(
            try JSONSerialization.data(withJSONObject: object),
            forKey: "sukebanMahjong.activeMatch.v1"
        )

        XCTAssertNil(MatchStore.load(defaults: defaults))
    }

    func testSnapshotWithFifthCopyOfTileIsRejected() throws {
        let suiteName = "MatchSnapshotFifthCopyTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        var object = try snapshotObject()
        var wall = try XCTUnwrap(object["wall"] as? [[String: Any]])
        let source = wall[0]
        let sourceSuit = source["suit"]
        let sourceValue = source["value"]
        let replacementIndex = try XCTUnwrap(
            wall.indices.first {
                String(describing: wall[$0]["suit"]) != String(describing: sourceSuit)
                    || String(describing: wall[$0]["value"]) != String(describing: sourceValue)
            }
        )
        wall[replacementIndex]["suit"] = sourceSuit
        wall[replacementIndex]["value"] = sourceValue
        object["wall"] = wall
        defaults.set(
            try JSONSerialization.data(withJSONObject: object),
            forKey: "sukebanMahjong.activeMatch.v1"
        )

        XCTAssertNil(MatchStore.load(defaults: defaults))
    }

    func testSnapshotWithImpossiblePointTotalIsRejected() throws {
        let suiteName = "MatchSnapshotPointTotalTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        var object = try snapshotObject()
        object["playerPoints"] = 99_999
        defaults.set(
            try JSONSerialization.data(withJSONObject: object),
            forKey: "sukebanMahjong.activeMatch.v1"
        )

        XCTAssertNil(MatchStore.load(defaults: defaults))
    }

    func testSnapshotWithInvalidRoundIsRejected() throws {
        let suiteName = "MatchSnapshotRoundTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        var object = try snapshotObject()
        object["round"] = 5
        defaults.set(
            try JSONSerialization.data(withJSONObject: object),
            forKey: "sukebanMahjong.activeMatch.v1"
        )

        XCTAssertNil(MatchStore.load(defaults: defaults))
    }

    func testSnapshotWithPendingRonButNoDiscardIsRejected() throws {
        let suiteName = "MatchSnapshotPendingRonTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        var object = try snapshotObject()
        object["pendingCall"] = NSNull()
        defaults.set(
            try JSONSerialization.data(withJSONObject: object),
            forKey: "sukebanMahjong.activeMatch.v1"
        )

        XCTAssertNil(MatchStore.load(defaults: defaults))
    }

    private func sampleSnapshot() -> MatchSnapshot {
        var tiles = MahjongRules.makeWall()
        let hand = (0..<14).compactMap { _ in tiles.popLast() }
        let enemyHand = (0..<13).compactMap { _ in tiles.popLast() }
        let doraIndicators = tiles.popLast().map { [$0] } ?? []
        let discards = tiles.popLast().map { [$0] } ?? []
        let enemyDiscards = tiles.popLast().map { [$0] } ?? []
        let result = HandResult(
            yaku: [.init(name: "立直", han: 1)],
            han: 1,
            fu: 30,
            points: 1000
        )
        return MatchSnapshot(
            version: MatchSnapshot.currentVersion,
            opponentID: 3,
            hand: hand,
            enemyHand: enemyHand,
            wall: tiles,
            doraIndicators: doraIndicators,
            discards: discards,
            enemyDiscards: enemyDiscards,
            discardHistory: discards,
            enemyDiscardHistory: enemyDiscards,
            openMelds: [],
            enemyOpenMelds: [],
            pendingCall: enemyDiscards.last,
            pendingRon: result,
            playerPoints: 13400,
            enemyPoints: 8600,
            riichiPot: 2000,
            round: 2,
            honba: 1,
            turn: 7,
            message: "対局再開",
            matchResult: nil,
            handEnded: false,
            handResult: nil,
            settledPoints: 0,
            dealerRepeats: false,
            isRiichi: true,
            enemyRiichi: false,
            playerIppatsu: true,
            enemyIppatsu: false,
            playerDoubleRiichi: false,
            enemyDoubleRiichi: false,
            playerTemporaryFuriten: true,
            playerRiichiPassFuriten: true,
            riichiMode: false,
            lastDrawnID: hand.last?.id,
            lastDrawWasReplacement: false
        )
    }

    private func snapshotObject() throws -> [String: Any] {
        let data = try JSONEncoder().encode(sampleSnapshot())
        return try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
    }
}
