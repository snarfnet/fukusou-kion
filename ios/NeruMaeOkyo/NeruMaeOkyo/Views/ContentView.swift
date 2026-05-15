import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var audioManager: SleepAudioManager

    @AppStorage("selectedMode") private var selectedModeRaw = SleepMode.three.rawValue
    @AppStorage("selectedGuideID") private var selectedGuideID = PriestGuide.all[0].id
    @AppStorage("chantVolume") private var chantVolume = Double(SoundLayer.chant.defaultVolume)
    @AppStorage("mokugyoVolume") private var mokugyoVolume = Double(SoundLayer.mokugyo.defaultVolume)
    @AppStorage("bellVolume") private var bellVolume = Double(SoundLayer.bell.defaultVolume)
    @AppStorage("rainVolume") private var rainVolume = Double(SoundLayer.rain.defaultVolume)
    @AppStorage("noiseVolume") private var noiseVolume = Double(SoundLayer.noise.defaultVolume)
    @AppStorage("droneVolume") private var droneVolume = Double(SoundLayer.drone.defaultVolume)
    @AppStorage("fadeOutEnabled") private var fadeOutEnabled = true
    @AppStorage("extraDarkEnabled") private var extraDarkEnabled = true
    @AppStorage("audioPresetVersion") private var audioPresetVersion = 0

    @State private var showingSettings = false

    private var selectedMode: SleepMode {
        get { SleepMode(rawValue: selectedModeRaw) ?? .three }
        nonmutating set { selectedModeRaw = newValue.rawValue }
    }

    private var selectedGuide: PriestGuide {
        get { PriestGuide.guide(for: selectedGuideID) }
        nonmutating set { selectedGuideID = newValue.id }
    }

    private var settings: MixerSettings {
        MixerSettings(
            chantVolume: Float(chantVolume),
            mokugyoVolume: Float(mokugyoVolume),
            bellVolume: Float(bellVolume),
            rainVolume: Float(rainVolume),
            noiseVolume: Float(noiseVolume),
            droneVolume: Float(droneVolume),
            fadeOutEnabled: fadeOutEnabled,
            extraDarkEnabled: extraDarkEnabled
        )
    }

    var body: some View {
        ZStack {
            SleepTheme.background(extraDark: extraDarkEnabled)
                .ignoresSafeArea()

            if audioManager.isPlaying {
                PlayingView(settings: settings, guide: audioManager.currentGuide)
            } else {
                HomeView(
                    selectedMode: Binding(get: { selectedMode }, set: { selectedMode = $0 }),
                    selectedGuide: Binding(get: { selectedGuide }, set: { selectedGuide = $0 }),
                    playAction: {
                        audioManager.play(mode: selectedMode, settings: settings, guide: selectedGuide)
                    },
                    stopAction: audioManager.stop,
                    settingsAction: { showingSettings = true }
                )
            }
        }
        .onAppear {
            applyQuietPresetIfNeeded()
        }
        .onChange(of: settings) { _, newValue in
            audioManager.update(settings: newValue)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(
                selectedGuide: selectedGuide,
                chantVolume: $chantVolume,
                mokugyoVolume: $mokugyoVolume,
                bellVolume: $bellVolume,
                rainVolume: $rainVolume,
                noiseVolume: $noiseVolume,
                droneVolume: $droneVolume,
                fadeOutEnabled: $fadeOutEnabled,
                extraDarkEnabled: $extraDarkEnabled
            )
            .environmentObject(audioManager)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private func applyQuietPresetIfNeeded() {
        guard audioPresetVersion < 4 else { return }

        chantVolume = Double(SoundLayer.chant.defaultVolume)
        mokugyoVolume = Double(SoundLayer.mokugyo.defaultVolume)
        bellVolume = Double(SoundLayer.bell.defaultVolume)
        rainVolume = Double(SoundLayer.rain.defaultVolume)
        noiseVolume = Double(SoundLayer.noise.defaultVolume)
        droneVolume = Double(SoundLayer.drone.defaultVolume)
        fadeOutEnabled = true
        extraDarkEnabled = true
        audioPresetVersion = 4
    }
}

private struct HomeView: View {
    @Binding var selectedMode: SleepMode
    @Binding var selectedGuide: PriestGuide
    let playAction: () -> Void
    let stopAction: () -> Void
    let settingsAction: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                HStack {
                    Spacer()
                    Button(action: settingsAction) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 44, height: 44)
                            .foregroundStyle(.white.opacity(0.78))
                            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
                    }
                    .accessibilityLabel("設定")
                }

                VStack(spacing: 12) {
                    Text("寝る前に聞くお経")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)

                    Text("3分で寺に沈む。")
                        .font(.headline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.62))
                }
                .padding(.top, 8)

                GuidePicker(selectedGuide: $selectedGuide)

                ModePicker(selectedMode: $selectedMode)

                VStack(spacing: 14) {
                    Button(action: playAction) {
                        Label("再生", systemImage: "play.fill")
                            .font(.title2.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 64)
                    }
                    .buttonStyle(PrimarySleepButtonStyle())

                    Button(action: stopAction) {
                        Label("停止", systemImage: "stop.fill")
                            .font(.headline.weight(.bold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                    }
                    .buttonStyle(SecondarySleepButtonStyle())
                }

                Text("低く響く読経、遠い鐘、低音ドローンで、睡眠前のリラックスをサポートします。")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.42))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
        }
    }
}

