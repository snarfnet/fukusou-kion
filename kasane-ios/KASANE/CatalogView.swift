import SwiftUI
import MapKit

struct CatalogView: View {
    @ObservedObject var locationManager: LocationManager
    let onSelect: (LocationSummary) -> Void
    @State private var query = ""
    @State private var region = "All"
    @State private var sortByDistance = false
    @State private var camera: MapCameraPosition = .region(.japan)

    private var usesCompactHeight: Bool { UIScreen.main.bounds.height <= 700 }

    private var results: [LocationSummary] {
        var values = LocationCatalog.all.filter { item in
            (region == "All" || item.region == region) &&
            (query.isEmpty || "\(item.name) \(item.kanji) \(item.prefecture) \(item.theme)".localizedCaseInsensitiveContains(query))
        }
        if sortByDistance, let current = locationManager.location {
            values.sort { ($0.distance(from: current) ?? .greatestFiniteMagnitude) < ($1.distance(from: current) ?? .greatestFiniteMagnitude) }
        }
        return values
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                map
                filters
                locationGrid
            }
        }
        .background(KasaneTheme.paper)
        .navigationBarHidden(true)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 72)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack { Text("KASANE").font(.kasaneSerif(21)).tracking(3); Text("重").font(.kasaneSerif(21)).foregroundStyle(KasaneTheme.vermilion); Spacer(); Text("EN").font(.caption.bold()).padding(8).overlay(Capsule().stroke(.secondary.opacity(0.4))) }
            Text("Stories beneath\nyour feet").font(.kasaneSerif(37)).tracking(-1.2).foregroundStyle(KasaneTheme.deep)
            HStack { Image(systemName: "magnifyingglass"); TextField("Search places, stories, or kanji", text: $query).textInputAutocapitalization(.never) }.padding(13).background(.white).clipShape(RoundedRectangle(cornerRadius: 12)).shadow(color: .black.opacity(0.07), radius: 12, y: 4)
        }
        .padding(.horizontal, 22)
        .padding(.top, usesCompactHeight ? 10 : 18)
        .padding(.bottom, usesCompactHeight ? 14 : 20)
    }

    private var map: some View {
        Map(position: $camera) {
            ForEach(results) { item in Annotation(item.name, coordinate: item.coordinate) { Button { onSelect(item) } label: { Image(systemName: item.isFeatured ? "seal.fill" : "circle.fill").font(.system(size: item.isFeatured ? 19 : 10)).foregroundStyle(item.isFeatured ? KasaneTheme.vermilion : KasaneTheme.indigo).background(Circle().fill(.white).padding(3)).shadow(radius: 3) } }
            }
        }.mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll)).frame(height: usesCompactHeight ? 215 : 270).overlay { KasaneTheme.indigo.opacity(0.12).allowsHitTesting(false) }.overlay(alignment: .bottomLeading) { Text("\(results.count) PLACE STORIES").font(.system(size: 9, weight: .bold)).tracking(1.2).foregroundStyle(.white).padding(9).background(KasaneTheme.indigo).padding(14) }
    }

    private var filters: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack { Text("Explore Japan").font(.kasaneSerif(24)); Spacer(); Button { locationManager.requestLocation(); sortByDistance.toggle() } label: { Label("Nearest", systemImage: "location.fill").font(.caption.bold()).foregroundStyle(sortByDistance ? KasaneTheme.vermilion : KasaneTheme.indigo) } }
            ScrollView(.horizontal, showsIndicators: false) { HStack { ForEach(LocationCatalog.regions, id: \.self) { value in Button(value) { region = value }.font(.caption.bold()).foregroundStyle(region == value ? .white : KasaneTheme.indigo).padding(.horizontal, 13).padding(.vertical, 8).background(region == value ? KasaneTheme.indigo : Color.white).clipShape(Capsule()).overlay(Capsule().stroke(KasaneTheme.indigo.opacity(0.18))) } } }
        }.padding(.horizontal, 22).padding(.top, usesCompactHeight ? 18 : 25)
    }

    private var locationGrid: some View {
        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
            ForEach(results) { item in Button { onSelect(item) } label: {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) { Text(item.kanji).font(.kasaneSerif(27)).foregroundStyle(KasaneTheme.deep); Spacer(); if item.isFeatured { Text("KASANE STORY").font(.system(size: 6, weight: .bold)).tracking(0.7).foregroundStyle(.white).padding(5).background(KasaneTheme.vermilion) } }
                    Text(item.name).font(.kasaneSerif(16)).foregroundStyle(KasaneTheme.deep)
                    Text(item.theme.uppercased()).font(.system(size: 7, weight: .semibold)).tracking(0.8).foregroundStyle(.secondary).lineLimit(1)
                    HStack { Text(item.prefecture); Spacer(); if let distance = item.distance(from: locationManager.location) { Text(distance < 1000 ? "\(Int(distance)) m" : String(format: "%.0f km", distance / 1000)) } }
                        .font(.system(size: 8)).foregroundStyle(.secondary).padding(.top, 5)
                }.padding(13).frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading).background(.white).overlay(Rectangle().stroke(Color.gray.opacity(0.22)))
            }.buttonStyle(.plain)
            }
        }.padding(22)
    }
}

private extension MKCoordinateRegion { static let japan = MKCoordinateRegion(center: .init(latitude: 36.4, longitude: 137.3), span: .init(latitudeDelta: 18, longitudeDelta: 18)) }
