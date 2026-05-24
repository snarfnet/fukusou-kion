import AudioToolbox
import Observation
import SwiftUI

struct ContentView: View {
    @State private var viewModel = CleaningViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                header
                fengShuiCards
                typewriterCard
                if let warning = viewModel.currentTip?.warning, !warning.isEmpty {
                    warningCard(warning)
                }
                filters
                statusLine
                timerCard
            }
            .padding(.horizontal, 14)
            .padding(.top, 18)
            .padding(.bottom, 24)
        }
        .background(AppColors.background.ignoresSafeArea())
        .task {
            viewModel.start()
        }
        .onDisappear {
            viewModel.stopAll()
        }
        .alert("掃除完了です", isPresented: $viewModel.showingAlarm) {
            Button("止める") {
                viewModel.stopAlarm()
            }
        } message: {
            Text("\(viewModel.currentTip?.action ?? "一か所だけ整える")、お疲れさまでした。")
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text("CLEAN NOTE")
                    .font(.caption.weight(.black))
                    .foregroundStyle(AppColors.green)
                Text("清掃の心得")
                    .font(.system(size: 42, weight: .black, design: .serif))
                    .foregroundStyle(AppColors.ink)
            }
            Spacer()
            Button {
                viewModel.randomTip()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 18, weight: .bold))
                    .frame(width: 48, height: 48)
                    .background(.white.opacity(0.82), in: Circle())
                    .overlay(Circle().stroke(AppColors.line))
                    .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("次の豆知識を表示")
        }
        .padding(.top, 4)
    }

    private var fengShuiCards: some View {
        let advice = viewModel.fengShui
        return HStack(spacing: 12) {
            FengCard(title: "今日はここが吉", main: advice.spot, message: advice.advice)
                .frame(maxWidth: .infinity)
            FengCard(title: "吉方角", main: advice.direction, message: "ラッキーカラー: \(advice.color)")
                .frame(width: 124)
        }
    }

    private var typewriterCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let tip = viewModel.currentTip {
                Text(tip.category)
                    .font(.caption.weight(.black))
                    .foregroundStyle(AppColors.gold)

                Text(tip.title)
                    .font(.system(size: 30, weight: .black, design: .serif))
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .minimumScaleFactor(0.82)

                HStack(spacing: 8) {
                    CapsuleLabel(tip.level)
                    CapsuleLabel("\(tip.minutes)分")
                    CapsuleLabel(tip.target)
                }
                .padding(.top, -2)

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.white.opacity(0.14))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.26)))
                    Text(viewModel.typedText)
                        .font(.system(size: 16, weight: .medium))
                        .lineSpacing(6)
                        .foregroundStyle(.white)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Rectangle()
                        .fill(AppColors.gold)
                        .frame(width: 9, height: 24)
                        .offset(x: 16, y: 204)
                        .opacity(viewModel.caretVisible ? 1 : 0.25)
                }
                .frame(height: 244)

                HStack(spacing: 12) {
                    Button("前へ") { viewModel.moveTip(-1) }
                        .buttonStyle(SecondaryButtonStyle())
                    Button("次の心得") { viewModel.moveTip(1) }
                        .buttonStyle(PrimaryButtonStyle())
                    Button(viewModel.isStreamPaused ? "再開" : "停止") { viewModel.toggleStream() }
                        .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
        .padding(18)
        .background(
            ZStack(alignment: .bottomTrailing) {
                LinearGradient(colors: [AppColors.green, AppColors.deepGreen], startPoint: .topLeading, endPoint: .bottomTrailing)
                Circle()
                    .stroke(.white.opacity(0.10), lineWidth: 44)
                    .frame(width: 240, height: 240)
                    .offset(x: 96, y: 88)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.10), radius: 18, y: 9)
    }

    private func warningCard(_ warning: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("注意")
                .font(.subheadline.weight(.black))
            Text(warning)
                .font(.subheadline.weight(.semibold))
                .lineSpacing(5)
        }
        .foregroundStyle(Color(red: 0.50, green: 0.23, blue: 0.12))
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 1.0, green: 0.94, blue: 0.90), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(red: 0.86, green: 0.42, blue: 0.30).opacity(0.35)))
    }

    private var filters: some View {
        VStack(spacing: 12) {
            TextField("例: 浴室、カビ、5分", text: $viewModel.query)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .padding(14)
                .background(.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppColors.line))

            Picker("場所", selection: $viewModel.selectedCategory) {
                ForEach(viewModel.categories, id: \.self) { category in
                    Text(category).tag(category)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppColors.line))
        }
        .onChange(of: viewModel.query) { _, _ in viewModel.applyFilters() }
        .onChange(of: viewModel.selectedCategory) { _, _ in viewModel.applyFilters() }
    }

    private var statusLine: some View {
        HStack {
            Text("\(viewModel.filteredTips.count)件")
            Spacer()
            Text("\(viewModel.tipIndex + 1) / \(max(viewModel.filteredTips.count, 1))")
        }
        .font(.subheadline.weight(.black))
        .foregroundStyle(AppColors.muted)
    }

    private var timerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("BROOM TIMER")
                        .font(.caption.weight(.black))
                        .foregroundStyle(AppColors.green)
                    Text("ホウキ針タイマー")
                        .font(.title2.weight(.black))
                }
                Spacer()
                Button {
                    viewModel.playAlarmPreview()
                } label: {
                    Image(systemName: "music.note")
                        .font(.system(size: 18, weight: .bold))
                        .frame(width: 46, height: 46)
                        .background(Color(red: 0.94, green: 0.97, blue: 0.94), in: Circle())
                        .overlay(Circle().stroke(AppColors.line))
                }
                .buttonStyle(.plain)
            }

            ZStack {
                Image("TimerDial")
                    .resizable()
                    .scaledToFit()
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.15), radius: 18, y: 8)
                Image("BroomHand")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 38, height: 154)
                    .rotationEffect(.degrees(viewModel.handAngle))
                    .offset(y: -74)
                    .shadow(color: .black.opacity(0.20), radius: 4, y: 3)
                Circle()
                    .fill(AppColors.coral)
                    .frame(width: 24, height: 24)
                Text(viewModel.timeReadout)
                    .font(.system(size: 32, weight: .black, design: .serif))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                    .background(.white.opacity(0.70), in: Capsule())
                    .offset(y: 66)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 300)
            .contentShape(Rectangle())
            .onTapGesture {
                viewModel.bumpMinutes()
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("分")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppColors.muted)
                Stepper(value: $viewModel.selectedMinutes, in: 1...180) {
                    Text("\(viewModel.selectedMinutes)")
                        .font(.headline)
                }
                .onChange(of: viewModel.selectedMinutes) { _, _ in viewModel.resetTimer() }
            }
            .padding(14)
            .background(.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(AppColors.line))

            HStack(spacing: 10) {
                ForEach([3, 5, 10, 15, 30], id: \.self) { minute in
                    Button("\(minute)") {
                        viewModel.setMinutes(minute)
                    }
                    .buttonStyle(QuickMinuteStyle())
                }
            }

            Button(viewModel.isTimerRunning ? "動作中" : "開始") {
                viewModel.startTimer()
            }
            .buttonStyle(PrimaryButtonStyle())

            Button("一時停止") {
                viewModel.pauseTimer()
            }
            .buttonStyle(SecondaryButtonStyle())

            Button("リセット") {
                viewModel.resetTimer()
            }
            .buttonStyle(SecondaryButtonStyle())

            VStack(alignment: .leading, spacing: 20) {
                Text("今の一手")
                    .font(.caption.weight(.black))
                    .foregroundStyle(.white.opacity(0.72))
                Text(viewModel.currentTip?.action ?? "一か所だけ整える")
                    .font(.title3.weight(.black))
                    .foregroundStyle(.white)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LinearGradient(colors: [AppColors.blue, AppColors.deepGreen], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 20))
        }
        .padding(16)
        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.10), radius: 18, y: 9)
    }
}

