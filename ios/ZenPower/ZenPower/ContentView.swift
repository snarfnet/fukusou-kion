import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("今日", systemImage: "circle.lefthalf.filled") }

            TimerPracticeView()
                .tabItem { Label("坐禅", systemImage: "timer") }

            LessonsView()
                .tabItem { Label("学ぶ", systemImage: "book.closed") }

            JournalView()
                .tabItem { Label("記録", systemImage: "calendar") }
        }
        .tint(.zenInk)
        .background(Color.zenPaper)
    }
}

private struct HomeView: View {
    @EnvironmentObject private var progress: ZenProgressStore
    private let quote = ZenContent.todayQuote

    var body: some View {
        NavigationStack {
            ZStack {
                Color.zenPaper.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("禅パワー")
                                .font(.system(size: 42, weight: .semibold, design: .serif))
                            Text("一日一座。短くても、戻る力を育てる。")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 16)

                        ImageHeroCard(
                            imageName: "zen-posture",
                            title: "まず、静かに座る",
                            body: "姿勢、呼吸、記録までを画像で見ながら進めます。難しい言葉より、今日できる一歩を大切にします。"
                        )

                        HStack(spacing: 12) {
                            MetricTile(title: "今日", value: "\(progress.todayMinutes)分")
                            MetricTile(title: "連続", value: "\(progress.streakDays)日")
                            MetricTile(title: "合計", value: "\(progress.totalMinutes)分")
                        }

                        QuoteCard(quote: quote)

                        NavigationLink {
                            TimerPracticeView()
                        } label: {
                            Label("今日の一座を始める", systemImage: "play.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.zenInk)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }

                        LessonPreview()
                    }
                    .padding(20)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                AdaptiveBannerSlot()
            }
        }
    }
}

private struct TimerPracticeView: View {
    @EnvironmentObject private var progress: ZenProgressStore
    @StateObject private var timer = MeditationTimer()
    @State private var note = ""
    @State private var selectedMinutes = 5

    private let minuteChoices = [3, 5, 10, 15, 20]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.zenPaper.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        ImageHeroCard(
                            imageName: "zen-breath",
                            title: "息を目印にする",
                            body: "吸う、吐く。考えが出たら、また息に戻ります。"
                        )

                        VStack(spacing: 8) {
                            Text(timer.display)
                                .font(.system(size: 64, weight: .light, design: .rounded))
                                .monospacedDigit()
                            Text(timer.statusText)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 26)
                        .background(Color.white.opacity(0.72))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                        Picker("時間", selection: $selectedMinutes) {
                            ForEach(minuteChoices, id: \.self) { minute in
                                Text("\(minute)分").tag(minute)
                            }
                        }
                        .pickerStyle(.segmented)
                        .disabled(timer.isRunning)

                        BreathingOrb(isRunning: timer.isRunning)

                        HStack(spacing: 12) {
                            Button {
                                timer.configure(minutes: selectedMinutes)
                                timer.start()
                            } label: {
                                Label(timer.hasStarted ? "再開" : "開始", systemImage: "play.fill")
                            }
                            .buttonStyle(PrimaryZenButtonStyle())
                            .disabled(timer.isRunning)

                            Button {
                                timer.pause()
                            } label: {
                                Label("一時停止", systemImage: "pause.fill")
                            }
                            .buttonStyle(SecondaryZenButtonStyle())
                            .disabled(!timer.isRunning)
                        }

                        Button {
                            timer.reset(minutes: selectedMinutes)
                        } label: {
                            Label("リセット", systemImage: "arrow.counterclockwise")
                        }
                        .buttonStyle(PlainZenButtonStyle())

                        VStack(alignment: .leading, spacing: 10) {
                            Text("終えた後の一言")
                                .font(.headline)
                            TextField("例: 少し落ち着いた", text: $note, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(2...4)
                            Button {
                                let practicedMinutes = max(1, timer.completedMinutes(defaultMinutes: selectedMinutes))
                                progress.addLog(minutes: practicedMinutes, note: note)
                                note = ""
                                timer.reset(minutes: selectedMinutes)
                            } label: {
                                Label("記録する", systemImage: "checkmark.circle.fill")
                            }
                            .buttonStyle(PrimaryZenButtonStyle())
                        }
                        .padding()
                        .background(Color.white.opacity(0.72))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(20)
                }
            }
            .navigationTitle("坐禅")
            .safeAreaInset(edge: .bottom) {
                AdaptiveBannerSlot()
            }
            .onAppear {
                timer.configure(minutes: selectedMinutes)
            }
            .onChange(of: selectedMinutes) { newValue in
                guard !timer.isRunning else { return }
                timer.configure(minutes: newValue)
            }
            .onChange(of: timer.didComplete) { didComplete in
                guard didComplete else { return }
                note = "坐禅を終えた"
            }
        }
    }
}

