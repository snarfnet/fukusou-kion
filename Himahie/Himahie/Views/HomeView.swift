import SwiftUI

struct HomeView: View {
    @Bindable var model: SpotViewModel
    @State private var showFilters = false
    @State private var minutes = 60
    @State private var suggestion: Spot?
    @State private var showNoSuggestion = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                header
                locationBar
                categoryPicker

                if let featured = model.recommended.first {
                    NavigationLink(value: featured) {
                        FeaturedSpotCard(spot: featured, distance: model.distance(to: featured))
                    }
                    .buttonStyle(.plain)
                }

                Button { chooseSuggestion() } label: {
                    Label("近くの涼しい場所を探す", systemImage: "magnifyingglass")
                        .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(Theme.blue)

                nearbySection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(LinearGradient(colors: [Theme.ice.opacity(0.65), Color(uiColor: .systemBackground)], startPoint: .topTrailing, endPoint: .center))
        .navigationBarHidden(true)
        .navigationDestination(for: Spot.self) { SpotDetailView(spot: $0, distance: model.distance(to: $0)) }
        .sheet(isPresented: $showFilters) { FilterView(model: model) }
        .sheet(item: $suggestion) { spot in NavigationStack { SpotDetailView(spot: spot, distance: model.distance(to: spot)) } }
        .alert("候補がありません", isPresented: $showNoSuggestion) { Button("OK") {} } message: { Text("距離を広げるか、条件を減らしてください。") }
        .alert("読み込みエラー", isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })) { Button("OK") { model.errorMessage = nil } } message: { Text(model.errorMessage ?? "") }
        .alert("位置情報", isPresented: Binding(get: { model.locationService.errorMessage != nil }, set: { if !$0 { model.locationService.errorMessage = nil } })) { Button("OK") { model.locationService.errorMessage = nil } } message: { Text(model.locationService.errorMessage ?? "") }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("そこそこ時間を\n潰せる")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(LinearGradient(colors: [Theme.deepBlue, Theme.blue], startPoint: .leading, endPoint: .trailing))
                .accessibilityAddTraits(.isHeader)
            Text("無料で、涼しくて、ちょっと楽しい場所を近くから。")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .padding(.top, 18)
    }

    private var locationBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "location.fill").foregroundStyle(Theme.blue)
            VStack(alignment: .leading, spacing: 2) {
                Text(model.locationService.location == nil ? "\(model.selectedPrefecture?.name ?? "地域")の中心から検索" : "現在地の近くを検索")
                    .font(.subheadline.weight(.semibold))
                Text(model.locationService.location == nil ? "現在地を使うと距離が正確になります" : "現在地を取得済み")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button(model.locationService.location == nil ? "現在地" : "更新") { model.locationService.request() }
                .font(.subheadline.weight(.semibold)).buttonStyle(.bordered)
            Menu {
                Picker("都道府県", selection: $model.selectedPrefectureCode) {
                    ForEach(model.prefectures) { Text($0.name).tag($0.code) }
                }
            } label: { Image(systemName: "chevron.down.circle.fill").font(.title3).foregroundStyle(Theme.blue) }
            .accessibilityLabel("都道府県を変更")
        }
        .padding(14).background(Theme.elevatedSurface.opacity(0.92), in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: Theme.deepBlue.opacity(0.08), radius: 14, y: 5)
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                ForEach(SpotCategoryFilter.allCases) { filter in
                    Button { model.categoryFilter = filter } label: {
                        Label(filter.rawValue, systemImage: filter.icon)
                            .font(.subheadline.weight(.semibold)).padding(.horizontal, 13).padding(.vertical, 9)
                            .foregroundStyle(model.categoryFilter == filter ? .white : Theme.deepBlue)
                            .background(model.categoryFilter == filter ? Theme.blue : Theme.elevatedSurface, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(model.categoryFilter == filter ? .isSelected : [])
                }
                Button { showFilters = true } label: {
                    Label("条件", systemImage: "slider.horizontal.3").font(.subheadline.weight(.semibold)).padding(.horizontal, 13).padding(.vertical, 9).background(Theme.elevatedSurface, in: Capsule())
                }.buttonStyle(.plain).foregroundStyle(Theme.deepBlue)
            }
        }
    }

    @ViewBuilder private var nearbySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("近くのスポット").font(.title3.bold())
                Spacer()
                Text("\(model.filtered.count)件").font(.subheadline).foregroundStyle(.secondary)
            }.padding(.bottom, 6)

            if model.filtered.isEmpty {
                ContentUnavailableView {
                    Label("条件に合う場所がありません", systemImage: "magnifyingglass")
                } description: { Text("距離を広げるか、条件を減らしてください。") }
                actions: { Button("条件をリセット") { model.resetFilters() } }
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(model.recommended.prefix(4).enumerated()), id: \.element.id) { index, spot in
                        NavigationLink(value: spot) { SpotCard(spot: spot, distance: model.distance(to: spot)) }.buttonStyle(.plain)
                        if index < min(model.recommended.count, 4) - 1 { Divider().padding(.leading, 62) }
                    }
                }
                .padding(.horizontal, 14)
                .background(Theme.elevatedSurface, in: RoundedRectangle(cornerRadius: 22))
            }
        }
    }

    private func chooseSuggestion() {
        suggestion = model.recommendation(minutes: minutes)
        showNoSuggestion = suggestion == nil
    }
}

private struct FeaturedSpotCard: View {
    let spot: Spot
    let distance: Double

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image("cool-breeze-background")
                .resizable().scaledToFill().frame(height: 340).clipped()
            LinearGradient(colors: [.white.opacity(0.10), Theme.deepBlue.opacity(0.88)], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("おすすめ", systemImage: "sparkles").font(.subheadline.bold()).padding(.horizontal, 11).padding(.vertical, 7).background(.ultraThinMaterial, in: Capsule())
                    Spacer()
                    Image(systemName: spot.categoryIcon).font(.title2).padding(13).background(Theme.blue.gradient, in: Circle()).foregroundStyle(.white)
                }
                Spacer(minLength: 24)
                Text(spot.name).font(.system(.title, design: .rounded, weight: .bold)).lineLimit(3).minimumScaleFactor(0.76)
                Text(spot.notes).font(.subheadline).lineLimit(2).foregroundStyle(.white.opacity(0.88))
                HStack(spacing: 8) {
                    FeaturedFact(icon: "yensign", text: spot.priceText)
                    FeaturedFact(icon: "snowflake", text: spot.airConditioned == true ? "冷房あり" : "冷房未確認")
                    if spot.verificationStatus == "verified" { FeaturedFact(icon: "checkmark.shield.fill", text: "確認済み") }
                }
                HStack(spacing: 22) {
                    Label("徒歩 \(max(1, Int(distance / 4.5 * 60)))分", systemImage: "figure.walk")
                    Label(spot.stayText, systemImage: "clock")
                }.font(.subheadline.weight(.semibold))
            }
            .padding(20).foregroundStyle(.white)
        }
        .frame(height: 340)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .shadow(color: Theme.deepBlue.opacity(0.20), radius: 18, y: 9)
        .accessibilityElement(children: .combine)
    }
}

private struct FeaturedFact: View {
    let icon: String
    let text: String
    var body: some View {
        Label(text, systemImage: icon).font(.caption.weight(.semibold)).lineLimit(1).padding(.horizontal, 9).padding(.vertical, 7).background(.ultraThinMaterial, in: Capsule())
    }
}
