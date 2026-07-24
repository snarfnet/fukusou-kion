import SwiftUI

struct GameView: View {
    @StateObject private var game = GameModel()
    @State private var alienPulse = false
    @State private var defeatRevealed = false
    @State private var blastExpanded = false

    private let ink = Color(red: 0.95, green: 0.94, blue: 0.85)
    private let signal = Color(red: 1.0, green: 0.36, blue: 0.18)
    private let cyan = Color(red: 0.35, green: 0.93, blue: 0.89)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.025, green: 0.04, blue: 0.11),
                         Color(red: 0.07, green: 0.05, blue: 0.17)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            starField

            if game.phase == .briefing {
                briefing
            } else {
                battle
            }

            if game.phase == .lost {
                defeatCinematic
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .foregroundStyle(ink)
        .animation(.snappy, value: game.phase)
        .animation(.snappy, value: game.hand)
    }

    private var starField: some View {
        Canvas { context, size in
            for index in 0..<44 {
                let x = CGFloat((index * 83) % 101) / 101 * size.width
                let y = CGFloat((index * 47) % 97) / 97 * size.height
                let radius = index.isMultiple(of: 7) ? 1.8 : 0.7
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: radius, height: radius)), with: .color(.white.opacity(0.45)))
            }
        }
        .allowsHitTesting(false)
    }

    private var briefing: some View {
        VStack(spacing: 0) {
            Spacer()
            Text("GALACTIC VERDICT // EARTH")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundStyle(cyan)

            alienPortrait(height: 230)
                .padding(.vertical, 28)

            Text("MOONSHOT\nMAHJONG")
                .font(.system(size: 49, weight: .black, design: .rounded))
                .tracking(-2)
                .multilineTextAlignment(.center)
                .lineSpacing(-8)

            Text("Four alien champions. One table.\nWin them all or lose Earth.")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(ink.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.top, 18)

            Button("PLAY FOR HUMANITY") { game.start() }
                .buttonStyle(SignalButtonStyle(color: signal))
                .padding(.top, 34)
            Spacer()
            Text("SOLO • OFFLINE • NO ADS")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1.5)
                .foregroundStyle(ink.opacity(0.42))
                .padding(.bottom, 18)
        }
        .padding(.horizontal, 28)
    }

    private var battle: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("FINAL TABLE // \(game.campaignProgress)")
                    Text("\(game.currentOpponent.species) • TURN \(game.turns + 1, format: .number)")
                        .foregroundStyle(ink.opacity(0.45))
                }
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .tracking(1)
                Spacer()
                Text(game.statusLabel)
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(game.phase == .alienTurn ? signal : cyan)
            }

            campaignMarkers
            tableInfoRow(left: game.currentOpponent.name, right: "DORA \(game.currentDora)")
            alienPortrait(height: 108)
                .opacity(game.phase == .alienTurn ? (alienPulse ? 0.58 : 1) : 1)
                .onChange(of: game.phase) { _, phase in
                    alienPulse = phase == .alienTurn
                }

            Text(game.message)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 42)
                .padding(.horizontal)

            discardStrip(game.alienDiscards, label: "ALIEN DISCARDS")
            meldStrip(game.alienMelds, label: "ALIEN CALLS")
            Spacer(minLength: 0)

            if game.phase == .won || game.phase == .lost || game.phase == .exhaustiveDraw {
                resultCard
            } else if game.phase == .callDecision {
                handGrid
                callButtons
            } else {
                handGrid
                HStack(spacing: 8) {
                    Button(game.riichiPending ? "CANCEL RIICHI" : "RIICHI") {
                        game.toggleRiichi()
                    }
                    .buttonStyle(SignalButtonStyle(color: game.canDeclareRiichi || game.riichiPending ? signal : ink.opacity(0.16)))
                    .disabled(!game.canDeclareRiichi && !game.riichiPending)

                    Button("TSUMO") {
                        game.declareTsumo()
                    }
                    .buttonStyle(SignalButtonStyle(color: game.canTsumo ? cyan : ink.opacity(0.16)))
                    .disabled(!game.canTsumo)

                    Button("KAN") {
                        game.declareKan()
                    }
                    .buttonStyle(SignalButtonStyle(color: game.canDeclareKan ? signal : ink.opacity(0.16)))
                    .disabled(!game.canDeclareKan)
                }
            }

            meldStrip(game.playerMelds, label: "YOUR CALLS")
            discardStrip(game.playerDiscards, label: "YOUR DISCARDS")
            tableInfoRow(left: game.isFuriten ? "EARTH // FURITEN" : game.playerRiichi ? "EARTH // RIICHI" : "EARTH // READY", right: "WALL \(game.wallCount)")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    private func alienPortrait(height: CGFloat) -> some View {
        ZStack {
            Image(game.currentOpponent.assetName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .clipped()
            LinearGradient(
                colors: [.clear, Color(red: 0.025, green: 0.04, blue: 0.11).opacity(0.72)],
                startPoint: .center,
                endPoint: .bottom
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(cyan.opacity(0.25), lineWidth: 1)
        }
        .shadow(color: cyan.opacity(0.16), radius: 18)
        .accessibilityLabel("\(game.currentOpponent.species), \(game.currentOpponent.name)")
    }

    private var defeatCinematic: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image("EarthExplosion")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .scaleEffect(blastExpanded ? 1.08 : 0.72)
                .opacity(defeatRevealed ? 1 : 0)
                .animation(.easeOut(duration: 1.35), value: blastExpanded)

            Color.white
                .ignoresSafeArea()
                .opacity(defeatRevealed ? 0 : 1)
                .animation(.easeOut(duration: 0.55), value: defeatRevealed)

            VStack {
                Spacer()
                Text("EARTH // TERMINATED")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .tracking(3)
                    .foregroundStyle(signal)
                Text("THE LAST\nDISCARD")
                    .font(.system(size: 43, weight: .black, design: .rounded))
                    .tracking(-1.5)
                    .multilineTextAlignment(.center)
                    .lineSpacing(-7)
                    .padding(.top, 8)
                Text("Xen-7 takes the moon. Earth is gone.")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
                    .padding(.top, 12)
                Button("REWIND THE SIGNAL") {
                    defeatRevealed = false
                    blastExpanded = false
                    game.playAgain()
                }
                .buttonStyle(SignalButtonStyle(color: signal))
                .padding(.top, 24)
                .padding(.bottom, 34)
            }
            .padding(.horizontal, 28)
            .opacity(defeatRevealed ? 1 : 0)
            .animation(.easeIn(duration: 0.7).delay(0.65), value: defeatRevealed)
        }
        .onAppear {
            defeatRevealed = false
            blastExpanded = false
            withAnimation { defeatRevealed = true }
            blastExpanded = true
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Earth explodes. Game over.")
    }

    private var handGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 7), spacing: 7) {
            ForEach(game.hand) { tile in
                Button {
                    game.discard(tile)
                } label: {
                    VStack(spacing: 2) {
                        Text(tile.glyph)
                            .font(.system(size: 27, weight: .regular))
                        Text(tile.suit == .honors ? "HONOR" : "\(tile.rank)")
                            .font(.system(size: 8, weight: .black, design: .monospaced))
                    }
                    .foregroundStyle(tile.suit == .characters || tile.suit == .honors ? signal : Color(red: 0.05, green: 0.08, blue: 0.13))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(ink, in: RoundedRectangle(cornerRadius: 7))
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(tile.suit == .bamboo ? Color.green : tile.suit == .circles ? Color.indigo : signal)
                            .frame(height: 4)
                    }
                }
                .buttonStyle(.plain)
                .disabled(!game.canDiscard(tile))
                .accessibilityLabel(tile.spokenName)
                .accessibilityHint(game.canDiscard(tile) ? "Discard tile" : "This tile cannot be discarded now")
            }
        }
    }

    private var resultCard: some View {
        VStack(spacing: 15) {
            Text(resultTitle)
                .font(.system(size: 34, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)
            Text(game.message)
                .foregroundStyle(ink.opacity(0.65))
                .multilineTextAlignment(.center)
            Button(resultButtonTitle) {
                if game.phase == .exhaustiveDraw {
                    game.retryRound()
                } else if game.isFinalOpponent {
                    game.playAgain()
                } else {
                    game.advanceOpponent()
                }
            }
                .buttonStyle(SignalButtonStyle(color: signal))
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(ink.opacity(0.07), in: RoundedRectangle(cornerRadius: 22))
    }

    private var callButtons: some View {
        HStack(spacing: 6) {
            callButton("RON", enabled: game.canRon, color: signal) { game.callRon() }
            callButton("PON", enabled: game.canPon, color: cyan) { game.callPon() }
            callButton("CHI", enabled: game.canChi, color: cyan) { game.callChi() }
            callButton("KAN", enabled: game.canOpenKan, color: signal) { game.callOpenKan() }
            callButton("PASS", enabled: true, color: ink.opacity(0.28)) { game.passCall() }
        }
    }

    private func callButton(_ title: String, enabled: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.system(size: 9, weight: .black, design: .monospaced))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(enabled ? color : ink.opacity(0.1), in: Capsule())
            .disabled(!enabled)
    }

    private var resultTitle: String {
        if game.phase == .exhaustiveDraw { return "DRAWN HAND" }
        return game.isFinalOpponent ? "HUMANITY LIVES" : "\(game.currentOpponent.name) DEFEATED"
    }

    private var resultButtonTitle: String {
        if game.phase == .exhaustiveDraw { return "REPLAY THIS HAND" }
        return game.isFinalOpponent ? "PLAY THE VERDICT AGAIN" : "FACE THE NEXT CHAMPION"
    }

    private var campaignMarkers: some View {
        HStack(spacing: 7) {
            ForEach(game.opponents.indices, id: \.self) { index in
                Capsule()
                    .fill(index < game.opponentIndex ? cyan : index == game.opponentIndex ? signal : ink.opacity(0.12))
                    .frame(maxWidth: .infinity)
                    .frame(height: 4)
            }
        }
        .accessibilityLabel("Opponent \(game.opponentIndex + 1) of \(game.opponents.count)")
    }

    private func tableInfoRow(left: String, right: String) -> some View {
        HStack {
            Text(left)
            Spacer()
            Text(right)
        }
        .font(.system(size: 9, weight: .bold, design: .monospaced))
        .tracking(1)
        .foregroundStyle(ink.opacity(0.7))
    }

    private func discardStrip(_ tiles: [SpaceTile], label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .tracking(1)
                .foregroundStyle(ink.opacity(0.38))
            HStack(spacing: 3) {
                ForEach(Array(tiles.suffix(10))) { tile in
                    Text(tile.glyph)
                        .font(.system(size: 16))
                        .frame(width: 24, height: 28)
                        .background(ink.opacity(0.9), in: RoundedRectangle(cornerRadius: 3))
                }
                Spacer(minLength: 0)
            }
            .frame(height: 28)
        }
    }

    private func meldStrip(_ melds: [CalledMeld], label: String) -> some View {
        Group {
            if !melds.isEmpty {
                HStack(spacing: 5) {
                    Text(label)
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundStyle(ink.opacity(0.38))
                    ForEach(melds) { meld in
                        HStack(spacing: 0) {
                            ForEach(meld.tiles) { tile in
                                Text(tile.glyph)
                                    .font(.system(size: 13))
                            }
                        }
                        .padding(3)
                        .background(ink.opacity(0.9), in: RoundedRectangle(cornerRadius: 4))
                    }
                    Spacer()
                }
            }
        }
    }
}

private struct SignalButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .black, design: .monospaced))
            .tracking(1)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(color.opacity(configuration.isPressed ? 0.7 : 1), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

#Preview {
    GameView()
}
