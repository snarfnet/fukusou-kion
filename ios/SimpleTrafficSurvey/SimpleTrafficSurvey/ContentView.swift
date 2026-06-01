import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var viewModel = CameraCounterViewModel()

    var body: some View {
        ZStack {
            IndustrialBackground()

            ScrollView {
                VStack(spacing: 14) {
                    header
                    cameraPanel
                    lineGuide
                    mechanicalCounter
                    controlDeck
                    recentLog
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.requestCameraAccess()
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("簡易歩行者交通量調査")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                Text("カウントライン通過で自動加算")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.62))
            }

            Spacer()

            StatusPill(text: viewModel.statusText, isRunning: viewModel.isRunning)
        }
    }

    private var cameraPanel: some View {
        GeometryReader { proxy in
            ZStack {
                if viewModel.permissionDenied {
                    permissionView
                } else {
                    CameraPreviewView(session: viewModel.session)
                        .overlay(.black.opacity(viewModel.isCameraReady ? 0 : 0.72))

                    if !viewModel.isCameraReady {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(1.15)
                    }
                }

                if viewModel.countMode == .storeTraffic {
                    countLine(size: proxy.size)
                } else {
                    pedestrianModeOverlay
                }
                detectionOverlay(size: proxy.size)
                cameraChrome
            }
        }
        .frame(height: 270)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        )
    }

    private var permissionView: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.fill")
                .font(.system(size: 34, weight: .bold))
            Text("カメラの使用を許可してください")
                .font(.system(size: 15, weight: .bold, design: .rounded))
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label("設定を開く", systemImage: "gearshape.fill")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .buttonStyle(PanelButtonStyle(tint: .orange))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.82))
    }

    private func countLine(size: CGSize) -> some View {
        let linePosition = max(0, min(size.width, size.width * viewModel.lineX))
        let leftLabel = viewModel.countMode == .storeTraffic ? viewModel.directionMode.leftLabel : "\u{901A}\u{884C}"
        let rightLabel = viewModel.countMode == .storeTraffic ? viewModel.directionMode.rightLabel : "\u{901A}\u{884C}"
        let leftColor = sideColor(for: leftLabel)
        let rightColor = sideColor(for: rightLabel)

        return ZStack {
            HStack {
                Text(leftLabel)
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundStyle(leftColor)
                Image(systemName: "arrow.left")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(leftColor)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(rightColor)
                Text(rightLabel)
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundStyle(rightColor)
            }
            .padding(.horizontal, 18)
            .padding(.top, 46)
            .frame(maxHeight: .infinity, alignment: .top)

            Rectangle()
                .fill(.orange)
                .frame(width: 3)
                .shadow(color: .orange.opacity(0.8), radius: 8)
                .position(x: linePosition, y: size.height / 2)

            VStack(spacing: 4) {
                Text("COUNT LINE")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundStyle(.orange)
                Text("ドラッグで移動")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.76))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.black.opacity(0.68), in: Capsule())
            .position(x: linePosition, y: 24)
        }
        .frame(width: size.width, height: size.height)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    viewModel.moveLine(to: value.location.x / max(size.width, 1))
                }
        )
    }

    private var lineGuide: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "line.3.horizontal.decrease.circle.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.countMode.guideText)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text(lineGuideDetail)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.68))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.orange.opacity(0.22), lineWidth: 1)
        )
    }

    private func sideColor(for label: String) -> Color {
        if label == "IN" {
            return .mint
        }
        if label == "\u{901A}\u{884C}" {
            return .yellow
        }
        return .orange
    }

    private var lineGuideDetail: String {
        switch viewModel.countMode {
        case .storeTraffic:
            return viewModel.directionMode.guideText
        case .pedestrianTraffic:
            return "\u{901A}\u{884C}\u{91CF}\u{30E2}\u{30FC}\u{30C9}\u{3067}\u{306F}\u{4E2D}\u{592E}\u{7DDA}\u{306F}\u{4F7F}\u{308F}\u{305A}\u{3001}\u{753B}\u{9762}\u{306B}\u{5165}\u{3063}\u{305F}\u{6B69}\u{884C}\u{8005}\u{3092}TOTAL\u{306B}\u{8A18}\u{9332}\u{3057}\u{307E}\u{3059}\u{3002}"
        }
    }

    private var pedestrianModeOverlay: some View {
        VStack {
            Text("\u{901A}\u{884C}\u{91CF}\u{30E2}\u{30FC}\u{30C9}")
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundStyle(.yellow)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(.black.opacity(0.68), in: Capsule())
                .padding(.top, 10)
            Spacer()
        }
    }

    private func detectionOverlay(size: CGSize) -> some View {
        ZStack {
            ForEach(viewModel.detections) { detection in
                let rect = mappedRect(detection.rect, in: size)
                RoundedRectangle(cornerRadius: 4)
                    .stroke(.mint, lineWidth: 2)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
                    .overlay {
                        Text("\(Int(detection.confidence * 100))")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(.mint, in: Capsule())
                            .position(x: rect.minX + 18, y: rect.minY + 10)
                    }
            }
        }
    }

    private var cameraChrome: some View {
        VStack {
            HStack {
                Label("LIVE", systemImage: "record.circle.fill")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(viewModel.isRunning ? .red : .white.opacity(0.44))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.black.opacity(0.55), in: Capsule())

                Spacer()

                Text("端末内処理")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.74))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.black.opacity(0.55), in: Capsule())
            }
            Spacer()
        }
        .padding(10)
    }

    private var mechanicalCounter: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.68, green: 0.70, blue: 0.68),
                                Color(red: 0.22, green: 0.24, blue: 0.25),
                                Color(red: 0.82, green: 0.82, blue: 0.78)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .black.opacity(0.45), radius: 16, y: 8)

                VStack(spacing: 10) {
                    Text("TOTAL")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundStyle(.black.opacity(0.62))

                    DigitWindow(value: viewModel.total)

                    counterBadges
                }
                .padding(16)
            }
            .frame(height: 178)

            HStack(spacing: 12) {
                ManualButton(label: manualMinusLabel, systemImage: "minus.circle.fill", tint: .red) {
                    viewModel.adjust(manualDirection, amount: -1)
                }
                ClickButton(isRunning: viewModel.isRunning) {
                    viewModel.isRunning ? viewModel.pauseCounting() : viewModel.startCounting()
                }
                ManualButton(label: manualPlusLabel, systemImage: "plus.circle.fill", tint: manualPlusTint) {
                    viewModel.adjust(manualDirection, amount: 1)
                }
            }
        }
    }

    @ViewBuilder
    private var counterBadges: some View {
        if viewModel.countMode == .storeTraffic {
            HStack(spacing: 12) {
                CountBadge(title: "IN", value: viewModel.countIn, color: .mint)
                CountBadge(title: "OUT", value: viewModel.countOut, color: .orange)
            }
        } else {
            HStack(spacing: 12) {
                CountBadge(title: "\u{901A}\u{884C}", value: viewModel.total, color: .yellow)
            }
        }
    }

    private var manualDirection: CountDirection {
        viewModel.countMode == .storeTraffic ? .in : .pedestrian
    }

    private var manualMinusLabel: String {
        viewModel.countMode == .storeTraffic ? "IN -1" : "\u{901A}\u{884C} -1"
    }

    private var manualPlusLabel: String {
        viewModel.countMode == .storeTraffic ? "IN +1" : "\u{901A}\u{884C} +1"
    }

    private var manualPlusTint: Color {
        viewModel.countMode == .storeTraffic ? .mint : .yellow
    }

    private var controlDeck: some View {
        VStack(spacing: 10) {
            Button {
                viewModel.toggleCountMode()
            } label: {
                Label(
                    "\u{8A08}\u{6E2C}\u{30E2}\u{30FC}\u{30C9}: \(viewModel.countMode.title)",
                    systemImage: "slider.horizontal.3"
                )
            }
            .buttonStyle(PanelButtonStyle(tint: .yellow))

            if viewModel.countMode == .storeTraffic {
                Button {
                    viewModel.toggleDirectionMode()
                } label: {
                    Label(
                        viewModel.directionMode == .leftToRightIn ? "IN/OUT方向: 左→右 IN" : "IN/OUT方向: 右→左 IN",
                        systemImage: "arrow.left.arrow.right"
                    )
                }
                .buttonStyle(PanelButtonStyle(tint: .mint))
            }

            HStack(spacing: 10) {
                Button {
                    viewModel.reset()
                } label: {
                    Label("RESET", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(PanelButtonStyle(tint: .gray))

                Button {
                    viewModel.adjust(viewModel.countMode == .storeTraffic ? .out : .pedestrian, amount: 1)
                } label: {
                    Label(viewModel.countMode == .storeTraffic ? "OUT +1" : "\u{901A}\u{884C} +1", systemImage: "arrow.left")
                }
                .buttonStyle(PanelButtonStyle(tint: .orange))

                Button {
                    viewModel.adjust(viewModel.countMode == .storeTraffic ? .out : .pedestrian, amount: -1)
                } label: {
                    Label(viewModel.countMode == .storeTraffic ? "OUT -1" : "\u{901A}\u{884C} -1", systemImage: "minus")
                }
                .buttonStyle(PanelButtonStyle(tint: .red))
            }
        }
        .font(.system(size: 13, weight: .heavy, design: .rounded))
    }

    private var recentLog: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("最近のカウント")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                Spacer()
                Text("簡易推定")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.56))
            }

            if viewModel.recentEvents.isEmpty {
                Text("ラインを越えるとここに記録されます")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.48))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
            } else {
                ForEach(viewModel.recentEvents) { event in
                    HStack {
                        Text(event.direction.rawValue)
                            .font(.system(size: 12, weight: .black, design: .monospaced))
                            .foregroundStyle(eventColor(event.direction))
                        Text(event.timestamp, style: .time)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.72))
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(14)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func eventColor(_ direction: CountDirection) -> Color {
        switch direction {
        case .in:
            return .mint
        case .out:
            return .orange
        case .pedestrian:
            return .yellow
        }
    }

    private func mappedRect(_ rect: CGRect, in size: CGSize) -> CGRect {
        CGRect(
            x: rect.minX * size.width,
            y: (1 - rect.maxY) * size.height,
            width: rect.width * size.width,
            height: rect.height * size.height
        )
    }
}

