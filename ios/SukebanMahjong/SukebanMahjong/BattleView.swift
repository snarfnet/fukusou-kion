import SwiftUI
import UIKit

struct BattleView: View {
    let opponent: Sukeban
    let completion: (Bool) -> Void

    @State private var hand: [MahjongTile] = []
    @State private var enemyHand: [MahjongTile] = []
    @State private var wall: [MahjongTile] = []
    @State private var doraIndicators: [MahjongTile] = []
    @State private var discards: [MahjongTile] = []
    @State private var enemyDiscards: [MahjongTile] = []
    @State private var discardHistory: [MahjongTile] = []
    @State private var enemyDiscardHistory: [MahjongTile] = []
    @State private var openMelds: [OpenMeld] = []
    @State private var enemyOpenMelds: [OpenMeld] = []
    @State private var pendingCall: MahjongTile?
    @State private var pendingRon: HandResult?
    @State private var playerPoints = 12000
    @State private var enemyPoints = 12000
    @State private var riichiPot = 0
    @State private var round = 1
    @State private var honba = 0
    @State private var turn = 1
    @State private var message = "牌を捨てな！"
    @State private var matchResult: Bool?
    @State private var handEnded = false
    @State private var handResult: HandResult?
    @State private var settledPoints = 0
    @State private var dealerRepeats = false
    @State private var isRiichi = false
    @State private var enemyRiichi = false
    @State private var playerIppatsu = false
    @State private var enemyIppatsu = false
    @State private var playerDoubleRiichi = false
    @State private var enemyDoubleRiichi = false
    @State private var playerTemporaryFuriten = false
    @State private var playerRiichiPassFuriten = false
    @State private var riichiMode = false
    @State private var lastDrawnID: UUID?
    @State private var lastDrawWasReplacement = false
    @State private var pendingDiscard: MahjongTile?
    @State private var showDiscardConfirmation = false
    @State private var bannerText: String?
    @State private var bannerColor = Color.red
    @AppStorage("settings.confirmDiscard") private var confirmDiscard = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var riichiCodes: Set<Int> {
        MahjongRules.riichiDiscardCodes(hand, wall: wall)
    }

    private var playerIsDealer: Bool { round % 2 == 1 }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ScrollView {
                    VStack(spacing: 7) {
                        opponentHeader
                        river(enemyDiscards, upsideDown: true)
                        if !enemyOpenMelds.isEmpty {
                            meldRow(enemyOpenMelds, label: "相手の鳴き")
                        }
                        HStack {
                            Text("東\(round)局 \(honba)本場　\(turn)巡").foregroundStyle(.yellow)
                            if riichiPot > 0 {
                                Text("供託\(riichiPot / 1000)")
                                    .foregroundStyle(.cyan)
                            }
                            Spacer()
                            if !doraIndicators.isEmpty {
                                Text("ドラ表示")
                                ForEach(doraIndicators) { TileFace(tile: $0, compact: true) }
                            }
                            Text("山\(wall.count)")
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("東\(round)局、\(honba)本場、\(turn)巡目。残り\(wall.count)枚")
                        Text(message)
                            .frame(minHeight: 36)
                            .multilineTextAlignment(.center)
                            .accessibilityLabel("対局状況、\(message)")
                        river(discards, upsideDown: false)
                        if !openMelds.isEmpty {
                            meldRow(openMelds, label: "鳴き")
                        }
                        playerHeader
                        handGrid
                        actionButtons
                    }
                    .frame(minHeight: geometry.size.height - 24, alignment: .top)
                    .padding()
                }
                if let bannerText {
                    BattleBanner(text: bannerText, color: bannerColor)
                        .transition(reduceMotion ? .opacity : .scale(scale: 0.6).combined(with: .opacity))
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
        }
        .onAppear { restoreOrStart() }
        .confirmationDialog(
            pendingDiscard.map { "\($0.label)を切るか？" } ?? "この牌を切るか？",
            isPresented: $showDiscardConfirmation,
            titleVisibility: .visible
        ) {
            if let pendingDiscard {
                Button("\(pendingDiscard.label)を切る", role: .destructive) {
                    discard(pendingDiscard)
                    self.pendingDiscard = nil
                }
            }
            Button("やめる", role: .cancel) { pendingDiscard = nil }
        }
    }

    private var opponentHeader: some View {
        HStack {
            PixelPortrait(girl: opponent, size: 66)
            VStack(alignment: .leading, spacing: 3) {
                Text(opponent.alias).foregroundStyle(opponent.colors[0])
                Text("\(enemyPoints)点\(playerIsDealer ? "" : "　親")\(enemyRiichi ? "　立直" : "")")
                ProgressView(value: Double(max(0, enemyPoints)), total: 24000).tint(.red)
                    .accessibilityLabel("\(opponent.name)の点棒")
                    .accessibilityValue("\(enemyPoints)点")
            }
            Spacer()
            Text(opponent.specialty).font(.caption).foregroundStyle(.gray)
        }
        .accessibilityElement(children: .contain)
    }

