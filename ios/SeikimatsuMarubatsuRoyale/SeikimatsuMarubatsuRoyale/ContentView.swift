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
        .overlay {
            if let cutIn = game.abilityCutIn {
                AbilityCutInView(cutIn: cutIn)
                    .transition(.asymmetric(insertion: .scale(scale: 1.08).combined(with: .opacity), removal: .opacity))
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: game.abilityCutIn)
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

private struct AbilityCutInView: View {
    let cutIn: AbilityCutIn
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.82)
                .ignoresSafeArea()

            Image(cutIn.character.imageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .scaleEffect(appeared ? 1.02 : 1.18)
                .offset(x: appeared ? 0 : -90)
                .opacity(appeared ? 1 : 0.45)
                .overlay {
                    LinearGradient(
                        colors: [.black.opacity(0.15), .black.opacity(0.88)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                }

            VStack(spacing: 10) {
                Spacer()

                Text(cutIn.character.rarity.rawValue)
                    .font(.caption.weight(.black))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(cutIn.character.rarity.color, in: RoundedRectangle(cornerRadius: 6))
                    .foregroundStyle(.black)

                Text(cutIn.title)
                    .font(.system(size: 58, weight: .black, design: .rounded))
                    .minimumScaleFactor(0.52)
                    .lineLimit(1)
                    .foregroundStyle(GameTheme.amber)
                    .shadow(color: .red.opacity(0.9), radius: 12)

                Text(cutIn.character.name)
                    .font(.title2.weight(.black))
                    .foregroundStyle(GameTheme.bone)

                Text("「\(cutIn.subtitle)」")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(GameTheme.smoke)
                    .padding(.bottom, 54)
            }
            .padding(.horizontal, 18)

            HStack {
                Rectangle()
                    .fill(GameTheme.amber)
                    .frame(width: appeared ? 260 : 0, height: 8)
                Spacer()
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 74)
        }
        .onAppear {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.76)) {
                appeared = true
            }
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
                Text("4つ並べろ。邪魔される前に。")
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

            CharacterSelectView()

            EconomyBar()
        }
    }
}

private struct BattleView: View {
    @EnvironmentObject private var game: GameStore

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: GameStore.boardSize)

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                Text("4 WAY ROYALE")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(GameTheme.amber)
                    .frame(maxWidth: .infinity)
                    .wastelandPanel(padding: 10)

                HStack {
                    ForEach(game.players) { player in
                        PlayerChip(player: player, active: player.id == game.currentPlayer)
                    }
                }

                Text(game.message)
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(GameTheme.bone)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .wastelandPanel(padding: 10)

                if game.hasHumanReach {
                    Image("WarningReachVisual")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay {
                            Text("WARNING")
                                .font(.title.weight(.black))
                                .foregroundStyle(.red)
                                .shadow(color: .black, radius: 5)
                        }
                }

                BoardGrid(columns: columns)
                    .frame(maxWidth: 430)

                ItemVisualStrip()

                HStack(spacing: 10) {
                    Button("\(game.selectedCharacter.abilityName) \(game.abilityUsesLeft)") {
                        game.useCharacterAbility()
                    }
                    .secondaryButton()
                    .disabled(!game.canUseAbility)
                    .opacity(game.canUseAbility ? 1 : 0.55)

                    Button("鉄板防御 \(game.shieldPlates)") {
                        game.useShieldPlate()
                    }
                    .secondaryButton()
                    .disabled(!game.isHumanTurn || game.shieldPlates <= 0)
                    .opacity(game.isHumanTurn && game.shieldPlates > 0 ? 1 : 0.55)
                }

                HStack(spacing: 10) {
                    Button {
                        game.bikeCharge()
                    } label: {
                        HStack(spacing: 8) {
                            Image("BikeIcon")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 24, height: 24)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            Text("バイク突撃 \(game.gasGauge)/3")
                        }
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
}

private struct PlayerChip: View {
    let player: Player
    let active: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(player.symbol)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundStyle(active ? .black : player.color)
                .frame(width: 38, height: 38)
                .background(active ? player.color.opacity(0.95) : player.color.opacity(0.18), in: Circle())
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
}

