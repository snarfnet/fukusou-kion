import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var audioManager: SleepAudioManager

    @AppStorage("selectedMode") private var selectedModeRaw = SleepMode.three.rawValue
    @AppStorage("chantVolume") private var chantVolume = Double(SoundLayer.chant.defaultVolume)
    @AppStorage("mokugyoVolume") private var mokugyoVolume = Double(SoundLayer.mokugyo.defaultVolume)
    @AppStorage("bellVolume") private var bellVolume = Double(SoundLayer.bell.defaultVolume)
    @AppStorage("rainVolume") private var rainVolume = Double(SoundLayer.rain.defaultVolume)
    @AppStorage("noiseVolume") private var noiseVolume = Double(SoundLayer.noise.defaultVolume)
    @AppStorage("droneVolume") private var droneVolume = Double(SoundLayer.drone.defaultVolume)
    @AppStorage("fadeOutEnabled") private var fadeOutEnabled = true
    @AppStorage("extraDarkEnabled") private var extraDarkEnabled = true

    @State private var showingSettings = false

    private var selectedMode: SleepMode {
        get { SleepMode(rawValue: selectedModeRaw) ?? .three }
        nonmutating set { selectedModeRaw = newValue.rawValue }
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
                PlayingView(settings: settings)
            } else {
                HomeView(
                    selectedMode: Binding(
                        get: { selectedMode },
                        set: { selectedMode = $0 }
                    ),
                    playAction: {
                        audioManager.play(mode: selectedMode, settings: settings)
                    },
                    stopAction: audioManager.stop,
                    settingsAction: { showingSettings = true }
                )
            }
        }
        .onChange(of: settings) { newValue in
            audioManager.update(settings: newValue)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(
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
}

private struct HomeView: View {
    @Binding var selectedMode: SleepMode
    let playAction: () -> Void
    let stopAction: () -> Void
    let settingsAction: () -> Void

    var body: some View {
        VStack(spacing: 26) {
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

            Spacer(minLength: 12)

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

            ModePicker(selectedMode: $selectedMode)
                .padding(.top, 8)

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

            Text("低音の読経、木魚、鐘、雨音、ピンクノイズで、睡眠前のリラックスをサポートします。")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.42))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.top, 6)

            Spacer()
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
    }
}

private struct PlayingView: View {
    @EnvironmentObject private var audioManager: SleepAudioManager
    let settings: MixerSettings

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            BreathingCircle()
                .frame(width: 210, height: 210)
                .opacity(settings.extraDarkEnabled ? 0.56 : 0.72)

            VStack(spacing: 10) {
                Text("ただいま読経中")
                    .font(.title2.weight(.semibold))

                Text(timeText)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
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

    private var timeText: String {
        guard let remaining = audioManager.remainingTime else { return "∞" }
        let seconds = max(0, Int(remaining.rounded()))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

private struct SettingsView: View {
    @EnvironmentObject private var audioManager: SleepAudioManager
    @Binding var chantVolume: Double
    @Binding var mokugyoVolume: Double
    @Binding var bellVolume: Double
    @Binding var rainVolume: Double
    @Binding var noiseVolume: Double
    @Binding var droneVolume: Double
    @Binding var fadeOutEnabled: Bool
    @Binding var extraDarkEnabled: Bool

    @State private var apiKey = KeychainStore.loadAPIKey()
    @State private var ttsText = "摩訶般若波羅蜜多心経。観自在菩薩。深く静かに、息を整えます。"
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
            VolumeSlider(title: "読経音量", value: $chantVolume, icon: "person.wave.2.fill")
            VolumeSlider(title: "木魚音量", value: $mokugyoVolume, icon: "circle.grid.cross.fill")
            VolumeSlider(title: "鐘音量", value: $bellVolume, icon: "bell.fill")
            VolumeSlider(title: "雨音音量", value: $rainVolume, icon: "cloud.rain.fill")
            VolumeSlider(title: "ノイズ音量", value: $noiseVolume, icon: "waveform")
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

            SecureField("OpenAI APIキー", text: $apiKey)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(12)
                .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
                .onChange(of: apiKey) { newValue in
                    KeychainStore.saveAPIKey(newValue)
                }

            TextEditor(text: $ttsText)
                .frame(minHeight: 92)
                .scrollContentBackground(.hidden)
                .padding(10)
                .background(.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))

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
                    Text(isGenerating ? "生成中" : "読経ボイスを生成")
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
        ttsStatus = "生成しています。完了後は読経音として優先再生します。"

        Task {
            do {
                _ = try await OpenAITTSService().generateChant(apiKey: apiKey, text: ttsText)
                await MainActor.run {
                    isGenerating = false
                    ttsStatus = "生成しました。再生時はこのMP3を使います。"
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
