import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appModel: WeatherAppModel
    @EnvironmentObject private var adService: AdService
    @StateObject private var interstitial = InterstitialAdCoordinator()
    @State private var didStartMainFlow = false

    var body: some View {
        TabView(selection: $appModel.selectedTab) {
            HomeView()
                .tabItem { Label("ホーム", systemImage: "house.fill") }
                .tag(AppTab.home)

            WeekView()
                .tabItem { Label("週間", systemImage: "calendar") }
                .tag(AppTab.week)

            NotificationSettingsView()
                .tabItem { Label("通知", systemImage: "bell.fill") }
                .tag(AppTab.notifications)

            AppSettingsView()
                .tabItem { Label("設定", systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
        }
        .tint(.blue)
        .task {
            await adService.prepareForLaunch()
            await startMainFlowIfReady()
        }
        .onChange(of: adService.didCompleteTrackingFlow) { _, _ in
            Task { await startMainFlowIfReady() }
        }
        .onChange(of: appModel.selectedTab) { _, tab in
            if tab == .week {
                interstitial.showIfReady()
            }
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { adService.shouldShowTrackingPermissionGate },
                set: { _ in }
            )
        ) {
            TrackingPermissionIntroView {
                Task {
                    await adService.requestTrackingAuthorizationFromGate()
                    await startMainFlowIfReady()
                }
            }
            .interactiveDismissDisabled(true)
        }
    }

    @MainActor
    private func startMainFlowIfReady() async {
        guard adService.didCompleteTrackingFlow, !didStartMainFlow else { return }
        didStartMainFlow = true
        await appModel.refresh()
        interstitial.load()
    }
}

private struct TrackingPermissionIntroView: View {
    let onContinue: () -> Void
    @State private var isRequesting = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.91, green: 0.97, blue: 1.0),
                    Color(red: 1.0, green: 0.96, blue: 0.88)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 56, weight: .semibold))

                VStack(spacing: 12) {
                    Text("広告の確認")
                        .font(.largeTitle.bold())

                    Text("服装気温では、広告の表示と効果測定のためにトラッキング許可を確認します。許可しなくても、天気と服装の提案はそのまま使えます。")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .frame(maxWidth: 520)
                }

                Button {
                    guard !isRequesting else { return }
                    isRequesting = true
                    onContinue()
                } label: {
                    HStack(spacing: 8) {
                        if isRequesting {
                            ProgressView()
                                .tint(.white)
                        }
                        Text("続ける")
                            .font(.headline)
                    }
                    .frame(maxWidth: 320)
                    .padding(.vertical, 15)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRequesting)
            }
            .padding(28)
        }
    }
}

struct HomeView: View {
    @EnvironmentObject private var appModel: WeatherAppModel

    private var todayAdvice: OutfitAdvice {
        appModel.advice(for: appModel.snapshot.today)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    HeroWeatherCard(snapshot: appModel.snapshot, advice: todayAdvice)

                    AdvicePanel(title: "おすすめ服装", advice: todayAdvice)

                    UmbrellaPanel(advice: todayAdvice, rainPercent: appModel.snapshot.today.rainPercent)

                    TodayMetricsGrid(forecast: appModel.snapshot.today)

                    WeatherAttributionView()

                    AdMobBannerSlotView(placement: .homeBottom)
                        .padding(.top, 4)
                }
                .padding(18)
            }
            .background(LinearGradient(
                colors: [Color(red: 0.93, green: 0.97, blue: 1), Color(red: 1, green: 0.98, blue: 0.92)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .navigationTitle("今日なに着る？")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await appModel.refresh() }
                    } label: {
                        Image(systemName: appModel.isLoading ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                    }
                    .accessibilityLabel("更新")
                }
            }
            .overlay(alignment: .bottom) {
                if let message = appModel.errorMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.black.opacity(0.75), in: Capsule())
                        .padding(.bottom, 10)
                }
            }
        }
    }
}

struct HeroWeatherCard: View {
    let snapshot: WeatherSnapshot
    let advice: OutfitAdvice

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(snapshot.locationName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("\(Int(snapshot.currentTemperature.rounded()))℃")
                        .font(.system(size: 64, weight: .black, design: .rounded))
                        .monospacedDigit()
                    Text(snapshot.currentCondition)
                        .font(.headline)

                    WeatherAttributionInlineView()
                        .padding(.top, 4)
                }

                Spacer()

                Image(systemName: snapshot.currentSymbolName)
                    .symbolRenderingMode(.multicolor)
                    .font(.system(size: 58))
            }

            HStack(spacing: 10) {
                TemperatureChip(title: "最高", value: snapshot.today.high)
                TemperatureChip(title: "最低", value: snapshot.today.low)
                Text(advice.accent)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .frame(height: 34)
                    .background(Color(red: 0.08, green: 0.28, blue: 0.55), in: Capsule())
            }
        }
        .padding(20)
        .background(.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.9), lineWidth: 1)
        )
        .shadow(color: .blue.opacity(0.12), radius: 18, x: 0, y: 10)
    }
}

