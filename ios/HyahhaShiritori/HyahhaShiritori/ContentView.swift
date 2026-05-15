import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var game: GameViewModel
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            WastelandBackground()

            Group {
                switch game.state {
                case .title:
                    TitleView()
                case .playing:
                    BattleView()
                case .roundWon, .roundLost, .cleared:
                    ResultView()
                }
            }
            .frame(maxWidth: 880)
            .padding(.horizontal, 16)
        }
        .onReceive(timer) { _ in
            game.tick()
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.82), value: game.state)
    }
}

private struct TitleView: View {
    @EnvironmentObject private var game: GameViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                ZStack(alignment: .bottom) {
                    Image("TitleVisual")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 430)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay {
                            LinearGradient(
                                colors: [.clear, Color.black.opacity(0.88)],
                                startPoint: .center,
                                endPoint: .bottom
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                    VStack(spacing: 8) {
                        Text("ヒャッハー")
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundStyle(HTheme.bone)
                            .shadow(color: .black, radius: 5, y: 3)
                        Text("しりとり")
                            .font(.system(size: 56, weight: .black, design: .rounded))
                            .foregroundStyle(HTheme.amber)
                            .shadow(color: HTheme.rust.opacity(0.85), radius: 10)
                    }
                    .minimumScaleFactor(0.74)
                    .padding(.bottom, 24)
                    .padding(.horizontal, 18)
                }

                VStack(spacing: 12) {
                    Text("水も食料も、語尾で奪い取れ。")
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(HTheme.bone)
                        .multilineTextAlignment(.center)

                    DifficultyPicker()

                    Button {
                        game.startBattle()
                    } label: {
                        Label("勝負開始", systemImage: "flame.fill")
                            .font(.title3.weight(.black))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(HTheme.amber, in: RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(.black)
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 8) {
                        Label("敵 \(game.progressText)", systemImage: "flag.checkered")
                        Spacer()
                        Label(game.maxUnlockedDifficulty.title, systemImage: "lock.open.fill")
                    }
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(HTheme.smoke)
                }
                .wastelandPanel()
            }
            .padding(.vertical, 22)
        }
    }
}

private struct DifficultyPicker: View {
    @EnvironmentObject private var game: GameViewModel

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Difficulty.allCases) { difficulty in
                let unlocked = difficulty.rawValue <= game.maxUnlockedDifficulty.rawValue

                Button {
                    game.chooseDifficulty(difficulty)
                } label: {
                    VStack(spacing: 3) {
                        Text(difficulty.title)
                            .font(.headline.weight(.black))
                        Text(unlocked ? difficulty.subtitle : "封鎖中")
                            .font(.caption2.weight(.bold))
                    }
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .background(
                        difficulty == game.difficulty ? HTheme.rust.opacity(0.92) : Color.white.opacity(unlocked ? 0.10 : 0.04),
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(difficulty == game.difficulty ? 0.36 : 0.12), lineWidth: 1)
                    }
                    .foregroundStyle(unlocked ? HTheme.bone : HTheme.smoke.opacity(0.42))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct BattleView: View {
    @EnvironmentObject private var game: GameViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                OpponentHeader()
                PromptPanel()
                CardGrid()
                BattleLogPanel()
            }
            .padding(.vertical, 16)
        }
    }
}

private struct OpponentHeader: View {
    @EnvironmentObject private var game: GameViewModel

    private var enemyAssetName: String {
        switch game.opponentIndex % 3 {
        case 0: "EnemyMechanic"
        case 1: "EnemyNurse"
        default: "EnemyQueen"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Image(enemyAssetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 112, height: 112)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(HTheme.color(game.opponent.colorName), lineWidth: 2)
                    }

                Text(game.opponent.mark)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.black)
                    .frame(width: 34, height: 34)
                    .background(HTheme.paper, in: RoundedRectangle(cornerRadius: 6))
                    .offset(x: 42, y: 42)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(game.opponent.colony)
                    .font(.caption.weight(.black))
                    .foregroundStyle(HTheme.amber)
                Text(game.opponent.name)
                    .font(.title3.weight(.black))
                    .foregroundStyle(HTheme.bone)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text(game.opponent.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(HTheme.smoke)
                Text(game.opponent.quote)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(HTheme.smoke.opacity(0.82))
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .wastelandPanel()
    }
}

