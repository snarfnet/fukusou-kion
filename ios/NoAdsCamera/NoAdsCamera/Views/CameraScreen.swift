import SwiftUI

struct CameraScreen: View {
    @StateObject private var camera = CameraController()
    @StateObject private var soundShutter = SoundShutterEngine()
    @StateObject private var director = CameraDirectorEngine()
    @StateObject private var purposePro = PurposeProEngine()
    @State private var focusPoint: CGPoint?
    @State private var showsFeatureHelp = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { proxy in
                CameraPreview(session: camera.session)
                    .ignoresSafeArea()
                    .overlay(GridOverlay().opacity(camera.selectedMode == .zen ? 0.18 : 0.28))
                    .overlay(modeOverlay)
                    .contentShape(Rectangle())
                    .gesture(
                        SpatialTapGesture()
                            .onEnded { value in
                                focusPoint = value.location
                                camera.focus(at: value.location, in: proxy.size)
                            }
                    )

                if let focusPoint {
                    FocusRing()
                        .position(focusPoint)
                        .transition(.scale.combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    self.focusPoint = nil
                                }
                            }
                        }
                }
            }

            VStack(spacing: 0) {
                topBar
                capabilityStrip
                Spacer()
                bottomPanel
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 22)
        }
        .task {
            soundShutter.onTrigger = {
                camera.capturePhoto()
            }
            camera.requestAccessAndStart()
        }
        .onChange(of: camera.selectedMode) { _, mode in
            if mode == .sound {
                soundShutter.start()
            } else {
                soundShutter.stop()
            }
            if mode == .purposePro {
                camera.applyPurposeGuide(purposePro.currentGuide)
            }
        }
        .onChange(of: camera.bestShotScore) { _, _ in
            updateDirector()
        }
        .onChange(of: camera.realtimeWarnings) { _, _ in
            updateDirector()
        }
        .onChange(of: purposePro.selectedPreset) { _, _ in
            camera.applyPurposeGuide(purposePro.currentGuide)
        }
        .sheet(isPresented: $showsFeatureHelp) {
            FeatureHelpSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "app_name"))
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                Text(camera.statusText)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
            }

            Spacer()

            Button {
                showsFeatureHelp = true
            } label: {
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 22, weight: .bold))
                    .frame(width: 42, height: 42)
                    .background(.black.opacity(0.45), in: Circle())
            }
            .accessibilityLabel("機能説明")
        }
        .foregroundStyle(.white)
        .shadow(radius: 10)
    }

    private var bottomPanel: some View {
        VStack(spacing: 16) {
            if camera.selectedMode == .strongShake {
                ShakeMeter(level: camera.shakeLevel, message: camera.shakeMessage)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            if camera.selectedMode == .auto || camera.selectedMode == .rawMaterial || camera.selectedMode == .hdrBracket || camera.selectedMode == .nightStack {
                MomentCaptureBadge(camera: camera)
            }
            if !camera.realtimeWarnings.isEmpty {
                RealtimeWarningStrip(warnings: camera.realtimeWarnings, score: camera.bestShotScore)
            }
            if camera.selectedMode == .sound {
                SoundShutterBadge(engine: soundShutter)
            }
            if camera.selectedMode == .director {
                CameraDirectorBadge(engine: director)
            }
            if camera.selectedMode == .purposePro {
                PurposeProPanel(engine: purposePro, exposureMessage: camera.semanticExposureMessage)
            }

            modePicker

            HStack(alignment: .center) {
                thumbnail

                Spacer()

                Button {
                    camera.capturePhoto()
                } label: {
                    ZStack {
                        Circle()
                            .stroke(.white.opacity(0.9), lineWidth: 4)
                            .frame(width: 76, height: 76)
                        Circle()
                            .fill(camera.isSaving ? .white.opacity(0.55) : .white)
                            .frame(width: 58, height: 58)
                    }
                }
                .disabled(camera.isSaving)
                .accessibilityLabel("撮影")

                Spacer()

                Button {
                    camera.selectedMode = .strongShake
                } label: {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 21, weight: .bold))
                        .frame(width: 48, height: 48)
                        .background(.black.opacity(0.5), in: Circle())
                        .foregroundStyle(camera.selectedMode == .strongShake ? .mint : .white)
                }
                .accessibilityLabel("最強手ブレ")
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.86), value: camera.selectedMode)
    }

    private var capabilityStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                CapabilityPill(title: "ZSL", isOn: camera.supportsZeroShutterLag)
                CapabilityPill(title: "FAST", isOn: camera.supportsFastCapture)
                CapabilityPill(title: "DEF", isOn: camera.supportsDeferredDelivery)
                CapabilityPill(title: "RAW", isOn: camera.supportsRAW)
                CapabilityPill(title: "DEPTH", isOn: camera.supportsDepth)
                CapabilityPill(title: "MATTE", isOn: camera.supportsPortraitMatte)
            }
            .padding(.top, 10)
        }
    }

    private var modePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CameraMode.allCases) { mode in
                    Button {
                        camera.selectedMode = mode
                    } label: {
                        VStack(spacing: 3) {
                            Text(mode.title)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                            Text(mode.caption)
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .lineLimit(1)
                        }
                        .foregroundStyle(camera.selectedMode == mode ? .black : .white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(camera.selectedMode == mode ? .white : .black.opacity(0.42), in: Capsule())
                    }
                    .accessibilityLabel(mode.title)
                }
            }
            .padding(.horizontal, 1)
        }
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let image = camera.lastSavedImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.6), lineWidth: 1))
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(.black.opacity(0.45))
                .frame(width: 48, height: 48)
                .overlay(Image(systemName: "photo").foregroundStyle(.white.opacity(0.75)))
        }
    }

    @ViewBuilder
    private var modeOverlay: some View {
        switch camera.selectedMode {
        case .customISP:
            ISPMoodOverlay()
        case .aiDevelop:
            AIDevelopOverlay()
        case .semanticExposure:
            SemanticExposureOverlay()
        case .purposePro:
            PurposeProOverlay(guide: purposePro.currentGuide)
        case .motionSubject:
            MotionSubjectOverlay()
        case .privacyCheck:
            PrivacyCheckOverlay()
        case .rawMaterial:
            ProMaterialOverlay()
        case .manual:
            ManualOverlay()
        case .hdrBracket:
            HDROverlay()
        case .nightStack:
            NightStackOverlay()
        case .depth:
            DepthOverlay()
        case .dual:
            DualCameraOverlay()
        case .sound:
            SoundShutterOverlay(level: soundShutter.level)
        case .director:
            CameraDirectorOverlay(advice: director.currentAdvice)
        case .ghostAlign:
            GhostAlignOverlay()
        case .document:
            DocumentOverlay()
        case .strongShake:
            StabilityReticle(level: camera.shakeLevel)
        case .zen:
            Color.black.opacity(0.06)
        case .auto:
            EmptyView()
        }
    }

    private func updateDirector() {
        guard camera.selectedMode == .director else { return }
        director.update(
            with: DirectorContext(
                highlightRatio: camera.highlightClippingRatio,
                shadowRatio: camera.shadowCrushRatio,
                shakeLevel: camera.shakeLevel,
                horizonTilt: camera.horizonTilt,
                bestShotScore: camera.bestShotScore,
                warnings: camera.realtimeWarnings
            )
        )
    }
}

