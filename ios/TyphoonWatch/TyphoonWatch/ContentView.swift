import SwiftUI

struct ContentView: View {
    @StateObject private var model = TyphoonViewModel()

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let safeWidth = max(260, proxy.size.width - proxy.safeAreaInsets.leading - proxy.safeAreaInsets.trailing)
                let contentWidth = min(430, max(248, safeWidth - 36))
                let metrics = LayoutMetrics(width: contentWidth, height: proxy.size.height)

                ZStack {
                    Image("TyphoonHeroBackdrop")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                        .overlay(Color.black.opacity(0.46))

                    ScrollView {
                        VStack(spacing: metrics.sectionSpacing) {
                            header(metrics)
                            riskDeck(metrics)
                            trackCard(metrics)
                            feedStrip(metrics)
                            timelineCard(metrics)
                        }
                        .frame(width: contentWidth, alignment: .topLeading)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, max(12, proxy.safeAreaInsets.top + 8))
                        .padding(.bottom, max(22, proxy.safeAreaInsets.bottom + 22))
                    }
                    .scrollIndicators(.hidden)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationBarHidden(true)
            .task {
                await model.refresh()
            }
            .refreshable {
                await model.refresh()
            }
        }
        .tint(.cyan)
    }

    private func header(_ metrics: LayoutMetrics) -> some View {
        CompactPanel(metrics: metrics, style: .hero) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("台風を観測")
                            .font(.system(size: metrics.titleSize, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)

                        Text(model.storm.name)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.78))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    Button {
                        Task { await model.refresh() }
                    } label: {
                        Image(systemName: model.isLoading ? "waveform" : "arrow.clockwise")
                            .font(.headline.weight(.bold))
                            .frame(width: metrics.refreshButtonSize, height: metrics.refreshButtonSize)
                            .background(Color.white.opacity(0.13), in: Circle())
                    }
                    .accessibilityLabel("更新")
                }

                HStack(spacing: 8) {
                    Label(model.statusText, systemImage: model.isLoading ? "arrow.triangle.2.circlepath" : "checkmark.seal.fill")
                    Spacer(minLength: 6)
                    Text(model.storm.updatedAt.compactTime)
                }
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.78))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            }
        }
    }

    private func riskDeck(_ metrics: LayoutMetrics) -> some View {
        CompactPanel(metrics: metrics) {
            VStack(alignment: .leading, spacing: metrics.innerSpacing) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("現在の判断")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.cyan.opacity(0.9))
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(model.selectedRegion.name)
                            .font(.system(size: metrics.headlineSize, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)

                        Text(model.risk.level.rawValue)
                            .font(.caption.weight(.black))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(Color(hex: model.risk.level.colorHex).opacity(0.22), in: Capsule())
                            .foregroundStyle(Color(hex: model.risk.level.colorHex))
                            .lineLimit(1)
                    }
                }

                Menu {
                    Picker("地域を選択", selection: $model.selectedRegion) {
                        ForEach(AppData.regions) { region in
                            Text(region.name).tag(region)
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "location.viewfinder")
                        Text(model.selectedRegion.name)
                            .font(.subheadline.weight(.bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption.weight(.black))
                            .foregroundStyle(.white.opacity(0.58))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(minHeight: 44)
                    .background(Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(.white)
                    .contentShape(RoundedRectangle(cornerRadius: 8))
                }
                .accessibilityLabel("地域を選択")

                Text(model.risk.summary)
                    .font(.footnote)
                    .foregroundStyle(.white)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                ProgressView(value: min(model.risk.score, 100), total: 100)
                    .tint(Color(hex: model.risk.level.colorHex))
                    .scaleEffect(x: 1, y: 1.6, anchor: .center)

                HStack(spacing: 8) {
                    Text("リスク目安")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.62))
                    Spacer(minLength: 0)
                    Text("\(Int(min(model.risk.score, 100).rounded()))%")
                        .font(.caption.weight(.black))
                        .foregroundStyle(Color(hex: model.risk.level.colorHex))
                }
                .accessibilityLabel("リスク目安 \(Int(min(model.risk.score, 100).rounded()))パーセント")

                LazyVGrid(columns: metrics.metricColumns, spacing: 8) {
                    MetricTile(title: "最接近", value: model.risk.closestAt?.compactTime ?? "不明")
                    MetricTile(title: "最短距離", value: "\(Int(model.risk.closestKm.rounded())) km")
                    MetricTile(title: "最大風速", value: model.risk.maxWind.map { "\($0) kt" } ?? "不明")
                    MetricTile(title: "データ", value: model.statusText)
                }
            }
        }
    }

    private func trackCard(_ metrics: LayoutMetrics) -> some View {
        CompactPanel(metrics: metrics) {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 3) {
                    Label("進路", systemImage: "scope")
                        .font(.headline.weight(.black))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(model.storm.source)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white.opacity(0.64))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                }
                .foregroundStyle(.white)

                TrackMap(points: model.storm.points, region: model.selectedRegion)
                    .frame(height: metrics.mapHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                LazyVGrid(columns: [GridItem(.adaptive(minimum: metrics.actionMinWidth), spacing: 8)], spacing: 8) {
                    ForEach(model.risk.actions, id: \.self) { action in
                        Label(action, systemImage: "checkmark.circle.fill")
                            .font(.caption2.weight(.bold))
                            .lineLimit(3)
                            .minimumScaleFactor(0.74)
                            .labelStyle(.titleAndIcon)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(.white.opacity(0.88))
                    }
                }
            }
        }
    }

    private func feedStrip(_ metrics: LayoutMetrics) -> some View {
        CompactPanel(metrics: metrics) {
            VStack(alignment: .leading, spacing: 10) {
                Label("データ元", systemImage: "antenna.radiowaves.left.and.right")
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)

                VStack(spacing: 8) {
                    ForEach(AppData.feeds.prefix(metrics.feedLimit)) { feed in
                        Link(destination: URL(string: feed.url)!) {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.up.forward.app")
                                    .font(.caption.weight(.black))
                                    .frame(width: 26, height: 26)
                                    .background(Color.white.opacity(0.1), in: Circle())

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(feed.name)
                                        .font(.subheadline.weight(.black))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.78)
                                    Text(feed.detail)
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.62))
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Spacer(minLength: 4)
                            }
                            .padding(10)
                            .frame(minHeight: 52)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(.white)
                            .contentShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
        }
    }

    private func timelineCard(_ metrics: LayoutMetrics) -> some View {
        CompactPanel(metrics: metrics) {
            VStack(alignment: .leading, spacing: 10) {
                Label("観測リスト", systemImage: "list.bullet.rectangle")
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)

                ForEach(model.storm.points.suffix(8)) { point in
                    timelineRow(point, metrics: metrics)
                }
            }
        }
    }

    private func timelineRow(_ point: TyphoonPoint, metrics: LayoutMetrics) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(point.time.compactTime)
                    .font(.caption.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                if point.isForecast {
                    Text("予報")
                        .font(.caption2.weight(.black))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color(hex: 0xF2B84B).opacity(0.22), in: Capsule())
                        .foregroundStyle(Color(hex: 0xF2B84B))
                }

                Spacer(minLength: 0)
            }

            if metrics.isNarrow {
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(point.latitude, specifier: "%.1f")N \(point.longitude, specifier: "%.1f")E")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    HStack(spacing: 10) {
                        Text("\(point.pressure.map(String.init) ?? "--") hPa")
                            .font(.caption.weight(.bold))
                            .lineLimit(1)

                        Text("\(point.wind.map(String.init) ?? "--") kt")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.cyan.opacity(0.9))
                            .lineLimit(1)
                    }
                }
            } else {
                HStack(spacing: 10) {
                    Text("\(point.latitude, specifier: "%.1f")N \(point.longitude, specifier: "%.1f")E")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Spacer(minLength: 0)

                    Text("\(point.pressure.map(String.init) ?? "--") hPa")
                        .font(.caption.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Text("\(point.wind.map(String.init) ?? "--") kt")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.cyan.opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
            }
        }
        .foregroundStyle(.white)
        .padding(.vertical, metrics.timelineVerticalPadding)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct LayoutMetrics {
    let width: CGFloat
    let height: CGFloat

    var isNarrow: Bool { width <= 375 }
    var sectionSpacing: CGFloat { isNarrow ? 9 : 14 }
    var innerSpacing: CGFloat { isNarrow ? 10 : 12 }
    var titleSize: CGFloat { isNarrow ? 24 : 32 }
    var headlineSize: CGFloat { isNarrow ? 20 : 24 }
    var refreshButtonSize: CGFloat { 44 }
    var panelPadding: CGFloat { isNarrow ? 11 : 14 }
    var panelCornerRadius: CGFloat { isNarrow ? 10 : 12 }
    var mapHeight: CGFloat {
        let availableWidth = width - panelPadding * 2
        let ratio = isNarrow ? 0.62 : 0.72
        return min(isNarrow ? 190 : 280, max(isNarrow ? 154 : 220, availableWidth * ratio))
    }
    var actionMinWidth: CGFloat { isNarrow ? width - panelPadding * 2 : 132 }
    var feedLimit: Int { isNarrow ? 4 : 6 }
    var timelineVerticalPadding: CGFloat { isNarrow ? 6 : 7 }
    var metricColumns: [GridItem] {
        if isNarrow {
            return [GridItem(.flexible(), spacing: 8)]
        }
        return Array(repeating: GridItem(.flexible(), spacing: 8), count: 2)
    }
}

private struct TrackMap: View {
    let points: [TyphoonPoint]
    let region: MonitorRegion

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)
            context.fill(Path(rect), with: .linearGradient(
                Gradient(colors: [Color(hex: 0x155F6B), Color(hex: 0x061F27)]),
                startPoint: .zero,
                endPoint: CGPoint(x: size.width, y: size.height)
            ))

            drawGrid(context: &context, size: size)
            drawTrack(context: &context, size: size)
            drawRegion(context: &context, size: size)
        }
    }

    private func drawGrid(context: inout GraphicsContext, size: CGSize) {
        var path = Path()
        stride(from: 0.0, through: size.width, by: 44).forEach { x in
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
        }
        stride(from: 0.0, through: size.height, by: 44).forEach { y in
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
        }
        context.stroke(path, with: .color(.white.opacity(0.12)), lineWidth: 1)
    }

    private func drawTrack(context: inout GraphicsContext, size: CGSize) {
        let projected = points.map { project($0, size: size) }
        guard projected.count > 1 else { return }

        var path = Path()
        path.move(to: projected[0])
        projected.dropFirst().forEach { path.addLine(to: $0) }
        context.stroke(path, with: .color(Color(hex: 0xF7E7A4)), lineWidth: 4)

        for (index, point) in projected.enumerated() {
            let circle = Path(ellipseIn: CGRect(x: point.x - 6, y: point.y - 6, width: 12, height: 12))
            let fill = index >= projected.count - 3 ? Color(hex: 0xFF6A4A) : Color(hex: 0x74D1C6)
            context.fill(circle, with: .color(fill))
            context.stroke(circle, with: .color(.white.opacity(0.9)), lineWidth: 1.5)
        }
    }

    private func drawRegion(context: inout GraphicsContext, size: CGSize) {
        let p = project(latitude: region.latitude, longitude: region.longitude, size: size)
        let marker = Path(ellipseIn: CGRect(x: p.x - 8, y: p.y - 8, width: 16, height: 16))
        context.fill(marker, with: .color(.white))
        context.stroke(marker, with: .color(Color(hex: 0xFF6A4A)), lineWidth: 3)
    }

    private func project(_ point: TyphoonPoint, size: CGSize) -> CGPoint {
        project(latitude: point.latitude, longitude: point.longitude, size: size)
    }

    private func project(latitude: Double, longitude: Double, size: CGSize) -> CGPoint {
        let bounds = (minLat: 18.0, maxLat: 46.0, minLon: 120.0, maxLon: 148.0)
        let padding = 22.0
        let x = padding + ((longitude - bounds.minLon) / (bounds.maxLon - bounds.minLon)) * (size.width - padding * 2)
        let y = padding + ((bounds.maxLat - latitude) / (bounds.maxLat - bounds.minLat)) * (size.height - padding * 2)
        return CGPoint(
            x: min(max(x, padding), size.width - padding),
            y: min(max(y, padding), size.height - padding)
        )
    }
}

