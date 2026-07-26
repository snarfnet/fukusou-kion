import SwiftUI

struct HomeView: View {
    @Bindable var model: SpotViewModel
    @Binding var selectedTab: AppTab
    @State private var showFilters = false
    @State private var minutes = 60
    @State private var suggestion: Spot?
    @State private var showNoSuggestion = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                header
                searchAreaCard
                categoryPicker

                if let featured = model.recommended.first {
                    NavigationLink(value: featured) {
                        FeaturedSpotCard(
                            spot: featured,
                            distanceText: model.distanceText(to: featured),
                            travelText: model.travelText(to: featured)
                        )
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

                dataQualityNotice
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
        .onChange(of: model.locationService.location?.coordinate.latitude) { _, _ in
            model.syncPrefectureToCurrentLocation()
        }
        .onChange(of: model.locationService.administrativeArea) { _, _ in
            model.syncPrefectureToCurrentLocation()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("そこそこ時間を\n潰せる")
                .font(.system(size: 38, weight: .black, design: .rounded))
                .foregroundStyle(LinearGradient(colors: [Theme.deepBlue, Theme.blue], startPoint: .leading, endPoint: .trailing))
                .accessibilityAddTraits(.isHeader)
            Text("無料情報と涼める屋内候補を、近い順に。")
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .padding(.top, 18)
    }

    private var searchAreaCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("探すエリア", systemImage: "map.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(Theme.blue)

            Menu {
                Picker(
                    "都道府県",
                    selection: Binding(
                        get: { model.selectedPrefectureCode },
                        set: { model.selectPrefecture($0) }
                    )
                ) {
                    ForEach(model.prefectures) { prefecture in
                        Text(prefecture.name).tag(prefecture.code)
                    }
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(model.selectedPrefecture?.name ?? "都道府県を選ぶ")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(model.distanceBasisText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("変更")
                        .font(.subheadline.weight(.bold))
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.bold())
                }
                .contentShape(Rectangle())
            }

            Button {
                model.searchFromCurrentLocation()
            } label: {
                Label(
                    model.followsCurrentLocation ? "現在地を更新" : "現在地から探す",
                    systemImage: "location.fill"
                )
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(Theme.blue)

            Label(
                "都道府県は施設の範囲、距離は現在地が基準です。",
                systemImage: "info.circle"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Theme.elevatedSurface.opacity(0.94), in: RoundedRectangle(cornerRadius: 20))
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

    private var dataQualityNotice: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.shield")
                .foregroundStyle(Theme.blue)
            VStack(alignment: .leading, spacing: 3) {
                Text("確認済みと候補を分けて表示")
                    .font(.subheadline.weight(.semibold))
                Text("「無料情報あり」「冷房未確認」は確定情報ではありません。詳細画面の情報元を確認してください。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(13)
        .background(Theme.ice.opacity(0.7), in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder private var nearbySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("近くのスポット").font(.title3.bold())
                Spacer()
                Button {
                    selectedTab = .list
                } label: {
                    HStack(spacing: 5) {
                        Text("\(model.filtered.count)件を一覧で見る")
                        Image(systemName: "chevron.right")
                            .font(.caption.bold())
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.blue)
                    .padding(.vertical, 8)
                    .padding(.leading, 10)
                }
                .buttonStyle(.plain)
                .accessibilityHint("スポット一覧タブを開きます")
            }.padding(.bottom, 6)

            if model.filtered.isEmpty {
                ContentUnavailableView {
                    Label("条件に合う場所がありません", systemImage: "magnifyingglass")
                } description: { Text("距離を広げるか、条件を減らしてください。") }
                actions: { Button("条件をリセット") { model.resetFilters() } }
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(model.filtered.prefix(4).enumerated()), id: \.element.id) { index, spot in
                        NavigationLink(value: spot) {
                            SpotCard(spot: spot, distanceText: model.distanceText(to: spot))
                        }
                        .buttonStyle(.plain)
                        if index < min(model.filtered.count, 4) - 1 { Divider().padding(.leading, 62) }
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
    let distanceText: String
    let travelText: String

    var body: some View {
        GeometryReader { proxy in
            let compactCard = proxy.size.width < 350
            ZStack(alignment: .bottomLeading) {
                Image("cool-breeze-background")
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                LinearGradient(colors: [.clear, Theme.deepBlue.opacity(0.94)], startPoint: .center, endPoint: .bottom)
                VStack(alignment: .leading, spacing: compactCard ? 8 : 11) {
                    HStack {
                        Label("おすすめ", systemImage: "sparkles")
                            .font(.subheadline.bold())
                            .padding(.horizontal, 11)
                            .padding(.vertical, 7)
                            .background(.ultraThinMaterial, in: Capsule())
                        Spacer()
                        Image(systemName: spot.categoryIcon)
                            .font(.headline)
                            .padding(11)
                            .background(Theme.blue.gradient, in: Circle())
                    }
                    Spacer(minLength: 12)
                    Text(spot.name)
                        .font(.system(compactCard ? .title2 : .title, design: .rounded, weight: .bold))
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                    if !compactCard {
                        Text(spot.notes)
                            .font(.subheadline)
                            .lineLimit(2)
                            .foregroundStyle(.white.opacity(0.88))
                    }
                    HStack(spacing: 7) {
                        FeaturedFact(icon: "yensign", text: spot.priceText)
                        FeaturedFact(icon: "snowflake", text: spot.airConditioned == true ? "冷房あり" : "冷房未確認")
                    }
                    HStack(spacing: 18) {
                        Label(travelText, systemImage: "location")
                        Label(spot.stayText, systemImage: "clock")
                    }
                    .font(.caption.weight(.semibold))
                }
                .padding(compactCard ? 16 : 20)
                .foregroundStyle(.white)
            }
            .clipShape(RoundedRectangle(cornerRadius: 26))
            .shadow(color: Theme.deepBlue.opacity(0.20), radius: 18, y: 9)
        }
        .frame(height: 300)
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