private struct FeatureHelpSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let rows: [FeatureHelpRowData] = [
        .init(icon: "camera.aperture", title: AppText.pick(ja: "RAW素材", en: "RAW Material"), detail: AppText.pick(ja: "RAW+JPEG、低ノイズRAW、編集前提の素材保存に使います。", en: "Capture RAW+JPEG material for editing with controlled noise and color.")),
        .init(icon: "bolt.fill", title: AppText.pick(ja: "決定的瞬間", en: "Decisive Moment"), detail: AppText.pick(ja: "ゼロシャッターラグ系の設定で、子供・ペット・動きものを狙います。", en: "Uses fast capture settings for kids, pets, movement, and expressions.")),
        .init(icon: "square.stack.3d.up.fill", title: AppText.pick(ja: "HDRブラケット", en: "HDR Bracket"), detail: AppText.pick(ja: "暗め・標準・明るめを撮って、逆光や夜景の失敗を減らします。", en: "Combines darker, normal, and brighter shots to protect highlights and shadows.")),
        .init(icon: "moon.stars.fill", title: AppText.pick(ja: "低照度スタック", en: "Low-Light Stack"), detail: AppText.pick(ja: "暗所で複数枚を重ね、ノイズと黒つぶれを抑えます。三脚や固定撮影と相性が良いです。", en: "Stacks multiple low-light frames to reduce noise and crushed shadows. Best with a steady phone.")),
        .init(icon: "waveform.path.ecg", title: AppText.pick(ja: "最強手ブレ", en: "Stability"), detail: AppText.pick(ja: "揺れを見て、今撮るべきか止めるべきかを表示します。", en: "Reads shake and tells you whether to shoot or hold still.")),
        .init(icon: "scope", title: AppText.pick(ja: "目的別Pro", en: "Purpose Pro"), detail: AppText.pick(ja: "商品撮影、ネイル、料理など用途ごとに構図と露出の見方を変えます。", en: "Adapts framing and exposure for product listings, nails, food, shop ads, and profile photos.")),
        .init(icon: "shield.lefthalf.filled", title: AppText.pick(ja: "投稿前チェック", en: "Privacy Check"), detail: AppText.pick(ja: "住所、QR、カード、顔など写り込みリスクを警告します。", en: "Warns about visible addresses, QR codes, cards, faces, and other posting risks.")),
        .init(icon: "person.wave.2.fill", title: AppText.pick(ja: "カメラ監督", en: "Camera Director"), detail: AppText.pick(ja: "明るさ、傾き、ブレを見て撮影指示を出します。", en: "Gives shooting advice based on brightness, tilt, and shake."))
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(AppText.pick(ja: "OAHSPE:α78 は、撮る前に失敗を減らすためのカメラです。", en: "OAHSPE:α78 helps reduce mistakes before you take the shot."))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 4)

                    ForEach(rows) { row in
                        FeatureHelpRow(row: row)
                    }
                }
                .padding(20)
            }
            .navigationTitle(AppText.pick(ja: "機能説明", en: "Feature Guide"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(AppText.pick(ja: "閉じる", en: "Close")) {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct FeatureHelpRowData: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let detail: String
}

private struct FeatureHelpRow: View {
    let row: FeatureHelpRowData

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: row.icon)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.cyan)
                .frame(width: 28, height: 28)
                .background(.cyan.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(row.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                Text(row.detail)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct PurposeProPanel: View {
    @ObservedObject var engine: PurposeProEngine
    let exposureMessage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PurposeProPreset.allCases) { preset in
                        Button {
                            engine.selectedPreset = preset
                        } label: {
                            Label(preset.title, systemImage: preset.iconName)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(engine.selectedPreset == preset ? .black : .white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(engine.selectedPreset == preset ? .white : .black.opacity(0.42), in: Capsule())
                        }
                    }
                }
            }

            Label(exposureMessage, systemImage: "scope")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.mint)
        }
        .foregroundStyle(.white)
        .padding(14)
        .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct SoundShutterBadge: View {
    @ObservedObject var engine: SoundShutterEngine

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("音シャッター", systemImage: "waveform")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Spacer()
                Text(engine.lastTrigger)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.mint)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.16))
                    Capsule()
                        .fill(.mint)
                        .frame(width: max(CGFloat(8), proxy.size.width * CGFloat(engine.level)))
                }
            }
            .frame(height: 8)
        }
        .foregroundStyle(.white)
        .padding(14)
        .background(.black.opacity(0.58), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct CameraDirectorBadge: View {
    @ObservedObject var engine: CameraDirectorEngine

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "person.wave.2.fill")
                .font(.system(size: 18, weight: .bold))
            Text(engine.currentAdvice)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .lineLimit(2)
            Spacer()
        }
        .foregroundStyle(.white)
        .padding(14)
        .background(.black.opacity(0.62), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct CapabilityPill: View {
    let title: String
    let isOn: Bool

    var body: some View {
        Text(title)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundStyle(isOn ? .black : .white.opacity(0.7))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(isOn ? .mint : .black.opacity(0.42), in: Capsule())
    }
}

private struct MomentCaptureBadge: View {
    @ObservedObject var camera: CameraController

    var body: some View {
        HStack(spacing: 8) {
            Label(camera.readinessText, systemImage: "bolt.fill")
            Text(camera.supportsDeferredDelivery ? "撮影は爆速、仕上げは高画質" : "決定的瞬間モード")
        }
        .font(.system(size: 12, weight: .bold, design: .rounded))
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.black.opacity(0.54), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct RealtimeWarningStrip: View {
    let warnings: [String]
    let score: Double

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            Text("撮る前チェック")
            ForEach(warnings, id: \.self) { warning in
                Text(warning)
            }
            Spacer()
            Text("\(Int(score * 100))")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(.yellow)
        }
        .font(.system(size: 12, weight: .bold, design: .rounded))
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.black.opacity(0.62), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct GridOverlay: View {
    var body: some View {
        GeometryReader { proxy in
            Path { path in
                let width = proxy.size.width
                let height = proxy.size.height

                for index in 1..<3 {
                    let x = width * CGFloat(index) / 3
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))

                    let y = height * CGFloat(index) / 3
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
            }
            .stroke(.white, lineWidth: 0.8)
        }
    }
}

private struct FocusRing: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(.yellow, lineWidth: 2)
            .frame(width: 74, height: 74)
            .shadow(color: .black.opacity(0.4), radius: 8)
    }
}

