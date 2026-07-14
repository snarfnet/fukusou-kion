import SwiftUI
import MapKit
import CoreLocation

@MainActor final class PoliceSearchModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var position: MapCameraPosition = .automatic
    @Published var results = [MKMapItem]()
    @Published var state: State = .idle
    enum State { case idle, loading, denied, failed }
    private let manager = CLLocationManager()
    override init() { super.init(); manager.delegate = self }
    func start() {
        guard CLLocationManager.locationServicesEnabled() else { state = .denied; return }
        manager.requestWhenInUseAuthorization(); manager.requestLocation(); state = .loading
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) { if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted { state = .denied } }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { guard let coordinate = locations.last?.coordinate else { return }; Task { await search(coordinate) } }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) { state = .failed }
    private func search(_ coordinate: CLLocationCoordinate2D) async {
        let request = MKLocalSearch.Request(); request.naturalLanguageQuery = "交番 police station"; request.region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 5000, longitudinalMeters: 5000)
        do { let response = try await MKLocalSearch(request: request).start(); results = Array(response.mapItems.prefix(10)); position = .region(request.region); state = .idle } catch { state = .failed }
    }
}

struct PoliceBoxSearchView: View {
    @StateObject private var model = PoliceSearchModel()
    var body: some View { VStack(spacing: 0) { Map(position: $model.position) { ForEach(model.results, id: \.self) { item in Marker(item.name ?? String(localized: "police.unknown"), coordinate: item.placemark.coordinate).tint(.brandBlue) } }.frame(height: 300); if model.state == .denied { ContentUnavailableView("police.permission", systemImage: "location.slash", description: Text("police.permissionDetail")) } else if model.results.isEmpty { ContentUnavailableView("police.searchPrompt", systemImage: "map", description: Text("police.onlineNote")) } else { List(model.results, id: \.self) { item in VStack(alignment: .leading) { Text(item.name ?? String(localized: "police.unknown")).font(.headline); Text(item.placemark.title ?? "").font(.caption).foregroundStyle(.secondary); Button("police.directions") { item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking]) } } } } }.navigationTitle("police.title").toolbar { Button("police.nearest") { model.start() } }.onAppear { model.start() } }
}