private struct PromptPanel: View {
    @EnvironmentObject private var game: GameViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                StatChip(title: "語尾", value: game.requiredKana)
                StatChip(title: "コンボ", value: "\(game.combo)")
                StatChip(title: "残り", value: "\(game.timeLeft)")
            }

            VStack(spacing: 6) {
                Text("相手の単語")
                    .font(.caption.weight(.black))
                    .foregroundStyle(HTheme.smoke)
                Text(game.promptWord)
                    .font(.system(size: 46, weight: .black, design: .rounded))
                    .foregroundStyle(HTheme.bone)
                    .minimumScaleFactor(0.70)
                    .lineLimit(1)
                Text("「\(game.requiredKana)」から始まるカードを選べ")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(HTheme.amber)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule()
                        .fill(index < game.misses ? HTheme.rust : Color.white.opacity(0.12))
                        .frame(height: 10)
                }
            }
            Text(game.dangerText)
                .font(.caption.weight(.heavy))
                .foregroundStyle(HTheme.smoke)
        }
        .wastelandPanel()
    }
}

private struct StatChip: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2.weight(.black))
                .foregroundStyle(HTheme.smoke)
            Text(value)
                .font(.title3.weight(.black))
                .foregroundStyle(HTheme.bone)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, minHeight: 58)
        .background(Color.black.opacity(0.22), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct CardGrid: View {
    @EnvironmentObject private var game: GameViewModel
    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(game.cards) { card in
                Button {
                    game.choose(card)
                } label: {
                    VStack(spacing: 8) {
                        Text(card.word)
                            .font(.system(size: 25, weight: .black, design: .rounded))
                            .foregroundStyle(Color.black)
                            .minimumScaleFactor(0.62)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity)

                        if let bonus = card.bonus {
                            Text(bonus)
                                .font(.caption2.weight(.black))
                                .foregroundStyle(HTheme.rust)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        } else {
                            Text("単語カード")
                                .font(.caption2.weight(.black))
                                .foregroundStyle(.black.opacity(0.42))
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 92)
                    .padding(.horizontal, 10)
                    .background(HTheme.paper, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(alignment: .topLeading) {
                        Text(String(card.word.prefix(1)))
                            .font(.caption.weight(.black))
                            .foregroundStyle(HTheme.paper)
                            .frame(width: 28, height: 28)
                            .background(HTheme.ink, in: RoundedRectangle(cornerRadius: 5))
                            .padding(7)
                    }
                    .rotationEffect(.degrees(card.id.uuidString.hashValue.isMultiple(of: 2) ? 0.7 : -0.7))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct BattleLogPanel: View {
    @EnvironmentObject private var game: GameViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(game.message)
                .font(.headline.weight(.heavy))
                .foregroundStyle(HTheme.bone)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(game.logs) { log in
                Text(log.text)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(HTheme.smoke)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .wastelandPanel()
    }
}

private struct ResultView: View {
    @EnvironmentObject private var game: GameViewModel

    private var enemyAssetName: String {
        switch game.opponentIndex % 3 {
        case 0: "EnemyMechanic"
        case 1: "EnemyNurse"
        default: "EnemyQueen"
        }
    }

    var title: String {
        switch game.state {
        case .roundWon: "コロニー通過"
        case .roundLost: "地下行き"
        case .cleared: "難易度制覇"
        case .title, .playing: ""
        }
    }

    var systemImage: String {
        switch game.state {
        case .roundWon, .cleared: "flame.fill"
        case .roundLost: "exclamationmark.triangle.fill"
        case .title, .playing: "circle"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(game.state == .roundLost ? enemyAssetName : "HeroVisual")
                .resizable()
                .scaledToFill()
                .frame(height: 280)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay {
                    LinearGradient(colors: [.clear, .black.opacity(0.78)], startPoint: .center, endPoint: .bottom)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .overlay(alignment: .bottomLeading) {
                    Label(title, systemImage: systemImage)
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundStyle(HTheme.amber)
                        .padding(16)
                }

            VStack(spacing: 12) {
                Text(game.message)
                    .font(.title3.weight(.black))
                    .foregroundStyle(HTheme.bone)
                    .multilineTextAlignment(.center)

                HStack {
                    StatChip(title: "コンボ", value: "\(game.combo)")
                    StatChip(title: "ミス", value: "\(game.misses)")
                    StatChip(title: "進行", value: game.progressText)
                }

                Button {
                    game.next()
                } label: {
                    Text(game.state == .roundLost ? "再戦する" : "次へ進む")
                        .font(.headline.weight(.black))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(HTheme.amber, in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(.black)
                }
                .buttonStyle(.plain)

                Button {
                    game.prepareTitle()
                } label: {
                    Text("タイトルへ")
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(HTheme.smoke)
                }
                .buttonStyle(.plain)
            }
            .wastelandPanel()
        }
        .padding(.vertical, 18)
    }
}