private struct ShakeMeter: View {
    let level: Double
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("最強手ブレ", systemImage: "waveform.path.ecg")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Spacer()
                Text(message)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(level < 0.08 ? .mint : .orange)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.16))
                    Capsule()
                        .fill(level < 0.08 ? .mint : .orange)
                        .frame(width: max(CGFloat(8), proxy.size.width * CGFloat(level)))
                }
            }
            .frame(height: 8)
        }
        .foregroundStyle(.white)
        .padding(14)
        .background(.black.opacity(0.58), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct StabilityReticle: View {
    let level: Double

    var body: some View {
        Circle()
            .stroke(level < 0.08 ? .mint : .orange, lineWidth: 2)
            .frame(width: 112 + CGFloat(level) * 40, height: 112 + CGFloat(level) * 40)
            .opacity(0.9)
            .overlay {
                Circle()
                    .fill(level < 0.08 ? .mint : .orange)
                    .frame(width: 7, height: 7)
            }
            .shadow(color: .black.opacity(0.45), radius: 10)
    }
}

private struct GhostAlignOverlay: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 26)
            .stroke(style: StrokeStyle(lineWidth: 2, dash: [10, 8]))
            .foregroundStyle(.cyan.opacity(0.75))
            .padding(.horizontal, 54)
            .padding(.vertical, 170)
    }
}

