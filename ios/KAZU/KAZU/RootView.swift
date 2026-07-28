import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: CalculatorStore
    @State private var selectedTab: RootTab = .calculator

    var body: some View {
        TabView(selection: $selectedTab) {
            CalculatorHomeView()
                .tabItem { Label("電卓", systemImage: "plus.forwardslash.minus") }
                .tag(RootTab.calculator)
            FormulaLibraryView()
                .tabItem { Label("公式", systemImage: "sum") }
                .tag(RootTab.formulas)
            HistoryView {
                selectedTab = .calculator
            }
            .tabItem { Label("履歴", systemImage: "clock.arrow.circlepath") }
            .tag(RootTab.history)
        }
        .tint(KazuTheme.cobalt)
    }
}

struct CalculatorHomeView: View {
    @EnvironmentObject private var store: CalculatorStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    DisplayPanel()
                    ModePicker()
                    modeContent
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .background(KazuTheme.canvas.ignoresSafeArea())
            .background(KeyboardDismissBridge())
            .navigationTitle("KAZU")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完了") { KeyboardDismissBridge.dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private var modeContent: some View {
        switch store.mode {
        case .standard, .scientific:
            CalculatorKeypad(scientific: store.mode == .scientific)
        case .finance: FinanceCalculatorView()
        case .convert: ConversionCalculatorView()
        case .date: DateCalculatorView()
        case .statistics: StatisticsCalculatorView()
        case .geometry: GeometryCalculatorView()
        case .compound: CompoundInterestCalculatorView()
        case .percentage: PercentageCalculatorView()
        case .health: HealthCalculatorView()
        case .electrical: ElectricalCalculatorView()
        }
    }
}

private struct DisplayPanel: View {
    @EnvironmentObject private var store: CalculatorStore

    var body: some View {
        VStack(alignment: .trailing, spacing: 12) {
            HStack {
                Label(store.mode.rawValue, systemImage: store.mode.symbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))
                Spacer()
                if store.mode == .scientific {
                    Button(store.isDegrees ? "DEG" : "RAD") {
                        store.isDegrees.toggle()
                    }
                    .font(.caption.monospaced().weight(.bold))
                    .foregroundStyle(.white)
                }
            }
            Text(store.expression.isEmpty ? " " : store.expression)
                .font(.body.monospaced())
                .foregroundStyle(.white.opacity(0.58))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(store.display)
                .font(.system(size: 52, weight: .light, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.42)
                .contentTransition(.numericText())
        }
        .padding(22)
        .frame(maxWidth: .infinity, minHeight: 176)
        .background(KazuTheme.navy, in: RoundedRectangle(cornerRadius: 26))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("計算結果 \(store.display)")
    }
}

private struct ModePicker: View {
    @EnvironmentObject private var store: CalculatorStore

    var body: some View {
        ScrollViewReader { proxy in
            ZStack(alignment: .trailing) {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(CalculatorMode.allCases) { mode in
                            Button {
                                withAnimation(.snappy) { store.mode = mode }
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: mode.symbol)
                                        .font(.system(size: 17, weight: .semibold))
                                    Text(mode.rawValue).font(.caption2.weight(.semibold))
                                }
                                .frame(width: 64, height: 58)
                                .foregroundStyle(store.mode == mode ? .white : KazuTheme.ink)
                                .background(store.mode == mode ? KazuTheme.cobalt : Color.white.opacity(0.7),
                                            in: RoundedRectangle(cornerRadius: 15))
                                .overlay(RoundedRectangle(cornerRadius: 15)
                                    .stroke(store.mode == mode ? .clear : KazuTheme.line.opacity(0.7)))
                            }
                            .id(mode)
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(mode.rawValue)電卓")
                        }
                    }
                    .padding(.trailing, 48)
                }
                .scrollIndicators(.hidden)

                if store.mode != CalculatorMode.allCases.last {
                    Button {
                        showNextMode(using: proxy)
                    } label: {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(KazuTheme.cobalt, in: Circle())
                            .shadow(color: KazuTheme.navy.opacity(0.2), radius: 7, y: 2)
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 4)
                    .accessibilityLabel("次の専門計算を表示")
                }
            }
        }
    }

    private func showNextMode(using proxy: ScrollViewProxy) {
        guard
            let index = CalculatorMode.allCases.firstIndex(of: store.mode),
            CalculatorMode.allCases.indices.contains(index + 1)
        else { return }

        let nextMode = CalculatorMode.allCases[index + 1]
        withAnimation(.snappy) {
            store.mode = nextMode
            proxy.scrollTo(nextMode, anchor: .center)
        }
    }
}
