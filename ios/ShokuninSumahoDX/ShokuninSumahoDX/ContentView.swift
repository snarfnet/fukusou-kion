import AudioToolbox
import AVFoundation
import CoreImage.CIFilterBuiltins
import CoreMotion
import PhotosUI
import Speech
import SwiftUI
import UIKit

final class MotionReader: ObservableObject {
    @Published var pitch: Double = 0
    @Published var roll: Double = 0

    private let manager = CMMotionManager()

    func start() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let motion else { return }
            self?.pitch = motion.attitude.pitch * 180 / .pi
            self?.roll = motion.attitude.roll * 180 / .pi
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
    }
}

struct ContentView: View {
    @StateObject private var motion = MotionReader()
    @State private var tool: CraftTool = .angle
    @State private var siteName = UserDefaults.standard.string(forKey: "shokuninDXSiteName") ?? "現場名未設定"
    @State private var notes: [MeasurementNote] = AppStore.load("shokuninDXNotes", fallback: [])
    @State private var checklist: [ChecklistItem] = AppStore.load("shokuninDXChecklist", fallback: ChecklistItem.defaults)
    @State private var favorites: [ConversionFavorite] = AppStore.load("shokuninDXConversionFavorites", fallback: ConversionFavorite.defaults)
    @State private var siteTemplates: [SiteTemplate] = SiteTemplate.defaults
    @State private var materialPrices: [MaterialPrice] = AppStore.load("shokuninDXMaterialPrices", fallback: MaterialPrice.defaults)
    @State private var stampsBySite: [String: SiteStamp] = AppStore.load("shokuninDXSiteStamps", fallback: [:])
    @AppStorage("shokuninDXAngleTolerance") private var angleTolerance = 0.8
    @AppStorage("shokuninDXLevelTolerance") private var levelTolerance = 0.7
    @AppStorage("shokuninDXMaterialLoss") private var materialLoss = 8.0

    var body: some View {
        NavigationStack {
            ZStack {
                CraftTheme.bg.ignoresSafeArea()
                VStack(spacing: 0) {
                    AppHeader(siteName: $siteName)
                    ToolTabs(selection: $tool)
                    ScrollView {
                        Group {
                            switch tool {
                            case .angle:
                                AngleTool(siteName: siteName, motion: motion, notes: $notes, stampsBySite: $stampsBySite, angleTolerance: $angleTolerance, levelTolerance: $levelTolerance)
                            case .level:
                                LevelTool(siteName: siteName, motion: motion, notes: $notes, stampsBySite: $stampsBySite, tolerance: $levelTolerance)
                            case .convert:
                                ConverterTool(siteName: siteName, notes: $notes, favorites: $favorites)
                            case .slope:
                                SlopeTool(siteName: siteName, notes: $notes)
                            case .material:
                                MaterialTool(siteName: siteName, notes: $notes, materialPrices: $materialPrices, defaultLoss: $materialLoss)
                            case .checklist:
                                ChecklistTool(items: $checklist, siteTemplates: siteTemplates, siteName: $siteName, angleTolerance: $angleTolerance, levelTolerance: $levelTolerance, materialLoss: $materialLoss, stampsBySite: $stampsBySite)
                            case .photo:
                                PhotoOverlayTool(siteName: siteName, motion: motion, notes: $notes, stampsBySite: $stampsBySite)
                            case .centerGuide:
                                CenterGuideTool(siteName: siteName, notes: $notes, stampsBySite: $stampsBySite)
                            case .notes:
                                NotesTool(notes: $notes, stampsBySite: $stampsBySite)
                            }
                        }
                        .padding(16)
                        .padding(.bottom, 24)
                    }
                    .scrollDismissesKeyboard(.interactively)
                }
            }
        }
        .tint(CraftTheme.orange)
        .onAppear { motion.start() }
        .onDisappear { motion.stop() }
        .onChange(of: notes) { _, newValue in AppStore.save(newValue, key: "shokuninDXNotes") }
        .onChange(of: checklist) { _, newValue in AppStore.save(newValue, key: "shokuninDXChecklist") }
        .onChange(of: favorites) { _, newValue in AppStore.save(newValue, key: "shokuninDXConversionFavorites") }
        .onChange(of: materialPrices) { _, newValue in AppStore.save(newValue, key: "shokuninDXMaterialPrices") }
        .onChange(of: stampsBySite) { _, newValue in AppStore.save(newValue, key: "shokuninDXSiteStamps") }
        .onChange(of: siteName) { _, newValue in UserDefaults.standard.set(newValue, forKey: "shokuninDXSiteName") }
    }
}

