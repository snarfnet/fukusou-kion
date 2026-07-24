import SwiftUI

struct RootView: View {
    @StateObject private var progress = GameProgress()
    @State private var screen: Screen = .title
    @State private var selected = StoryData.heroines[1]
    @State private var dialogue: [StoryLine] = []
    @State private var dialogueIndex = 0
    @State private var dialogueDestination: DialogueDestination = .battle
    @State private var showYakuReference = false
    @State private var showSettings = false
    @State private var castReturnScreen: Screen = .title
    @State private var chapterReturnScreen: Screen = .title
    @AppStorage("tutorial.completed") private var tutorialCompleted = false
    @AppStorage("story.prologueSeen") private var prologueSeen = false

    enum Screen {
        case title, tutorial, map, profile, cast, castProfile, chapters, dialogue, battle, ending
    }
    enum DialogueDestination { case map, battle, chapters, ending }

    var body: some View {
        ZStack {
            Color(red: 0.035, green: 0.055, blue: 0.08).ignoresSafeArea()
            scanlines
            switch screen {
            case .title: title
            case .tutorial:
                TutorialView {
                    tutorialCompleted = true
                    openMapWithPrologueIfNeeded()
                }
            case .map: map
            case .profile: profile
            case .cast: cast
            case .castProfile: castProfile
            case .chapters: chapterArchive
            case .dialogue: dialogueView
            case .battle:
                BattleView(opponent: selected) { won in
                    if won {
                        progress.clear(selected.id)
                        beginDialogue(
                            StoryScenes.outro(for: selected),
                            destination: selected.id == StoryData.heroines.count - 1
                                ? .ending
                                : .map
                        )
                    } else {
                        screen = .map
                    }
                }
            case .ending: ending
            }
        }
        .foregroundStyle(.white)
        .pixelText()
        .sheet(isPresented: $showYakuReference) { YakuReferenceView() }
        .sheet(isPresented: $showSettings) { GameSettingsView() }
    }

    private var scanlines: some View {
        VStack(spacing: 3) {
            ForEach(0..<200, id: \.self) { _ in
                Color.black.opacity(0.11).frame(height: 1)
            }
        }.ignoresSafeArea().allowsHitTesting(false)
    }

