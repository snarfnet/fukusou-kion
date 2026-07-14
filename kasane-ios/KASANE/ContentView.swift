import SwiftUI
import MapKit

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var speechReader = SpeechReader()
    @State private var selectedPlace = PlaceStory.featured[0]
    @State private var selectedEra = PlaceStory.featured[0].eras[0]
    @State private var camera: MapCameraPosition = .region(.asakusa)
    @State private var showDetail = false
    @State private var showSaved = false
    @State private var selectedTab = 0
    @State private var shouldFocusUserLocation = false
    @AppStorage("saved.asakusa") private var isSaved = false

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                CatalogView(locationManager: locationManager) { summary in open(summary) }
                    .navigationDestination(isPresented: $showDetail) { exploreView }
            }
                .tag(0)
                .tabItem { Label("Explore", systemImage: "map") }
            EmptyStateView(symbol: "figure.walk", title: "Curated walks", message: "Story-led walks will appear here.")
                .tag(1)
                .tabItem { Label("Walks", systemImage: "figure.walk") }
            EmptyStateView(symbol: "bookmark", title: "Saved places", message: isSaved ? "Asakusa · Taitō, Tokyo" : "Save a place to find it here later.")
                .tag(2)
                .tabItem { Label("Saved", systemImage: "bookmark") }
        }
        .tint(KasaneTheme.vermilion)
    }

    private var exploreView: some View {
        ScrollView {
            VStack(spacing: 0) {
                mapHeader
                storySheet
            }
        }
        .background(KasaneTheme.paper)
        .ignoresSafeArea(edges: .top)
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: locationManager.location?.timestamp) { _, _ in
            guard shouldFocusUserLocation, let coordinate = locationManager.location?.coordinate else { return }
            focusMap(on: coordinate)
            shouldFocusUserLocation = false
        }
    }

    private var mapHeader: some View {
        ZStack(alignment: .bottomLeading) {
            Map(position: $camera) {
                Marker(selectedPlace.name, systemImage: "building.columns.fill", coordinate: placeCoordinate)
                    .tint(KasaneTheme.vermilion)
                UserAnnotation()
            }
            .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll))
            .overlay { KasaneMapTint().allowsHitTesting(false) }

            TimeLens(year: selectedEra.year, placeLabel: selectedPlace.oldName)
                .frame(width: 194, height: 194)
                .position(x: UIScreen.main.bounds.width / 2, y: 220)
                .accessibilityLabel("Historical map lens, year \(selectedEra.year)")

            VStack(alignment: .leading, spacing: 5) {
                Text(String(format: "%.4f° N · %.4f° E", selectedPlace.latitude, selectedPlace.longitude))
                    .font(.system(size: 9, weight: .semibold)).tracking(1.2)
                HStack(alignment: .firstTextBaseline, spacing: 9) {
                    Text(selectedPlace.kanji).font(.kasaneSerif(25))
                    Text(selectedPlace.name).font(.kasaneSerif(34))
                }
                Text("\(selectedPlace.area) · You are here").font(.caption)
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.4), radius: 10)
            .padding(.horizontal, 22).padding(.bottom, 25)

            VStack {
                HStack {
                    Button { showDetail = false } label: {
                        Label("MAP", systemImage: "chevron.left")
                            .font(.system(size: 12, weight: .bold))
                            .tracking(1.2)
                            .frame(minHeight: 44)
                            .padding(.horizontal, 13)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay(Capsule().stroke(.white.opacity(0.7)))
                    }
                    .accessibilityLabel("Back to the Japan map")
                    Spacer()
                    Menu {
                        ForEach(PlaceStory.featured) { place in
                            Button("\(place.kanji)  \(place.name)") { select(place) }
                        }
                    } label: { Text("PLACES  ⌄").font(.caption2.bold()) }.buttonStyle(.bordered).tint(.white)
                }
                Spacer()
                HStack { Spacer(); locateButton }
            }
            .foregroundStyle(.white).padding(.horizontal, 20).padding(.top, 55).padding(.bottom, 126)
        }
        .frame(height: 470)
    }

    private var locateButton: some View {
        Button {
            shouldFocusUserLocation = true
            locationManager.requestLocation()
            if let coordinate = locationManager.location?.coordinate {
                focusMap(on: coordinate)
                shouldFocusUserLocation = false
            }
        } label: {
            Image(systemName: "location.circle.fill").font(.system(size: 38)).symbolRenderingMode(.palette).foregroundStyle(KasaneTheme.indigo, .white)
        }
        .accessibilityLabel("Find my location")
    }

    private func focusMap(on coordinate: CLLocationCoordinate2D) {
        withAnimation(.easeInOut) {
            camera = .region(MKCoordinateRegion(center: coordinate, latitudinalMeters: 900, longitudinalMeters: 900))
        }
    }

    private var storySheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule().fill(Color.gray.opacity(0.35)).frame(width: 39, height: 4).frame(maxWidth: .infinity).padding(.bottom, 19)
            HStack {
                Label("PLACE STORY", systemImage: "circle.fill").font(.system(size: 10, weight: .semibold)).tracking(1.2).foregroundStyle(KasaneTheme.muted)
                Spacer()
                Button { isSaved.toggle() } label: { Label(isSaved ? "Saved" : "Save", systemImage: isSaved ? "bookmark.fill" : "bookmark") }.font(.caption.bold()).foregroundStyle(isSaved ? KasaneTheme.vermilion : KasaneTheme.indigo)
            }
            Text(selectedPlace.headline).font(.kasaneSerif(34)).tracking(-1).foregroundStyle(KasaneTheme.deep).padding(.top, 18)
            Text(selectedPlace.introduction)
                .font(.system(size: 14)).foregroundStyle(.secondary).lineSpacing(7).padding(.top, 15)
            HStack(spacing: 12) {
                Button {
                    let spokenText = selectedPlace.body.isEmpty ? selectedPlace.introduction : selectedPlace.body
                    speechReader.toggle(text: "\(selectedPlace.name). \(spokenText)")
                } label: {
                    Label(speechReader.isPaused ? "Resume" : speechReader.isSpeaking ? "Pause" : "Listen",
                          systemImage: speechReader.isPaused ? "play.fill" : speechReader.isSpeaking ? "pause.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 12, weight: .bold))
                        .frame(minHeight: 44)
                        .padding(.horizontal, 14)
                        .foregroundStyle(.white)
                        .background(KasaneTheme.indigo, in: Capsule())
                }
                if speechReader.isSpeaking || speechReader.isPaused {
                    Button("Stop") { speechReader.stop() }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(KasaneTheme.vermilion)
                        .frame(minHeight: 44)
                }
                Spacer()
                Text("English audio").font(.caption2).foregroundStyle(.secondary)
            }
            .padding(.top, 16)
            if !selectedPlace.body.isEmpty {
                Text(selectedPlace.body)
                    .font(.system(size: 14))
                    .foregroundStyle(KasaneTheme.deep.opacity(0.86))
                    .lineSpacing(7)
                    .padding(.top, 22)
            }
            if !selectedPlace.placeNameOrigin.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("PLACE NAME").font(.system(size: 9, weight: .bold)).tracking(1.4).foregroundStyle(KasaneTheme.vermilion)
                    Text(selectedPlace.placeNameOrigin).font(.system(size: 12)).foregroundStyle(.secondary).lineSpacing(5)
                }
                .padding(15)
                .background(KasaneTheme.mist)
                .padding(.top, 20)
            }
            FactStrip(founded: selectedPlace.foundedLabel, oldName: selectedPlace.oldName).padding(.vertical, 27)
            EraPicker(eras: selectedPlace.eras, selected: $selectedEra)
            Text(selectedEra.story).font(.kasaneSerif(13, weight: .medium)).lineSpacing(5).foregroundStyle(.secondary).padding(15).frame(maxWidth: .infinity, alignment: .leading).background(KasaneTheme.mist).overlay(alignment: .leading) { Rectangle().fill(KasaneTheme.vermilion).frame(width: 3) }.padding(.top, 18)
            NearbySection(stories: selectedPlace.nearby).padding(.top, 32)
            if selectedPlace.sources.isEmpty {
                SourceNote().padding(.top, 26)
            } else {
                SourcesSection(sources: selectedPlace.sources, claimCount: selectedPlace.claims.count).padding(.top, 26)
            }
        }
        .padding(.horizontal, 22).padding(.top, 13).padding(.bottom, 38)
        .background(KasaneTheme.paper)
        .clipShape(.rect(topLeadingRadius: 17, topTrailingRadius: 17))
        .offset(y: -12).padding(.bottom, -12)
    }

    private var placeCoordinate: CLLocationCoordinate2D { .init(latitude: selectedPlace.latitude, longitude: selectedPlace.longitude) }

    private func select(_ place: PlaceStory) {
        speechReader.stop()
        selectedPlace = place
        selectedEra = place.eras[0]
        withAnimation(.easeInOut) { camera = .region(MKCoordinateRegion(center: .init(latitude: place.latitude, longitude: place.longitude), latitudinalMeters: 1250, longitudinalMeters: 1250)) }
    }

    private func open(_ summary: LocationSummary) {
        let editorial = EditorialCatalog.detailedStories.min { lhs, rhs in
            abs(lhs.latitude - summary.latitude) + abs(lhs.longitude - summary.longitude) < abs(rhs.latitude - summary.latitude) + abs(rhs.longitude - summary.longitude)
        }
        let isNearbyEditorial = editorial.map { abs($0.latitude - summary.latitude) < 0.012 && abs($0.longitude - summary.longitude) < 0.012 } ?? false
        if let editorial, isNearbyEditorial {
            select(editorial)
        } else if let detailed = PlaceStory.featured.first(where: { $0.id == summary.id }) {
            select(detailed)
        } else {
            let generalEras = [
                Era(year: "Today", story: "Explore the streets and surviving traces of \(summary.name) as they appear today."),
                Era(year: "1900", story: "Modern transport and new institutions began reshaping this part of \(summary.prefecture)."),
                Era(year: "Edo", story: "Roads, waterways and local communities formed the historical landscape beneath the present city."),
                Era(year: "Origins", story: "Place-name records and local archives offer clues to the area’s earliest known story.")
            ]
            let record = PlaceStory(id: summary.id, kanji: summary.kanji, name: summary.name, area: summary.prefecture,
                latitude: summary.latitude, longitude: summary.longitude,
                headline: "Layers of \(summary.theme.lowercased())\nbeneath the present city.",
                introduction: "This local record brings together mapped history, place-name evidence and nearby cultural traces. Detailed editorial stories and source links will be added as the KASANE collection grows.",
                foundedLabel: "—", oldName: summary.kanji, eras: generalEras,
                nearby: [NearbyStory(kanji: "道", category: "LOCAL RECORD", title: "Historic paths around \(summary.name)", place: summary.prefecture, distance: 300)])
            select(record)
        }
        showDetail = true
    }
}