private struct CharacterSelectView: View {
    @EnvironmentObject private var game: GameStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image("CharacterSelectVisual")
                .resizable()
                .scaledToFill()
                .frame(height: 86)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(alignment: .bottomLeading) {
                    Text("CHARACTER SELECT")
                        .font(.caption.weight(.black))
                        .foregroundStyle(GameTheme.amber)
                        .padding(8)
                        .shadow(color: .black, radius: 4)
                }

            HStack {
                Text("主人公")
                    .font(.headline.weight(.black))
                    .foregroundStyle(GameTheme.bone)
                Spacer()
                Text(game.selectedCharacter.rarity.rawValue)
                    .font(.caption.weight(.black))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(game.selectedCharacter.rarity.color.opacity(0.95), in: RoundedRectangle(cornerRadius: 6))
                    .foregroundStyle(.black)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(game.sortedCharacters) { character in
                        CharacterCard(
                            character: character,
                            unlocked: game.unlockedCharacterIDs.contains(character.id),
                            selected: character.id == game.selectedCharacterID
                        )
                        .onTapGesture {
                            game.selectCharacter(character)
                        }
                    }
                }
            }
        }
        .wastelandPanel(padding: 12)
    }
}

private struct ItemVisualStrip: View {
    var body: some View {
        HStack(spacing: 8) {
            ItemLegend(image: "MineIcon", text: "爆弾")
            ItemLegend(image: "GasIcon", text: "ガソリン")
            ItemLegend(image: "EMPIcon", text: "EMP")
            ItemLegend(image: "ShieldIcon", text: "鉄板")
        }
        .font(.caption.weight(.black))
        .foregroundStyle(GameTheme.bone)
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct ItemLegend: View {
    let image: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(image)
                .resizable()
                .scaledToFill()
                .frame(width: 22, height: 22)
                .clipShape(RoundedRectangle(cornerRadius: 4))
            Text(text)
        }
    }
}

private struct CharacterCard: View {
    let character: BattleCharacter
    let unlocked: Bool
    let selected: Bool

    var body: some View {
        VStack(spacing: 6) {
            Image(character.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    if !unlocked {
                        Color.black.opacity(0.72)
                        Image(systemName: "lock.fill")
                            .foregroundStyle(GameTheme.amber)
                    }
                }

            Text(unlocked ? character.name : "未解放")
                .font(.caption.weight(.black))
                .lineLimit(1)
                .minimumScaleFactor(0.65)

            Text(character.abilityName)
                .font(.caption2.weight(.heavy))
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .foregroundStyle(GameTheme.smoke)

            Text(character.rarity.rawValue)
                .font(.caption2.weight(.black))
                .foregroundStyle(.black)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(character.rarity.color, in: RoundedRectangle(cornerRadius: 5))
        }
        .frame(width: 96, height: 132)
        .padding(8)
        .background(selected ? GameTheme.amber.opacity(0.28) : Color.black.opacity(0.25), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(selected ? GameTheme.amber : GameTheme.amber.opacity(0.18), lineWidth: selected ? 2 : 1)
        }
        .foregroundStyle(GameTheme.bone)
    }
}

private struct BoardGrid: View {
    @EnvironmentObject private var game: GameStore
    let columns: [GridItem]

    var body: some View {
        ZStack {
            LazyVGrid(columns: columns, spacing: 3) {
                ForEach(game.board) { cell in
                    Button {
                        game.tapCell(cell.id)
                    } label: {
                        CellView(cell: cell)
                    }
                    .buttonStyle(.plain)
                    .disabled(!game.isHumanTurn || game.aiHandMove != nil || cell.owner != nil)
                }
            }

            if let move = game.aiHandMove {
                AIHandOverlay(move: move)
                    .transition(.opacity)
            }
        }
        .padding(8)
        .background(.black.opacity(0.42), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(GameTheme.amber.opacity(0.25), lineWidth: 1)
        }
        .aspectRatio(1, contentMode: .fit)
        .animation(.easeInOut(duration: 0.22), value: game.aiHandMove)
    }
}

private struct AIHandOverlay: View {
    let move: AIHandMove
    @State private var landed = false

