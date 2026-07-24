import Foundation

struct MatchSnapshot: Codable, Equatable {
    let version: Int
    let opponentID: Int
    let hand: [MahjongTile]
    let enemyHand: [MahjongTile]
    let wall: [MahjongTile]
    let doraIndicators: [MahjongTile]
    let discards: [MahjongTile]
    let enemyDiscards: [MahjongTile]
    let discardHistory: [MahjongTile]
    let enemyDiscardHistory: [MahjongTile]
    let openMelds: [OpenMeld]
    let enemyOpenMelds: [OpenMeld]
    let pendingCall: MahjongTile?
    let pendingRon: HandResult?
    let playerPoints: Int
    let enemyPoints: Int
    let riichiPot: Int
    let round: Int
    let honba: Int
    let turn: Int
    let message: String
    let matchResult: Bool?
    let handEnded: Bool
    let handResult: HandResult?
    let settledPoints: Int
    let dealerRepeats: Bool
    let isRiichi: Bool
    let enemyRiichi: Bool
    let playerIppatsu: Bool
    let enemyIppatsu: Bool
    let playerDoubleRiichi: Bool
    let enemyDoubleRiichi: Bool
    let playerTemporaryFuriten: Bool
    let playerRiichiPassFuriten: Bool
    let riichiMode: Bool
    let lastDrawnID: UUID?
    let lastDrawWasReplacement: Bool

    static let currentVersion = 5

    var activeTileCount: Int {
        activeTiles.count
    }

    var hasValidTileSet: Bool {
        guard activeTileCount == 136 else { return false }
        guard Set(activeTiles.map(\.id)).count == activeTiles.count else { return false }
        guard activeTiles.allSatisfy(\.hasValidValue) else { return false }

        let copies = Dictionary(grouping: activeTiles, by: MahjongRules.code)
        return copies.values.allSatisfy { $0.count == 4 }
            && copies.keys.count == 34
    }

    var hasValidState: Bool {
        guard (1...5).contains(opponentID) else { return false }
        guard (1...4).contains(round), honba >= 0, turn >= 0 else { return false }
        guard riichiPot >= 0, riichiPot.isMultiple(of: 1000) else { return false }
        guard playerPoints + enemyPoints + riichiPot == 24_000 else { return false }
        guard doraIndicators.count >= 1, doraIndicators.count <= 5 else { return false }
        guard openMelds.count <= 4, enemyOpenMelds.count <= 4 else { return false }
        guard (openMelds + enemyOpenMelds).allSatisfy(\.hasValidShape) else {
            return false
        }
        guard pendingRon == nil || pendingCall != nil else { return false }
        guard matchResult == nil || handEnded else { return false }
        guard !riichiMode || !isRiichi else { return false }
        return true
    }

    private var activeTiles: [MahjongTile] {
        hand
            + enemyHand
            + wall
            + doraIndicators
            + discards
            + enemyDiscards
            + openMelds.flatMap(\.tiles)
            + enemyOpenMelds.flatMap(\.tiles)
    }
}

enum MatchStore {
    private static let key = "sukebanMahjong.activeMatch.v1"

    static func save(_ snapshot: MatchSnapshot, defaults: UserDefaults = .standard) {
        guard snapshot.hasValidTileSet, snapshot.hasValidState else { return }
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key)
    }

    static func load(defaults: UserDefaults = .standard) -> MatchSnapshot? {
        guard let data = defaults.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(MatchSnapshot.self, from: data),
              snapshot.version == MatchSnapshot.currentVersion,
              snapshot.hasValidTileSet,
              snapshot.hasValidState else { return nil }
        return snapshot
    }

    static func clear(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }

    static var savedOpponentID: Int? {
        load()?.opponentID
    }
}

private extension MahjongTile {
    var hasValidValue: Bool {
        switch suit {
        case .man, .pin, .sou:
            return (1...9).contains(value)
        case .honor:
            return (1...7).contains(value)
        }
    }
}

private extension OpenMeld {
    var hasValidShape: Bool {
        switch kind {
        case .chi:
            guard tiles.count == 3,
                  let suit = tiles.first?.suit,
                  suit != .honor,
                  tiles.allSatisfy({ $0.suit == suit }) else { return false }
            let values = tiles.map(\.value).sorted()
            return values[1] == values[0] + 1
                && values[2] == values[1] + 1
        case .pon:
            return tiles.count == 3
                && Set(tiles.map(MahjongRules.code)).count == 1
        case .openKan, .closedKan, .addedKan:
            return tiles.count == 4
                && Set(tiles.map(MahjongRules.code)).count == 1
        }
    }
}