private struct DigitWindow: View {
    let value: Int

    private var digits: [String] {
        String(format: "%05d", min(value, 99999)).map(String.init)
    }

    var body: some View {
        HStack(spacing: 5) {
            ForEach(Array(digits.enumerated()), id: \.offset) { _, digit in
                Text(digit)
                    .font(.system(size: 36, weight: .black, design: .monospaced))
                    .foregroundStyle(.black)
                    .frame(width: 42, height: 58)
                    .background(
                        LinearGradient(
                            colors: [.white, Color(red: 0.78, green: 0.78, blue: 0.72), .white],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .stroke(.black.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
            }
        }
        .padding(8)
        .background(.black, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .animation(.spring(response: 0.22, dampingFraction: 0.72), value: value)
    }
}

private struct CountBadge: View {
    let title: String
    let value: Int
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundStyle(color)
            Text("\(value)")
                .font(.system(size: 15, weight: .black, design: .monospaced))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.black.opacity(0.62), in: Capsule())
    }
}

private struct ClickButton: View {
    let isRunning: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                    .font(.system(size: 28, weight: .black))
                Text(isRunning ? "PAUSE" : "START")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
            }
            .foregroundStyle(.white)
            .frame(width: 118, height: 78)
            .background(
                RadialGradient(
                    colors: [
                        Color(red: 0.18, green: 0.18, blue: 0.18),
                        Color(red: 0.01, green: 0.01, blue: 0.01)
                    ],
                    center: .top,
                    startRadius: 8,
                    endRadius: 78
                ),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.white.opacity(0.16), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.45), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
    }
}

