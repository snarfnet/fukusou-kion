import SwiftUI

struct ContentView<Ads: AdService>: View {
    let adService: Ads

    var body: some View {
        TabView {
            HomeView(adService: adService)
                .tabItem {
                    Label("ホーム", systemImage: "house.fill")
                }

            HistoryView()
                .tabItem {
                    Label("履歴", systemImage: "clock.fill")
                }
        }
        .tint(.yellow)
    }
}

private struct HomeView<Ads: AdService>: View {
    let adService: Ads
    @State private var selectedTheme: NumberTheme = .today
    @State private var inputText = ""
    @State private var reading: NumberReading?
    @State private var savedItem: NumberHistoryItem?
    @State private var pulse = false

    @EnvironmentObject private var historyStore: ResultHistoryStore

    private let engine = NumberReadingEngine()
    private let soundPlayer = DrumrollSoundPlayer()
    private let haptics = HapticPerformer()

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                FloatingNumbers()

                ScrollView {
                    VStack(spacing: 18) {
                        header
                        ThemePicker(selectedTheme: $selectedTheme)
                        NumberInputField(theme: selectedTheme, text: $inputText)

                        Button {
                            tellStory()
                        } label: {
                            Label("数字のお話を聞く", systemImage: "sparkles")
                                .font(.title3.weight(.black))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(SpinButtonBackground(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(.white.opacity(0.55), lineWidth: 2)
                                )
                                .shadow(color: .yellow.opacity(0.48), radius: 18, y: 8)
                        }

                        if let reading {
                            ReadingPanel(reading: reading, theme: selectedTheme, shareItem: savedItem)
                                .transition(.scale(scale: 0.92).combined(with: .opacity))
                        } else {
                            EmptyReadingCard()
                        }

                        Text("占いとして気軽に楽しむアプリです。大事な判断は、あなたの状況に合わせて決めてください。")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white.opacity(0.62))
                            .multilineTextAlignment(.center)

                        adService.banner()
                    }
                    .padding(20)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("数字のお話")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    pulse.toggle()
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                Text("その数字、何を言ってる？")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.72)

                Text("日付、名前、迷っていること。数字に変えて、短い物語として読みます。")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))
            }

            ZStack {
                Circle()
                    .fill(.yellow.opacity(0.18))
                    .frame(width: 112, height: 112)
                    .scaleEffect(pulse ? 1.06 : 0.94)
                Image("MysteryMeerkat")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 98, height: 98)
                    .rotationEffect(.degrees(pulse ? 4 : -4))
                    .shadow(color: .yellow.opacity(0.55), radius: 12)
                    .accessibilityLabel("アプリキャラクター")
            }
        }
        .padding(.top, 14)
    }

    private func tellStory() {
        soundPlayer.play()
        haptics.spinTick()

        let newReading = engine.reading(for: inputText, theme: selectedTheme)
        historyStore.add(theme: selectedTheme, input: inputText, reading: newReading)
        savedItem = historyStore.items.first

        withAnimation(.spring(response: 0.32, dampingFraction: 0.68)) {
            reading = newReading
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            soundPlayer.stop()
            haptics.explosion()
        }
    }
}

private struct ThemePicker: View {
    @Binding var selectedTheme: NumberTheme

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(NumberTheme.allCases) { theme in
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                        selectedTheme = theme
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: theme.icon)
                            .font(.headline)
                            .frame(width: 24)
                        Text(theme.rawValue)
                            .font(.headline.weight(.bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(selectedTheme == theme ? .black : .white)
                    .padding(14)
                    .frame(minHeight: 56)
                    .background {
                        if selectedTheme == theme {
                            LinearGradient(colors: theme.colors + [.yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
                        } else {
                            Color.white.opacity(0.08)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.white.opacity(selectedTheme == theme ? 0.72 : 0.12), lineWidth: 1)
                    )
                }
            }
        }
    }
}

private struct NumberInputField: View {
    let theme: NumberTheme
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.65))
            TextField(placeholder, text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .padding(14)
                .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.white.opacity(0.16), lineWidth: 1)
                )
        }
    }

    private var label: String {
        switch theme {
        case .today: "気になる日付や言葉"
        case .name: "名前"
        case .choice: "迷っていること"
        case .custom: "数字や言葉"
        }
    }

    private var placeholder: String {
        switch theme {
        case .today: "例: 2026/05/13"
        case .name: "例: さくら"
        case .choice: "例: 転職するか迷っている"
        case .custom: "例: 777"
        }
    }
}

