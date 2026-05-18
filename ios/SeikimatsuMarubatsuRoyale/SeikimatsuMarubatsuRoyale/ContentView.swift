import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var game: GameStore

    var body: some View {
        ZStack {
            WastelandBackground()

            Group {
                switch game.phase {
                case .title:
                    TitleView()
                case .story:
                    StoryView()
                case .menu:
                    MainMenuView()
                case .battle:
                    BattleView()
                case .result:
                    ResultView()
                case .gacha:
                    GachaView()
                }
            }
            .frame(maxWidth: 760)
            .padding(.horizontal, 16)
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: game.phase)
    }
}

private struct WastelandBackground: View {
    var body: some View {
        LinearGradient(
            colors: [GameTheme.bg, Color(red: 0.18, green: 0.06, blue: 0.035), .black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay {
            RadialGradient(colors: [GameTheme.rust.opacity(0.45), .clear], center: .topTrailing, startRadius: 20, endRadius: 280)
                .ignoresSafeArea()
        }
        .overlay {
            RadialGradient(colors: [GameTheme.poison.opacity(0.24), .clear], center: .bottomLeading, startRadius: 30, endRadius: 320)
                .ignoresSafeArea()
        }
    }
}

private struct TitleView: View {
    @EnvironmentObject private var game: GameStore

    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 14)

            ZStack(alignment: .bottom) {
                Image("TitleVisual")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 440)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        LinearGradient(colors: [.clear, .black.opacity(0.88)], startPoint: .center, endPoint: .bottom)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                VStack(spacing: 8) {
                    Text("世紀末")
                        .font(.system(size: 54, weight: .black, design: .rounded))
                    Text("マルバツロワイヤル")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                }
                .minimumScaleFactor(0.65)
                .foregroundStyle(GameTheme.bone)
                .shadow(color: .black, radius: 6, y: 3)
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }

            VStack(spacing: 12) {
                Text("5つ並べろ。邪魔される前に。")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(GameTheme.bone)

                Button {
                    game.startTapped()
                } label: {
                    Text("START")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(GameTheme.amber, in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)

                Button("ストーリーを見る") {
                    game.replayStory()
                }
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(GameTheme.smoke)
            }
            .wastelandPanel()

            Spacer(minLength: 10)
        }
    }
}

private struct StoryView: View {
    @EnvironmentObject private var game: GameStore

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            VStack(alignment: .leading, spacing: 18) {
                Text("WASTELAND STORY")
                    .font(.caption.weight(.black))
                    .foregroundStyle(GameTheme.amber)

                ProgressView(value: Double(game.storyIndex + 1), total: Double(game.story.count))
                    .tint(GameTheme.amber)

                Text(game.story[game.storyIndex])
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(GameTheme.bone)
                    .lineSpacing(8)
                    .frame(maxWidth: .infinity, minHeight: 180, alignment: .leading)

                HStack(spacing: 10) {
                    Button("スキップ") {
                        game.finishStory()
                    }
                    .secondaryButton()

                    Button(game.storyIndex == game.story.count - 1 ? "荒野へ" : "次へ") {
                        game.nextStory()
                    }
                    .primaryButton()
                }
            }
            .wastelandPanel()
        }
        .padding(.vertical, 28)
    }
}

private struct MainMenuView: View {
    @EnvironmentObject private var game: GameStore

    var body: some View {
        VStack(spacing: 14) {
            Image("ModeSelectVisual")
                .resizable()
                .scaledToFill()
                .frame(height: 230)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    LinearGradient(colors: [.clear, .black.opacity(0.72)], startPoint: .center, endPoint: .bottom)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

            Text("荒野へ出る")
                .font(.system(size: 42, weight: .black, design: .rounded))
                .foregroundStyle(GameTheme.bone)

            VStack(spacing: 10) {
                Button("CPU対戦を始める") {
                    game.startBattle()
                }
                .primaryButton()

                Button("世紀末補給箱") {
                    game.openGacha()
                }
                .secondaryButton()

                Button("タイトルへ戻る") {
                    game.backToTitle()
                }
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(GameTheme.smoke)
            }
            .wastelandPanel()

            EconomyBar()
        }
    }
}