private struct LessonsView: View {
    @EnvironmentObject private var progress: ZenProgressStore

    var body: some View {
        NavigationStack {
            ZStack {
                Color.zenPaper.ignoresSafeArea()
                List {
                    Section("絵で見る基本") {
                        ForEach(ZenContent.visualGuides) { guide in
                            VisualGuideCard(guide: guide)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    }

                    Section("初心者コース") {
                        ForEach(ZenContent.lessons) { lesson in
                            NavigationLink {
                                LessonDetailView(lesson: lesson)
                            } label: {
                                LessonRow(lesson: lesson, isDone: progress.completedLessonIDs.contains(lesson.id))
                            }
                        }
                    }

                    Section("禅語") {
                        ForEach(ZenContent.quotes) { quote in
                            QuoteCard(quote: quote)
                                .listRowBackground(Color.clear)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("学ぶ")
            .safeAreaInset(edge: .bottom) {
                AdaptiveBannerSlot()
            }
        }
    }
}

private struct LessonDetailView: View {
    @EnvironmentObject private var progress: ZenProgressStore
    let lesson: ZenLesson

    var body: some View {
        ZStack {
            Color.zenPaper.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    LessonImage(imageName: lesson.imageName)

                    Text(lesson.title)
                        .font(.system(size: 34, weight: .semibold, design: .serif))
                    Text(lesson.summary)
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(Array(lesson.steps.enumerated()), id: \.offset) { index, step in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.caption.weight(.bold))
                                    .frame(width: 26, height: 26)
                                    .background(Color.zenMist)
                                    .clipShape(Circle())
                                Text(step)
                                    .font(.body)
                            }
                        }
                    }

                    Button {
                        progress.completeLesson(lesson)
                    } label: {
                        Label("学習を完了", systemImage: "checkmark.seal.fill")
                    }
                    .buttonStyle(PrimaryZenButtonStyle())
                }
                .padding(20)
            }
        }
        .navigationTitle("レッスン")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct JournalView: View {
    @EnvironmentObject private var progress: ZenProgressStore

    var body: some View {
        NavigationStack {
            ZStack {
                Color.zenPaper.ignoresSafeArea()
                if progress.logs.isEmpty {
                    VStack(spacing: 12) {
                        Image("zen-journal")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 220, height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        Text("まだ記録がありません")
                            .font(.headline)
                        Text("坐禅を終えたら、短い一言を残しましょう。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .multilineTextAlignment(.center)
                    .padding(24)
                } else {
                    List(progress.logs) { log in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(log.date, style: .date)
                                    .font(.headline)
                                Spacer()
                                Text("\(log.minutes)分")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.zenInk)
                            }
                            if !log.note.isEmpty {
                                Text(log.note)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 6)
                        .listRowBackground(Color.white.opacity(0.72))
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("記録")
            .safeAreaInset(edge: .bottom) {
                AdaptiveBannerSlot()
            }
        }
    }
}

private struct LessonPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最初の一歩")
                .font(.headline)
            ForEach(ZenContent.lessons.prefix(2)) { lesson in
                HStack {
                    Image(lesson.imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 54, height: 54)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(lesson.title)
                            .font(.subheadline.weight(.semibold))
                        Text(lesson.summary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(lesson.minutes)分")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.zenInk)
                }
                Divider()
            }
        }
        .padding()
        .background(Color.white.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct LessonRow: View {
    let lesson: ZenLesson
    let isDone: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Image(lesson.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 58, height: 58)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isDone ? Color.zenInk : .white)
                    .background(Circle().fill(Color.white.opacity(0.78)))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.title)
                    .font(.headline)
                Text(lesson.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer()
            Text("\(lesson.minutes)分")
                .font(.caption.weight(.bold))
        }
        .padding(.vertical, 4)
    }
}

private struct ImageHeroCard: View {
    let imageName: String
    let title: String
    let body: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                Text(body)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.76))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct VisualGuideCard: View {
    let guide: ZenVisualGuide

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(guide.imageName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 170)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            Text(guide.title)
                .font(.headline)
            Text(guide.body)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color.white.opacity(0.76))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct LessonImage: View {
    let imageName: String

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: 260)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct MetricTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct QuoteCard: View {
    let quote: ZenQuote

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(quote.phrase)
                .font(.system(size: 30, weight: .semibold, design: .serif))
            Text(quote.reading)
                .font(.caption)
                .foregroundStyle(Color.zenMoss)
            Text(quote.meaning)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.76))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct BreathingOrb: View {
    let isRunning: Bool
    @State private var breathe = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.zenMist)
                .frame(width: breathe ? 168 : 118, height: breathe ? 168 : 118)
                .animation(
                    isRunning ? .easeInOut(duration: 4).repeatForever(autoreverses: true) : .easeOut(duration: 0.3),
                    value: breathe
                )
            Circle()
                .stroke(Color.zenInk.opacity(0.45), lineWidth: 1)
                .frame(width: 190, height: 190)
            Text(isRunning ? "吸って\n吐く" : "呼吸")
                .multilineTextAlignment(.center)
                .font(.headline)
                .foregroundStyle(Color.zenInk)
        }
        .frame(height: 210)
        .onChange(of: isRunning) { running in
            breathe = running
        }
        .onAppear {
            breathe = isRunning
        }
    }
}

