import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var viewModel = CandidateDetectorViewModel()

    var body: some View {
        ZStack {
            ForestBackground()

            ScrollView {
                VStack(spacing: 14) {
                    header
                    cameraPanel
                    resultPanel
                    controlPanel
                    guidePanel
                    recentLog
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 28)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.requestCameraAccess()
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(UIStrings.title)
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                Text(UIStrings.subtitle)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.66))
            }

            Spacer()

            StatusPill(text: viewModel.statusText, active: viewModel.isScanning)
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

                scannerOverlay(size: proxy.size)
                cameraChrome
            }
        }
        .frame(height: 310)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(viewModel.hasCandidate ? .cyan : .white.opacity(0.18), lineWidth: 1.5)
        )
    }

    private var permissionView: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.fill")
                .font(.system(size: 34, weight: .bold))
            Text(UIStrings.cameraPermission)
                .font(.system(size: 15, weight: .bold, design: .rounded))
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Label(UIStrings.openSettings, systemImage: "gearshape.fill")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
            }
            .buttonStyle(PanelButtonStyle(tint: .cyan))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.82))
    }

    private func scannerOverlay(size: CGSize) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(viewModel.hasCandidate ? .cyan : .white.opacity(0.45), style: StrokeStyle(lineWidth: 3, dash: [34, 18]))
                .frame(width: size.width * 0.72, height: size.height * 0.56)
                .shadow(color: .cyan.opacity(viewModel.hasCandidate ? 0.75 : 0.18), radius: 14)

            if viewModel.hasCandidate {
                Image(systemName: "scope")
                    .font(.system(size: 58, weight: .bold))
                    .foregroundStyle(.cyan.opacity(0.9))
                    .shadow(color: .cyan.opacity(0.8), radius: 12)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.hasCandidate)
    }

    private var cameraChrome: some View {
        VStack {
            HStack {
                Label("LIVE", systemImage: "record.circle.fill")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(viewModel.isScanning ? .red : .white.opacity(0.44))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.black.opacity(0.55), in: Capsule())

                Spacer()

                Text(UIStrings.onDevice)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.76))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.black.opacity(0.55), in: Capsule())
            }
            Spacer()
        }
        .padding(10)
    }

    private var resultPanel: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(viewModel.candidateLabel)
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                    Text("\(UIStrings.confidence) \(viewModel.confidenceLabel)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.66))
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.16), lineWidth: 10)
                    Circle()
                        .trim(from: 0, to: viewModel.candidateConfidence)
                        .stroke(viewModel.hasCandidate ? .cyan : .green, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text(viewModel.confidenceLabel)
                        .font(.system(size: 15, weight: .black, design: .rounded))
                }
                .frame(width: 82, height: 82)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label(UIStrings.threshold, systemImage: "slider.horizontal.3")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                    Spacer()
                    Text(viewModel.thresholdLabel)
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(.cyan)
                }

                Slider(value: $viewModel.threshold, in: 0.55...0.95)
                    .tint(.cyan)
            }
        }
        .padding(14)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.cyan.opacity(0.22), lineWidth: 1)
        )
    }

    private var controlPanel: some View {
        HStack(spacing: 12) {
            Button {
                viewModel.isScanning ? viewModel.pauseScanning() : viewModel.startScanning()
            } label: {
                Label(viewModel.isScanning ? UIStrings.pause : UIStrings.start, systemImage: viewModel.isScanning ? "pause.fill" : "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PanelButtonStyle(tint: .cyan))

            Button {
                viewModel.resetLog()
            } label: {
                Label(UIStrings.reset, systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PanelButtonStyle(tint: .white))
        }
    }

    private var guidePanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(UIStrings.howToUse, systemImage: "leaf.fill")
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(.cyan)

            Text(UIStrings.guide)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.78))
                .lineSpacing(3)

            Text(UIStrings.disclaimer)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.58))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var recentLog: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(UIStrings.logTitle)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                Spacer()
                Text("\(viewModel.recentEvents.count)\(UIStrings.countSuffix)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(.cyan)
            }

            if viewModel.recentEvents.isEmpty {
                Text(UIStrings.emptyLog)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            } else {
                ForEach(viewModel.recentEvents) { event in
                    HStack {
                        Label(event.timestamp.formatted(date: .omitted, time: .standard), systemImage: "scope")
                        Spacer()
                        Text("\(Int(event.confidence * 100))%")
                    }
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.78))
                    .padding(.vertical, 7)
                    .padding(.horizontal, 10)
                    .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
        }
        .padding(14)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct ForestBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.02, green: 0.05, blue: 0.05),
                Color(red: 0.04, green: 0.12, blue: 0.11),
                Color(red: 0.01, green: 0.02, blue: 0.03)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay {
            VStack {
                Color.cyan.opacity(0.08)
                    .frame(height: 180)
                    .blur(radius: 60)
                Spacer()
            }
            .ignoresSafeArea()
        }
    }
}