@Observable
final class CleaningViewModel {
    let allTips: [CleaningTip] = CleaningData.makeTips()
    var filteredTips: [CleaningTip] = []
    var categories: [String] = ["すべて"]
    var selectedCategory = "すべて"
    var query = ""
    var tipIndex = 0
    var typedText = ""
    var caretVisible = true
    var isStreamPaused = false
    var recentKeys: [String] = []
    var selectedMinutes = 10
    var remainingSeconds = 600
    var isTimerRunning = false
    var showingAlarm = false

    private var typeTask: Task<Void, Never>?
    private var streamTask: Task<Void, Never>?
    private var caretTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?
    private var alarmTask: Task<Void, Never>?

    init() {
        filteredTips = allTips
        categories = ["すべて"] + Array(Set(allTips.map(\.category))).sorted()
    }

    var currentTip: CleaningTip? {
        guard !filteredTips.isEmpty else { return nil }
        return filteredTips[min(tipIndex, filteredTips.count - 1)]
    }

    var fengShui: FengShuiAdvice {
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let seed = (comps.year ?? 2026) + (comps.month ?? 1) * 31 + (comps.day ?? 1)
        return CleaningData.fengShui[seed % CleaningData.fengShui.count]
    }

    var timeReadout: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var handAngle: Double {
        if isTimerRunning {
            let total = max(selectedMinutes * 60, 1)
            return (1.0 - Double(remainingSeconds) / Double(total)) * 360.0
        }
        return Double(selectedMinutes % 60) * 6.0
    }