private struct AdaptiveBannerSlot: View {
    var body: some View {
        GeometryReader { proxy in
            let width = max(320, proxy.size.width)
            BannerAdView(width: width)
                .frame(width: width, height: 64)
                .frame(maxWidth: .infinity)
                .background(Color.zenPaper)
        }
        .frame(height: 66)
    }
}

private final class MeditationTimer: ObservableObject {
    @Published var remainingSeconds = 300
    @Published var totalSeconds = 300
    @Published var isRunning = false
    @Published var didComplete = false

    private var timer: Timer?

    var hasStarted: Bool {
        remainingSeconds < totalSeconds
    }

    var display: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var statusText: String {
        if didComplete { return "おつかれさまです" }
        if isRunning { return "ただ座る" }
        if hasStarted { return "静かに再開できます" }
        return "時間を選んで始める"
    }

    func configure(minutes: Int) {
        guard !isRunning, !hasStarted else { return }
        totalSeconds = minutes * 60
        remainingSeconds = totalSeconds
        didComplete = false
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        didComplete = false
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func reset(minutes: Int) {
        pause()
        totalSeconds = minutes * 60
        remainingSeconds = totalSeconds
        didComplete = false
    }

    func completedMinutes(defaultMinutes: Int) -> Int {
        let practicedSeconds = max(0, totalSeconds - remainingSeconds)
        if didComplete { return totalSeconds / 60 }
        if practicedSeconds == 0 { return defaultMinutes }
        return max(1, Int(ceil(Double(practicedSeconds) / 60.0)))
    }

    @MainActor
    private func tick() {
        guard remainingSeconds > 0 else {
            finish()
            return
        }

        remainingSeconds -= 1
        if remainingSeconds == 0 {
            finish()
        }
    }

    @MainActor
    private func finish() {
        pause()
        didComplete = true
    }
}

private struct PrimaryZenButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.zenInk.opacity(configuration.isPressed ? 0.82 : 1))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct SecondaryZenButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.zenMist.opacity(configuration.isPressed ? 0.7 : 1))
            .foregroundStyle(Color.zenInk)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct PlainZenButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.zenInk.opacity(configuration.isPressed ? 0.72 : 1))
    }
}

private extension Color {
    static let zenPaper = Color(red: 0.94, green: 0.93, blue: 0.88)
    static let zenInk = Color(red: 0.12, green: 0.18, blue: 0.16)
    static let zenMist = Color(red: 0.77, green: 0.84, blue: 0.79)
    static let zenMoss = Color(red: 0.30, green: 0.40, blue: 0.31)
}