private struct TimeLens: View {
    let year: String
    let placeLabel: String
    var body: some View {
        ZStack {
            Circle().fill(Color(red: 0.84, green: 0.77, blue: 0.62))
            Canvas { context, size in
                for index in 0..<11 {
                    var path = Path(); let y = CGFloat(index) * 22
                    path.move(to: CGPoint(x: -20, y: y)); path.addLine(to: CGPoint(x: size.width + 20, y: y + 70))
                    context.stroke(path, with: .color(.brown.opacity(0.38)), lineWidth: index.isMultiple(of: 3) ? 3 : 1)
                }
            }.clipShape(Circle())
            VStack(spacing: -1) {
                ForEach(Array(placeLabel.prefix(4).enumerated()), id: \.offset) { pair in
                    Text(String(pair.element)).font(.kasaneSerif(20)).foregroundStyle(.brown)
                }
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .overlay(Rectangle().stroke(.brown.opacity(0.7)))
            Text(year).font(.caption2.bold()).tracking(1).foregroundStyle(.white).padding(.horizontal, 9).padding(.vertical, 5).background(KasaneTheme.vermilion).offset(x: 62, y: 62)
        }
        .overlay(Circle().stroke(KasaneTheme.paper, lineWidth: 7)).overlay(Circle().stroke(KasaneTheme.vermilion, lineWidth: 2).padding(-2)).shadow(color: .black.opacity(0.35), radius: 20, y: 12)
    }
}

private struct KasaneMapTint: View { var body: some View { KasaneTheme.indigo.opacity(0.62).blendMode(.multiply) } }

private struct FactStrip: View {
    let founded: String
    let oldName: String
    var body: some View {
        HStack(spacing: 0) {
            fact("FOUNDED", founded); Divider(); fact("OLD NAME", oldName); Divider(); fact("WALK", "4 min")
        }.frame(height: 54).padding(.vertical, 14).overlay(alignment: .top) { Divider() }.overlay(alignment: .bottom) { Divider() }
    }
    private func fact(_ label: String, _ value: String) -> some View { VStack(alignment: .leading, spacing: 5) { Text(label).font(.system(size: 8)).tracking(1).foregroundStyle(.secondary); Text(value).font(.kasaneSerif(16)) }.frame(maxWidth: .infinity, alignment: .leading).padding(.leading, 12) }
}

private struct EraPicker: View {
    let eras: [Era]
    @Binding var selected: Era
    var body: some View {
        HStack { ForEach(eras) { era in Button { withAnimation(.snappy) { selected = era } } label: { VStack(spacing: 8) { Circle().fill(selected == era ? KasaneTheme.vermilion : KasaneTheme.paper).frame(width: 12, height: 12).overlay(Circle().stroke(selected == era ? KasaneTheme.vermilion : .gray, lineWidth: 2)); Text(era.year).font(.caption2.bold()).foregroundStyle(selected == era ? KasaneTheme.deep : .secondary) }.frame(maxWidth: .infinity) } } }.overlay(alignment: .top) { Divider().padding(.horizontal, 35).padding(.top, 6).zIndex(-1) }
    }
}

private struct NearbySection: View {
    let stories: [NearbyStory]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("KEEP WALKING").font(.system(size: 9, weight: .bold)).tracking(1.5).foregroundStyle(KasaneTheme.vermilion)
            Text("Stories nearby").font(.kasaneSerif(23))
            ForEach(stories) { story in
                HStack(spacing: 13) {
                    ZStack(alignment: .bottom) { Rectangle().fill(story.kanji == "舟" ? Color.teal : KasaneTheme.vermilion).frame(width: 58, height: 68); Text(story.kanji).font(.kasaneSerif(26)).foregroundStyle(.white).padding(.bottom, 17); Text("\(story.distance) m").font(.system(size: 7)).foregroundStyle(.white).padding(.bottom, 5) }
                    VStack(alignment: .leading, spacing: 3) { Text(story.category).font(.system(size: 8)).tracking(0.8).foregroundStyle(.secondary); Text(story.title).font(.kasaneSerif(14)); Text(story.place).font(.caption2).foregroundStyle(.secondary) }
                    Spacer(); Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(KasaneTheme.vermilion)
                }.padding(12).background(.white).overlay(Rectangle().stroke(Color.gray.opacity(0.25)))
            }
        }
    }
}