private struct CompactPanel<Content: View>: View {
    enum Style {
        case standard
        case hero
    }

    let metrics: LayoutMetrics
    let style: Style
    let content: Content

    init(metrics: LayoutMetrics, style: Style = .standard, @ViewBuilder content: () -> Content) {
        self.metrics = metrics
        self.style = style
        self.content = content()
    }

    var body: some View {
        content
            .padding(metrics.panelPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: metrics.panelCornerRadius, style: .continuous)
                        .fill(style == .hero ? Color(hex: 0x0A3E46).opacity(0.84) : Color.white.opacity(0.08))
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: metrics.panelCornerRadius, style: .continuous))

                    Image("RadarPanelTexture")
                        .resizable()
                        .scaledToFill()
                        .opacity(0.16)
                        .blendMode(.screen)
                        .clipShape(RoundedRectangle(cornerRadius: metrics.panelCornerRadius, style: .continuous))
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: metrics.panelCornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.16), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: metrics.panelCornerRadius, style: .continuous))
    }
}

private struct MetricTile: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.58))
                .frame(minWidth: 58, alignment: .leading)
            Text(value)
                .font(.subheadline.weight(.black))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }
}

private extension Date {
    var compactTime: String {
        formatted(.dateTime.month(.twoDigits).day(.twoDigits).hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
    }
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
