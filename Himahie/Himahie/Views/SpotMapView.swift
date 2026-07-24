import SwiftUI
import MapKit

struct SpotMapView: View {
    @Bindable var model: SpotViewModel
    @State private var position: MapCameraPosition = .region(.init(center: .init(latitude: 35.4478, longitude: 139.6425), span: .init(latitudeDelta: 0.15, longitudeDelta: 0.15)))
    var body: some View {
        Map(position: $position) {
            UserAnnotation()
            ForEach(model.filtered.prefix(300)) { spot in
                Annotation(spot.name, coordinate: spot.coordinate) {
                    NavigationLink(value: spot) {
                        Image(systemName: spot.categoryIcon)
                            .font(.subheadline.weight(.bold))
                            .frame(width: 38, height: 38)
                            .background(spot.categoryColor.gradient, in: Circle())
                            .foregroundStyle(.white)
                            .overlay(Circle().stroke(.white, lineWidth: 2))
                            .shadow(color: Theme.deepBlue.opacity(0.25), radius: 5, y: 3)
                    }
                }
            }
        }.mapControls { MapCompass(); MapScaleView(); MapUserLocationButton() }
            .overlay(alignment: .top) {
                if model.filtered.count > 300 {
                    Text("地図には近い300件を表示")
                        .font(.caption.bold()).padding(8).background(.thinMaterial, in: Capsule()).padding(.top, 8)
                }
            }
            .navigationTitle("近くの地図").navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Spot.self) { SpotDetailView(spot: $0, distance: model.distance(to: $0)) }
            .onChange(of: model.selectedPrefectureCode) { _, _ in recenterToSelectedArea() }
            .onChange(of: model.locationService.location?.coordinate.latitude) { _, _ in
                if model.followsCurrentLocation { recenterToCurrentLocation() }
            }
    }
    private func recenterToSelectedArea() {
        position = .region(.init(center: model.fallbackLocation.coordinate, span: .init(latitudeDelta: 0.45, longitudeDelta: 0.45)))
    }
    private func recenterToCurrentLocation() {
        position = .region(.init(center: model.currentLocation.coordinate, span: .init(latitudeDelta: 0.15, longitudeDelta: 0.15)))
    }
}