private struct ManualButton: View {
    let label: String
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .bold))
                Text(label)
                    .font(.system(size: 14, weight: .black, design: .monospaced))
            }
            .foregroundStyle(tint)
            .frame(width: 78, height: 66)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct StatusPill: View {
    let text: String
    let isRunning: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isRunning ? .red : .white.opacity(0.42))
                .frame(width: 8, height: 8)
            Text(text)
                .font(.system(size: 11, weight: .black, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.white.opacity(0.08), in: Capsule())
    }
}

private struct PanelButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.white.opacity(configuration.isPressed ? 0.15 : 0.08), in: RoundedRectangle(cornerRadius: 8))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

private struct IndustrialBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.09, blue: 0.09),
                Color(red: 0.16, green: 0.15, blue: 0.13),
                Color(red: 0.05, green: 0.05, blue: 0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay {
            StripedMetalTexture()
                .opacity(0.24)
                .ignoresSafeArea()
        }
    }
}

private struct StripedMetalTexture: View {
    var body: some View {
        GeometryReader { proxy in
            Path { path in
                let width = proxy.size.width
                let height = proxy.size.height
                var x: CGFloat = -height
                while x < width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x + height, y: height))
                    x += 18
                }
            }
            .stroke(.white.opacity(0.18), lineWidth: 1)
        }
    }
}

#Preview {
    ContentView()
}