private struct BattleView: View {
    @EnvironmentObject private var game: GameStore

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 10)

    var body: some View {
        VStack(spacing: 10) {
            Image("BattleIntroVisual")
                .resizable()
                .scaledToFill()
                .frame(height: 118)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(alignment: .bottomLeading) {
                    Text("4 WAY ROYALE")
                        .font(.caption.weight(.black))
                        .foregroundStyle(GameTheme.amber)
                        .padding(10)
                }

            HStack {
                ForEach(game.players) { player in
                    PlayerChip(player: player, active: player.id == game.currentPlayer)
                }
            }

            Text(game.message)
                .font(.headline.weight(.heavy))
                .foregroundStyle(GameTheme.bone)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 54)
                .wastelandPanel(padding: 10)

            LazyVGrid(columns: columns, spacing: 3) {
                ForEach(game.board) { cell in
                    Button {
                        game.tapCell(cell.id)
                    } label: {
                        CellView(cell: cell)
                    }
                    .buttonStyle(.plain)
                    .disabled(!game.isHumanTurn || cell.owner != nil)
                }
            }
            .padding(8)
            .background(.black.opacity(0.42), in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(GameTheme.amber.opacity(0.25), lineWidth: 1)
            }

            HStack(spacing: 10) {
                Button("バイク突撃 \(game.gasGauge)/3") {
                    game.bikeCharge()
                }
                .secondaryButton()
                .disabled(!game.isHumanTurn || game.gasGauge < 3)
                .opacity(game.gasGauge >= 3 ? 1 : 0.55)

                Button("メニュー") {
                    game.backToMenu()
                }
                .secondaryButton()
            }

            EconomyBar()
        }
        .padding(.vertical, 10)
    }
}

private struct PlayerChip: View {
    let player: Player
    let active: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(characterImage)
                .resizable()
                .scaledToFill()
                .frame(width: 38, height: 38)
                .clipShape(Circle())
                .overlay(Circle().stroke(active ? .black.opacity(0.45) : GameTheme.amber.opacity(0.35), lineWidth: 1))
            Text(player.name)
                .font(.caption2.weight(.black))
                .lineLimit(1)
                .minimumScaleFactor(0.55)
        }
        .frame(maxWidth: .infinity, minHeight: 52)
        .padding(.horizontal, 4)
        .background(active ? player.color.opacity(0.75) : GameTheme.panel.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
        .foregroundStyle(active ? .black : GameTheme.bone)
    }

    private var characterImage: String {
        switch player.id {
        case 0: "CharacterGasmask"
        case 1: "CharacterMech"
        case 2: "CharacterMohawk"
        default: "CharacterFlame"
        }
    }
}

private struct CellView: View {
    let cell: BoardCell

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(background)
                .overlay {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                }

            if let owner = cell.owner {
                Text(owner.isMultiple(of: 2) ? "○" : "×")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(color(for: owner))
                    .shadow(color: color(for: owner).opacity(0.7), radius: 8)
            } else if cell.hasGas {
                Image(systemName: "fuelpump.fill")
                    .font(.caption.weight(.black))
                    .foregroundStyle(GameTheme.amber)
            } else if cell.hasMine {
                Circle()
                    .fill(Color.black.opacity(0.7))
                    .frame(width: 9, height: 9)
                    .overlay(Circle().stroke(GameTheme.rust, lineWidth: 1))
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private var background: Color {
        if cell.contaminatedTurns > 0 { return GameTheme.poison.opacity(0.45) }
        return Color(red: 0.20, green: 0.17, blue: 0.13).opacity(0.95)
    }

    private func color(for owner: Int) -> Color {
        switch owner {
        case 0: .red
        case 1: .cyan
        case 2: .yellow
        default: .green
        }
    }
}

private struct ResultView: View {
    @EnvironmentObject private var game: GameStore

