import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var model = TyphoonViewModel()
    @State private var viewportSize: CGSize = .zero
    private var metrics: LayoutMetrics {
        LayoutMetrics(
            width: viewportSize.width > 0 ? viewportSize.width : UIScreen.main.bounds.width,
            height: viewportSize.height > 0 ? viewportSize.height : UIScreen.main.bounds.height
        )
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let metrics = LayoutMetrics(width: proxy.size.width, height: proxy.size.height)

                ZStack {
                    Image("TyphoonHeroBackdrop")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                        .overlay(Color.black.opacity(0.46))

                    ScrollView {
                        VStack(spacing: metrics.sectionSpacing) {
                            header
                            riskDeck
                            trackCard
                            feedStrip
                            timelineCard
                        }
                        .padding(.horizontal, metrics.screenPadding)
                        .padding(.top, max(8, proxy.safeAreaInsets.top + 6))
                        .padding(.bottom, max(18, proxy.safeAreaInsets.bottom + 18))
                        .frame(width: metrics.contentWidth, alignment: .topLeading)
                    }
                }
                .onAppear {
                    viewportSize = proxy.size
                }
                .onChange(of: proxy.size) { _, newSize in
                    viewportSize = newSize
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

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Typhoon Watch")
                    .font(.system(size: metrics.titleSize, weight: .black, design: .serif))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)

                Text(model.storm.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(2)
            }

            Spacer()

            Button {
                Task { await model.refresh() }
            } label: {
                Image(systemName: model.isLoading ? "waveform" : "arrow.clockwise")
                    .font(.headline.weight(.bold))
                    .frame(width: metrics.refreshButtonSize, height: metrics.refreshButtonSize)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .accessibilityLabel("更新")
        }
    }

    private var riskDeck: some View {
        CompactPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("現在の判断")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.cyan.opacity(0.9))
                        Text("\(model.selectedRegion.name) \(model.risk.level.rawValue)")
                            .font(.title2.weight(.black))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .minimumScaleFactor(0.76)
                    }
                    Spacer()
                    Text(model.statusText)
                        .font(.caption.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(hex: model.risk.level.colorHex).opacity(0.22), in: Capsule())
                        .foregroundStyle(Color(hex: model.risk.level.colorHex))
                }

                Menu {
                    Picker("監視地点", selection: $model.selectedRegion) {
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
                    .background(Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 8))
                    .foregroundStyle(.white)
                }

                ProgressView(value: min(model.risk.score, 100), total: 100)
                    .tint(Color(hex: model.risk.level.colorHex))
                    .scaleEffect(x: 1, y: 1.6, anchor: .center)

                Text(model.risk.summary)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.78))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                    MetricTile(title: "最接近", value: model.risk.closestAt?.compactTime ?? "不明")
                    MetricTile(title: "最短距離", value: "\(Int(model.risk.closestKm.rounded())) km")
                    MetricTile(title: "最大風速", value: model.risk.maxWind.map { "\($0) kt" } ?? "不明")
                    MetricTile(title: "更新", value: model.storm.updatedAt.compactTime)
                }
            }
        }
    }

    private var trackCard: some View {
        CompactPanel {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("進路", systemImage: "scope")
                        .font(.headline.weight(.black))
                    Spacer()
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
                        Text(action)
                            .font(.caption2.weight(.bold))
                            .lineLimit(2)
                            .minimumScaleFactor(0.72)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(.white.opacity(0.88))
                    }
                }
            }
        }
    }

    private var feedStrip: some View {
        CompactPanel {
            VStack(alignment: .leading, spacing: 10) {
                Label("データ元", systemImage: "antenna.radiowaves.left.and.right")
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(AppData.feeds) { feed in
                            Link(destination: URL(string: feed.url)!) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(feed.name)
                                        .font(.subheadline.weight(.black))
                                    Text(feed.detail)
                                        .font(.caption2)
                                        .foregroundStyle(.white.opacity(0.62))
                                        .lineLimit(2)
                                }
                                .frame(width: metrics.feedWidth, alignment: .leading)
                                .padding(10)
                                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                                .foregroundStyle(.white)
                            }
                        }
                    }
                }
            }
        }
    }

    private var timelineCard: some View {
        CompactPanel {
            VStack(alignment: .leading, spacing: 10) {
                Label("観測リスト", systemImage: "list.bullet.rectangle")
                    .font(.headline.weight(.black))
                    .foregroundStyle(.white)

                ForEach(model.storm.points.suffix(8)) { point in
                    timelineRow(point)
                }
            }
        }
    }

    private func timelineRow(_ point: TyphoonPoint) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Text(point.time.compactTime)
                    .font(.caption.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)

                Spacer(minLength: 6)

                Text("\(point.pressure.map(String.init) ?? "--") hPa")
                    .font(.caption.weight(.bold))
                    .lineLimit(1)

                Text("\(point.wind.map(String.init) ?? "--") kt")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.cyan.opacity(0.9))
                    .lineLimit(1)
            }

            Text("\(point.latitude, specifier: "%.1f")N \(point.longitude, specifier: "%.1f")E")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
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
    var screenPadding: CGFloat { isNarrow ? 10 : 16 }
    var contentWidth: CGFloat { max(0, width - screenPadding * 2) }
    var sectionSpacing: CGFloat { isNarrow ? 10 : 14 }
    var titleSize: CGFloat { isNarrow ? 28 : 34 }
    var refreshButtonSize: CGFloat { isNarrow ? 38 : 42 }
    var panelPadding: CGFloat { isNarrow ? 10 : 14 }
    var panelCornerRadius: CGFloat { isNarrow ? 10 : 12 }
    var mapHeight: CGFloat {
        let availableWidth = width - screenPadding * 2 - panelPadding * 2
        let ratio = isNarrow ? 0.62 : 0.72
        return min(isNarrow ? 220 : 280, max(isNarrow ? 168 : 220, availableWidth * ratio))
    }
    var actionMinWidth: CGFloat { isNarrow ? 118 : 132 }
    var feedWidth: CGFloat { isNarrow ? 124 : 142 }
    var timelineVerticalPadding: CGFloat { isNarrow ? 6 : 7 }
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
    let content: Content
    private var metrics: LayoutMetrics {
        LayoutMetrics(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    }

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(metrics.panelPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: metrics.panelCornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)

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
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.58))
            Text(value)
                .font(.subheadline.weight(.black))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
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
