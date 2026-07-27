import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var audio = AudioTransformer()
    @State private var bpm = 174.0
    @State private var style: DNBStyle = .jungle
    @State private var showingImporter = false
    @State private var pulse = false

    private let ink = Color(red: 0.055, green: 0.06, blue: 0.12)
    private let panel = Color(red: 0.095, green: 0.10, blue: 0.18)
    private let violet = Color(red: 0.67, green: 0.43, blue: 0.91)
    private let amber = Color(red: 0.96, green: 0.66, blue: 0.27)

    var body: some View {
        ZStack {
            ink.ignoresSafeArea()
            backgroundGrid

            ScrollView {
                VStack(spacing: 22) {
                    header
                    sourcePanel
                    tempoPanel
                    stylePicker
                    actionPanel
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 34)
            }
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                Task { await audio.load(url: url) }
            }
        }
    }

    private var backgroundGrid: some View {
        Canvas { context, size in
            let spacing: CGFloat = 28
            var path = Path()
            for x in stride(from: 0, through: size.width, by: spacing) {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }
            for y in stride(from: 0, through: size.height, by: spacing) {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
            context.stroke(path, with: .color(.white.opacity(0.025)), lineWidth: 0.5)
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("CHOP")
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .tracking(-1.5)
                Text("// 170")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(amber)
            }
            Spacer()
            Text("DNB GENERATOR")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .tracking(1.5)
                .foregroundStyle(.white.opacity(0.48))
        }
    }

    private var sourcePanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label(audio.sourceURL == nil ? "音を入れる" : audio.sourceName, systemImage: "waveform")
                    .font(.system(size: 15, weight: .bold))
                    .lineLimit(1)
                Spacer()
                if audio.duration > 0 {
                    Text(durationText)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.55))
                }
            }

            WaveformView(samples: audio.waveform, tint: audio.sourceURL == nil ? .white.opacity(0.22) : style.color)
                .frame(height: 94)

            HStack(spacing: 10) {
                Button {
                    showingImporter = true
                } label: {
                    Label(audio.sourceURL == nil ? "ファイルを選ぶ" : "別の音を選ぶ", systemImage: "folder")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                }
                .buttonStyle(OutlineButtonStyle())
                .disabled(audio.isRecording)

                Button {
                    Task { await audio.toggleRecording() }
                } label: {
                    Label(audio.isRecording ? "停止" : "録音",
                          systemImage: audio.isRecording ? "stop.fill" : "mic.fill")
                        .frame(minWidth: 72)
                        .padding(.vertical, 13)
                }
                .buttonStyle(RecordingButtonStyle(isRecording: audio.isRecording, color: amber))
            }

            if audio.isRecording {
                HStack(spacing: 8) {
                    Circle()
                        .fill(amber)
                        .frame(width: 7, height: 7)
                    Text("録音中")
                        .fontWeight(.bold)
                    Spacer()
                    Text(recordingDurationText)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                }
                .font(.system(size: 12))
                .foregroundStyle(amber)
                .accessibilityElement(children: .combine)
            }
        }
        .panelStyle(panel)
    }

    private var tempoPanel: some View {
        VStack(spacing: 15) {
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TEMPO")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .tracking(1.6)
                        .foregroundStyle(.white.opacity(0.48))
                    HStack(alignment: .lastTextBaseline, spacing: 7) {
                        Text("\(Int(bpm))")
                            .font(.system(size: 56, weight: .black, design: .rounded))
                            .contentTransition(.numericText())
                        Text("BPM")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(amber)
                            .padding(.bottom, 9)
                    }
                }
                Spacer()
                Button {
                    bpm = 174
                } label: {
                    Text("174")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .padding(10)
                        .background(.white.opacity(0.07), in: Circle())
                }
                .foregroundStyle(.white.opacity(0.7))
            }

            Slider(value: $bpm, in: 140...190, step: 1)
                .tint(amber)

            HStack {
                Text("140")
                Spacer()
                Text("HALF-TIME")
                    .foregroundStyle(amber.opacity(0.8))
                Spacer()
                Text("190")
            }
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundStyle(.white.opacity(0.38))
        }
        .panelStyle(panel)
    }

    private var stylePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("スタイル")
                .font(.system(size: 13, weight: .bold))

            HStack(spacing: 9) {
                ForEach(DNBStyle.allCases) { item in
                    Button {
                        withAnimation(.snappy) { style = item }
                    } label: {
                        VStack(spacing: 7) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 8, height: 8)
                                .shadow(color: item.color, radius: style == item ? 8 : 0)
                            Text(item.rawValue)
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            style == item ? item.color.opacity(0.14) : .white.opacity(0.035),
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(style == item ? item.color.opacity(0.7) : .white.opacity(0.06))
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                }
            }

            Text(style.subtitle)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.48))
        }
    }

    @ViewBuilder
    private var actionPanel: some View {
        switch audio.state {
        case .rendering(let progress):
            VStack(spacing: 15) {
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.08), lineWidth: 5)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(style.color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(style.color)
                }
                .frame(width: 76, height: 76)
                Text("刻んでいます…")
                    .font(.system(size: 16, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 26)

        case .complete:
            VStack(spacing: 12) {
                Button(action: audio.togglePlayback) {
                    Label(audio.isPlaying ? "一時停止" : "生成した音を聴く",
                          systemImage: audio.isPlaying ? "pause.fill" : "play.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                }
                .buttonStyle(FilledButtonStyle(color: style.color))

                if let outputURL = audio.outputURL {
                    ShareLink(item: outputURL) {
                        Label("WAVを書き出す", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                    }
                    .buttonStyle(OutlineButtonStyle())
                }

                Button("同じ音でもう一度作る") {
                    Task { await audio.transform(bpm: Int(bpm), style: style) }
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.58))
                .padding(.top, 4)
            }

        case .failed(let message):
            VStack(spacing: 12) {
                Text(message)
                    .font(.system(size: 13))
                    .foregroundStyle(.red.opacity(0.85))
                transformButton
            }

        default:
            transformButton
        }
    }

    private var transformButton: some View {
        Button {
            Task { await audio.transform(bpm: Int(bpm), style: style) }
        } label: {
            HStack {
                Image(systemName: "scissors")
                Text("DnBにする")
                Spacer()
                Text("\(Int(bpm)) BPM")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .opacity(0.65)
            }
            .font(.system(size: 17, weight: .black))
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
        }
        .buttonStyle(FilledButtonStyle(color: style.color))
        .disabled(audio.sourceURL == nil)
        .opacity(audio.sourceURL == nil ? 0.38 : 1)
    }

    private var durationText: String {
        let total = Int(audio.duration)
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    private var recordingDurationText: String {
        let total = Int(audio.recordingDuration)
        let tenths = Int((audio.recordingDuration * 10).rounded(.down)) % 10
        return String(format: "%d:%02d.%d", total / 60, total % 60, tenths)
    }
}

private struct WaveformView: View {
    let samples: [CGFloat]
    let tint: Color

    var body: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = 2
            let width = max(1, (geometry.size.width - CGFloat(samples.count - 1) * spacing) / CGFloat(samples.count))
            HStack(alignment: .center, spacing: spacing) {
                ForEach(Array(samples.enumerated()), id: \.offset) { index, sample in
                    Capsule()
                        .fill(index % 4 == 0 ? tint : tint.opacity(0.58))
                        .frame(width: width, height: max(4, geometry.size.height * sample))
                }
            }
        }
        .accessibilityLabel("読み込んだ音の波形")
    }
}

private struct FilledButtonStyle: ButtonStyle {
    let color: Color
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color(red: 0.055, green: 0.06, blue: 0.12))
            .background(color.opacity(configuration.isPressed ? 0.72 : 1), in: RoundedRectangle(cornerRadius: 15))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

private struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white.opacity(configuration.isPressed ? 0.55 : 0.82))
            .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 13))
            .overlay {
                RoundedRectangle(cornerRadius: 13)
                    .stroke(.white.opacity(0.1))
            }
    }
}

private struct RecordingButtonStyle: ButtonStyle {
    let isRecording: Bool
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(isRecording ? Color(red: 0.055, green: 0.06, blue: 0.12) : color)
            .background(
                isRecording ? color.opacity(configuration.isPressed ? 0.72 : 1) : color.opacity(0.09),
                in: RoundedRectangle(cornerRadius: 13)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 13)
                    .stroke(color.opacity(isRecording ? 1 : 0.48))
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

private extension View {
    func panelStyle(_ color: Color) -> some View {
        padding(18)
            .background(color.opacity(0.92), in: RoundedRectangle(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.055))
            }
    }
}

#Preview {
    ContentView()
}