    func start() {
        applyFilters()
        caretTask = Task { @MainActor in
            while !Task.isCancelled {
                caretVisible.toggle()
                try? await Task.sleep(for: .milliseconds(520))
            }
        }
    }

    func stopAll() {
        typeTask?.cancel()
        streamTask?.cancel()
        caretTask?.cancel()
        timerTask?.cancel()
        alarmTask?.cancel()
    }

    func applyFilters() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        filteredTips = allTips.filter { tip in
            let categoryOK = selectedCategory == "すべて" || tip.category == selectedCategory
            guard categoryOK else { return false }
            guard !trimmed.isEmpty else { return true }
            return [tip.category, tip.target, tip.title, tip.body, tip.action, tip.level, "\(tip.minutes)分"].joined(separator: " ").localizedCaseInsensitiveContains(trimmed)
        }
        tipIndex = 0
        showCurrentTip()
    }

    func moveTip(_ delta: Int) {
        guard !filteredTips.isEmpty else { return }
        let direction = delta >= 0 ? 1 : -1
        for step in 1...filteredTips.count {
            let index = (tipIndex + direction * step + filteredTips.count) % filteredTips.count
            if !recentKeys.contains(filteredTips[index].key) {
                tipIndex = index
                showCurrentTip()
                return
            }
        }
        tipIndex = (tipIndex + direction + filteredTips.count) % filteredTips.count
        showCurrentTip()
    }

    func randomTip() {
        guard !filteredTips.isEmpty else { return }
        var next = Int.random(in: 0..<filteredTips.count)
        for _ in 0..<40 {
            let candidate = Int.random(in: 0..<filteredTips.count)
            if !recentKeys.contains(filteredTips[candidate].key) {
                next = candidate
                break
            }
        }
        tipIndex = next
        showCurrentTip()
    }

    func toggleStream() {
        isStreamPaused.toggle()
        if isStreamPaused {
            streamTask?.cancel()
        } else {
            scheduleNextTip()
        }
    }

    func setMinutes(_ minute: Int) {
        selectedMinutes = minute
        resetTimer()
    }

    func bumpMinutes() {
        selectedMinutes = selectedMinutes >= 60 ? 1 : selectedMinutes + 1
        resetTimer()
    }

    func startTimer() {
        guard !isTimerRunning else { return }
        showingAlarm = false
        isTimerRunning = true
        if remainingSeconds <= 0 {
            remainingSeconds = selectedMinutes * 60
        }
        timerTask?.cancel()
        timerTask = Task { @MainActor in
            while !Task.isCancelled && remainingSeconds > 0 {
                try? await Task.sleep(for: .seconds(1))
                remainingSeconds -= 1
            }
            if remainingSeconds <= 0 {
                finishTimer()
            }
        }
    }

    func pauseTimer() {
        isTimerRunning = false
        timerTask?.cancel()
    }

    func resetTimer() {
        pauseTimer()
        remainingSeconds = selectedMinutes * 60
        showingAlarm = false
        alarmTask?.cancel()
    }

    func playAlarmPreview() {
        playAlarm()
    }

    func stopAlarm() {
        showingAlarm = false
        alarmTask?.cancel()
    }

    private func finishTimer() {
        isTimerRunning = false
        showingAlarm = true
        playAlarm()
        alarmTask?.cancel()
        alarmTask = Task { @MainActor in
            while !Task.isCancelled && showingAlarm {
                try? await Task.sleep(for: .seconds(2))
                playAlarm()
            }
        }
    }

    private func showCurrentTip() {
        guard let tip = currentTip else {
            typedText = "検索語を短くするか、場所を「すべて」に戻してください。"
            return
        }
        remember(tip)
        type(tip.body)
        if !isStreamPaused {
            scheduleNextTip()
        }
    }

    private func remember(_ tip: CleaningTip) {
        recentKeys.removeAll { $0 == tip.key }
        recentKeys.insert(tip.key, at: 0)
        recentKeys = Array(recentKeys.prefix(12))
    }

    private func type(_ text: String) {
        typeTask?.cancel()
        typedText = ""
        typeTask = Task { @MainActor in
            for index in text.indices {
                if Task.isCancelled { return }
                typedText = String(text[...index])
                try? await Task.sleep(for: .milliseconds(22))
            }
        }
    }

    private func scheduleNextTip() {
        streamTask?.cancel()
        streamTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(8))
            if !Task.isCancelled && !isStreamPaused {
                moveTip(1)
            }
        }
    }

    private func playAlarm() {
        AudioServicesPlaySystemSound(1005)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            AudioServicesPlaySystemSound(1006)
        }
    }
}