private struct AppHeader: View {
    @Binding var siteName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top) {
                    headerTitle
                    Spacer(minLength: 12)
                    originalAppBadge
                }
                VStack(alignment: .leading, spacing: 10) {
                    headerTitle
                    originalAppBadge
                }
            }

            TextField("現場名", text: $siteName)
                .font(.headline.weight(.bold))
                .textInputAutocapitalization(.never)
                .padding(12)
                .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(.white)
        }
        .padding(16)
        .background(
            ZStack {
                CraftTheme.steel
                LinearGradient(colors: [CraftTheme.orange, .clear, CraftTheme.ink.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing)
            }
        )
        .foregroundStyle(.white)
    }

    private var headerTitle: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("職人スマホDX")
                .font(.system(.largeTitle, design: .rounded).weight(.black))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text("測る、残す、説明する。現場用の道具箱。")
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    private var originalAppBadge: some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text("元アプリ")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.7))
            Text(AppStoreConfig.originalAppAppleID)
                .font(.caption.monospacedDigit().weight(.semibold))
        }
        .padding(10)
        .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct ToolTabs: View {
    @Binding var selection: CraftTool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CraftTool.allCases) { item in
                    Button {
                        selection = item
                    } label: {
                        Label(item.rawValue, systemImage: item.symbol)
                            .font(.subheadline.weight(.bold))
                            .padding(.horizontal, 13)
                            .frame(minWidth: 74, minHeight: 44)
                            .background(selection == item ? CraftTheme.ink : Color.white, in: RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(selection == item ? .white : CraftTheme.ink)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(item.rawValue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .accessibilityIdentifier("tool-tabs")
        .background(Color.white.opacity(0.68))
    }
}

private struct AngleTool: View {
    let siteName: String
    @ObservedObject var motion: MotionReader
    @Binding var notes: [MeasurementNote]
    @Binding var stampsBySite: [String: SiteStamp]
    @Binding var angleTolerance: Double
    @Binding var levelTolerance: Double
    @State private var target = 45.0
    @State private var zero = 0.0
    @State private var useRoll = true
    @State private var memo = ""
    @State private var tag: NoteTag = .floor
    @State private var preset: TolerancePreset = .standard
    @StateObject private var voiceMemo = VoiceMemo()
    @State private var lastMeasured = 0.0

    private var measured: Double { (useRoll ? motion.roll : motion.pitch) - zero }
    private var gap: Double { abs(measured - target) }
    private var isOK: Bool { gap <= angleTolerance }
    private var isStable: Bool { abs(measured - lastMeasured) < 0.35 }

    var body: some View {
        VStack(spacing: 16) {
            SectionTitle("角度計DX", icon: "angle")
            GaugeCard(value: measured, label: useRoll ? "左右角度" : "前後角度", target: target)

            VStack(alignment: .leading, spacing: 12) {
                Picker("軸", selection: $useRoll) {
                    Text("左右").tag(true)
                    Text("前後").tag(false)
                }
                .pickerStyle(.segmented)

                PresetRow(target: $target)
                Text("目標 \(target, specifier: "%.0f")° / 差分 \(gap, specifier: "%.1f")°")
                    .font(.subheadline.weight(.bold))
                Slider(value: $target, in: -90...90, step: 1)
                HStack {
                    StatusPill(title: "自動判定", value: isOK ? "OK" : "NG")
                    StatusPill(title: "静止", value: isStable ? "OK" : "揺れ")
                }
                Picker("許容差", selection: $preset) {
                    ForEach(TolerancePreset.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: preset) { _, value in
                    angleTolerance = value.angle
                    levelTolerance = value.level
                }
                Text("OKしきい値 \(angleTolerance.rounded1)°")
                    .font(.subheadline.weight(.bold))
                Slider(value: $angleTolerance, in: 0.1...5, step: 0.1)
                Picker("タグ", selection: $tag) {
                    ForEach(NoteTag.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.menu)
                TextField("測定メモ", text: $memo)
                    .textFieldStyle(.roundedBorder)
                Button {
                    voiceMemo.toggle { text in
                        memo = text
                    }
                } label: {
                    Label(voiceMemo.isRecording ? "音声入力中" : "音声メモ", systemImage: "mic")
                }
                .buttonStyle(.bordered)
            }
            .panelStyle()
            .onReceive(motion.$roll) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    lastMeasured = measured
                }
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) {
                    angleActionButtons
                }
                VStack(spacing: 10) {
                    angleActionButtons
                }
            }
        }
    }

    private var angleActionButtons: some View {
        Group {
            Button { zero = useRoll ? motion.roll : motion.pitch } label: {
                Label("ゼロ補正", systemImage: "scope")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(CraftButtonStyle(color: CraftTheme.steel))

            Button { save() } label: {
                Label("保存", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(CraftButtonStyle(color: CraftTheme.orange))
        }
    }

    private func save() {
        notes.insert(MeasurementNote(siteName: siteName, title: "角度", value: "\(measured.rounded1)° / 目標 \(Int(target))° / \(isOK ? "OK" : "NG")", memo: isStable ? memo : "端末が揺れています。再測定推奨。\(memo)", tag: tag.rawValue), at: 0)
        if isOK {
            var stamp = stampsBySite[siteName] ?? SiteStamp()
            stamp.angleOK = true
            stampsBySite[siteName] = stamp
        }
        memo = ""
    }
}

private struct PresetRow: View {
    @Binding var target: Double

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach([0.0, 45.0, 90.0], id: \.self) { value in
                    Button("\(Int(value))°") { target = value }
                        .buttonStyle(.bordered)
                }
                Button("1/50") { target = atan(1.0 / 50.0) * 180 / .pi }
                    .buttonStyle(.bordered)
            }
        }
    }
}

private struct LevelTool: View {
    let siteName: String
    @ObservedObject var motion: MotionReader
    @Binding var notes: [MeasurementNote]
    @Binding var stampsBySite: [String: SiteStamp]
    @Binding var tolerance: Double
    @State private var soundEnabled = true
    @State private var lastBuzz = Date.distantPast

    private var offsetX: CGFloat { CGFloat(max(-1, min(1, motion.roll / 18))) * 110 }
    private var offsetY: CGFloat { CGFloat(max(-1, min(1, motion.pitch / 18))) * 110 }
    private var isLevel: Bool { abs(motion.roll) <= tolerance && abs(motion.pitch) <= tolerance }

    var body: some View {
        VStack(spacing: 16) {
            SectionTitle("2軸水平器", icon: "circle.dashed.inset.filled")
            ZStack {
                Circle().stroke(CraftTheme.grid, lineWidth: 2).frame(width: 260, height: 260)
                Circle().stroke(CraftTheme.grid, lineWidth: 2).frame(width: 150, height: 150)
                Rectangle().fill(CraftTheme.grid).frame(width: 260, height: 2)
                Rectangle().fill(CraftTheme.grid).frame(width: 2, height: 260)
                Circle()
                    .fill(isLevel ? CraftTheme.green : CraftTheme.orange)
                    .frame(width: 58, height: 58)
                    .scaleEffect(isLevel ? 1.12 : 1)
                    .shadow(color: isLevel ? CraftTheme.green.opacity(0.75) : .black.opacity(0.18), radius: isLevel ? 22 : 10, y: 6)
                    .offset(x: offsetX, y: offsetY)
                    .animation(.spring(response: 0.28, dampingFraction: 0.58), value: isLevel)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 26)
            .background(CraftTheme.ink, in: RoundedRectangle(cornerRadius: 8))
            .onChange(of: isLevel) { _, newValue in
                guard soundEnabled, newValue, Date().timeIntervalSince(lastBuzz) > 2 else { return }
                lastBuzz = Date()
                AudioServicesPlaySystemSound(1104)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }

            HStack {
                StatusPill(title: "左右", value: "\(motion.roll.rounded1)°")
                StatusPill(title: "前後", value: "\(motion.pitch.rounded1)°")
                StatusPill(title: "判定", value: isLevel ? "OK" : "NG")
            }

            VStack(alignment: .leading, spacing: 10) {
                Toggle("水平時に音と振動で通知", isOn: $soundEnabled)
                    .font(.headline)
                Text("OKしきい値 ±\(tolerance.rounded1)°")
                    .font(.subheadline.weight(.bold))
                Slider(value: $tolerance, in: 0.1...3, step: 0.1)
            }
                .panelStyle()

            Button {
                notes.insert(MeasurementNote(siteName: siteName, title: "水平", value: "左右 \(motion.roll.rounded1)° / 前後 \(motion.pitch.rounded1)°", memo: isLevel ? "水平OK" : "調整あり", tag: NoteTag.finish.rawValue), at: 0)
                if isLevel {
                    var stamp = stampsBySite[siteName] ?? SiteStamp()
                    stamp.levelOK = true
                    stampsBySite[siteName] = stamp
                }
            } label: {
                Label("測定を保存", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(CraftButtonStyle(color: CraftTheme.orange))
        }
    }
}

private struct ConverterTool: View {
    let siteName: String
    @Binding var notes: [MeasurementNote]
    @Binding var favorites: [ConversionFavorite]
    @State private var kind: ConverterKind = .length
    @State private var input = 1.0
    @State private var expression = "3.2+1.5"
    @State private var from: CraftUnit = .shaku
    @State private var to: CraftUnit = .meter

    private var units: [CraftUnit] { CraftUnit.allCases.filter { $0.kind == kind } }
    private var result: Double { input * from.baseFactor / to.baseFactor }

    var body: some View {
        VStack(spacing: 16) {
            SectionTitle("単位変換DX", icon: "arrow.left.arrow.right")
            if !favorites.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("お気に入り")
                        .font(.headline)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(favorites) { favorite in
                                Button {
                                    kind = favorite.kind
                                    from = favorite.from
                                    to = favorite.to
                                } label: {
                                    Text(favorite.title)
                                        .font(.subheadline.weight(.bold))
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                .panelStyle()
            }

            VStack(spacing: 12) {
                Picker("種類", selection: $kind) {
                    ForEach(ConverterKind.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .onChange(of: kind) { _, newValue in
                    guard from.kind != newValue || to.kind != newValue else { return }
                    let filtered = CraftUnit.allCases.filter { $0.kind == newValue }
                    from = filtered.first ?? .meter
                    to = filtered.dropFirst().first ?? filtered.first ?? .meter
                }

                TextField("数値", value: $input, format: .number)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 42, weight: .black, design: .rounded).monospacedDigit())
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
                ViewThatFits(in: .horizontal) {
                    HStack { calculatorControls }
                    VStack { calculatorControls }
                }

                ViewThatFits(in: .horizontal) {
                    HStack {
                        UnitPicker(title: "変換元", selection: $from, units: units)
                        Image(systemName: "arrow.right")
                        UnitPicker(title: "変換先", selection: $to, units: units)
                    }
                    VStack {
                        UnitPicker(title: "変換元", selection: $from, units: units)
                        Image(systemName: "arrow.down")
                        UnitPicker(title: "変換先", selection: $to, units: units)
                    }
                }
            }
            .panelStyle()

            ResultCard(text: "\(result.rounded4)", unit: to.rawValue)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { converterActions }
                VStack(spacing: 10) { converterActions }
            }
        }
    }

    private var converterActions: some View {
        Group {
            SaveButton(title: "結果を保存") {
                notes.insert(MeasurementNote(siteName: siteName, title: "変換", value: "\(input.rounded4) \(from.rawValue) = \(result.rounded4) \(to.rawValue)", memo: ""), at: 0)
            }
            Button {
                addFavorite()
            } label: {
                Label("お気に入り", systemImage: "star.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(CraftButtonStyle(color: CraftTheme.steel))
        }
    }

    private var calculatorControls: some View {
        Group {
            TextField("電卓 例: 3.2+1.5*2", text: $expression)
                .textFieldStyle(.roundedBorder)
            Button("計算") {
                input = ExpressionCalculator.evaluate(expression) ?? input
            }
            .buttonStyle(.bordered)
        }
    }

    private func addFavorite() {
        let title = "\(from.rawValue)→\(to.rawValue)"
        let favorite = ConversionFavorite(title: title, kind: kind, from: from, to: to)
        guard !favorites.contains(where: { $0.kind == kind && $0.from == from && $0.to == to }) else { return }
        favorites.insert(favorite, at: 0)
    }
}

private struct SlopeTool: View {
    let siteName: String
    @Binding var notes: [MeasurementNote]
    @State private var angle = 1.15
    @State private var rise = 1.0
    @State private var run = 50.0

    private var slopeRatio: Double { tan(angle * .pi / 180) }
    private var ratioText: String { slopeRatio == 0 ? "0" : "1/\((1 / slopeRatio).rounded1)" }
    private var angleFromRatio: Double { atan(rise / max(run, 0.001)) * 180 / .pi }

    var body: some View {
        VStack(spacing: 16) {
            SectionTitle("勾配計算", icon: "chart.line.uptrend.xyaxis")
            VStack(alignment: .leading, spacing: 12) {
                Text("角度から勾配")
                    .font(.headline)
                Text("角度 \(angle.rounded1)°")
                Slider(value: $angle, in: 0...45, step: 0.05)
                ResultCard(text: ratioText, unit: "勾配")
            }
            .panelStyle()

            VStack(alignment: .leading, spacing: 12) {
                Text("立ち上がり / 距離から角度")
                    .font(.headline)
                ViewThatFits(in: .horizontal) {
                    HStack { slopeInputs }
                    VStack { slopeInputs }
                }
                ResultCard(text: angleFromRatio.rounded2, unit: "°")
            }
            .panelStyle()

            SaveButton(title: "勾配を保存") {
                notes.insert(MeasurementNote(siteName: siteName, title: "勾配", value: "\(angle.rounded1)° = \(ratioText)", memo: "立ち上がり \(rise.rounded1) / 距離 \(run.rounded1)"), at: 0)
            }
        }
    }

    private var slopeInputs: some View {
        Group {
            DecimalInput("立ち上がり", value: $rise)
            DecimalInput("距離", value: $run)
        }
    }
}

private struct MaterialTool: View {
    let siteName: String
    @Binding var notes: [MeasurementNote]
    @Binding var materialPrices: [MaterialPrice]
    @Binding var defaultLoss: Double
    @State private var kind: MaterialKind = .flooring
    @State private var area = 20.0
    @State private var unitCoverage = 1.65
    @State private var loss = 8.0
    @State private var selectedPriceID: UUID?
    @State private var newPriceName = ""
    @State private var newUnitPrice = 3000
    @State private var newCoverage = 1.65

    private var neededArea: Double { area * (1 + loss / 100) }
    private var quantity: Int { Int(ceil(neededArea / max(unitCoverage, 0.001))) }
    private var selectedPrice: MaterialPrice? { materialPrices.first(where: { $0.id == selectedPriceID }) }
    private var estimatedCost: Int { quantity * (selectedPrice?.unitPrice ?? 0) }

    var body: some View {
        VStack(spacing: 16) {
            SectionTitle("材料計算", icon: "square.grid.3x3")
            VStack(spacing: 12) {
                Picker("材料", selection: $kind) {
                    ForEach(MaterialKind.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .onChange(of: kind) { _, newKind in
                    selectedPriceID = materialPrices.first(where: { $0.kind == newKind })?.id
                }
                Picker("単価", selection: $selectedPriceID) {
                    Text("単価なし").tag(Optional<UUID>.none)
                    ForEach(materialPrices.filter { $0.kind == kind }) { price in
                        Text("\(price.name) / \(price.unitPrice)円").tag(Optional<UUID>.some(price.id))
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedPriceID) { _, _ in
                    if let selectedPrice {
                        unitCoverage = selectedPrice.unitCoverage
                    }
                }
                ViewThatFits(in: .horizontal) {
                    HStack { materialInputs }
                    VStack { materialInputs }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("ロス率 \(loss.rounded1)%")
                    Slider(value: $loss, in: 0...25, step: 0.5)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            Button("床材8%") { loss = 8 }
                            Button("壁紙12%") { loss = 12 }
                            Button("塗料5%") { loss = 5 }
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .panelStyle()

            ResultCard(text: "\(quantity)", unit: "\(kind.rawValue)の目安数量")
            StatusPill(title: "ロス込み面積", value: "\(neededArea.rounded2) m2")
            if selectedPrice != nil {
                StatusPill(title: "概算金額", value: "\(estimatedCost) 円")
            }

            SaveButton(title: "材料計算を保存") {
                notes.insert(MeasurementNote(siteName: siteName, title: "材料", value: "\(kind.rawValue) \(quantity) 個目安", memo: "施工 \(area.rounded2)m2 / ロス \(loss.rounded1)% / 概算 \(estimatedCost)円"), at: 0)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("よく使う材料単価")
                    .font(.headline)
                TextField("材料名", text: $newPriceName)
                    .textFieldStyle(.roundedBorder)
                ViewThatFits(in: .horizontal) {
                    HStack { priceInputs }
                    VStack { priceInputs }
                }
                Button {
                    addMaterialPrice()
                } label: {
                    Label("単価を登録", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(CraftButtonStyle(color: CraftTheme.steel))
                .disabled(newPriceName.trimmed.isEmpty)
            }
            .panelStyle()
        }
        .onAppear {
            loss = defaultLoss
            selectedPriceID = materialPrices.first(where: { $0.kind == kind })?.id
        }
        .onChange(of: loss) { _, newValue in
            defaultLoss = newValue
        }
    }

    private func addMaterialPrice() {
        let item = MaterialPrice(name: newPriceName.trimmed, kind: kind, unitPrice: newUnitPrice, unitCoverage: newCoverage)
        materialPrices.insert(item, at: 0)
        selectedPriceID = item.id
        unitCoverage = item.unitCoverage
        newPriceName = ""
    }

    private var materialInputs: some View {
        Group {
            DecimalInput("施工面積 m2", value: $area)
            DecimalInput("1個あたり m2", value: $unitCoverage)
        }
    }

    private var priceInputs: some View {
        Group {
            IntInput("単価 円", value: $newUnitPrice)
            DecimalInput("1個あたり m2", value: $newCoverage)
        }
    }
}

private struct ChecklistTool: View {
    @Binding var items: [ChecklistItem]
    let siteTemplates: [SiteTemplate]
    @Binding var siteName: String
    @Binding var angleTolerance: Double
    @Binding var levelTolerance: Double
    @Binding var materialLoss: Double
    @Binding var stampsBySite: [String: SiteStamp]
    @State private var newItem = ""
    @State private var duplicateName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle("現場チェックリスト", icon: "checklist")
            VStack(alignment: .leading, spacing: 10) {
                Text("現場テンプレ")
                    .font(.headline)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(siteTemplates) { template in
                            Button(template.name) {
                                apply(template)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(CraftTheme.steel)
                        }
                    }
                }
                HStack {
                    StatusPill(title: "角度OK", value: "±\(angleTolerance.rounded1)°")
                    StatusPill(title: "水平OK", value: "±\(levelTolerance.rounded1)°")
                    StatusPill(title: "ロス", value: "\(materialLoss.rounded1)%")
                }
            }
            .panelStyle()

            ForEach(items.indices, id: \.self) { index in
                HStack(spacing: 12) {
                    Button { items[index].isDone.toggle() } label: {
                        Image(systemName: items[index].isDone ? "checkmark.square.fill" : "square")
                            .font(.title2)
                            .foregroundStyle(items[index].isDone ? CraftTheme.green : CraftTheme.muted)
                    }
                    .buttonStyle(.plain)
                    TextField("項目", text: $items[index].title)
                }
                .panelStyle()
            }
            ViewThatFits(in: .horizontal) {
                HStack { addItemControls }
                VStack { addItemControls }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("現場セットを複製")
                    .font(.headline)
                TextField("新しい現場名", text: $duplicateName)
                    .textFieldStyle(.roundedBorder)
                Button {
                    duplicateSite()
                } label: {
                    Label("今のセットを複製", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(CraftButtonStyle(color: CraftTheme.orange))
                .disabled(duplicateName.trimmed.isEmpty)
            }
            .panelStyle()
        }
    }

    private var addItemControls: some View {
        Group {
            TextField("項目を追加", text: $newItem)
                .textFieldStyle(.roundedBorder)
            Button { add() } label: {
                Label("追加", systemImage: "plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(CraftButtonStyle(color: CraftTheme.ink))
            .disabled(newItem.trimmed.isEmpty)
        }
    }

    private func add() {
        guard !newItem.trimmed.isEmpty else { return }
        items.append(ChecklistItem(title: newItem.trimmed, isDone: false))
        newItem = ""
    }

    private func apply(_ template: SiteTemplate) {
        siteName = template.name
        items = template.checklistItems.map { ChecklistItem(title: $0, isDone: false) }
        angleTolerance = template.angleTolerance
        levelTolerance = template.levelTolerance
        materialLoss = template.materialLoss
    }

    private func duplicateSite() {
        siteName = duplicateName.trimmed
        items = items.map { ChecklistItem(title: $0.title, isDone: false) }
        stampsBySite[siteName] = SiteStamp()
        duplicateName = ""
    }
}

private struct PhotoOverlayTool: View {
    let siteName: String
    @ObservedObject var motion: MotionReader
    @Binding var notes: [MeasurementNote]
    @Binding var stampsBySite: [String: SiteStamp]
    @State private var selectedItem: PhotosPickerItem?
    @State private var image: UIImage?
    @State private var label = "水平OK"
    @State private var annotationStyle: PhotoAnnotationStyle = .arrowCircle
    @State private var status = "写真を選ぶと、測定ラベル付きで保存できます。"

    var body: some View {
        VStack(spacing: 16) {
            SectionTitle("写真に測定値を重ねる", icon: "camera.viewfinder")
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label("写真を選択", systemImage: "photo")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(CraftButtonStyle(color: CraftTheme.steel))
            .onChange(of: selectedItem) { _, item in load(item) }

            TextField("写真に載せる文字", text: $label)
                .textFieldStyle(.roundedBorder)
                .onAppear {
                    label = "角度 \(motion.roll.rounded1)° / \(abs(motion.roll) < 0.7 && abs(motion.pitch) < 0.7 ? "水平OK" : "調整あり")"
                }
            Picker("注釈", selection: $annotationStyle) {
                ForEach(PhotoAnnotationStyle.allCases) { style in
                    Text(style.rawValue).tag(style)
                }
            }
            .pickerStyle(.segmented)

            if let image {
                Image(uiImage: renderOverlay(on: image))
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Button {
                guard let image else { return }
                UIImageWriteToSavedPhotosAlbum(renderOverlay(on: image), nil, nil, nil)
                notes.insert(MeasurementNote(siteName: siteName, title: "写真", value: label, memo: "写真へ測定ラベルを追加", tag: NoteTag.photo.rawValue), at: 0)
                var stamp = stampsBySite[siteName] ?? SiteStamp()
                stamp.photoDone = true
                stampsBySite[siteName] = stamp
                status = "写真アプリへ保存しました。"
            } label: {
                Label("ラベル付き写真を保存", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(CraftButtonStyle(color: CraftTheme.orange))
            .disabled(image == nil)

            Text(status)
                .font(.footnote)
                .foregroundStyle(CraftTheme.muted)
        }
    }

    private func load(_ item: PhotosPickerItem?) {
        Task {
            guard let data = try? await item?.loadTransferable(type: Data.self),
                  let picked = UIImage(data: data) else { return }
            await MainActor.run { image = picked }
        }
    }

    private func renderOverlay(on image: UIImage) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: image.size))
            let scale = image.size.width / 1200
            let box = CGRect(x: 36 * scale, y: 36 * scale, width: image.size.width - 72 * scale, height: 150 * scale)
            UIColor.black.withAlphaComponent(0.68).setFill()
            UIBezierPath(roundedRect: box, cornerRadius: 24 * scale).fill()
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 54 * scale),
                .foregroundColor: UIColor.white
            ]
            label.draw(in: box.insetBy(dx: 28 * scale, dy: 36 * scale), withAttributes: attrs)
            context.cgContext.setStrokeColor(UIColor.systemOrange.cgColor)
            context.cgContext.setLineWidth(8 * scale)
            let center = CGPoint(x: image.size.width / 2, y: image.size.height / 2)
            if annotationStyle == .arrow || annotationStyle == .arrowCircle {
                let start = CGPoint(x: center.x - 210 * scale, y: center.y + 130 * scale)
                let end = CGPoint(x: center.x - 24 * scale, y: center.y + 10 * scale)
                context.cgContext.setShadow(offset: .zero, blur: 18 * scale, color: UIColor.systemOrange.cgColor)
                context.cgContext.move(to: start)
                context.cgContext.addLine(to: end)
                context.cgContext.move(to: end)
                context.cgContext.addLine(to: CGPoint(x: end.x - 8 * scale, y: end.y + 44 * scale))
                context.cgContext.move(to: end)
                context.cgContext.addLine(to: CGPoint(x: end.x - 44 * scale, y: end.y + 2 * scale))
                context.cgContext.strokePath()
            }
            if annotationStyle == .circle || annotationStyle == .arrowCircle {
                context.cgContext.setShadow(offset: .zero, blur: 18 * scale, color: UIColor.systemOrange.cgColor)
                context.cgContext.strokeEllipse(in: CGRect(x: center.x - 120 * scale, y: center.y - 120 * scale, width: 240 * scale, height: 240 * scale))
            }
        }
    }
}

private enum PhotoAnnotationStyle: String, CaseIterable, Identifiable {
    case none = "なし"
    case arrow = "矢印"
    case circle = "丸印"
    case arrowCircle = "両方"

    var id: String { rawValue }
}

private struct CenterGuideTool: View {
    let siteName: String
    @Binding var notes: [MeasurementNote]
    @Binding var stampsBySite: [String: SiteStamp]
    @State private var selectedItem: PhotosPickerItem?
    @State private var afterItem: PhotosPickerItem?
    @State private var image: UIImage?
    @State private var afterImage: UIImage?
    @State private var verticalOffset = 0.0
    @State private var horizontalOffset = 0.0
    @State private var showThirds = true
    @State private var status = "写真に中心線を重ねて、位置合わせのメモとして保存できます。"

    var body: some View {
        VStack(spacing: 16) {
            SectionTitle("中心線ガイド", icon: "plus.viewfinder")
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label("施工前写真を選択", systemImage: "photo")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(CraftButtonStyle(color: CraftTheme.steel))
            .onChange(of: selectedItem) { _, item in load(item) }
            PhotosPicker(selection: $afterItem, matching: .images) {
                Label("施工後写真を選択", systemImage: "photo.stack")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(CraftButtonStyle(color: CraftTheme.steel))
            .onChange(of: afterItem) { _, item in loadAfter(item) }

            VStack(alignment: .leading, spacing: 12) {
                Toggle("三分割ガイドも表示", isOn: $showThirds)
                Text("縦中心の調整 \(verticalOffset.rounded1)%")
                Slider(value: $verticalOffset, in: -30...30, step: 0.5)
                Text("横中心の調整 \(horizontalOffset.rounded1)%")
                Slider(value: $horizontalOffset, in: -30...30, step: 0.5)
            }
            .panelStyle()

            if let image {
                Image(uiImage: renderGuide(on: image))
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            if let image, let afterImage {
                Image(uiImage: renderBeforeAfter(before: image, after: afterImage))
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Button {
                guard let image else { return }
                let output = afterImage == nil ? renderGuide(on: image) : renderBeforeAfter(before: image, after: afterImage!)
                UIImageWriteToSavedPhotosAlbum(output, nil, nil, nil)
                notes.insert(
                    MeasurementNote(
                        siteName: siteName,
                        title: "中心線",
                        value: "縦 \(verticalOffset.rounded1)% / 横 \(horizontalOffset.rounded1)%",
                        memo: showThirds ? "三分割ガイドあり" : "中心線のみ"
                    ),
                    at: 0
                )
                var stamp = stampsBySite[siteName] ?? SiteStamp()
                stamp.photoDone = true
                stampsBySite[siteName] = stamp
                status = "中心線付き写真を保存しました。"
            } label: {
                Label("中心線付き写真を保存", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(CraftButtonStyle(color: CraftTheme.orange))
            .disabled(image == nil)

            Text(status)
                .font(.footnote)
                .foregroundStyle(CraftTheme.muted)
        }
    }

    private func load(_ item: PhotosPickerItem?) {
        Task {
            guard let data = try? await item?.loadTransferable(type: Data.self),
                  let picked = UIImage(data: data) else { return }
            await MainActor.run { image = picked }
        }
    }

    private func loadAfter(_ item: PhotosPickerItem?) {
        Task {
            guard let data = try? await item?.loadTransferable(type: Data.self),
                  let picked = UIImage(data: data) else { return }
            await MainActor.run { afterImage = picked }
        }
    }

    private func renderGuide(on image: UIImage) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: image.size))
            let cg = context.cgContext
            let x = image.size.width * (0.5 + verticalOffset / 100)
            let y = image.size.height * (0.5 + horizontalOffset / 100)
            let scale = image.size.width / 1200

            if showThirds {
                cg.setStrokeColor(UIColor.white.withAlphaComponent(0.55).cgColor)
                cg.setLineWidth(3 * scale)
                for ratio in [CGFloat(1.0 / 3.0), CGFloat(2.0 / 3.0)] {
                    cg.move(to: CGPoint(x: image.size.width * ratio, y: 0))
                    cg.addLine(to: CGPoint(x: image.size.width * ratio, y: image.size.height))
                    cg.move(to: CGPoint(x: 0, y: image.size.height * ratio))
                    cg.addLine(to: CGPoint(x: image.size.width, y: image.size.height * ratio))
                }
                cg.strokePath()
            }

            cg.setStrokeColor(UIColor.systemOrange.cgColor)
            cg.setLineWidth(8 * scale)
            cg.move(to: CGPoint(x: x, y: 0))
            cg.addLine(to: CGPoint(x: x, y: image.size.height))
            cg.move(to: CGPoint(x: 0, y: y))
            cg.addLine(to: CGPoint(x: image.size.width, y: y))
            cg.strokePath()

            UIColor.black.withAlphaComponent(0.68).setFill()
            let box = CGRect(x: 32 * scale, y: 32 * scale, width: 430 * scale, height: 84 * scale)
            UIBezierPath(roundedRect: box, cornerRadius: 18 * scale).fill()
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 32 * scale),
                .foregroundColor: UIColor.white
            ]
            "中心線ガイド".draw(in: box.insetBy(dx: 20 * scale, dy: 22 * scale), withAttributes: attrs)
        }
    }

    private func renderBeforeAfter(before: UIImage, after: UIImage) -> UIImage {
        let targetSize = CGSize(width: 1600, height: 900)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            UIColor.black.setFill()
            UIBezierPath(rect: CGRect(origin: .zero, size: targetSize)).fill()
            renderGuide(on: before).draw(in: CGRect(x: 0, y: 0, width: 800, height: 900))
            renderGuide(on: after).draw(in: CGRect(x: 800, y: 0, width: 800, height: 900))
            let attrs: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 44), .foregroundColor: UIColor.white]
            "Before".draw(at: CGPoint(x: 38, y: 38), withAttributes: attrs)
            "After".draw(at: CGPoint(x: 838, y: 38), withAttributes: attrs)
        }
    }
}

private struct NotesTool: View {
    @Binding var notes: [MeasurementNote]
    @Binding var stampsBySite: [String: SiteStamp]
    @State private var pdfURL: URL?
    @State private var selectedSite = "すべて"
    @State private var searchText = ""
    @State private var selectedTag = "すべて"

    private var sites: [String] {
        ["すべて"] + Array(Set(notes.map(\.siteName))).sorted()
    }

    private var visibleNotes: [MeasurementNote] {
        let scoped = selectedSite == "すべて" ? notes : notes.filter { $0.siteName == selectedSite }
        let tagged = selectedTag == "すべて" ? scoped : scoped.filter { $0.tag == selectedTag }
        guard !searchText.trimmed.isEmpty else { return tagged }
        let query = searchText.trimmed.lowercased()
        return tagged.filter {
            $0.siteName.lowercased().contains(query) ||
            $0.title.lowercased().contains(query) ||
            $0.value.lowercased().contains(query) ||
            $0.memo.lowercased().contains(query) ||
            $0.tag.lowercased().contains(query)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle("測定履歴とPDF", icon: "doc.richtext")
            if notes.isEmpty {
                Text("保存した測定値がここに並びます。")
                    .foregroundStyle(CraftTheme.muted)
                    .panelStyle()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("現場ごとの測定セット")
                        .font(.headline)
                    StampBookView(stamp: stampsBySite[selectedSite] ?? SiteStamp())
                    TextField("履歴を検索", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                    Picker("タグ", selection: $selectedTag) {
                        Text("すべて").tag("すべて")
                        ForEach(NoteTag.allCases) { tag in
                            Text(tag.rawValue).tag(tag.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                    Picker("現場", selection: $selectedSite) {
                        ForEach(sites, id: \.self) { site in
                            Text(site).tag(site)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .panelStyle()

                Button {
                    var stamp = stampsBySite[selectedSite] ?? SiteStamp()
                    stamp.reportDone = true
                    stampsBySite[selectedSite] = stamp
                    pdfURL = PDFReport.make(notes: visibleNotes, stamp: stamp)
                } label: {
                    Label("PDFレポートを作成", systemImage: "doc.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(CraftButtonStyle(color: CraftTheme.orange))

                if let pdfURL {
                    ShareLink(item: pdfURL) {
                        Label("PDFを共有", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(CraftButtonStyle(color: CraftTheme.steel))

                    if let qr = QRCode.make(from: pdfURL.absoluteString) {
                        VStack(spacing: 8) {
                            Image(uiImage: qr)
                                .interpolation(.none)
                                .resizable()
                                .frame(width: 180, height: 180)
                            Text("PDF共有用QR")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(CraftTheme.muted)
                        }
                        .frame(maxWidth: .infinity)
                        .panelStyle()
                    }
                }

                ForEach(visibleNotes) { note in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(note.title)
                                .font(.headline)
                            Spacer()
                            Text(note.createdAt, style: .time)
                                .font(.caption)
                                .foregroundStyle(CraftTheme.muted)
                        }
                        Text(note.siteName)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(CraftTheme.muted)
                        Text(note.tag)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(CraftTheme.orange)
                        Text(note.value)
                            .font(.title3.weight(.black))
                        if !note.memo.isEmpty {
                            Text(note.memo)
                                .font(.subheadline)
                                .foregroundStyle(CraftTheme.muted)
                        }
                    }
                    .panelStyle()
                }

                Button(role: .destructive) { notes.removeAll() } label: {
                    Label("履歴を消去", systemImage: "trash")
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

private struct UnitPicker: View {
    let title: String
    @Binding var selection: CraftUnit
    let units: [CraftUnit]

    var body: some View {
        Picker(title, selection: $selection) {
            ForEach(units) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.menu)
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct DecimalInput: View {
    let title: String
    @Binding var value: Double

    init(_ title: String, value: Binding<Double>) {
        self.title = title
        self._value = value
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(CraftTheme.muted)
            TextField(title, value: $value, format: .number)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
        }
    }
}

private struct IntInput: View {
    let title: String
    @Binding var value: Int

    init(_ title: String, value: Binding<Int>) {
        self.title = title
        self._value = value
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(CraftTheme.muted)
            TextField(title, value: $value, format: .number)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
        }
    }
}

private struct GaugeCard: View {
    let value: Double
    let label: String
    let target: Double

    var body: some View {
        VStack(spacing: 10) {
            Text(label)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.78))
            Text("\(value, specifier: "%.1f")°")
                .font(.system(size: 68, weight: .black, design: .rounded).monospacedDigit())
                .minimumScaleFactor(0.55)
            ZStack(alignment: .center) {
                Capsule().fill(.white.opacity(0.16)).frame(height: 12)
                Rectangle().fill(CraftTheme.yellow).frame(width: 4, height: 28)
                    .offset(x: CGFloat(max(-130, min(130, (value - target) * 3))))
            }
            .frame(maxWidth: 280)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(CraftTheme.ink, in: RoundedRectangle(cornerRadius: 8))
        .foregroundStyle(.white)
    }
}

private struct ResultCard: View {
    let text: String
    let unit: String

    var body: some View {
        VStack(spacing: 6) {
            Text(text)
                .font(.system(size: 48, weight: .black, design: .rounded).monospacedDigit())
                .minimumScaleFactor(0.45)
            Text(unit)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(CraftTheme.ink, in: RoundedRectangle(cornerRadius: 8))
        .foregroundStyle(.white)
    }
}

private struct StatusPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(CraftTheme.muted)
            Text(value)
                .font(.headline.weight(.black))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct StampBookView: View {
    let stamp: SiteStamp

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("測定スタンプ \(stamp.doneCount)/4")
                .font(.headline)
            HStack {
                StampCell(title: "角度", isDone: stamp.angleOK)
                StampCell(title: "水平", isDone: stamp.levelOK)
                StampCell(title: "写真", isDone: stamp.photoDone)
                StampCell(title: "PDF", isDone: stamp.reportDone)
            }
        }
    }
}

private struct StampCell: View {
    let title: String
    let isDone: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: isDone ? "seal.fill" : "seal")
                .font(.title2)
                .foregroundStyle(isDone ? CraftTheme.orange : CraftTheme.muted)
            Text(title)
                .font(.caption.weight(.bold))
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct SaveButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: "square.and.arrow.down")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(CraftButtonStyle(color: CraftTheme.orange))
    }
}

private func SectionTitle(_ title: String, icon: String) -> some View {
    HStack(spacing: 10) {
        Image(systemName: icon)
            .foregroundStyle(CraftTheme.orange)
        Text(title)
            .font(.title2.weight(.black))
        Spacer()
    }
}

private enum AppStore {
    static func load<T: Decodable>(_ key: String, fallback: T) -> T {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(T.self, from: data) else {
            return fallback
        }
        return decoded
    }

    static func save<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

private enum PDFReport {
    static func make(notes: [MeasurementNote], stamp: SiteStamp) -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("shokunin-dx-report.pdf")
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842))
        try? renderer.writePDF(to: url) { context in
            context.beginPage()
            var y: CGFloat = 42
            draw("職人スマホDX 測定レポート", size: 24, weight: .bold, y: &y)
            draw("OKスタンプ \(stamp.doneCount)/4", size: 18, weight: .bold, y: &y)
            draw("角度 \(stamp.angleOK ? "OK" : "-") / 水平 \(stamp.levelOK ? "OK" : "-") / 写真 \(stamp.photoDone ? "OK" : "-")", size: 13, weight: .regular, y: &y)
            y += 12
            for note in notes.prefix(18) {
                draw("\(note.siteName) / \(note.title)", size: 14, weight: .bold, y: &y)
                draw(note.value, size: 13, weight: .regular, y: &y)
                if !note.memo.isEmpty { draw(note.memo, size: 11, weight: .regular, y: &y) }
                y += 8
                if y > 780 {
                    context.beginPage()
                    y = 42
                }
            }
        }
        return url
    }

    private static func draw(_ text: String, size: CGFloat, weight: UIFont.Weight, y: inout CGFloat) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: UIColor.black
        ]
        text.draw(in: CGRect(x: 42, y: y, width: 511, height: 44), withAttributes: attrs)
        y += size + 10
    }
}

private final class VoiceMemo: ObservableObject {
    @Published var isRecording = false
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    func toggle(onText: @escaping (String) -> Void) {
        isRecording ? stop() : start(onText: onText)
    }

    private func start(onText: @escaping (String) -> Void) {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            guard status == .authorized else { return }
            DispatchQueue.main.async {
                self?.begin(onText: onText)
            }
        }
    }

    private func begin(onText: @escaping (String) -> Void) {
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request else { return }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? session.setActive(true, options: .notifyOthersOnDeactivation)
        let input = engine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }
        engine.prepare()
        try? engine.start()
        isRecording = true
        task = recognizer?.recognitionTask(with: request) { result, _ in
            if let text = result?.bestTranscription.formattedString {
                onText(text)
            }
        }
    }

    private func stop() {
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        isRecording = false
    }
}

private enum ExpressionCalculator {
    static func evaluate(_ expression: String) -> Double? {
        let allowed = CharacterSet(charactersIn: "0123456789.+-*/() ")
        guard expression.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return nil }
        var parser = Parser(Array(expression.filter { !$0.isWhitespace }))
        return parser.parseExpression()
    }

    private struct Parser {
        var chars: [Character]
        var index = 0

        init(_ chars: [Character]) {
            self.chars = chars
        }

        mutating func parseExpression() -> Double? {
            var value = parseTerm()
            while let op = peek(), op == "+" || op == "-" {
                advance()
                guard let rhs = parseTerm(), let lhs = value else { return nil }
                value = op == "+" ? lhs + rhs : lhs - rhs
            }
            return value
        }

        mutating private func parseTerm() -> Double? {
            var value = parseFactor()
            while let op = peek(), op == "*" || op == "/" {
                advance()
                guard let rhs = parseFactor(), let lhs = value, rhs != 0 else { return nil }
                value = op == "*" ? lhs * rhs : lhs / rhs
            }
            return value
        }

        mutating private func parseFactor() -> Double? {
            if peek() == "(" {
                advance()
                let value = parseExpression()
                guard peek() == ")" else { return nil }
                advance()
                return value
            }
            if peek() == "-" {
                advance()
                return (parseFactor() ?? 0) * -1
            }
            var text = ""
            while let char = peek(), char.isNumber || char == "." {
                text.append(char)
                advance()
            }
            return Double(text)
        }

        private func peek() -> Character? {
            index < chars.count ? chars[index] : nil
        }

        mutating private func advance() {
            index += 1
        }
    }
}

private enum QRCode {
    static func make(from string: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let transformed = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        return UIImage(ciImage: transformed)
    }
}

private struct CraftButtonStyle: ButtonStyle {
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .lineLimit(1)
            .minimumScaleFactor(0.72)
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(color.opacity(configuration.isPressed ? 0.72 : 1), in: RoundedRectangle(cornerRadius: 8))
            .foregroundStyle(.white)
    }
}

private enum CraftTheme {
    static let bg = Color(hex: 0xF4F1EA)
    static let ink = Color(hex: 0x1C2733)
    static let steel = Color(hex: 0x334155)
    static let muted = Color(hex: 0x64748B)
    static let grid = Color(hex: 0xCBD5E1)
    static let orange = Color(hex: 0xF97316)
    static let yellow = Color(hex: 0xFACC15)
    static let green = Color(hex: 0x22C55E)
}

private extension ChecklistItem {
    static let defaults = [
        ChecklistItem(title: "測定前に端末のゼロ補正を確認", isDone: false),
        ChecklistItem(title: "施工前写真を撮影", isDone: false),
        ChecklistItem(title: "角度・水平の測定値を保存", isDone: false),
        ChecklistItem(title: "材料数量をロス込みで確認", isDone: false),
        ChecklistItem(title: "完了写真に測定ラベルを追加", isDone: false)
    ]
}

private extension ConversionFavorite {
    static let defaults = [
        ConversionFavorite(title: "尺→m", kind: .length, from: .shaku, to: .meter),
        ConversionFavorite(title: "寸→mm", kind: .length, from: .sun, to: .millimeter),
        ConversionFavorite(title: "坪→m2", kind: .area, from: .tsubo, to: .squareMeter),
        ConversionFavorite(title: "m2→坪", kind: .area, from: .squareMeter, to: .tsubo)
    ]
}

private extension SiteTemplate {
    static let defaults = [
        SiteTemplate(
            name: "内装",
            checklistItems: ["施工前写真を撮影", "既存床・壁の水平を確認", "材料数量をロス込みで確認", "仕上げ後の角度・水平を保存"],
            angleTolerance: 1.0,
            levelTolerance: 0.7,
            materialLoss: 8
        ),
        SiteTemplate(
            name: "外構",
            checklistItems: ["基準線を写真で確認", "排水勾配を測定", "中心線ガイドで位置を記録", "完了写真に注釈を追加"],
            angleTolerance: 1.5,
            levelTolerance: 1.0,
            materialLoss: 12
        ),
        SiteTemplate(
            name: "設備",
            checklistItems: ["取り付け位置を中心線で確認", "水平器で左右を確認", "勾配を記録", "PDFレポートを作成"],
            angleTolerance: 0.7,
            levelTolerance: 0.5,
            materialLoss: 5
        )
    ]
}

private extension MaterialPrice {
    static let defaults = [
        MaterialPrice(name: "フロア材", kind: .flooring, unitPrice: 4200, unitCoverage: 1.65),
        MaterialPrice(name: "壁紙ロール", kind: .wallpaper, unitPrice: 6800, unitCoverage: 30.0),
        MaterialPrice(name: "塗料缶", kind: .paint, unitPrice: 5200, unitCoverage: 18.0)
    ]
}

private extension View {
    func panelStyle() -> some View {
        padding(14)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black.opacity(0.07), lineWidth: 1))
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

private extension Double {
    var rounded1: String { String(format: "%.1f", self) }
    var rounded2: String { String(format: "%.2f", self) }
    var rounded4: String { String(format: "%.4f", self) }
}

private extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 8) & 0xff) / 255,
            blue: Double(hex & 0xff) / 255,
            opacity: alpha
        )
    }
}
