import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label(ZenLocale.text(ja: "今日", en: "Today"), systemImage: "circle.lefthalf.filled") }

            TimerPracticeView()
                .tabItem { Label(ZenLocale.text(ja: "坐禅", en: "Zazen"), systemImage: "timer") }

            LessonsView()
                .tabItem { Label(ZenLocale.text(ja: "学ぶ", en: "Learn"), systemImage: "book.closed") }

            JournalView()
                .tabItem { Label(ZenLocale.text(ja: "記録", en: "Log"), systemImage: "calendar") }
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
                            Text(ZenLocale.text(ja: "禅パワー", en: "Zen Power"))
                                .font(.system(size: 42, weight: .semibold, design: .serif))
                            Text(ZenLocale.text(ja: "一日一座。短くても、戻る力を育てる。", en: "One quiet sit a day. Build the power to return."))
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.top, 16)

                        ImageHeroCard(
                            imageName: "zen-posture",
                            title: ZenLocale.text(ja: "まず、静かに座る", en: "Start by Sitting Quietly"),
                            description: ZenLocale.text(ja: "姿勢、呼吸、記録までを画像で見ながら進めます。難しい言葉より、今日できる一歩を大切にします。", en: "Learn posture, breathing, and reflection with simple visuals. The goal is one doable step today.")
                        )

                        HStack(spacing: 12) {
                            MetricTile(title: ZenLocale.text(ja: "今日", en: "Today"), value: ZenLocale.text(ja: "\(progress.todayMinutes)分", en: "\(progress.todayMinutes)m"))
                            MetricTile(title: ZenLocale.text(ja: "連続", en: "Streak"), value: ZenLocale.text(ja: "\(progress.streakDays)日", en: "\(progress.streakDays)d"))
                            MetricTile(title: ZenLocale.text(ja: "合計", en: "Total"), value: ZenLocale.text(ja: "\(progress.totalMinutes)分", en: "\(progress.totalMinutes)m"))
                        }

                        QuoteCard(quote: quote)

                        NavigationLink {
                            TimerPracticeView()
                        } label: {
                            Label(ZenLocale.text(ja: "今日の一座を始める", en: "Start Today's Sit"), systemImage: "play.fill")
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
                            title: ZenLocale.text(ja: "息を目印にする", en: "Use Breath as Your Anchor"),
                            description: ZenLocale.text(ja: "吸う、吐く。考えが出たら、また息に戻ります。", en: "Breathe in and out. When thoughts appear, return to the breath.")
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

                        Picker(ZenLocale.text(ja: "時間", en: "Time"), selection: $selectedMinutes) {
                            ForEach(minuteChoices, id: \.self) { minute in
                                Text(ZenLocale.text(ja: "\(minute)分", en: "\(minute)m")).tag(minute)
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
                                Label(timer.hasStarted ? ZenLocale.text(ja: "再開", en: "Resume") : ZenLocale.text(ja: "開始", en: "Start"), systemImage: "play.fill")
                            }
                            .buttonStyle(PrimaryZenButtonStyle())
                            .disabled(timer.isRunning)

                            Button {
                                timer.pause()
                            } label: {
                                Label(ZenLocale.text(ja: "一時停止", en: "Pause"), systemImage: "pause.fill")
                            }
                            .buttonStyle(SecondaryZenButtonStyle())
                            .disabled(!timer.isRunning)
                        }

                        Button {
                            timer.reset(minutes: selectedMinutes)
                        } label: {
                            Label(ZenLocale.text(ja: "リセット", en: "Reset"), systemImage: "arrow.counterclockwise")
                        }
                        .buttonStyle(PlainZenButtonStyle())

                        VStack(alignment: .leading, spacing: 10) {
                            Text(ZenLocale.text(ja: "終えた後の一言", en: "One Line After Practice"))
                                .font(.headline)
                            TextField(ZenLocale.text(ja: "例: 少し落ち着いた", en: "Example: I feel a little calmer"), text: $note, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(2...4)
                            Button {
                                let practicedMinutes = max(1, timer.completedMinutes(defaultMinutes: selectedMinutes))
                                progress.addLog(minutes: practicedMinutes, note: note)
                                note = ""
                                timer.reset(minutes: selectedMinutes)
                            } label: {
                                Label(ZenLocale.text(ja: "記録する", en: "Save Log"), systemImage: "checkmark.circle.fill")
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
            .navigationTitle(ZenLocale.text(ja: "坐禅", en: "Zazen"))
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
                note = ZenLocale.text(ja: "坐禅を終えた", en: "Finished a zazen session")
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
                    Section(ZenLocale.text(ja: "絵で見る基本", en: "Visual Basics")) {
                        ForEach(ZenContent.visualGuides) { guide in
                            VisualGuideCard(guide: guide)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    }

                    Section(ZenLocale.text(ja: "初心者コース", en: "Beginner Course")) {
                        ForEach(ZenContent.lessons) { lesson in
                            NavigationLink {
                                LessonDetailView(lesson: lesson)
                            } label: {
                                LessonRow(lesson: lesson, isDone: progress.completedLessonIDs.contains(lesson.id))
                            }
                        }
                    }

                    Section(ZenLocale.text(ja: "禅語", en: "Zen Words")) {
                        ForEach(ZenContent.quotes) { quote in
                            QuoteCard(quote: quote)
                                .listRowBackground(Color.clear)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(ZenLocale.text(ja: "学ぶ", en: "Learn"))
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
                        Label(ZenLocale.text(ja: "学習を完了", en: "Mark Complete"), systemImage: "checkmark.seal.fill")
                    }
                    .buttonStyle(PrimaryZenButtonStyle())
                }
                .padding(20)
            }
        }
        .navigationTitle(ZenLocale.text(ja: "レッスン", en: "Lesson"))
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
                        Text(ZenLocale.text(ja: "まだ記録がありません", en: "No logs yet"))
                            .font(.headline)
                        Text(ZenLocale.text(ja: "坐禅を終えたら、短い一言を残しましょう。", en: "After sitting, leave one short note."))
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
                                Text(ZenLocale.text(ja: "\(log.minutes)分", en: "\(log.minutes)m"))
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
            .navigationTitle(ZenLocale.text(ja: "記録", en: "Log"))
            .safeAreaInset(edge: .bottom) {
                AdaptiveBannerSlot()
            }
        }
    }
}

private struct LessonPreview: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(ZenLocale.text(ja: "最初の一歩", en: "First Steps"))
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
                    Text(ZenLocale.text(ja: "\(lesson.minutes)分", en: "\(lesson.minutes)m"))
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
            Text(ZenLocale.text(ja: "\(lesson.minutes)分", en: "\(lesson.minutes)m"))
                .font(.caption.weight(.bold))
        }
        .padding(.vertical, 4)
    }
}

private struct ImageHeroCard: View {
    let imageName: String
    let title: String
    let description: String

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
                Text(description)
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
            Text(isRunning ? ZenLocale.text(ja: "吸って\n吐く", en: "Inhale\nExhale") : ZenLocale.text(ja: "呼吸", en: "Breath"))
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
        if didComplete { return ZenLocale.text(ja: "おつかれさまです", en: "Well done") }
        if isRunning { return ZenLocale.text(ja: "ただ座る", en: "Just sit") }
        if hasStarted { return ZenLocale.text(ja: "静かに再開できます", en: "Resume when ready") }
        return ZenLocale.text(ja: "時間を選んで始める", en: "Choose a time to begin")
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