private struct SourceNote: View {
    var body: some View { HStack(alignment: .top, spacing: 12) { Text("資料").font(.kasaneSerif(13)).frame(width: 40, height: 33).overlay(Rectangle().stroke(.gray.opacity(0.6))); Text("Based on records from Taitō City, the Geospatial Information Authority of Japan and Wikimedia. View sources").font(.system(size: 9)).foregroundStyle(.secondary).lineSpacing(3) }.padding(.top, 17).overlay(alignment: .top) { Divider() } }
}

private struct SourcesSection: View {
    let sources: [StorySource]
    let claimCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("SOURCES").font(.system(size: 9, weight: .bold)).tracking(1.4).foregroundStyle(KasaneTheme.vermilion)
                Spacer()
                Text("\(claimCount) sourced claims").font(.caption2).foregroundStyle(.secondary)
            }
            ForEach(sources) { source in
                if let url = source.url {
                    Link(destination: url) { sourceRow(source) }
                } else {
                    sourceRow(source)
                }
            }
        }
        .padding(.top, 17)
        .overlay(alignment: .top) { Divider() }
    }

    private func sourceRow(_ source: StorySource) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "doc.text").foregroundStyle(KasaneTheme.indigo)
            VStack(alignment: .leading, spacing: 3) {
                Text(source.title).font(.system(size: 11, weight: .semibold)).foregroundStyle(KasaneTheme.deep)
                Text(source.publisher).font(.system(size: 9)).foregroundStyle(.secondary)
            }
            Spacer()
            if source.url != nil { Image(systemName: "arrow.up.right").font(.caption2).foregroundStyle(KasaneTheme.vermilion) }
        }
        .padding(11)
        .background(.white)
        .overlay(Rectangle().stroke(Color.gray.opacity(0.2)))
    }
}

private struct EmptyStateView: View {
    let symbol: String; let title: String; let message: String
    var body: some View { ZStack { KasaneTheme.paper.ignoresSafeArea(); VStack(spacing: 14) { Image(systemName: symbol).font(.system(size: 32)).foregroundStyle(KasaneTheme.vermilion); Text(title).font(.kasaneSerif(25)); Text(message).font(.subheadline).foregroundStyle(.secondary) } } }
}

private extension CLLocationCoordinate2D { static let asakusa = CLLocationCoordinate2D(latitude: 35.7148, longitude: 139.7967) }
private extension MKCoordinateRegion { static let asakusa = MKCoordinateRegion(center: .asakusa, latitudinalMeters: 1250, longitudinalMeters: 1250) }

#Preview { ContentView() }