private enum AppColors {
    static let background = LinearGradient(colors: [Color(red: 0.95, green: 0.97, blue: 0.94), Color(red: 0.98, green: 0.96, blue: 0.90)], startPoint: .top, endPoint: .bottom)
    static let ink = Color(red: 0.13, green: 0.19, blue: 0.18)
    static let muted = Color(red: 0.41, green: 0.46, blue: 0.44)
    static let line = Color(red: 0.85, green: 0.82, blue: 0.74)
    static let green = Color(red: 0.18, green: 0.44, blue: 0.36)
    static let deepGreen = Color(red: 0.13, green: 0.19, blue: 0.18)
    static let gold = Color(red: 0.95, green: 0.79, blue: 0.47)
    static let coral = Color(red: 0.85, green: 0.42, blue: 0.31)
    static let blue = Color(red: 0.29, green: 0.44, blue: 0.56)
}

private struct FengCard: View {
    let title: String
    let main: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.black))
                .foregroundStyle(AppColors.muted)
            Text(main)
                .font(.system(size: 30, weight: .black, design: .serif))
                .foregroundStyle(AppColors.ink)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppColors.muted)
                .lineLimit(3)
        }
        .padding(16)
        .frame(minHeight: 128, alignment: .topLeading)
        .background(
            LinearGradient(colors: [.white.opacity(0.90), Color(red: 0.94, green: 0.98, blue: 0.94).opacity(0.70)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 20)
        )
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(red: 0.77, green: 0.55, blue: 0.20).opacity(0.28)))
    }
}

private struct CapsuleLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.black))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(.white.opacity(0.15), in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.22)))
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.black))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(AppColors.green.opacity(configuration.isPressed ? 0.82 : 1), in: RoundedRectangle(cornerRadius: 15))
    }
}

private struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.black))
            .foregroundStyle(AppColors.ink)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(.white.opacity(configuration.isPressed ? 0.64 : 0.86), in: RoundedRectangle(cornerRadius: 15))
            .overlay(RoundedRectangle(cornerRadius: 15).stroke(AppColors.line))
    }
}

private struct QuickMinuteStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.black))
            .foregroundStyle(AppColors.ink)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(Color(red: 0.93, green: 0.97, blue: 0.94).opacity(configuration.isPressed ? 0.70 : 1), in: RoundedRectangle(cornerRadius: 13))
            .overlay(RoundedRectangle(cornerRadius: 13).stroke(AppColors.line))
    }
}