struct TemperatureChip: View {
    let title: String
    let value: Double

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
            Text("\(Int(value.rounded()))℃")
                .monospacedDigit()
                .fontWeight(.bold)
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .frame(height: 34)
        .background(Color.black.opacity(0.06), in: Capsule())
    }
}

struct AdvicePanel: View {
    let title: String
    let advice: OutfitAdvice

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: "tshirt.fill")
                .font(.headline)

            Text(advice.title)
                .font(.title3.weight(.bold))

            ForEach(advice.details, id: \.self) { detail in
                Label(detail, systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct UmbrellaPanel: View {
    let advice: OutfitAdvice
    let rainPercent: Int

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: advice.umbrella == .none ? "sun.max.fill" : "umbrella.fill")
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 36))
                .frame(width: 52, height: 52)
                .background(Color.white, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("傘いる？")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Text(advice.umbrella.rawValue)
                    .font(.headline)
                Text("降水確率 \(rainPercent)%")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(18)
        .background(Color(red: 0.88, green: 0.94, blue: 1), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct TodayMetricsGrid: View {
    let forecast: DayForecast

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MetricTile(icon: "drop.fill", title: "降水確率", value: "\(forecast.rainPercent)%")
            MetricTile(icon: "wind", title: "風速", value: String(format: "%.1f m/s", forecast.windSpeed))
            MetricTile(icon: "sun.max.fill", title: "UV指数", value: "\(forecast.uvIndex)")
            MetricTile(icon: "thermometer.medium", title: "気温差", value: "\(Int((forecast.high - forecast.low).rounded()))℃")
        }
    }
}

struct MetricTile: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct WeatherAttributionView: View {
    var body: some View {
        Link(destination: URL(string: "https://weatherkit.apple.com/legal-attribution.html")!) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Weather data provided by  Weather")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)

                Text("https://weatherkit.apple.com/legal-attribution.html")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.blue)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Weather data provided by Apple Weather. Legal attribution link.")
    }
}

struct WeatherAttributionInlineView: View {
    var body: some View {
        Link(destination: URL(string: "https://weatherkit.apple.com/legal-attribution.html")!) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Weather data provided by  Weather")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("https://weatherkit.apple.com/legal-attribution.html")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.blue)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Weather data provided by Apple Weather. Legal attribution link.")
    }
}

struct WeekView: View {
    @EnvironmentObject private var appModel: WeatherAppModel

    var body: some View {
        NavigationStack {
            List {
                ForEach(appModel.snapshot.week) { day in
                    let advice = appModel.advice(for: day)
                    HStack(spacing: 14) {
                        Image(systemName: day.symbolName)
                            .symbolRenderingMode(.multicolor)
                            .font(.title2)
                            .frame(width: 34)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(day.date, format: .dateTime.weekday(.wide).month().day())
                                .font(.headline)
                            Text(advice.title)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(Int(day.high.rounded())) / \(Int(day.low.rounded()))℃")
                                .font(.subheadline.monospacedDigit().weight(.bold))
                            Text("\(day.rainPercent)%")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(day.rainPercent >= 40 ? .blue : .secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                WeatherAttributionView()
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
            }
            .navigationTitle("7日分の服装")
        }
    }
}

struct NotificationSettingsView: View {
    @EnvironmentObject private var appModel: WeatherAppModel

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("朝の通知", isOn: $appModel.notificationsEnabled)
                        .onChange(of: appModel.notificationsEnabled) {
                            Task { await appModel.updateNotification() }
                        }

                    Picker("通知時間", selection: $appModel.notificationHour) {
                        ForEach(NotificationHour.allCases) { hour in
                            Text(hour.label).tag(hour)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: appModel.notificationHour) {
                        Task { await appModel.updateNotification() }
                    }
                } footer: {
                    Text("朝7時、8時、9時から選べます。")
                }
            }
            .navigationTitle("通知設定")
        }
    }
}

struct AppSettingsView: View {
    @EnvironmentObject private var appModel: WeatherAppModel

    var body: some View {
        NavigationStack {
            Form {
                Section("体感") {
                    Picker("暑さ寒さ", selection: $appModel.temperatureSense) {
                        ForEach(TemperatureSense.allCases) { sense in
                            Text(sense.rawValue).tag(sense)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("服装タイプ") {
                    Picker("提案", selection: $appModel.styleTarget) {
                        ForEach(StyleTarget.allCases) { target in
                            Text(target.rawValue).tag(target)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("広告") {
                    HStack {
                        Label("広告なし課金", systemImage: "sparkles")
                        Spacer()
                        Text("準備中")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("設定")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WeatherAppModel())
}