private struct DocumentOverlay: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(.white.opacity(0.82), lineWidth: 2)
            .padding(.horizontal, 34)
            .padding(.vertical, 134)
            .overlay(alignment: .top) {
                Text("DOCUMENT")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.black.opacity(0.45), in: Capsule())
                    .foregroundStyle(.white)
                    .padding(.top, 118)
            }
    }
}

private struct ProMaterialOverlay: View {
    var body: some View {
        VStack {
            Spacer()
            Text("RAW + JPEG")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.black.opacity(0.48), in: Capsule())
                .foregroundStyle(.white)
                .padding(.bottom, 168)
        }
    }
}

private struct ISPMoodOverlay: View {
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 6) {
                Text("CUSTOM ISP")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                Text("料理 / 人物 / 商品 / Film")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .foregroundStyle(.white)
            .padding(.bottom, 168)
        }
    }
}

private struct AIDevelopOverlay: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 32, weight: .bold))
            Text("被写体ごとに補正")
                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(.black.opacity(0.46), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct SemanticExposureOverlay: View {
    var body: some View {
        VStack {
            Spacer()
            Text("顔ではなく、写したいものに露出を合わせる")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .foregroundStyle(.white)
                .padding(.bottom, 168)
        }
    }
}

private struct PurposeProOverlay: View {
    let guide: PurposeProGuide

    var body: some View {
        ZStack {
            if guide.targetAspect == "1:1" {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white.opacity(0.78), lineWidth: 2)
                    .aspectRatio(1, contentMode: .fit)
                    .padding(.horizontal, 42)
            } else if guide.targetAspect == "16:9" {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white.opacity(0.78), lineWidth: 2)
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .padding(.horizontal, 22)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white.opacity(0.78), lineWidth: 2)
                    .aspectRatio(4 / 5, contentMode: .fit)
                    .padding(.horizontal, 58)
            }

            VStack {
                HStack {
                    Image(systemName: guide.preset.iconName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(.black.opacity(0.42), in: Circle())
                    Spacer()
                }
                .padding(.top, 106)
                .padding(.leading, 18)
                Spacer()
            }
        }
    }
}