    var body: some View {
        VStack(spacing: 14) {
            Image(game.winner?.id == 0 ? "ResultWinVisual" : "ExplosionVisual")
                .resizable()
                .scaledToFill()
                .frame(height: 260)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(game.winner?.id == 0 ? "勝利" : "決着")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .foregroundStyle(game.winner?.id == 0 ? GameTheme.amber : GameTheme.rust)

            Text(game.message)
                .font(.title3.weight(.heavy))
                .foregroundStyle(GameTheme.bone)
                .multilineTextAlignment(.center)

            EconomyBar()

            VStack(spacing: 10) {
                Button("もう一戦") {
                    game.startBattle()
                }
                .primaryButton()

                Button("補給箱を開ける") {
                    game.openGacha()
                }
                .secondaryButton()

                Button("メニューへ") {
                    game.backToMenu()
                }
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(GameTheme.smoke)
            }
            .wastelandPanel()
        }
    }
}

private struct GachaView: View {
    @EnvironmentObject private var game: GameStore
    @EnvironmentObject private var rewardedAd: RewardedAdService

    var body: some View {
        VStack(spacing: 14) {
            Text("世紀末補給箱")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundStyle(GameTheme.amber)

            VStack(spacing: 12) {
                Image("GachaCrateVisual")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: GameTheme.poison.opacity(0.8), radius: 18)

                EconomyBar()

                Button("300スクラップで開ける") {
                    game.pullGacha()
                }
                .primaryButton()

                Button {
                    rewardedAd.showRewardedAd {
                        game.pullRewardedGacha()
                    } onUnavailable: {
                        game.message = "広告を読み込み中。少し待ってもう一度。"
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: rewardedAd.isLoaded ? "play.rectangle.fill" : "hourglass")
                        Text(rewardedAd.isLoaded ? "広告を見て1回" : "広告を読み込み中")
                        Spacer()
                        Image(systemName: "shippingbox.fill")
                    }
                }
                .secondaryButton()
                .disabled(!rewardedAd.isLoaded)
                .opacity(rewardedAd.isLoaded ? 1 : 0.58)

                Text(game.message)
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(GameTheme.bone)
                    .multilineTextAlignment(.center)
            }
            .wastelandPanel()

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(game.rewards) { reward in
                        HStack {
                            Image(reward.rarity == "SSR" ? "GachaSSRVisual" : "GachaCrateVisual")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 46, height: 46)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            Text(reward.rarity)
                                .font(.caption.weight(.black))
                                .foregroundStyle(GameTheme.amber)
                                .frame(width: 44)
                            Text(reward.name)
                                .font(.headline.weight(.heavy))
                                .foregroundStyle(GameTheme.bone)
                            Spacer()
                        }
                        .padding(10)
                        .background(GameTheme.panel.opacity(0.76), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            Button("メニューへ") {
                game.backToMenu()
            }
            .secondaryButton()
        }
        .padding(.vertical, 12)
    }
}
private struct EconomyBar: View {
    @EnvironmentObject private var game: GameStore

    var body: some View {
        HStack {
            Label("\(game.scraps)", systemImage: "bolt.circle.fill")
            Spacer()
            Label("\(game.gasGauge)/3", systemImage: "fuelpump.fill")
        }
        .font(.headline.weight(.black))
        .foregroundStyle(GameTheme.amber)
        .wastelandPanel(padding: 12)
    }
}

private extension View {
    func wastelandPanel(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(GameTheme.panel.opacity(0.88), in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(GameTheme.amber.opacity(0.22), lineWidth: 1)
            }
    }

    func primaryButton() -> some View {
        self
            .font(.headline.weight(.black))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(GameTheme.amber, in: RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(.black)
            .buttonStyle(.plain)
    }

    func secondaryButton() -> some View {
        self
            .font(.headline.weight(.black))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(GameTheme.panel, in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(GameTheme.amber.opacity(0.35), lineWidth: 1)
            }
            .foregroundStyle(GameTheme.bone)
            .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
        .environmentObject(GameStore())
}