private struct EmptyReadingCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("1 2 3 4 5 6 7 8 9")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(.yellow)
            Text("数字を入れてボタンを押すと、今のテーマに合わせた短い読み解きが出ます。")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white.opacity(0.72))
                .multilineTextAlignment(.center)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 150)
        .background(.black.opacity(0.42), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        )
    }
}

private struct ReadingPanel: View {
    let reading: NumberReading
    let theme: NumberTheme
    let shareItem: NumberHistoryItem?

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Label(theme.rawValue, systemImage: theme.icon)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.yellow)
                Spacer()
                Text(reading.hint)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white, in: Capsule())
            }

            Text("\(reading.number)")
                .font(.system(size: 78, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [.white, .yellow, .pink], startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: .yellow.opacity(0.45), radius: 14)

            Text(reading.title)
                .font(.title2.weight(.black))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(reading.message)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.76))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let shareItem {
                ShareLink(item: shareItem.shareText) {
                    Label("共有する", systemImage: "square.and.arrow.up.fill")
                        .font(.headline.weight(.black))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))
                }
                .padding(.top, 4)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(.black.opacity(0.52), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(LinearGradient(colors: theme.colors + [.yellow], startPoint: .leading, endPoint: .trailing), lineWidth: 2)
        )
    }
}

private struct HistoryView: View {
    @EnvironmentObject private var historyStore: ResultHistoryStore

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                if historyStore.items.isEmpty {
                    VStack(spacing: 12) {
                        Text("まだ履歴はありません")
                            .font(.title2.weight(.black))
                            .foregroundStyle(.white)
                        Text("数字のお話を聞くと、ここに結果が残ります。")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.65))
                            .multilineTextAlignment(.center)
                    }
                    .padding(24)
                } else {
                    List {
                        ForEach(historyStore.items) { item in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Label(item.theme.rawValue, systemImage: item.theme.icon)
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(.yellow)
                                    Spacer()
                                    Text(item.date, style: .date)
                                        .font(.caption2.weight(.bold))
                                        .foregroundStyle(.white.opacity(0.5))
                                }

                                Text("\(item.number)  \(item.title)")
                                    .font(.title2.weight(.black))
                                    .foregroundStyle(.white)

                                Text(item.message)
                                    .font(.callout.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.65))

                                ShareLink(item: item.shareText) {
                                    Label("共有", systemImage: "square.and.arrow.up")
                                        .font(.caption.weight(.bold))
                                }
                            }
                            .listRowBackground(Color.white.opacity(0.06))
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("履歴")
            .toolbar {
                if !historyStore.items.isEmpty {
                    Button("消す") {
                        historyStore.clear()
                    }
                    .foregroundStyle(.yellow)
                }
            }
        }
    }
}

private struct SpinButtonBackground: View {
    let cornerRadius: CGFloat

    var body: some View {
        Image("SpinButtonChrome")
            .resizable()
            .scaledToFill()
            .overlay(
                LinearGradient(colors: [.white.opacity(0.28), .clear, .black.opacity(0.12)], startPoint: .top, endPoint: .bottom)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

private struct FloatingNumbers: View {
    private let symbols = ["1", "2", "3", "5", "8", "13", "21", "34"]

    var body: some View {
        ZStack {
            ForEach(symbols.indices, id: \.self) { index in
                Text(symbols[index])
                    .font(.system(size: CGFloat(28 + index * 2), weight: .black, design: .rounded))
                    .foregroundStyle((index.isMultiple(of: 2) ? Color.yellow : Color.cyan).opacity(0.13))
                    .rotationEffect(.degrees(Double(index * 23 - 35)))
                    .offset(
                        x: CGFloat((index % 4) * 92 - 150),
                        y: CGFloat((index / 2) * 130 - 270)
                    )
            }
        }
        .ignoresSafeArea()
    }
}

private struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.02, green: 0.02, blue: 0.05),
                Color(red: 0.20, green: 0.02, blue: 0.16),
                Color(red: 0.02, green: 0.12, blue: 0.16)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay {
            Image("SillyDoodleBackground")
                .resizable()
                .scaledToFill()
                .opacity(0.38)
                .saturation(1.25)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .overlay {
            LinearGradient(
                colors: [.black.opacity(0.2), .clear, .black.opacity(0.38)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
        .overlay {
            RadialGradient(colors: [.yellow.opacity(0.24), .clear], center: .topTrailing, startRadius: 12, endRadius: 360)
                .ignoresSafeArea()
        }
        .overlay {
            RadialGradient(colors: [.pink.opacity(0.16), .clear], center: .bottomLeading, startRadius: 16, endRadius: 420)
                .ignoresSafeArea()
        }
    }
}

#Preview {
    ContentView(adService: PlaceholderAdService())
        .environmentObject(ResultHistoryStore())
}