private struct MotionSubjectOverlay: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 18)
            .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 8]))
            .foregroundStyle(.mint.opacity(0.8))
            .frame(width: 190, height: 250)
            .overlay(alignment: .bottom) {
                Text("動く部分だけ別処理")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.black.opacity(0.52), in: Capsule())
                    .foregroundStyle(.white)
                    .padding(.bottom, -42)
            }
    }
}

private struct PrivacyCheckOverlay: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 34, weight: .bold))
            Text("投稿前チェック")
                .font(.system(size: 13, weight: .bold, design: .rounded))
            Text("住所・QR・顔・カードを警告")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(.black.opacity(0.48), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct ManualOverlay: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("ISO  /  SS  /  WB  /  MF")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(.black.opacity(0.48), in: Capsule())
            Spacer()
        }
        .foregroundStyle(.white)
        .padding(.top, 102)
    }
}

private struct HDROverlay: View {
    var body: some View {
        HStack(spacing: 10) {
            ExposureMark(label: "-1")
            ExposureMark(label: "0")
            ExposureMark(label: "+1")
        }
        .padding(.bottom, 158)
        .frame(maxHeight: .infinity, alignment: .bottom)
    }
}

private struct NightStackOverlay: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 30, weight: .bold))
            Text(AppText.pick(ja: "低照度スタック", en: "Low-Light Stack"))
                .font(.system(size: 13, weight: .bold, design: .rounded))
            Text(AppText.pick(ja: "固定して撮ると強い", en: "Best when steady"))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.78))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(.black.opacity(0.46), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct ExposureMark: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.system(size: 12, weight: .bold, design: .monospaced))
            .foregroundStyle(.white)
            .frame(width: 40, height: 28)
            .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct DepthOverlay: View {
    var body: some View {
        Circle()
            .stroke(.cyan.opacity(0.8), lineWidth: 2)
            .frame(width: 180, height: 180)
            .overlay {
                Text("DEPTH")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.black.opacity(0.45), in: Capsule())
            }
    }
}

private struct DualCameraOverlay: View {
    var body: some View {
        VStack {
            HStack {
                Spacer()
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white.opacity(0.86), lineWidth: 2)
                    .frame(width: 104, height: 150)
                    .overlay {
                        Text("FRONT")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                    }
            }
            Spacer()
        }
        .padding(.top, 106)
        .padding(.trailing, 20)
    }
}

private struct SoundShutterOverlay: View {
    let level: Double

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: level > 0.72 ? "camera.fill" : "waveform")
                .font(.system(size: 34, weight: .bold))
            Text(level > 0.72 ? "撮影" : "声・拍手・笑い声")
                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(.black.opacity(0.46), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct CameraDirectorOverlay: View {
    let advice: String

    var body: some View {
        VStack {
            Spacer()
            Text(advice)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(.black.opacity(0.46), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(.bottom, 168)
        }
    }
}
