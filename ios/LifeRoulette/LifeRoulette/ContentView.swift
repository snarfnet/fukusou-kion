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
        .tint(AppPalette.accent)
    }
}

private struct HomeView<Ads: AdService>: View {
    let adService: Ads

    @State private var selectedTheme: NumberTheme = .today
    @State private var inputText = ""
    @State private var reading: NumberReading?
    @State private var savedItem: NumberHistoryItem?

    @EnvironmentObject private var historyStore: ResultHistoryStore

    private let engine = NumberReadingEngine()
    private let soundPlayer = DrumrollSoundPlayer()
    private let haptics = HapticPerformer()

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HeroHeader()
                        ThemePicker(selectedTheme: $selectedTheme)
                        InputPanel(theme: selectedTheme, text: $inputText)
                        PrimaryActionButton(title: "数字のお話を聞く") {
                            tellStory()
                        }

                        if let reading {
                            ReadingPanel(reading: reading, theme: selectedTheme, shareItem: savedItem)
                                .transition(.opacity.combined(with: .scale(scale: 0.97)))
                        } else {
                            EmptyReadingPanel()
                        }

                        Text("このアプリは気軽に楽しむための読み物です。大切な判断は、あなたの状況に合わせて決めてください。")
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(AppPalette.mutedText)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 2)

                        adService.banner()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("数字のお話")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func tellStory() {
        soundPlayer.play()
        haptics.spinTick()

        let newReading = engine.reading(for: inputText, theme: selectedTheme)
        historyStore.add(theme: selectedTheme, input: inputText, reading: newReading)
        savedItem = historyStore.items.first

        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
            reading = newReading
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            soundPlayer.stop()
            haptics.explosion()
        }
    }
}

private struct HeroHeader: View {
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("その数字は、何を話す？")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(AppPalette.text)
                    .fixedSize(horizontal: false, vertical: true)

                Text("日付、名前、迷いごとを1から9の数字に変えて、今日の小さなヒントを読みます。")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(AppPalette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ZStack {
                Circle()
                    .fill(AppPalette.accent.opacity(0.16))
                    .frame(width: 94, height: 94)
                Text("9")
                    .font(.system(size: 58, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppPalette.accent, AppPalette.coral],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .accessibilityHidden(true)
        }
        .padding(18)
        .background(.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.74), lineWidth: 1)
        )
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
                    withAnimation(.spring(response: 0.26, dampingFraction: 0.78)) {
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
                            .minimumScaleFactor(0.86)
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(selectedTheme == theme ? .white : AppPalette.text)
                    .padding(14)
                    .frame(minHeight: 56)
                    .background {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(selectedTheme == theme ? theme.tint : .white.opacity(0.72))
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(selectedTheme == theme ? .white.opacity(0.5) : .white.opacity(0.68), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct InputPanel: View {
    let theme: NumberTheme
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(theme.promptTitle, systemImage: "pencil.line")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(AppPalette.secondaryText)

            TextField(theme.placeholder, text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.body.weight(.semibold))
                .foregroundStyle(AppPalette.text)
                .padding(15)
                .frame(minHeight: 56)
                .background(AppPalette.field, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(theme.tint.opacity(0.34), lineWidth: 1)
                )
        }
        .padding(16)
        .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct PrimaryActionButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: "sparkles")
                .font(.headline.weight(.black))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(AppPalette.text, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(AppPalette.accent.opacity(0.65), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct EmptyReadingPanel: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("1 2 3 4 5 6 7 8 9")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundStyle(AppPalette.accent)

            Text("数字を入れてボタンを押すと、ここに短い読み解きが表示されます。")
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppPalette.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 150)
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct ReadingPanel: View {
    let reading: NumberReading
    let theme: NumberTheme
    let shareItem: NumberHistoryItem?

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Label(theme.rawValue, systemImage: theme.icon)
                    .font(.caption.weight(.black))
                    .foregroundStyle(theme.tint)
                Spacer()
                Text(reading.hint)
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(theme.tint, in: Capsule())
            }

            Text("\(reading.number)")
                .font(.system(size: 86, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.tint, AppPalette.coral],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(maxWidth: .infinity)

            VStack(spacing: 8) {
                Text(reading.title)
                    .font(.title2.weight(.black))
                    .foregroundStyle(AppPalette.text)
                    .multilineTextAlignment(.center)

                Text(reading.message)
                    .font(.body.weight(.semibold))
                    .lineSpacing(4)
                    .foregroundStyle(AppPalette.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let shareItem {
                ShareLink(item: shareItem.shareText) {
                    Label("共有", systemImage: "square.and.arrow.up.fill")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppPalette.text)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(AppPalette.field, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .padding(.top, 2)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(theme.tint.opacity(0.4), lineWidth: 1)
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
                        Image(systemName: "clock")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundStyle(AppPalette.accent)

                        Text("まだ履歴はありません")
                            .font(.title2.weight(.black))
                            .foregroundStyle(AppPalette.text)

                        Text("数字のお話を聞くと、ここに結果が残ります。")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(AppPalette.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(24)
                    .background(.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .padding(20)
                } else {
                    List {
                        ForEach(historyStore.items) { item in
                            HistoryRow(item: item)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("履歴")
            .toolbar {
                if !historyStore.items.isEmpty {
                    Button("消す") {
                        historyStore.clear()
                    }
                    .foregroundStyle(AppPalette.accent)
                }
            }
        }
    }
}

private struct HistoryRow: View {
    let item: NumberHistoryItem

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(item.theme.rawValue, systemImage: item.theme.icon)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(item.theme.tint)
                Spacer()
                Text(item.date, style: .date)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(AppPalette.mutedText)
            }

            Text("\(item.number)  \(item.title)")
                .font(.title3.weight(.black))
                .foregroundStyle(AppPalette.text)

            Text(item.message)
                .font(.callout.weight(.semibold))
                .foregroundStyle(AppPalette.secondaryText)

            ShareLink(item: item.shareText) {
                Label("共有", systemImage: "square.and.arrow.up")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppPalette.text)
            }
        }
        .padding(16)
        .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.64), lineWidth: 1)
        )
        .padding(.vertical, 4)
    }
}

private struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.95, green: 0.93, blue: 0.86),
                Color(red: 0.84, green: 0.91, blue: 0.89),
                Color(red: 0.93, green: 0.86, blue: 0.88)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay(alignment: .topTrailing) {
            Text("1  3  5  8")
                .font(.system(size: 56, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.28))
                .rotationEffect(.degrees(-12))
                .offset(x: 42, y: 48)
        }
        .overlay(alignment: .bottomLeading) {
            Text("2  4  6  9")
                .font(.system(size: 52, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.24))
                .rotationEffect(.degrees(10))
                .offset(x: -24, y: -30)
        }
    }
}

private enum AppPalette {
    static let text = Color(red: 0.12, green: 0.14, blue: 0.18)
    static let secondaryText = Color(red: 0.33, green: 0.36, blue: 0.40)
    static let mutedText = Color(red: 0.48, green: 0.50, blue: 0.54)
    static let accent = Color(red: 0.85, green: 0.54, blue: 0.16)
    static let coral = Color(red: 0.86, green: 0.35, blue: 0.34)
    static let field = Color(red: 0.97, green: 0.95, blue: 0.90)
}

#Preview {
    ContentView(adService: PlaceholderAdService())
        .environmentObject(ResultHistoryStore())
}