private struct PlayingView: View {
    @EnvironmentObject private var audioManager: SleepAudioManager
    let settings: MixerSettings
    let guide: PriestGuide

    var body: some View {
        TimelineView(.animation) { timeline in
            VStack(spacing: 20) {
                Spacer(minLength: 24)

                Image(guide.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 132, height: 132)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white.opacity(0.16), lineWidth: 1))
                    .shadow(color: .black.opacity(0.45), radius: 18, y: 10)

                BreathingCircle()
                    .frame(width: 150, height: 150)
                    .opacity(settings.extraDarkEnabled ? 0.40 : 0.58)
                    .overlay(
                        Text(currentLine(at: timeline.date))
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.86))
                            .multilineTextAlignment(.center)
                            .lineSpacing(5)
                            .padding(.horizontal, 18)
                            .minimumScaleFactor(0.72)
                            .id(currentLine(at: timeline.date))
                            .transition(.opacity)
                    )

                VStack(spacing: 8) {
                    Text("\(guide.name) ただいま読経中")
                        .font(.headline.weight(.semibold))

                    Text(timeText)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.88))
                }

                Text(audioManager.currentMode == .infinite ? "停止するまで静かに流れます" : "終了30秒前から、ゆっくり音を下げます")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white.opacity(0.44))
                    .multilineTextAlignment(.center)

                Spacer()

                Button {
                    audioManager.stop()
                } label: {
                    Label("停止", systemImage: "stop.fill")
                        .font(.headline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                }
                .buttonStyle(SecondarySleepButtonStyle())
                .padding(.horizontal, 22)
                .padding(.bottom, 18)
            }
        }
    }

    private var timeText: String {
        guard let remaining = audioManager.remainingTime else { return "∞" }
        let seconds = max(0, Int(remaining.rounded()))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private func currentLine(at date: Date) -> String {
        guard !guide.displayLines.isEmpty else { return guide.speechText }
        let elapsed = audioManager.sessionStartedAt.map { date.timeIntervalSince($0) } ?? 0
        let index = Int(max(0, elapsed) / 7) % guide.displayLines.count
        return guide.displayLines[index]
    }
}

private struct SettingsView: View {
    @EnvironmentObject private var audioManager: SleepAudioManager
    let selectedGuide: PriestGuide
    @Binding var chantVolume: Double
    @Binding var mokugyoVolume: Double
    @Binding var bellVolume: Double
    @Binding var rainVolume: Double
    @Binding var noiseVolume: Double
    @Binding var droneVolume: Double
    @Binding var fadeOutEnabled: Bool
    @Binding var extraDarkEnabled: Bool

    @State private var apiKey = KeychainStore.loadAPIKey()
    @State private var customText = ""
    @State private var ttsStatus = "AI生成音声を使う場合があります。人の声ではありません。"
    @State private var isGenerating = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    mixerSection
                    behaviorSection
                    openAISection
                }
                .padding(20)
            }
            .background(SleepTheme.background(extraDark: false).ignoresSafeArea())
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var mixerSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel("ミキサー")
            VolumeSlider(title: "声の音量", value: $chantVolume, icon: "person.wave.2.fill")
            VolumeSlider(title: "鐘音量", value: $bellVolume, icon: "bell.fill")
            VolumeSlider(title: "低音ドローン", value: $droneVolume, icon: "speaker.wave.2.fill")
        }
        .padding(16)
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 8))
    }

    private var behaviorSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel("睡眠設定")
            Toggle("フェードアウト", isOn: $fadeOutEnabled)
            Toggle("画面を暗くする", isOn: $extraDarkEnabled)
        }
        .font(.body.weight(.medium))
        .tint(.yellow.opacity(0.78))
        .padding(16)
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 8))
    }

    private var openAISection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel("OpenAI TTS")

            HStack(spacing: 12) {
                Image(selectedGuide.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 54, height: 54)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedGuide.name)
                        .font(.headline.weight(.bold))
                    Text(selectedGuide.voiceDescription)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.56))
                }
                Spacer()
            }

            SecureField("OpenAI APIキー", text: $apiKey)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(12)
                .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
                .onChange(of: apiKey) { _, newValue in
                    KeychainStore.saveAPIKey(newValue)
                }

            TextEditor(text: $customText)
                .frame(minHeight: 92)
                .scrollContentBackground(.hidden)
                .padding(10)
                .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
                .overlay(alignment: .topLeading) {
                    if customText.isEmpty {
                        Text(selectedGuide.speechText)
                            .font(.body)
                            .foregroundStyle(.white.opacity(0.28))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 18)
                            .allowsHitTesting(false)
                    }
                }

            Button {
                generateSpeech()
            } label: {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .tint(.black)
                    } else {
                        Image(systemName: "wand.and.stars")
                    }
                    Text(isGenerating ? "生成中" : "\(selectedGuide.name)の声を生成")
                }
                .font(.headline.weight(.bold))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            .buttonStyle(PrimarySleepButtonStyle())
            .disabled(isGenerating)

            Text(ttsStatus)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.48))
                .lineSpacing(3)
        }
        .padding(16)
        .background(.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 8))
    }

    private func generateSpeech() {
        isGenerating = true
        ttsStatus = "生成しています。完了後は選択中の住職の声として優先再生します。"

        Task {
            do {
                let text = customText.trimmingCharacters(in: .whitespacesAndNewlines)
                _ = try await OpenAITTSService().generateChant(
                    apiKey: apiKey,
                    guide: selectedGuide,
                    text: text.isEmpty ? nil : text
                )
                await MainActor.run {
                    isGenerating = false
                    ttsStatus = "生成しました。次の再生からこの声を使います。"
                    audioManager.refreshChantPlayerIfNeeded()
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    ttsStatus = error.localizedDescription
                }
            }
        }
    }
}