private struct StatusPill: View {
    let text: String
    let active: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(active ? .red : .white.opacity(0.5))
                .frame(width: 8, height: 8)
            Text(text)
                .font(.system(size: 12, weight: .black, design: .rounded))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(.white.opacity(0.1), in: Capsule())
    }
}

private struct PanelButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .heavy, design: .rounded))
            .foregroundStyle(.black)
            .padding(.vertical, 13)
            .background(tint.opacity(configuration.isPressed ? 0.72 : 1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

private enum UIStrings {
    static let title = "\u{30C4}\u{30C1}\u{30CE}\u{30B3}\u{5019}\u{88DC}\u{63A2}\u{77E5}"
    static let subtitle = "\u{5C71}\u{9053}\u{3084}\u{8349}\u{3080}\u{3089}\u{306E}\u{6620}\u{50CF}\u{304B}\u{3089}\u{5019}\u{88DC}\u{3092}\u{63A2}\u{3059}"
    static let cameraPermission = "\u{30AB}\u{30E1}\u{30E9}\u{306E}\u{4F7F}\u{7528}\u{3092}\u{8A31}\u{53EF}\u{3057}\u{3066}\u{304F}\u{3060}\u{3055}\u{3044}"
    static let openSettings = "\u{8A2D}\u{5B9A}\u{3092}\u{958B}\u{304F}"
    static let onDevice = "\u{7AEF}\u{672B}\u{5185}\u{89E3}\u{6790}"
    static let confidence = "\u{4FE1}\u{983C}\u{5EA6}"
    static let threshold = "\u{5019}\u{88DC}\u{5224}\u{5B9A}\u{30E9}\u{30A4}\u{30F3}"
    static let start = "\u{958B}\u{59CB}"
    static let pause = "\u{505C}\u{6B62}"
    static let reset = "\u{30EA}\u{30BB}\u{30C3}\u{30C8}"
    static let howToUse = "\u{4F7F}\u{3044}\u{65B9}"
    static let guide = "\u{5730}\u{9762}\u{304C}\u{898B}\u{3048}\u{308B}\u{3088}\u{3046}\u{306B}\u{56FA}\u{5B9A}\u{3057}\u{3001}\u{8349}\u{3080}\u{3089}\u{3084}\u{5C71}\u{9053}\u{3092}\u{3086}\u{3063}\u{304F}\u{308A}\u{6620}\u{3057}\u{3066}\u{304F}\u{3060}\u{3055}\u{3044}\u{3002}\u{5019}\u{88DC}\u{304C}\u{51FA}\u{305F}\u{3089}\u{753B}\u{9762}\u{3060}\u{3051}\u{3067}\u{65AD}\u{5B9A}\u{305B}\u{305A}\u{3001}\u{5468}\u{56F2}\u{306E}\u{72B6}\u{6CC1}\u{3068}\u{6620}\u{50CF}\u{3092}\u{898B}\u{3066}\u{78BA}\u{8A8D}\u{3057}\u{3066}\u{304F}\u{3060}\u{3055}\u{3044}\u{3002}"
    static let disclaimer = "\u{679D}\u{3001}\u{6839}\u{3001}\u{30DB}\u{30FC}\u{30B9}\u{3001}\u{666E}\u{901A}\u{306E}\u{30D8}\u{30D3}\u{3001}\u{5F71}\u{3092}\u{5019}\u{88DC}\u{3068}\u{3057}\u{3066}\u{62FE}\u{3046}\u{5834}\u{5408}\u{304C}\u{3042}\u{308A}\u{307E}\u{3059}\u{3002}"
    static let logTitle = "\u{5019}\u{88DC}\u{30ED}\u{30B0}"
    static let countSuffix = "\u{4EF6}"
    static let emptyLog = "\u{307E}\u{3060}\u{5019}\u{88DC}\u{306F}\u{3042}\u{308A}\u{307E}\u{305B}\u{3093}"
}