    private var title: some View {
        ScrollView {
            VStack(spacing: 13) {
                ZStack(alignment: .bottomLeading) {
                    TitleBackdrop()
                    VStack(spacing: 1) {
                        Text("昭和六十三年・春")
                            .font(.caption)
                            .foregroundStyle(Color(red: 0.95, green: 0.82, blue: 0.43))
                        Text("雀 華 番 長")
                            .font(.system(size: 43, weight: .black, design: .monospaced))
                            .minimumScaleFactor(0.65)
                            .foregroundStyle(Color(red: 0.86, green: 0.12, blue: 0.1))
                            .shadow(color: Color(red: 0.96, green: 0.58, blue: 0.16), radius: 0, x: 3, y: 3)
                            .accessibilityIdentifier("title.logo")
                        Text("全 国 制 覇 編")
                            .font(.headline)
                            .foregroundStyle(.cyan)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.leading, 88)
                    .padding(.bottom, 16)
                    PixelPortrait(girl: StoryData.heroines[0], size: 96)
                        .offset(x: 9, y: 18)
                }
                .frame(maxWidth: 420)
                .aspectRatio(4.0 / 3.0, contentMode: .fit)
                .background(Color.black)
                .overlay(Rectangle().stroke(.white, lineWidth: 3))

                VStack(spacing: 11) {
                    Text("牌で獲れ。あたしらの明日を。")
                        .foregroundStyle(Color(red: 0.95, green: 0.82, blue: 0.43))
                    Text("全66章　女子番長100人")
                        .font(.caption)
                        .foregroundStyle(.cyan)
                    Button {
                        if tutorialCompleted {
                            openMapWithPrologueIfNeeded()
                        } else {
                            screen = .tutorial
                        }
                    } label: {
                        BlinkingStartLabel(
                            text: progress.cleared.count > 1 ? "▶  続きから" : "▶  勝負を始める"
                        )
                    }
                    .buttonStyle(PixelButtonStyle(color: .red))
                    .accessibilityIdentifier("title.start")
                    Text("制覇 \(max(0, progress.cleared.count - 1)) / 5")
                        .font(.caption)
                        .foregroundStyle(.cyan)
                }
                .frame(maxWidth: 430)
                .padding(12)
                .background(Color.black.opacity(0.88))
                .overlay(Rectangle().stroke(Color.cyan, lineWidth: 2))

                if let savedID = MatchStore.savedOpponentID,
                   let savedOpponent = StoryData.heroines.first(where: { $0.id == savedID }) {
                    Button("対局再開　\(savedOpponent.name)") {
                        selected = savedOpponent
                        screen = .battle
                    }
                    .buttonStyle(PixelButtonStyle(color: .blue))
                }
                HStack {
                    Button("遊び方") { screen = .tutorial }
                    Button("役一覧") { showYakuReference = true }
                    Button("設定") { showSettings = true }
                        .accessibilityIdentifier("title.settings")
                }
                .foregroundStyle(.cyan)
                Button("全国人物録　100人") {
                    castReturnScreen = .title
                    screen = .cast
                }
                    .foregroundStyle(.yellow)
                    .accessibilityIdentifier("title.cast")
                Button("物語記録　\(unlockedChapterCount) / 66") {
                    chapterReturnScreen = .title
                    screen = .chapters
                }
                .foregroundStyle(.cyan)
                .accessibilityIdentifier("title.chapters")
                if progress.cleared.count > 1 {
                    Button("記録を消して最初から") {
                        progress.reset()
                        MatchStore.clear()
                        prologueSeen = false
                    }
                        .font(.caption).foregroundStyle(.gray)
                }
                Text("© 1988 紅天女電算部　1 PLAYER")
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private var map: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("全国番長地図").font(.largeTitle).foregroundStyle(.yellow)
                    .accessibilityIdentifier("map.title")
                Text("制覇 \(max(0, progress.cleared.count - 1)) / \(StoryData.heroines.count - 1)")
                HStack {
                    Button("遊び方") { screen = .tutorial }
                    Button("役一覧") { showYakuReference = true }
                    Button("設定") { showSettings = true }
                }
                .foregroundStyle(.cyan)
                Button("全国人物録　100人") {
                    castReturnScreen = .map
                    screen = .cast
                }
                    .foregroundStyle(.yellow)
                Button("物語記録　\(unlockedChapterCount) / 66") {
                    chapterReturnScreen = .map
                    screen = .chapters
                }
                .foregroundStyle(.cyan)
                ForEach(StoryData.heroines) { girl in
                    let isHome = girl.id == 0
                    let isLocked = girl.id > progress.cleared.count
                    Button {
                        if !isLocked {
                            selected = girl
                            screen = .profile
                        }
                    } label: {
                        HStack(spacing: 14) {
                            PixelPortrait(girl: girl, size: 76)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(girl.region)　\(girl.alias)").foregroundStyle(girl.colors[0])
                                Text(girl.name).font(.title3)
                                Text(girl.school).font(.caption).foregroundStyle(.gray)
                            }
                            Spacer()
                            Text(isHome ? "本拠地" : isLocked ? "？？" : progress.cleared.contains(girl.id) ? "制覇" : "挑戦")
                                .foregroundStyle(progress.cleared.contains(girl.id) ? .yellow : isLocked ? .gray : .white)
                        }
                        .padding(12)
                        .background(Color.black.opacity(0.65))
                        .overlay(Rectangle().stroke(girl.colors[0], lineWidth: 2))
                        .opacity(isLocked ? 0.45 : 1)
                    }
                    .buttonStyle(.plain)
                    .disabled(isLocked)
                    .accessibilityIdentifier("map.school.\(girl.id)")
                }
            }.padding()
        }
    }

    private var profile: some View {
        ScrollView {
            VStack(spacing: 18) {
                PixelPortrait(girl: selected, size: 180)
                Text(selected.alias).foregroundStyle(selected.colors[0])
                Text(selected.name).font(.largeTitle)
                    .accessibilityIdentifier("profile.name")
                Text("「\(selected.catchphrase)」").foregroundStyle(.yellow)
                storyCard("風貌", selected.appearance)
                storyCard("身上書", selected.story)
                storyCard("誰にも言えないこと", selected.secret)
                storyCard("得意技", selected.specialty)
                if selected.id == 0 {
                    Text("ここが朱莉たちの帰る場所だ。").foregroundStyle(.yellow)
                } else if progress.cleared.contains(selected.id) {
                    Text("舎弟ではない。肩を並べる仲間だ。").foregroundStyle(.yellow)
                } else if MatchStore.savedOpponentID == selected.id {
                    Button("中断した対局を再開") { screen = .battle }
                        .buttonStyle(PixelButtonStyle(color: .blue))
                } else {
                    Button("校門へ乗り込む") {
                        beginDialogue(StoryScenes.intro(for: selected), destination: .battle)
                    }
                    .buttonStyle(PixelButtonStyle(color: selected.colors[0]))
                    .accessibilityIdentifier("profile.challenge")
                }
                Button("全国地図へ戻る") { screen = .map }.foregroundStyle(.gray)
            }.padding()
        }
    }

    private var cast: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    Text("全国人物録")
                        .font(.largeTitle)
                        .foregroundStyle(.yellow)
                        .accessibilityIdentifier("cast.title")
                    Text("主要6人＋47都道府県94人　全100人")
                        .foregroundStyle(.cyan)
                    Button("No.100へ移動") {
                        withAnimation { proxy.scrollTo(99, anchor: .center) }
                    }
                    .foregroundStyle(.yellow)
                    .accessibilityIdentifier("cast.jump.last")
                    ForEach(StoryData.allCharacters) { girl in
                        Button {
                            selected = girl
                            screen = .castProfile
                        } label: {
                            HStack(spacing: 12) {
                                PixelPortrait(girl: girl, size: 62)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(String(format: "No.%03d　%@", girl.id + 1, girl.name))
                                        .foregroundStyle(.white)
                                    Text("\(girl.region)　\(girl.alias)")
                                        .font(.caption)
                                        .foregroundStyle(girl.colors[0])
                                    Text(girl.school)
                                        .font(.caption2)
                                        .foregroundStyle(.gray)
                                }
                                Spacer()
                                Text(girl.id < 6 ? "主要" : "連盟")
                                    .font(.caption2)
                                    .foregroundStyle(girl.id < 6 ? .yellow : .cyan)
                            }
                            .padding(10)
                            .background(Color.black.opacity(0.72))
                            .overlay(Rectangle().stroke(girl.colors[0], lineWidth: 2))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("cast.character.\(girl.id)")
                        .id(girl.id)
                    }
                    Button("戻る") {
                        screen = castReturnScreen
                    }
                    .foregroundStyle(.gray)
                }
                .padding()
            }
        }
    }

    private var castProfile: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text(String(format: "No.%03d / 100", selected.id + 1))
                    .foregroundStyle(.cyan)
                PixelPortrait(girl: selected, size: 180)
                Text(selected.alias).foregroundStyle(selected.colors[0])
                Text(selected.name)
                    .font(.largeTitle)
                    .accessibilityIdentifier("cast.profile.name")
                Text("\(selected.region)　\(selected.school)")
                    .foregroundStyle(.gray)
                Text("「\(selected.catchphrase)」").foregroundStyle(.yellow)
                storyCard("昭和の装い", selected.appearance)
                storyCard("この子の物語", selected.story)
                storyCard("誰にも言えない夢", selected.secret)
                storyCard("得意な打ち筋", selected.specialty)
                storyCard(
                    "好きな食べ物",
                    selected.favoriteFood,
                    identifier: "cast.profile.favoriteFood"
                )
                storyCard(
                    "好きなタイプ",
                    selected.favoriteType,
                    identifier: "cast.profile.favoriteType"
                )
                storyCard(
                    "好きな単車",
                    selected.favoriteMotorcycle,
                    identifier: "cast.profile.favoriteMotorcycle"
                )
                storyCard(
                    "好きな車",
                    selected.favoriteCar,
                    identifier: "cast.profile.favoriteCar"
                )
                Button("人物録へ戻る") { screen = .cast }
                    .buttonStyle(PixelButtonStyle(color: selected.colors[0]))
            }
            .padding()
        }
    }

    private var unlockedChapterCount: Int {
        StoryScenes.unlockedChapterCount(
            clearedSchoolCount: progress.cleared.count
        )
    }

    private var chapterArchive: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                Text("物語記録")
                    .font(.largeTitle)
                    .foregroundStyle(.yellow)
                    .accessibilityIdentifier("chapters.title")
                Text("解放 \(unlockedChapterCount) / 66")
                    .foregroundStyle(.cyan)
                ForEach(StoryScenes.allChapters.indices, id: \.self) { index in
                    let line = StoryScenes.allChapters[index]
                    let unlocked = index < unlockedChapterCount
                    Button {
                        if unlocked {
                            beginDialogue([line], destination: .chapters)
                        }
                    } label: {
                        HStack {
                            Text(
                                unlocked
                                    ? "第\(index + 1)章　\(line.chapterTitle ?? "")"
                                    : "第\(index + 1)章　？？？？"
                            )
                            Spacer()
                            Text(unlocked ? "読む" : "未解放")
                                .font(.caption)
                                .foregroundStyle(unlocked ? .cyan : .gray)
                        }
                        .padding(12)
                        .background(Color.black.opacity(0.72))
                        .overlay(
                            Rectangle().stroke(
                                unlocked ? Color.cyan : Color.gray.opacity(0.4),
                                lineWidth: 2
                            )
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!unlocked)
                    .opacity(unlocked ? 1 : 0.5)
                    .accessibilityIdentifier("chapters.chapter.\(index + 1)")
                }
                Button("戻る") { screen = chapterReturnScreen }
                    .foregroundStyle(.gray)
            }
            .padding()
        }
    }

    private func storyCard(
        _ title: String,
        _ body: String,
        identifier: String? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).foregroundStyle(.cyan)
            Text(body)
                .font(.callout)
                .lineSpacing(5)
                .accessibilityIdentifier(identifier ?? "")
        }
        .frame(maxWidth: 520, alignment: .leading)
        .padding()
        .background(Color.black.opacity(0.7))
        .overlay(Rectangle().stroke(Color.white.opacity(0.5), lineWidth: 2))
    }

    private var dialogueView: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let chapterNumber = dialogue[dialogueIndex].chapterNumber,
                   let chapterTitle = dialogue[dialogueIndex].chapterTitle {
                    Text("第\(chapterNumber)章　\(chapterTitle)")
                        .font(.title2)
                        .foregroundStyle(.yellow)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("dialogue.chapter")
                }
                let featured = dialogue[dialogueIndex].featuredCharacterIDs.compactMap {
                    id in StoryData.allCharacters.first { $0.id == id }
                }
                if !featured.isEmpty {
                    VStack(spacing: 7) {
                        Text("この章の仲間")
                            .font(.caption)
                            .foregroundStyle(.cyan)
                        HStack(spacing: 14) {
                            ForEach(featured) { girl in
                                VStack(spacing: 4) {
                                    PixelPortrait(girl: girl, size: 48)
                                    Text(girl.name)
                                        .font(.caption2)
                                        .lineLimit(1)
                                }
                                .accessibilityElement(children: .combine)
                            }
                        }
                    }
                    .padding(8)
                    .background(Color.black.opacity(0.65))
                    .overlay(Rectangle().stroke(Color.cyan, lineWidth: 1))
                    .accessibilityIdentifier("dialogue.featured")
                }
                HStack(alignment: .bottom, spacing: 10) {
                    if dialogue[dialogueIndex].speaker == "語り" {
                        Text("昭\n和")
                            .font(.system(size: 38, weight: .black, design: .monospaced))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.yellow)
                            .frame(width: 145, height: 145)
                            .background(Color.black)
                            .overlay(Rectangle().stroke(.yellow, lineWidth: 3))
                    } else {
                        PixelPortrait(
                            girl: dialoguePortrait(
                                for: dialogue[dialogueIndex].speaker
                            ),
                            size: 145
                        )
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text(dialogue[dialogueIndex].speaker).foregroundStyle(.yellow)
                        Text(dialogue[dialogueIndex].text).lineSpacing(6)
                        Text("▼").frame(maxWidth: .infinity, alignment: .trailing).foregroundStyle(.cyan)
                    }
                    .padding()
                    .frame(maxWidth: 420, minHeight: 150, alignment: .topLeading)
                    .background(Color.black)
                    .overlay(Rectangle().stroke(.white, lineWidth: 3))
                }
                Button("つぎへ") { advanceDialogue() }
                    .buttonStyle(PixelButtonStyle(color: selected.colors[0]))
                    .accessibilityIdentifier("dialogue.next")
            }
            .padding()
        }
    }

    private var ending: some View {
        ScrollView {
            VStack(spacing: 22) {
                Text("全国制覇").font(.system(size: 42, weight: .black, design: .monospaced))
                    .minimumScaleFactor(0.65)
                    .foregroundStyle(.yellow).shadow(color: .red, radius: 0, x: 4, y: 4)
                HStack(spacing: 4) {
                    ForEach(StoryData.heroines) { PixelPortrait(girl: $0, size: 52) }
                }
                Text("紅天女学院　廃校撤回")
                VStack(alignment: .leading, spacing: 9) {
                    ForEach(Array(StoryScenes.epilogue.enumerated()), id: \.offset) { _, line in
                        Text(line)
                    }
                }
                .frame(maxWidth: 540, alignment: .leading)
                .padding()
                .background(Color.black.opacity(0.75))
                .overlay(Rectangle().stroke(.cyan, lineWidth: 2))
                Text("六人の卒業旅行は、まだ始まったばかりだ。")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.cyan)
                Button("全国地図へ") { screen = .map }.buttonStyle(PixelButtonStyle(color: .red))
            }
            .padding()
        }
    }

    private func beginDialogue(
        _ lines: [StoryLine],
        destination: DialogueDestination
    ) {
        guard !lines.isEmpty else {
            switch destination {
            case .map: screen = .map
            case .battle: screen = .battle
            case .chapters: screen = .chapters
            case .ending: screen = .ending
            }
            return
        }
        dialogue = lines
        dialogueIndex = 0
        dialogueDestination = destination
        screen = .dialogue
    }

    private func advanceDialogue() {
        if dialogueIndex + 1 < dialogue.count {
            dialogueIndex += 1
        } else {
            switch dialogueDestination {
            case .map: screen = .map
            case .battle: screen = .battle
            case .chapters: screen = .chapters
            case .ending: screen = .ending
            }
        }
    }

    private func dialoguePortrait(for speaker: String) -> Sukeban {
        if speaker == "朱莉" { return StoryData.heroines[0] }
        return StoryData.allCharacters.first { girl in
            girl.name.split(separator: " ").last.map(String.init) == speaker
        } ?? selected
    }

    private func openMapWithPrologueIfNeeded() {
        if prologueSeen {
            screen = .map
        } else {
            prologueSeen = true
            selected = StoryData.heroines[0]
            beginDialogue(StoryScenes.prologue, destination: .map)
        }
    }
}

struct PixelButtonStyle: ButtonStyle {
    let color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24).padding(.vertical, 14)
            .background(configuration.isPressed ? .white : color)
            .foregroundStyle(configuration.isPressed ? .black : .white)
            .overlay(Rectangle().stroke(.white, lineWidth: 3))
            .offset(x: configuration.isPressed ? 3 : 0, y: configuration.isPressed ? 3 : 0)
    }
}