private struct GuidePicker: View {
    @Binding var selectedGuide: PriestGuide

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionLabel("住職を選ぶ")
                Spacer()
                Label("右へスクロール", systemImage: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.44))
                    .labelStyle(.titleAndIcon)
            }
            .padding(.horizontal, 2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(PriestGuide.all) { guide in
                        Button {
                            selectedGuide = guide
                        } label: {
                            VStack(spacing: 8) {
                                Image(guide.imageName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 72, height: 72)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(selectedGuide == guide ? .white.opacity(0.82) : .white.opacity(0.12), lineWidth: selectedGuide == guide ? 2 : 1))

                                Text(guide.name)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white.opacity(0.88))
                                    .lineLimit(1)

                                Text(guide.role)
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(.white.opacity(0.48))
                                    .lineLimit(1)
                            }
                            .frame(width: 94, height: 128)
                            .background(selectedGuide == guide ? .white.opacity(0.11) : .white.opacity(0.045), in: RoundedRectangle(cornerRadius: 8))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(selectedGuide == guide ? .white.opacity(0.22) : .white.opacity(0.08)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

private struct ModePicker: View {
    @Binding var selectedMode: SleepMode

    var body: some View {
        HStack(spacing: 8) {
            ForEach(SleepMode.allCases) { mode in
                Button {
                    selectedMode = mode
                } label: {
                    Text(mode.title)
                        .font(.headline.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .foregroundStyle(selectedMode == mode ? .black : .white.opacity(0.72))
                .background(
                    selectedMode == mode ? .white.opacity(0.86) : .white.opacity(0.07),
                    in: RoundedRectangle(cornerRadius: 8)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.white.opacity(selectedMode == mode ? 0 : 0.12))
                )
            }
        }
    }
}

private struct BreathingCircle: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let pulse = 0.5 + 0.5 * sin(t / 3.2)
            let scale = 0.88 + pulse * 0.16

            ZStack {
                Circle()
                    .fill(.white.opacity(0.035))
                    .scaleEffect(scale + 0.16)
                Circle()
                    .stroke(.white.opacity(0.14), lineWidth: 1)
                    .scaleEffect(scale)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white.opacity(0.14), .white.opacity(0.02), .clear],
                            center: .center,
                            startRadius: 12,
                            endRadius: 110
                        )
                    )
                    .scaleEffect(scale)
            }
            .animation(.easeInOut(duration: 2.4), value: scale)
        }
    }
}

private struct VolumeSlider: View {
    let title: String
    @Binding var value: Double
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(Int(value * 100))")
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(.white.opacity(0.52))
            }

            Slider(value: $value, in: 0...1)
                .tint(.yellow.opacity(0.72))
        }
    }
}

private struct SectionLabel: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.caption.weight(.bold))
            .foregroundStyle(.white.opacity(0.54))
            .textCase(.uppercase)
            .tracking(1.2)
    }
}

private enum SleepTheme {
    static func background(extraDark: Bool) -> some View {
        ZStack {
            Color.black
            LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.02, blue: 0.024),
                    Color(red: 0.005, green: 0.005, blue: 0.007),
                    .black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            if extraDark {
                Color.black.opacity(0.46)
            }
        }
    }
}

private struct PrimarySleepButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.black)
            .background(.white.opacity(configuration.isPressed ? 0.68 : 0.88), in: RoundedRectangle(cornerRadius: 8))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

private struct SecondarySleepButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white.opacity(0.82))
            .background(.white.opacity(configuration.isPressed ? 0.10 : 0.055), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.12)))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

#Preview {
    ContentView()
        .environmentObject(SleepAudioManager())
}