    var body: some View {
        GeometryReader { proxy in
            let cell = max(16, min(proxy.size.width, proxy.size.height) / CGFloat(GameStore.boardSize))
            let row = move.targetCell / GameStore.boardSize
            let col = move.targetCell % GameStore.boardSize
            let target = CGPoint(x: CGFloat(col) * cell + cell / 2, y: CGFloat(row) * cell + cell / 2)
            let start = startPoint(in: proxy.size)

            FictionalHandView(playerID: move.playerID, size: cell * 1.55)
                .position(landed ? target : start)
                .rotationEffect(.degrees(landed ? -10 : entryAngle))
                .scaleEffect(landed ? 1.0 : 0.78)
                .shadow(color: handColor.opacity(0.75), radius: landed ? 18 : 8)
                .animation(.spring(response: 0.46, dampingFraction: 0.72), value: landed)
                .onAppear {
                    landed = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        landed = true
                    }
                }
        }
        .allowsHitTesting(false)
    }

    private var handColor: Color {
        switch move.playerID {
        case 1: .cyan
        case 2: .yellow
        default: .green
        }
    }

    private var entryAngle: Double {
        switch move.playerID {
        case 1: -34
        case 2: 22
        default: -16
        }
    }

    private func startPoint(in size: CGSize) -> CGPoint {
        switch move.playerID {
        case 1:
            CGPoint(x: size.width + 56, y: -38)
        case 2:
            CGPoint(x: -56, y: size.height * 0.48)
        default:
            CGPoint(x: size.width + 54, y: size.height + 42)
        }
    }
}

private struct FictionalHandView: View {
    let playerID: Int
    let size: CGFloat

    var body: some View {
        ZStack {
            ForEach(0..<4) { index in
                Capsule()
                    .fill(color.opacity(0.92))
                    .frame(width: size * 0.18, height: size * 0.58)
                    .offset(x: CGFloat(index - 2) * size * 0.13, y: -size * 0.12)
                    .rotationEffect(.degrees(Double(index - 1) * 4))
            }

            RoundedRectangle(cornerRadius: size * 0.18)
                .fill(color)
                .frame(width: size * 0.72, height: size * 0.56)
                .offset(y: size * 0.18)

            Text(playerID.isMultiple(of: 2) ? "○" : "×")
                .font(.system(size: size * 0.42, weight: .black, design: .rounded))
                .foregroundStyle(.black.opacity(0.75))
                .offset(y: size * 0.13)
        }
        .frame(width: size, height: size)
        .overlay {
            Circle()
                .stroke(.white.opacity(0.25), lineWidth: 2)
                .frame(width: size * 0.94, height: size * 0.94)
        }
    }

    private var color: Color {
        switch playerID {
        case 1: .cyan
        case 2: .yellow
        default: .green
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

            if cell.contaminatedTurns > 0 {
                Image("ContaminationIcon")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.78)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            if let owner = cell.owner {
                Text(owner.isMultiple(of: 2) ? "○" : "×")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(color(for: owner))
                    .shadow(color: color(for: owner).opacity(0.7), radius: 8)
            } else if cell.hasGas {
                BoardItemIcon(image: "GasIcon")
            } else if cell.hasEMP {
                BoardItemIcon(image: "EMPIcon")
            } else if cell.hasShield {
                BoardItemIcon(image: "ShieldIcon")
            } else if cell.hasScrapTrap {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.caption2.weight(.black))
                    .foregroundStyle(GameTheme.smoke)
            } else if cell.hasMine {
                BoardItemIcon(image: "MineIcon")
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .overlay(alignment: .topTrailing) {
            if cell.shieldOwner != nil {
                Image("ShieldIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .padding(3)
            }
        }
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

private struct BoardItemIcon: View {
    let image: String

    var body: some View {
        Image(image)
            .resizable()
            .scaledToFit()
            .frame(width: 30, height: 30)
            .clipShape(RoundedRectangle(cornerRadius: 5))
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
                Image(game.rewards.isEmpty ? "GachaScreenVisual" : "GachaOpeningVisual")
                    .resizable()
                    .scaledToFill()
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
                            Image(reward.character.rarity >= .ssr ? "GachaSSRVisual" : reward.character.imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 46, height: 46)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            Text(reward.character.rarity.rawValue)
                                .font(.caption.weight(.black))
                                .foregroundStyle(reward.character.rarity.color)
                                .frame(width: 44)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(reward.character.name)
                                    .font(.headline.weight(.heavy))
                                Text(reward.isNew ? "NEW / 選択可能" : "所持済み / スクラップ変換")
                                    .font(.caption2.weight(.heavy))
                                    .foregroundStyle(GameTheme.smoke)
                            }
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
            Spacer()
            Label("\(game.shieldPlates)", systemImage: "shield.fill")
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