    private var playerHeader: some View {
        VStack(spacing: 3) {
            HStack {
                Text(
                    "朱莉　\(playerPoints)点"
                    + (playerIsDealer ? "　親" : "")
                    + (isRiichi ? "　立直" : "")
                    + (playerTemporaryFuriten || playerRiichiPassFuriten ? "　フリテン" : "")
                )
                Spacer()
                if hand.count == 14 - openMelds.count * 3 {
                    Text(
                        MahjongRules.isWinning(hand, openMeldCount: openMelds.count)
                        ? "和了！"
                        : openMelds.isEmpty ? "立直候補 \(riichiCodes.count)" : "副露 \(openMelds.count)"
                    )
                        .foregroundStyle(.cyan)
                }
            }
            ProgressView(value: Double(max(0, playerPoints)), total: 24000).tint(.cyan)
                .accessibilityLabel("朱莉の点棒")
                .accessibilityValue("\(playerPoints)点")
        }
    }

    private var handGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 7), spacing: 4) {
            ForEach(hand) { tile in
                let candidate = riichiCodes.contains(MahjongRules.code(tile))
                Button { chooseDiscard(tile) } label: {
                    TileFace(tile: tile)
                        .overlay(Rectangle().stroke(riichiMode && candidate ? .yellow : .clear, lineWidth: 4))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(tile.spokenLabel)を捨てる")
                .accessibilityHint(
                    riichiMode && candidate
                    ? "この牌でリーチを宣言します"
                    : "ダブルタップで打牌します"
                )
                .disabled(
                    handEnded ||
                    pendingCall != nil ||
                    (riichiMode && !candidate) ||
                    (isRiichi && tile.id != lastDrawnID)
                )
                .opacity(riichiMode && !candidate ? 0.35 : 1)
            }
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        if let pendingCall {
            callButtons(for: pendingCall)
        } else if let matchResult {
            scorePanel
            Button(matchResult ? "勝負の続きを見る" : "もう一度立つ") {
                if matchResult {
                    MatchStore.clear()
                    completion(true)
                } else {
                    resetMatch()
                }
            }.buttonStyle(PixelButtonStyle(color: matchResult ? .red : .blue))
            Button("全国地図へ戻る") {
                MatchStore.clear()
                completion(false)
            }
            .font(.caption)
            .foregroundStyle(.gray)
        } else if handEnded {
            scorePanel
            Button(dealerRepeats ? "東\(round)局 \(honba + 1)本場へ" : "東\(round + 1)局へ") {
                if dealerRepeats {
                    honba += 1
                } else {
                    round += 1
                    honba = 0
                }
                dealHand()
            }.buttonStyle(PixelButtonStyle(color: .blue))
        } else {
            HStack {
                if currentPlayerResult != nil {
                    Button("ツモ！") { declareWin() }.buttonStyle(PixelButtonStyle(color: .red))
                }
                if !isRiichi, !riichiCodes.isEmpty, playerPoints >= 1000 {
                    Button(riichiMode ? "取消" : "リーチ") {
                        riichiMode.toggle()
                        saveSnapshot()
                    }
                        .buttonStyle(PixelButtonStyle(color: .blue))
                }
            }
            if !isRiichi, !MahjongRules.closedKanCodes(in: hand).isEmpty {
                HStack {
                    ForEach(MahjongRules.closedKanCodes(in: hand).sorted(), id: \.self) { code in
                        Button("暗カン \(MahjongRules.tileForCode(code).label)") { callClosedKan(code) }
                            .buttonStyle(PixelButtonStyle(color: .purple))
                    }
                }
            }
            if !isRiichi {
                HStack {
                    ForEach(
                        Array(MahjongRules.addedKanOptions(hand: hand, melds: openMelds).enumerated()),
                        id: \.offset
                    ) { _, option in
                        Button("加カン \(option.tile.label)") { callAddedKan(option) }
                            .buttonStyle(PixelButtonStyle(color: .purple))
                    }
                }
            }
            Button("対局を降りる") {
                MatchStore.clear()
                completion(false)
            }
                .font(.caption).foregroundStyle(.gray)
        }
    }

    @ViewBuilder
    private var scorePanel: some View {
        if let handResult {
            VStack(spacing: 3) {
                ForEach(handResult.yaku, id: \.name) { Text("\($0.name)　\($0.han)翻") }
                Text(
                    handResult.fu == 0
                    ? "\(handResult.han)翻　\(settledPoints)点"
                    : "\(handResult.han)翻 \(handResult.fu)符　\(settledPoints)点"
                )
                    .font(.title3).foregroundStyle(.yellow)
            }
            .padding(7)
            .background(Color.black)
            .overlay(Rectangle().stroke(.yellow, lineWidth: 2))
        }
    }

    private var currentPlayerResult: HandResult? {
        MahjongRules.result(
            for: hand,
            riichi: isRiichi,
            turn: turn,
            selfDraw: true,
            rinshan: lastDrawWasReplacement,
            lastTile: wall.isEmpty,
            ippatsu: playerIppatsu,
            doubleRiichi: playerDoubleRiichi,
            seatWind: playerIsDealer ? 1 : 2,
            roundWind: 1,
            winningTile: hand.first { $0.id == lastDrawnID },
            doraIndicators: doraIndicators,
            openMelds: openMelds
        )
    }

    private func river(_ tiles: [MahjongTile], upsideDown: Bool) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 2) {
                ForEach(tiles) {
                    TileFace(tile: $0, compact: true).rotationEffect(upsideDown ? .degrees(180) : .zero)
                }
            }
        }
        .frame(height: 30)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            tiles.isEmpty
            ? "捨て牌なし"
            : "捨て牌、" + tiles.map(\.spokenLabel).joined(separator: "、")
        )
    }

    private func meldRow(_ melds: [OpenMeld], label: String) -> some View {
        HStack {
            Text(label)
            ForEach(Array(melds.enumerated()), id: \.offset) { _, meld in
                HStack(spacing: 1) {
                    ForEach(meld.tiles) { TileFace(tile: $0, compact: true) }
                }
            }
            Spacer()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            label + "、" + melds.flatMap(\.tiles).map(\.spokenLabel).joined(separator: "、")
        )
    }

    private func resetMatch() {
        MatchStore.clear()
        playerPoints = 12000
        enemyPoints = 12000
        riichiPot = 0
        round = 1
        honba = 0
        matchResult = nil
        dealHand()
    }

    private func dealHand() {
        var freshWall = MahjongRules.makeWall()
        let startingSizes = MatchRules.startingHandSizes(playerIsDealer: playerIsDealer)
        hand = (0..<startingSizes.player).compactMap { _ in freshWall.popLast() }
        enemyHand = (0..<startingSizes.enemy).compactMap { _ in freshWall.popLast() }
        let enemyOpeningTile = playerIsDealer ? nil : enemyHand.last
        doraIndicators = freshWall.popLast().map { [$0] } ?? []
        wall = freshWall
        hand = MahjongRules.sort(hand)
        enemyHand = MahjongRules.sort(enemyHand)
        discards = []
        enemyDiscards = []
        discardHistory = []
        enemyDiscardHistory = []
        openMelds = []
        enemyOpenMelds = []
        pendingCall = nil
        pendingRon = nil
        pendingDiscard = nil
        showDiscardConfirmation = false
        bannerText = nil
        turn = playerIsDealer ? 1 : 0
        handEnded = false
        handResult = nil
        settledPoints = 0
        dealerRepeats = false
        isRiichi = false
        enemyRiichi = false
        playerIppatsu = false
        enemyIppatsu = false
        playerDoubleRiichi = false
        enemyDoubleRiichi = false
        playerTemporaryFuriten = false
        playerRiichiPassFuriten = false
        riichiMode = false
        lastDrawnID = playerIsDealer ? hand.last?.id : nil
        lastDrawWasReplacement = false
        message = playerIsDealer
            ? "朱莉が親だ。配牌から一枚切れ！"
            : "\(opponent.name)が親。先打ちを見極めろ！"
        if let enemyOpeningTile {
            runOpponentTurn(alreadyDrawn: enemyOpeningTile)
            if !handEnded, pendingCall == nil {
                drawForPlayer()
            }
        }
        saveSnapshot()
    }

    private func discard(_ tile: MahjongTile) {
        guard !handEnded, let index = hand.firstIndex(of: tile) else { return }
        var declaredRiichiNow = false
        if riichiMode {
            guard riichiCodes.contains(MahjongRules.code(tile)) else { return }
            isRiichi = true
            riichiMode = false
            playerPoints -= 1000
            riichiPot += 1000
            playerIppatsu = true
            playerDoubleRiichi = turn == 1
            declaredRiichiNow = true
            message = "リーチ！ 千点棒を叩きつけた！"
            GameFeedback.shared.play(.riichi)
            showBanner("リーチ！", color: .blue)
        }
        hand.remove(at: index)
        discards.append(tile)
        discardHistory.append(tile)
        if !declaredRiichiNow { GameFeedback.shared.play(.discard) }
        if isRiichi, !declaredRiichiNow { playerIppatsu = false }

        let ronHand = enemyHand + [tile]
        if !MahjongRules.isFuriten(
            enemyHand,
            discards: enemyDiscardHistory,
            openMeldCount: enemyOpenMelds.count
        ),
           let score = MahjongRules.result(
               for: ronHand,
               riichi: enemyRiichi,
               turn: turn,
               selfDraw: false,
               lastDiscard: wall.isEmpty,
               ippatsu: enemyIppatsu,
               doubleRiichi: enemyDoubleRiichi,
               seatWind: playerIsDealer ? 2 : 1,
               roundWind: 1,
               winningTile: tile,
               doraIndicators: doraIndicators,
               openMelds: enemyOpenMelds
           ) {
            finishHand(playerWon: false, score: score, text: "\(opponent.name)「ロン！」")
            return
        }
        if attemptEnemyCall(on: tile) { return }
        runOpponentTurn()
        guard !handEnded else { return }
        if pendingCall == nil { drawForPlayer() }
    }

    private func runOpponentTurn(alreadyDrawn: MahjongTile? = nil) {
        let drawn: MahjongTile
        if let alreadyDrawn {
            drawn = alreadyDrawn
        } else {
            guard let tile = wall.popLast() else { finishExhaustiveDraw(); return }
            drawn = tile
            enemyHand.append(tile)
        }
        if attemptEnemyClosedKan() { return }
        if attemptEnemyAddedKan() { return }
        if let score = MahjongRules.result(
            for: enemyHand,
            riichi: enemyRiichi,
            turn: turn,
            selfDraw: true,
            lastTile: wall.isEmpty,
            ippatsu: enemyIppatsu,
            doubleRiichi: enemyDoubleRiichi,
            seatWind: playerIsDealer ? 2 : 1,
            roundWind: 1,
            winningTile: drawn,
            doraIndicators: doraIndicators,
            openMelds: enemyOpenMelds
        ) {
            finishHand(playerWon: false, score: score, text: "\(opponent.name)のツモ！")
            return
        }
        if enemyRiichi { enemyIppatsu = false }

        let chosenIndex: Int
        if enemyRiichi {
            chosenIndex = enemyHand.firstIndex(of: drawn) ?? enemyHand.index(before: enemyHand.endIndex)
        } else if Int.random(in: 1...6) <= opponent.tactics.smartDiscardChance {
            chosenIndex = MahjongRules.bestDiscardIndex(
                in: enemyHand,
                wall: wall,
                openMeldCount: enemyOpenMelds.count
            )
        } else {
            chosenIndex = Int.random(in: enemyHand.indices)
        }
        let enemyDiscard = enemyHand.remove(at: chosenIndex)
        enemyDiscards.append(enemyDiscard)
        enemyDiscardHistory.append(enemyDiscard)
        enemyHand = MahjongRules.sort(enemyHand)

        let enemyClosed = enemyOpenMelds.allSatisfy { !$0.breaksClosedHand }
        if !enemyRiichi, enemyClosed, enemyPoints >= 1000,
           !MahjongRules.waitingCodes(enemyHand, openMeldCount: enemyOpenMelds.count).isEmpty {
            enemyRiichi = true
            enemyIppatsu = true
            enemyDoubleRiichi = turn <= 1
            enemyPoints -= 1000
            riichiPot += 1000
            message = "\(opponent.name)「リーチ」"
            GameFeedback.shared.play(.riichi)
            showBanner("相手リーチ！", color: .red)
        }
        offerPlayerCall(on: enemyDiscard)
    }

    private func attemptEnemyClosedKan() -> Bool {
        guard !enemyRiichi,
              Int.random(in: 1...6) <= opponent.tactics.kanChance,
              let code = MahjongRules.closedKanCodes(in: enemyHand).sorted().first else {
            return false
        }

        let kanTiles = enemyHand.filter { MahjongRules.code($0) == code }
        guard kanTiles.count == 4 else { return false }
        removeEnemyTiles(kanTiles)
        enemyOpenMelds.append(OpenMeld(kind: .closedKan, tiles: kanTiles))
        if let indicator = wall.popLast() { doraIndicators.append(indicator) }
        guard let replacement = wall.popLast() else {
            finishExhaustiveDraw()
            return true
        }
        enemyHand.append(replacement)
        if let score = MahjongRules.result(
            for: enemyHand,
            riichi: false,
            turn: turn,
            selfDraw: true,
            rinshan: true,
            seatWind: playerIsDealer ? 2 : 1,
            roundWind: 1,
            winningTile: replacement,
            doraIndicators: doraIndicators,
            openMelds: enemyOpenMelds
        ) {
            finishHand(playerWon: false, score: score, text: "\(opponent.name)「暗カン嶺上！」")
            return true
        }
        message = "\(opponent.name)「暗カン！」"
        cancelIppatsu()
        GameFeedback.shared.play(.call)
        showBanner("相手暗カン！", color: .purple)
        finishEnemyCallTurn(shouldDrawPlayer: false)
        return true
    }

    private func attemptEnemyAddedKan() -> Bool {
        guard !enemyRiichi,
              Int.random(in: 1...6) <= opponent.tactics.kanChance,
              let option = MahjongRules.addedKanOptions(
                  hand: enemyHand,
                  melds: enemyOpenMelds
              ).first else { return false }

        if MatchRules.canRon(
            isDiscardFuriten: MahjongRules.isFuriten(
                hand,
                discards: discardHistory,
                openMeldCount: openMelds.count
            ),
            isTemporaryFuriten: playerTemporaryFuriten,
            isRiichiPassFuriten: playerRiichiPassFuriten
        ), let score = MahjongRules.result(
            for: hand + [option.tile],
            riichi: isRiichi,
            turn: turn,
            selfDraw: false,
            robbingKan: true,
            ippatsu: playerIppatsu,
            doubleRiichi: playerDoubleRiichi,
            seatWind: playerIsDealer ? 1 : 2,
            roundWind: 1,
            winningTile: option.tile,
            doraIndicators: doraIndicators,
            openMelds: openMelds
        ) {
            if let tileIndex = enemyHand.firstIndex(of: option.tile) {
                hand.append(enemyHand.remove(at: tileIndex))
                hand = MahjongRules.sort(hand)
            }
            finishHand(playerWon: true, score: score, text: "朱莉「槍槓！」")
            return true
        }

        guard let tileIndex = enemyHand.firstIndex(of: option.tile) else { return false }
        let added = enemyHand.remove(at: tileIndex)
        let old = enemyOpenMelds[option.meldIndex]
        enemyOpenMelds[option.meldIndex] = OpenMeld(
            kind: .addedKan,
            tiles: old.tiles + [added]
        )
        if let indicator = wall.popLast() { doraIndicators.append(indicator) }
        guard let replacement = wall.popLast() else {
            finishExhaustiveDraw()
            return true
        }
        enemyHand.append(replacement)
        if let score = MahjongRules.result(
            for: enemyHand,
            riichi: false,
            turn: turn,
            selfDraw: true,
            rinshan: true,
            seatWind: playerIsDealer ? 2 : 1,
            roundWind: 1,
            winningTile: replacement,
            doraIndicators: doraIndicators,
            openMelds: enemyOpenMelds
        ) {
            finishHand(playerWon: false, score: score, text: "\(opponent.name)「加カン嶺上！」")
            return true
        }
        message = "\(opponent.name)「加カン！」"
        cancelIppatsu()
        GameFeedback.shared.play(.call)
        finishEnemyCallTurn(shouldDrawPlayer: false)
        return true
    }

    private func attemptEnemyCall(on discardedTile: MahjongTile) -> Bool {
        guard !enemyRiichi else { return false }
        let target = MahjongRules.code(discardedTile)
        let matching = enemyHand.filter { MahjongRules.code($0) == target }
        let isDragon = discardedTile.suit == .honor && discardedTile.value >= 5
        let callRoll = Int.random(in: 1...6) <= opponent.tactics.callChance

        if matching.count >= 3, isDragon || callRoll {
            cancelIppatsu()
            GameFeedback.shared.play(.call)
            consumePlayerDiscard()
            removeEnemyTiles(Array(matching.prefix(3)))
            enemyOpenMelds.append(
                OpenMeld(kind: .openKan, tiles: Array(matching.prefix(3)) + [discardedTile])
            )
            if let indicator = wall.popLast() { doraIndicators.append(indicator) }
            guard let replacement = wall.popLast() else {
                finishExhaustiveDraw()
                return true
            }
            enemyHand.append(replacement)
            if let score = MahjongRules.result(
                for: enemyHand,
                riichi: false,
                turn: turn,
                selfDraw: true,
                rinshan: true,
                seatWind: playerIsDealer ? 2 : 1,
                roundWind: 1,
                winningTile: replacement,
                doraIndicators: doraIndicators,
                openMelds: enemyOpenMelds
            ) {
                finishHand(playerWon: false, score: score, text: "\(opponent.name)「嶺上ツモ！」")
                return true
            }
            message = "\(opponent.name)「カン！」"
            showBanner("カン！", color: .purple)
            finishEnemyCallTurn()
            return true
        }

        if matching.count >= 2, isDragon || callRoll {
            cancelIppatsu()
            GameFeedback.shared.play(.call)
            consumePlayerDiscard()
            let consumed = Array(matching.prefix(2))
            removeEnemyTiles(consumed)
            enemyOpenMelds.append(OpenMeld(kind: .pon, tiles: consumed + [discardedTile]))
            message = "\(opponent.name)「ポン！」"
            showBanner("ポン！", color: .red)
            finishEnemyCallTurn()
            return true
        }

        let chiOptions = MahjongRules.chiOptions(for: discardedTile, in: enemyHand)
        if let option = chiOptions.randomElement(), callRoll {
            cancelIppatsu()
            GameFeedback.shared.play(.call)
            consumePlayerDiscard()
            removeEnemyTiles(option)
            enemyOpenMelds.append(OpenMeld(kind: .chi, tiles: option + [discardedTile]))
            message = "\(opponent.name)「チー！」"
            showBanner("チー！", color: .green)
            finishEnemyCallTurn()
            return true
        }
        return false
    }

    private func finishEnemyCallTurn(shouldDrawPlayer: Bool = true) {
        guard !handEnded, !enemyHand.isEmpty else { return }
        let index = MahjongRules.bestDiscardIndex(
            in: enemyHand,
            wall: wall,
            openMeldCount: enemyOpenMelds.count
        )
        let discarded = enemyHand.remove(at: index)
        enemyDiscards.append(discarded)
        enemyDiscardHistory.append(discarded)
        enemyHand = MahjongRules.sort(enemyHand)
        offerPlayerCall(on: discarded)
        if shouldDrawPlayer, pendingCall == nil { drawForPlayer() }
    }

    private func consumePlayerDiscard() {
        _ = discards.popLast()
    }

    private func removeEnemyTiles(_ tiles: [MahjongTile]) {
        let ids = Set(tiles.map(\.id))
        enemyHand.removeAll { ids.contains($0.id) }
    }

    private func offerPlayerCall(on enemyDiscard: MahjongTile) {
        let matchingCount = hand.filter {
            MahjongRules.code($0) == MahjongRules.code(enemyDiscard)
        }.count
        let hasChi = !MahjongRules.chiOptions(for: enemyDiscard, in: hand).isEmpty
        let ron = MatchRules.canRon(
            isDiscardFuriten: MahjongRules.isFuriten(
                hand,
                discards: discardHistory,
                openMeldCount: openMelds.count
            ),
            isTemporaryFuriten: playerTemporaryFuriten,
            isRiichiPassFuriten: playerRiichiPassFuriten
        ) ? MahjongRules.result(
            for: hand + [enemyDiscard],
            riichi: isRiichi,
            turn: turn,
            selfDraw: false,
            lastDiscard: wall.isEmpty,
            ippatsu: playerIppatsu,
            doubleRiichi: playerDoubleRiichi,
            seatWind: playerIsDealer ? 1 : 2,
            roundWind: 1,
            winningTile: enemyDiscard,
            doraIndicators: doraIndicators,
            openMelds: openMelds
        ) : nil
        if ron != nil || (!isRiichi && (matchingCount >= 2 || hasChi)) {
            pendingCall = enemyDiscard
            pendingRon = ron
            message = "\(enemyDiscard.label)を鳴くか？"
            saveSnapshot()
        }
    }

    private func drawForPlayer() {
        guard let drawn = wall.popLast() else { finishExhaustiveDraw(); return }
        playerTemporaryFuriten = false
        hand.append(drawn)
        lastDrawnID = drawn.id
        lastDrawWasReplacement = false
        hand = MahjongRules.sort(hand)
        turn += 1
        if isRiichi {
            message = "\(drawn.label)をツモ。上がりでなければツモ切りだ"
            if playerRiichiPassFuriten {
                message += "（ロン不可）"
            }
        } else {
            message = "\(drawn.label)をツモ"
        }
        saveSnapshot()
    }

    private func chooseDiscard(_ tile: MahjongTile) {
        if confirmDiscard {
            pendingDiscard = tile
            showDiscardConfirmation = true
        } else {
            discard(tile)
        }
    }

    private func declareWin() {
        guard let score = currentPlayerResult else { return }
        finishHand(playerWon: true, score: score, text: "朱莉「ツモ！」")
    }

    @ViewBuilder
    private func callButtons(for calledTile: MahjongTile) -> some View {
        let target = MahjongRules.code(calledTile)
        let matching = hand.filter { MahjongRules.code($0) == target }
        VStack(spacing: 6) {
            HStack {
                if let pendingRon {
                    Button("ロン！") { callRon(pendingRon) }
                        .buttonStyle(PixelButtonStyle(color: .yellow))
                }
                if matching.count >= 2 {
                    Button("ポン") { callPon(calledTile) }
                        .buttonStyle(PixelButtonStyle(color: .red))
                }
                if matching.count >= 3 {
                    Button("カン") { callOpenKan(calledTile) }
                        .buttonStyle(PixelButtonStyle(color: .purple))
                }
                Button("見送る") { skipCall() }
                    .buttonStyle(PixelButtonStyle(color: .blue))
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(
                        Array(MahjongRules.chiOptions(for: calledTile, in: hand).enumerated()),
                        id: \.offset
                    ) { _, option in
                        Button("チー " + option.map(\.label).joined(separator: "・")) {
                            callChi(calledTile, using: option)
                        }
                        .buttonStyle(PixelButtonStyle(color: .green))
                    }
                }
            }
        }
    }

    private func callPon(_ calledTile: MahjongTile) {
        let target = MahjongRules.code(calledTile)
        let consumed = Array(hand.filter { MahjongRules.code($0) == target }.prefix(2))
        guard consumed.count == 2 else { skipCall(); return }
        finishOpenCall(kind: .pon, calledTile: calledTile, consumed: consumed)
        message = "ポン！ 手牌から一枚捨てろ"
        showBanner("ポン！", color: .red)
        saveSnapshot()
    }

    private func callChi(_ calledTile: MahjongTile, using consumed: [MahjongTile]) {
        guard consumed.count == 2 else { skipCall(); return }
        finishOpenCall(kind: .chi, calledTile: calledTile, consumed: consumed)
        message = "チー！ 手牌から一枚捨てろ"
        showBanner("チー！", color: .green)
        saveSnapshot()
    }

    private func callOpenKan(_ calledTile: MahjongTile) {
        let target = MahjongRules.code(calledTile)
        let consumed = Array(hand.filter { MahjongRules.code($0) == target }.prefix(3))
        guard consumed.count == 3 else { skipCall(); return }
        finishOpenCall(kind: .openKan, calledTile: calledTile, consumed: consumed)
        guard drawReplacementAfterKan() else { return }
        message = "カン！ 嶺上牌を引いた"
        showBanner("カン！", color: .purple)
        saveSnapshot()
    }

    private func finishOpenCall(
        kind: OpenMeldKind,
        calledTile: MahjongTile,
        consumed: [MahjongTile]
    ) {
        let ids = Set(consumed.map(\.id))
        hand.removeAll { ids.contains($0.id) }
        _ = enemyDiscards.popLast()
        openMelds.append(OpenMeld(kind: kind, tiles: consumed + [calledTile]))
        if pendingRon != nil {
            playerTemporaryFuriten = true
        }
        pendingCall = nil
        pendingRon = nil
        riichiMode = false
        cancelIppatsu()
        GameFeedback.shared.play(.call)
    }

    private func callClosedKan(_ code: Int) {
        let kanTiles = hand.filter { MahjongRules.code($0) == code }
        guard kanTiles.count == 4 else { return }
        let ids = Set(kanTiles.map(\.id))
        hand.removeAll { ids.contains($0.id) }
        openMelds.append(OpenMeld(kind: .closedKan, tiles: kanTiles))
        cancelIppatsu()
        GameFeedback.shared.play(.call)
        guard drawReplacementAfterKan() else { return }
        message = "暗カン！ 門前のまま嶺上牌を引いた"
        showBanner("暗カン！", color: .purple)
        saveSnapshot()
    }

    private func callAddedKan(_ option: AddedKanOption) {
        guard openMelds.indices.contains(option.meldIndex),
              hand.contains(option.tile) else { return }

        if !MahjongRules.isFuriten(
            enemyHand,
            discards: enemyDiscardHistory,
            openMeldCount: enemyOpenMelds.count
        ), let score = MahjongRules.result(
            for: enemyHand + [option.tile],
            riichi: enemyRiichi,
            turn: turn,
            selfDraw: false,
            robbingKan: true,
            ippatsu: enemyIppatsu,
            doubleRiichi: enemyDoubleRiichi,
            seatWind: playerIsDealer ? 2 : 1,
            roundWind: 1,
            winningTile: option.tile,
            doraIndicators: doraIndicators,
            openMelds: enemyOpenMelds
        ) {
            finishHand(playerWon: false, score: score, text: "\(opponent.name)「槍槓！」")
            return
        }

        guard let tileIndex = hand.firstIndex(of: option.tile) else { return }
        let added = hand.remove(at: tileIndex)
        let old = openMelds[option.meldIndex]
        openMelds[option.meldIndex] = OpenMeld(kind: .addedKan, tiles: old.tiles + [added])
        cancelIppatsu()
        GameFeedback.shared.play(.call)
        guard drawReplacementAfterKan() else { return }
        message = "加カン！ 嶺上牌を引いた"
        showBanner("加カン！", color: .purple)
        saveSnapshot()
    }

    @discardableResult
    private func drawReplacementAfterKan() -> Bool {
        if let indicator = wall.popLast() { doraIndicators.append(indicator) }
        guard let replacement = wall.popLast() else {
            finishExhaustiveDraw()
            return false
        }
        hand.append(replacement)
        playerTemporaryFuriten = false
        lastDrawnID = replacement.id
        lastDrawWasReplacement = true
        hand = MahjongRules.sort(hand)
        return true
    }

    private func skipCall() {
        if pendingRon != nil {
            playerTemporaryFuriten = true
            if isRiichi {
                playerRiichiPassFuriten = true
                showBanner("リーチ後フリテン", color: .orange)
            }
        }
        pendingCall = nil
        pendingRon = nil
        drawForPlayer()
    }

    private func callRon(_ score: HandResult) {
        if let winningTile = pendingCall {
            _ = enemyDiscards.popLast()
            hand.append(winningTile)
            hand = MahjongRules.sort(hand)
        }
        pendingCall = nil
        pendingRon = nil
        finishHand(playerWon: true, score: score, text: "朱莉「ロン！」")
    }

    private func cancelIppatsu() {
        playerIppatsu = false
        enemyIppatsu = false
    }

    private func finishHand(playerWon: Bool, score: HandResult, text: String) {
        handResult = score
        let winnerIsDealer = playerWon ? playerIsDealer : !playerIsDealer
        let payment = MatchRules.settledPoints(
            base: score.points,
            winnerIsDealer: winnerIsDealer,
            honba: honba
        )
        let winnerGain = MatchRules.winnerGain(
            base: score.points,
            winnerIsDealer: winnerIsDealer,
            honba: honba,
            riichiPot: riichiPot
        )
        settledPoints = payment
        if playerWon {
            playerPoints += winnerGain
            enemyPoints -= payment
        } else {
            enemyPoints += winnerGain
            playerPoints -= payment
        }
        let collectedRiichiPot = riichiPot
        riichiPot = 0
        dealerRepeats = MatchRules.dealerRepeats(
            winnerIsDealer: winnerIsDealer,
            dealerTenpaiOnDraw: false
        )
        handEnded = true
        message = "\(text) \(score.han)翻 \(payment)点"
        if collectedRiichiPot > 0 {
            message += "　供託\(collectedRiichiPot)点獲得！"
        }
        if dealerRepeats {
            message += "　親の連荘！"
        }
        GameFeedback.shared.play(playerWon ? .win : .lose)
        showBanner(playerWon ? "勝負あり！" : "直撃！", color: playerWon ? .yellow : .red)
        decideMatchIfNeeded()
        saveSnapshot()
    }

    private func finishExhaustiveDraw() {
        let playerTenpai = !MahjongRules.waitingCodes(
            hand,
            openMeldCount: openMelds.count
        ).isEmpty
        let enemyTenpai = !MahjongRules.waitingCodes(
            enemyHand,
            openMeldCount: enemyOpenMelds.count
        ).isEmpty
        if playerTenpai != enemyTenpai {
            let payment = 1500
            playerPoints += playerTenpai ? payment : -payment
            enemyPoints += enemyTenpai ? payment : -payment
        }
        let dealerTenpai = playerIsDealer ? playerTenpai : enemyTenpai
        dealerRepeats = MatchRules.dealerRepeats(
            winnerIsDealer: nil,
            dealerTenpaiOnDraw: dealerTenpai
        )
        handEnded = true
        message = playerTenpai ? "流局。朱莉はテンパイ" : "流局。朱莉はノーテン"
        if dealerRepeats { message += "　親テンパイで連荘！" }
        showBanner("流局", color: .blue)
        decideMatchIfNeeded()
        saveSnapshot()
    }

    private func decideMatchIfNeeded() {
        guard let conclusion = MatchRules.conclusionIfNeeded(
            playerPoints: playerPoints,
            enemyPoints: enemyPoints,
            round: round,
            dealerRepeats: dealerRepeats,
            riichiPot: riichiPot
        ) else { return }

        if conclusion.riichiPotWentToPlayer == true {
            message += "　最終供託\(riichiPot)点を獲得！"
        } else if conclusion.riichiPotWentToPlayer == false {
            message += "　最終供託は相手へ"
        }
        playerPoints = conclusion.playerPoints
        enemyPoints = conclusion.enemyPoints
        riichiPot = 0
        matchResult = conclusion.playerWon
        message += conclusion.playerWon ? "　全国制覇へ前進！" : "　点差で敗北……"
    }

    private func restoreOrStart() {
        guard let snapshot = MatchStore.load(),
              snapshot.opponentID == opponent.id else {
            resetMatch()
            return
        }
        hand = snapshot.hand
        enemyHand = snapshot.enemyHand
        wall = snapshot.wall
        doraIndicators = snapshot.doraIndicators
        discards = snapshot.discards
        enemyDiscards = snapshot.enemyDiscards
        discardHistory = snapshot.discardHistory
        enemyDiscardHistory = snapshot.enemyDiscardHistory
        openMelds = snapshot.openMelds
        enemyOpenMelds = snapshot.enemyOpenMelds
        pendingCall = snapshot.pendingCall
        pendingRon = snapshot.pendingRon
        playerPoints = snapshot.playerPoints
        enemyPoints = snapshot.enemyPoints
        riichiPot = snapshot.riichiPot
        round = snapshot.round
        honba = snapshot.honba
        turn = snapshot.turn
        message = snapshot.message
        matchResult = snapshot.matchResult
        handEnded = snapshot.handEnded
        handResult = snapshot.handResult
        settledPoints = snapshot.settledPoints
        dealerRepeats = snapshot.dealerRepeats
        isRiichi = snapshot.isRiichi
        enemyRiichi = snapshot.enemyRiichi
        playerIppatsu = snapshot.playerIppatsu
        enemyIppatsu = snapshot.enemyIppatsu
        playerDoubleRiichi = snapshot.playerDoubleRiichi
        enemyDoubleRiichi = snapshot.enemyDoubleRiichi
        playerTemporaryFuriten = snapshot.playerTemporaryFuriten
        playerRiichiPassFuriten = snapshot.playerRiichiPassFuriten
        riichiMode = snapshot.riichiMode
        lastDrawnID = snapshot.lastDrawnID
        lastDrawWasReplacement = snapshot.lastDrawWasReplacement
        pendingDiscard = nil
        showDiscardConfirmation = false
        bannerText = nil
        UIAccessibility.post(notification: .announcement, argument: "保存した対局を再開しました")
    }

    private func saveSnapshot() {
        MatchStore.save(MatchSnapshot(
            version: MatchSnapshot.currentVersion,
            opponentID: opponent.id,
            hand: hand,
            enemyHand: enemyHand,
            wall: wall,
            doraIndicators: doraIndicators,
            discards: discards,
            enemyDiscards: enemyDiscards,
            discardHistory: discardHistory,
            enemyDiscardHistory: enemyDiscardHistory,
            openMelds: openMelds,
            enemyOpenMelds: enemyOpenMelds,
            pendingCall: pendingCall,
            pendingRon: pendingRon,
            playerPoints: playerPoints,
            enemyPoints: enemyPoints,
            riichiPot: riichiPot,
            round: round,
            honba: honba,
            turn: turn,
            message: message,
            matchResult: matchResult,
            handEnded: handEnded,
            handResult: handResult,
            settledPoints: settledPoints,
            dealerRepeats: dealerRepeats,
            isRiichi: isRiichi,
            enemyRiichi: enemyRiichi,
            playerIppatsu: playerIppatsu,
            enemyIppatsu: enemyIppatsu,
            playerDoubleRiichi: playerDoubleRiichi,
            enemyDoubleRiichi: enemyDoubleRiichi,
            playerTemporaryFuriten: playerTemporaryFuriten,
            playerRiichiPassFuriten: playerRiichiPassFuriten,
            riichiMode: riichiMode,
            lastDrawnID: lastDrawnID,
            lastDrawWasReplacement: lastDrawWasReplacement
        ))
    }

    private func showBanner(_ text: String, color: Color) {
        let animation: Animation? = reduceMotion ? nil : .easeOut(duration: 0.12)
        withAnimation(animation) {
            bannerColor = color
            bannerText = text
        }
        UIAccessibility.post(notification: .announcement, argument: text)
        Task { @MainActor in
            try? await Task<Never, Never>.sleep(nanoseconds: 700_000_000)
            guard bannerText == text else { return }
            withAnimation(animation) { bannerText = nil }
        }
    }
}

