import SwiftUI
import SwiftData
import MapKit

struct SpotDetailView: View {
    @Environment(\.modelContext) private var context
    @Query private var favorites: [Favorite]
    let spot: Spot; let distance: Double
    @State private var showReport = false
    var isFavorite: Bool { favorites.contains { $0.spotID == spot.id } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ZStack(alignment: .bottomLeading) {
                    Image("cool-breeze-background")
                        .resizable()
                        .scaledToFill()
                        .frame(height: 170)
                        .clipped()
                    LinearGradient(
                        colors: [.clear, Theme.deepBlue.opacity(0.82)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    HStack(spacing: 10) {
                        Image(systemName: spot.categoryIcon)
                            .font(.title2.weight(.bold))
                            .frame(width: 48, height: 48)
                            .background(spot.categoryColor.gradient, in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(spot.category).font(.caption.weight(.semibold))
                            Text(spot.priceText).font(.headline)
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(18)
                }
                .clipShape(RoundedRectangle(cornerRadius: 24))
                Map(initialPosition: .region(.init(center: spot.coordinate, span: .init(latitudeDelta: 0.02, longitudeDelta: 0.02)))) { Marker(spot.name, coordinate: spot.coordinate).tint(Theme.blue) }
                    .frame(height: 190).clipShape(RoundedRectangle(cornerRadius: 24)).allowsHitTesting(false)
                VStack(alignment: .leading, spacing: 8) {
                    Text(spot.category).font(.subheadline).foregroundStyle(Theme.blue)
                    Text(spot.name).font(.largeTitle.bold())
                    if !spot.address.isEmpty { Text(spot.address).foregroundStyle(.secondary) }
                    HStack { Badge(spot.priceText); Badge("徒歩目安 \(Int(distance / 4.5 * 60))分"); Badge(spot.stayText) }
                }
                scoreGrid
                detailRows
                Text(spot.notes).padding().frame(maxWidth: .infinity, alignment: .leading).background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                if let officialURL = URL(string: spot.officialURL), !spot.officialURL.isEmpty {
                    Link(destination: officialURL) { Label("公式サイトを確認", systemImage: "safari").frame(maxWidth: .infinity) }
                        .buttonStyle(.bordered)
                }
                if let sourceName = spot.sourceName, let sourceURL = spot.sourceURL, let url = URL(string: sourceURL) {
                    HStack { Text("データ提供").foregroundStyle(.secondary); Spacer(); Link(sourceName, destination: url).bold() }
                    if sourceName.contains("OpenStreetMap") {
                        Link("OpenStreetMapの著作権とライセンス", destination: URL(string: "https://www.openstreetmap.org/copyright")!)
                            .font(.caption)
                    }
                }
                Button { openMaps() } label: { Label("Appleマップで経路を開く", systemImage: "arrow.triangle.turn.up.right.diamond.fill").frame(maxWidth: .infinity) }.buttonStyle(.borderedProminent).controlSize(.large)
                Button("情報の修正を報告") { showReport = true }.frame(maxWidth: .infinity)
                Text("最終確認: \(spot.lastVerifiedAt)　\(spot.verificationText)。営業時間や利用条件は現地・公式情報も確認してください。") .font(.caption).foregroundStyle(.secondary)
            }.padding()
        }
        .background(LinearGradient(colors: [Theme.ice.opacity(0.45), Color(uiColor: .systemBackground)], startPoint: .top, endPoint: .center))
        .navigationTitle("スポット詳細").navigationBarTitleDisplayMode(.inline)
            .toolbar { Button { toggleFavorite() } label: { Image(systemName: isFavorite ? "heart.fill" : "heart").foregroundStyle(isFavorite ? .pink : .primary) }.accessibilityLabel(isFavorite ? "お気に入りから削除" : "お気に入りに追加") }
            .sheet(isPresented: $showReport) { ReportView(spot: spot) }
    }
    var scoreGrid: some View { Grid(horizontalSpacing: 10, verticalSpacing: 10) { GridRow { score("涼しさ", spot.airConditioned == true ? 5 : 0); score("面白さ", spot.funScore) }; GridRow { score("居やすさ", spot.stayScore); score("一人向け", spot.soloFriendly) } } }
    func score(_ title: String, _ value: Int) -> some View { VStack { Text(title).font(.caption); Text(String(repeating: "★", count: value)).foregroundStyle(.orange).minimumScaleFactor(0.7) }.padding().frame(maxWidth: .infinity).background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14)) }
    var detailRows: some View { VStack(spacing: 12) { row("営業時間", spot.openingHoursText); row("冷房", spot.availabilityText(spot.airConditioned)); row("座席", spot.availabilityText(spot.hasSeats)); row("トイレ", spot.availabilityText(spot.hasToilet)); row("Wi-Fi / 電源", "\(spot.availabilityText(spot.hasWifi)) / \(spot.availabilityText(spot.hasPower))") } }
    func row(_ title: String, _ value: String) -> some View { HStack { Text(title).foregroundStyle(.secondary); Spacer(); Text(value).bold() }.padding(.vertical, 4) }
    func toggleFavorite() { if let item = favorites.first(where: { $0.spotID == spot.id }) { context.delete(item) } else { context.insert(Favorite(spot: spot)) } }
    func openMaps() { MKMapItem(placemark: .init(coordinate: spot.coordinate)).openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking]) }
}
