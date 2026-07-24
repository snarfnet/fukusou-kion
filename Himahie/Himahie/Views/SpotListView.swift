import SwiftUI

struct SpotListView: View {
    @Bindable var model: SpotViewModel
    @State private var showFilters = false
    var body: some View {
        Group {
            if model.filtered.isEmpty {
                ContentUnavailableView.search(text: model.searchText)
            } else {
                List(model.filtered) { spot in
                    NavigationLink(value: spot) {
                        SpotCard(spot: spot, distanceText: model.distanceText(to: spot))
                            .listRowInsets(.init())
                            .padding(.vertical, 6)
                    }
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .background(LinearGradient(colors: [Theme.ice.opacity(0.45), Color(uiColor: .systemBackground)], startPoint: .top, endPoint: .center))
            }
        }.searchable(text: $model.searchText, prompt: "施設名・住所・カテゴリ")
            .navigationTitle(model.selectedPrefecture?.name ?? "涼しい場所")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("\(model.filtered.count)件").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showFilters = true } label: { Label("絞り込み", systemImage: "line.3.horizontal.decrease.circle") }
                }
            }
            .sheet(isPresented: $showFilters) { FilterView(model: model) }
            .navigationDestination(for: Spot.self) { SpotDetailView(spot: $0, distance: model.distance(to: $0)) }
    }
}