private struct BattleBanner: View {
    let text: String
    let color: Color

    var body: some View {
        VStack(spacing: 0) {
            Color.black.frame(height: 5)
            Text(text)
                .font(.system(size: 38, weight: .black, design: .monospaced))
                .minimumScaleFactor(0.6)
                .foregroundStyle(.white)
                .shadow(color: color, radius: 0, x: 4, y: 4)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 22)
                .background(Color.black.opacity(0.94))
            color.frame(height: 5)
        }
        .overlay(Rectangle().stroke(.white, lineWidth: 3))
        .padding(.horizontal, 12)
    }
}

private struct TileFace: View {
    let tile: MahjongTile
    var compact = false

    var body: some View {
        Text(tile.label)
            .font(.system(size: compact ? 9 : 13, weight: .black, design: .monospaced))
            .frame(width: compact ? 24 : nil, height: compact ? 28 : 45)
            .frame(maxWidth: compact ? nil : .infinity)
            .background(Color(red: 0.94, green: 0.91, blue: 0.76))
            .foregroundStyle(tile.suit == .man ? .red : tile.suit == .sou ? .green : tile.suit == .honor ? .black : .blue)
            .overlay(Rectangle().stroke(.black, lineWidth: 2))
            .accessibilityLabel(tile.spokenLabel)
    }
}
