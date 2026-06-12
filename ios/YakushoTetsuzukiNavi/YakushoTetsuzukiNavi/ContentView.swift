import SwiftUI

enum ActiveSheet: String, Identifiable {
    case municipality
    case notifications
    case privacy

    var id: String { rawValue }
}

struct ContentView: View {
    @State private var selectedTab: MainTab = .home
    @State private var selectedEvent: LifeEvent = .moving
    @State private var selectedItem: ProcedureItem?
    @State private var searchText = ""
    @State private var savedIDs: Set<String> = ["move-002", "birth-002", "inherit-007"]
    @State private var activeSheet: ActiveSheet?
    @StateObject private var locationResolver = LocationMunicipalityResolver()
    @State private var locationAlertMessage = ""
    @State private var showingLocationAlert = false
    @AppStorage("selectedMunicipality") private var selectedMunicipality = "東京都 新宿区"
    @AppStorage("notificationSetting") private var notificationSetting = "7日前・前日"

    private var filteredItems: [ProcedureItem] {
        ProcedureData.items
            .filter { selectedTab == .saved ? savedIDs.contains($0.id) : $0.event == selectedEvent || selectedTab == .deadline }
            .filter { item in
                searchText.isEmpty ||
                item.title.localizedStandardContains(searchText) ||
                item.office.localizedStandardContains(searchText) ||
                item.documents.joined(separator: " ").localizedStandardContains(searchText)
            }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                HeaderView(
                    searchText: $searchText,
                    municipality: selectedMunicipality,
                    isLocating: locationResolver.isResolving,
                    openMunicipality: { activeSheet = .municipality },
                    locateMunicipality: { locationResolver.locate() },
                    openNotifications: { activeSheet = .notifications }
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        switch selectedTab {
                        case .home:
                            HomeTimelineView(
                                selectedEvent: $selectedEvent,
                                items: eventItems,
                                savedIDs: $savedIDs,
                                selectedItem: $selectedItem
                            )
                        case .list:
                            ProcedureListView(
                                selectedEvent: $selectedEvent,
                                items: filteredItems,
                                savedIDs: $savedIDs,
                                selectedItem: $selectedItem
                            )
                        case .deadline:
                            DeadlineView(
                                items: ProcedureData.items,
                                savedIDs: $savedIDs,
                                selectedItem: $selectedItem
                            )
                        case .saved:
                            SavedView(
                                items: filteredItems,
                                savedIDs: $savedIDs,
                                selectedItem: $selectedItem
                            )
                        case .settings:
                            SettingsView(
                                municipality: selectedMunicipality,
                                notificationSetting: notificationSetting,
                                openMunicipality: { activeSheet = .municipality },
                                openNotifications: { activeSheet = .notifications },
                                openPrivacy: { activeSheet = .privacy }
                            )
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 92)
                }
            }

            BottomTabBar(selectedTab: $selectedTab)
        }
        .foregroundStyle(AppTheme.navy)
        .sheet(item: $selectedItem) { item in
            ProcedureDetailView(item: item, municipality: selectedMunicipality, isSaved: savedIDs.contains(item.id)) {
                if savedIDs.contains(item.id) {
                    savedIDs.remove(item.id)
                } else {
                    savedIDs.insert(item.id)
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .municipality:
                MunicipalityPickerView(selectedMunicipality: $selectedMunicipality)
            case .notifications:
                NotificationSettingsView(notificationSetting: $notificationSetting)
            case .privacy:
                PrivacySettingsView()
            }
        }
        .onChange(of: locationResolver.resolvedMunicipality) { _, municipality in
            guard let municipality else { return }
            selectedMunicipality = municipality.displayName
        }
        .onChange(of: locationResolver.message) { _, message in
            guard let message else { return }
            locationAlertMessage = message
            showingLocationAlert = true
        }
        .alert("現在地から自治体を選択", isPresented: $showingLocationAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(locationAlertMessage)
        }
    }

    private var eventItems: [ProcedureItem] {
        ProcedureData.items.filter { $0.event == selectedEvent }
    }
}

struct HeaderView: View {
    @Binding var searchText: String
    let municipality: String
    let isLocating: Bool
    let openMunicipality: () -> Void
    let locateMunicipality: () -> Void
    let openNotifications: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(AppTheme.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("役所手続きナビ")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                    Text("買い切り100円・広告なし")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.78))
                }

                Spacer()

                Button(action: locateMunicipality) {
                    ZStack {
                        if isLocating {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "location.circle")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: 38, height: 38)
                }
                .buttonStyle(.plain)
                .disabled(isLocating)
                .accessibilityLabel("現在地から自治体を選択")

                Button(action: openNotifications) {
                    Image(systemName: "bell.badge")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                }
                .buttonStyle(.plain)
            }

            Button(action: openMunicipality) {
                HStack(spacing: 8) {
                    Label(municipality, systemImage: "mappin.and.ellipse")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AppTheme.navy)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text("自治体変更")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AppTheme.blue)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppTheme.blue)
                }
                .padding(10)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppTheme.grayText)
                TextField("手続き・書類・窓口を検索", text: $searchText)
                    .font(.system(size: 14))
            }
            .padding(.horizontal, 11)
            .frame(height: 42)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(AppTheme.navy)
    }
}

struct HomeTimelineView: View {
    @Binding var selectedEvent: LifeEvent
    let items: [ProcedureItem]
    @Binding var savedIDs: Set<String>
    @Binding var selectedItem: ProcedureItem?

    var body: some View {
        VStack(spacing: 12) {
            SummaryStrip(items: items)
            EventSelector(selectedEvent: $selectedEvent)
            TodayCheckView(items: Array(items.prefix(5)), savedIDs: $savedIDs, selectedItem: $selectedItem)
            DeadlineGroups(items: items, savedIDs: $savedIDs, selectedItem: $selectedItem)
            OfficialNotice()
        }
    }
}

struct SummaryStrip: View {
    let items: [ProcedureItem]

    var body: some View {
        OfficialCard {
            HStack(spacing: 0) {
                SummaryCell(title: "未着手", value: "\(items.count)", color: AppTheme.navy)
                Divider()
                SummaryCell(title: "期限近い", value: "\(items.filter { $0.urgency == .urgent || $0.urgency == .soon }.count)", color: AppTheme.alert)
                Divider()
                SummaryCell(title: "書類合計", value: "\(items.reduce(0) { $0 + $1.documents.count })", color: AppTheme.blue)
            }
        }
    }
}

struct SummaryCell: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.grayText)
        }
        .frame(maxWidth: .infinity)
    }
}

struct EventSelector: View {
    @Binding var selectedEvent: LifeEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            SectionTitle("状況を選択", caption: "ライフイベントごとに必要な届出をまとめます")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(LifeEvent.allCases) { event in
                        Button {
                            selectedEvent = event
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: event.symbol)
                                Text(event.rawValue)
                            }
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(selectedEvent == event ? .white : AppTheme.navy)
                            .padding(.horizontal, 11)
                            .frame(height: 36)
                            .background(selectedEvent == event ? AppTheme.blue : .white)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(selectedEvent == event ? AppTheme.blue : AppTheme.line)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

struct TodayCheckView: View {
    let items: [ProcedureItem]
    @Binding var savedIDs: Set<String>
    @Binding var selectedItem: ProcedureItem?

    var body: some View {
        OfficialCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle("今日確認する手続き", caption: "期限が短いものから優先して表示")

                ForEach(items) { item in
                    ProcedureRow(item: item, isSaved: savedIDs.contains(item.id)) {
                        selectedItem = item
                    } toggleSave: {
                        toggle(item)
                    }
                }
            }
        }
    }

    private func toggle(_ item: ProcedureItem) {
        if savedIDs.contains(item.id) {
            savedIDs.remove(item.id)
        } else {
            savedIDs.insert(item.id)
        }
    }
}

struct DeadlineGroups: View {
    let items: [ProcedureItem]
    @Binding var savedIDs: Set<String>
    @Binding var selectedItem: ProcedureItem?

    var body: some View {
        OfficialCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionTitle("期限別タイムライン")

                group("7日以内", items: items.filter { $0.deadline.contains("7日") })
                group("14日以内", items: items.filter { $0.deadline.contains("14日") })
                group("15日以内", items: items.filter { $0.deadline.contains("15日") })
                group("1か月以降", items: items.filter { !$0.deadline.contains("7日") && !$0.deadline.contains("14日") && !$0.deadline.contains("15日") })
            }
        }
    }

    private func group(_ title: String, items: [ProcedureItem]) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.navy)
                Spacer()
                Text("\(items.count)件")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.grayText)
            }

            ForEach(items.prefix(4)) { item in
                CompactTimelineRow(item: item, isSaved: savedIDs.contains(item.id)) {
                    selectedItem = item
                }
            }

            if items.isEmpty {
                Text("該当する手続きはありません")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.grayText)
                    .padding(.vertical, 4)
            }
        }
        .padding(.top, 4)
    }
}

struct ProcedureListView: View {
    @Binding var selectedEvent: LifeEvent
    let items: [ProcedureItem]
    @Binding var savedIDs: Set<String>
    @Binding var selectedItem: ProcedureItem?

    var body: some View {
        VStack(spacing: 12) {
            EventSelector(selectedEvent: $selectedEvent)
            OfficialCard {
                VStack(alignment: .leading, spacing: 10) {
                    SectionTitle("手続き一覧", caption: "\(selectedEvent.rawValue)に関係する届出を表示")
                    ForEach(items) { item in
                        ProcedureRow(item: item, isSaved: savedIDs.contains(item.id)) {
                            selectedItem = item
                        } toggleSave: {
                            if savedIDs.contains(item.id) { savedIDs.remove(item.id) } else { savedIDs.insert(item.id) }
                        }
                    }
                }
            }
        }
    }
}

struct DeadlineView: View {
    let items: [ProcedureItem]
    @Binding var savedIDs: Set<String>
    @Binding var selectedItem: ProcedureItem?

    var sorted: [ProcedureItem] {
        items.sorted { lhs, rhs in
            score(lhs) < score(rhs)
        }
    }

    var body: some View {
        OfficialCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle("全状況の期限順", caption: "忘れると困る手続きを先頭に表示")
                ForEach(sorted.prefix(28)) { item in
                    ProcedureRow(item: item, isSaved: savedIDs.contains(item.id)) {
                        selectedItem = item
                    } toggleSave: {
                        if savedIDs.contains(item.id) { savedIDs.remove(item.id) } else { savedIDs.insert(item.id) }
                    }
                }
            }
        }
    }

    private func score(_ item: ProcedureItem) -> Int {
        switch item.urgency {
        case .urgent: 0
        case .soon: 1
        case .normal: 2
        case .confirm: 3
        }
    }
}

struct SavedView: View {
    let items: [ProcedureItem]
    @Binding var savedIDs: Set<String>
    @Binding var selectedItem: ProcedureItem?

    var body: some View {
        OfficialCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle("保存した手続き", caption: "あとで確認する項目")
                if items.isEmpty {
                    Text("保存した手続きはまだありません")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.grayText)
                        .padding(.vertical, 20)
                } else {
                    ForEach(items) { item in
                        ProcedureRow(item: item, isSaved: true) {
                            selectedItem = item
                        } toggleSave: {
                            savedIDs.remove(item.id)
                        }
                    }
                }
            }
        }
    }
}

struct SettingsView: View {
    let municipality: String
    let notificationSetting: String
    let openMunicipality: () -> Void
    let openNotifications: () -> Void
    let openPrivacy: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            OfficialCard {
                VStack(alignment: .leading, spacing: 12) {
                    SectionTitle("設定", caption: "自治体、通知、保存情報を管理します")
                    SettingLine(symbol: "building.2", title: "自治体", value: municipality, action: openMunicipality)
                    SettingLine(symbol: "bell", title: "期限通知", value: notificationSetting, action: openNotifications)
                    SettingLine(symbol: "hand.raised", title: "プライバシー", value: "端末内保存", action: openPrivacy)
                }
            }

            OfficialNotice()
        }
    }
}

struct SettingLine: View {
    let symbol: String
    let title: String
    let value: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .foregroundStyle(AppTheme.blue)
                    .frame(width: 24)
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.navy)
                Spacer()
                Text(value)
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.grayText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.grayText)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.vertical, 6)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppTheme.line)
                .frame(height: 0.5)
        }
    }
}

struct ProcedureRow: View {
    let item: ProcedureItem
    let isSaved: Bool
    let action: () -> Void
    let toggleSave: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Button(action: action) {
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 6) {
                        Badge(text: item.urgency.rawValue, color: item.urgency.color)
                        Badge(text: item.online ? "オンライン可" : "窓口確認", color: item.online ? AppTheme.success : AppTheme.grayText)
                        Spacer()
                        Text(item.event.rawValue)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppTheme.grayText)
                    }

                    Text(item.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppTheme.navy)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 8) {
                        Label(item.deadline, systemImage: "clock")
                        Label(item.documentCountText, systemImage: "doc.text")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppTheme.grayText)

                    Text(item.office)
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.grayText)
                        .lineLimit(1)
                }
            }
            .buttonStyle(.plain)

            Button(action: toggleSave) {
                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isSaved ? AppTheme.blue : AppTheme.grayText)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AppTheme.line)
                .frame(height: 0.5)
        }
    }
}

struct CompactTimelineRow: View {
    let item: ProcedureItem
    let isSaved: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 9) {
                Circle()
                    .fill(item.urgency.color)
                    .frame(width: 9, height: 9)
                    .padding(.top, 5)

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(item.title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.navy)
                        Spacer()
                        if isSaved {
                            Image(systemName: "bookmark.fill")
                                .font(.system(size: 11))
                                .foregroundStyle(AppTheme.blue)
                        }
                    }
                    Text("\(item.deadline) / \(item.office)")
                        .font(.system(size: 12))
                        .foregroundStyle(AppTheme.grayText)
                        .lineLimit(1)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

struct OfficialNotice: View {
    var body: some View {
        OfficialCard {
            VStack(alignment: .leading, spacing: 7) {
                Label("公式確認メモ", systemImage: "exclamationmark.triangle")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(AppTheme.navy)
                Text("アプリ内の手続きは全国共通の案内を中心にしています。自治体ごとに変わる条件は、選択した自治体の公式サイトとマイナポータルで確認してください。")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.grayText)
                    .lineSpacing(2)
            }
        }
    }
}

struct MunicipalityPickerView: View {
    @Binding var selectedMunicipality: String
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var selectedPrefecture = "すべて"

    private var prefectures: [String] {
        ["すべて"] + MunicipalityData.prefectures
    }

    private var filtered: [Municipality] {
        MunicipalityData.all
            .filter { selectedPrefecture == "すべて" || $0.prefecture == selectedPrefecture }
            .filter { $0.matches(query) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(prefectures, id: \.self) { prefecture in
                            Button {
                                selectedPrefecture = prefecture
                            } label: {
                                Text(prefecture)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(selectedPrefecture == prefecture ? .white : AppTheme.navy)
                                    .padding(.horizontal, 11)
                                    .frame(height: 34)
                                    .background(selectedPrefecture == prefecture ? AppTheme.blue : .white)
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(selectedPrefecture == prefecture ? AppTheme.blue : AppTheme.line)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AppTheme.grayText)
                    TextField("自治体名・かな・コードを検索", text: $query)
                        .font(.system(size: 14))
                }
                .padding(.horizontal, 11)
                .frame(height: 42)
                .background(AppTheme.background)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                HStack {
                    Text("\(filtered.count)件を表示")
                    Spacer()
                    Text("収録 \(MunicipalityData.all.count)件")
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppTheme.grayText)

                List(filtered) { municipality in
                    Button {
                        selectedMunicipality = municipality.displayName
                        dismiss()
                    } label: {
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(municipality.displayName)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(AppTheme.navy)
                                Text("\(municipality.kana) / \(municipality.code)")
                                    .font(.system(size: 11))
                                    .foregroundStyle(AppTheme.grayText)
                                    .lineLimit(1)
                            }
                            Spacer()
                            if selectedMunicipality == municipality.displayName {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(AppTheme.blue)
                            }
                        }
                    }
                }
                .listStyle(.plain)

                Text("自治体名と公式URLは \(MunicipalityData.sourceName) の公開データを同梱しています。手続きの詳細条件は、各自治体の公式ページで確認してください。")
                    .font(.system(size: 11))
                    .foregroundStyle(AppTheme.grayText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .navigationTitle("自治体変更")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}

struct NotificationSettingsView: View {
    @Binding var notificationSetting: String
    @Environment(\.dismiss) private var dismiss

    private let options = ["通知しない", "前日", "3日前・前日", "7日前・前日", "14日前・7日前・前日"]

    var body: some View {
        NavigationStack {
            List {
                Section("期限通知") {
                    ForEach(options, id: \.self) { option in
                        Button {
                            notificationSetting = option
                        } label: {
                            HStack {
                                Text(option)
                                    .foregroundStyle(AppTheme.navy)
                                Spacer()
                                if notificationSetting == option {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(AppTheme.blue)
                                }
                            }
                        }
                    }
                }

                Section {
                    Text("実リリースでは、ここでローカル通知の許可を取り、保存した手続きの期限から通知日を計算します。")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.grayText)
                }
            }
            .navigationTitle("通知設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}

struct PrivacySettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("保存する情報") {
                    Label("選択した自治体", systemImage: "building.2")
                    Label("保存した手続き", systemImage: "bookmark")
                    Label("通知設定", systemImage: "bell")
                }

                Section {
                    Text("この試作では個人情報をサーバーへ送信しません。現在地は自治体の推定にだけ使い、緯度経度は保存しません。")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.grayText)
                }
            }
            .navigationTitle("プライバシー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
}

struct BottomTabBar: View {
    @Binding var selectedTab: MainTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 18, weight: .semibold))
                        Text(tab.rawValue)
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(selectedTab == tab ? AppTheme.blue : AppTheme.grayText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(.white)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppTheme.line)
                .frame(height: 0.5)
        }
    }
}

struct ProcedureDetailView: View {
    let item: ProcedureItem
    let municipality: String
    let isSaved: Bool
    let toggleSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    private var selectedMunicipality: Municipality? {
        MunicipalityData.find(displayName: municipality)
    }

    private var cityHall: CityHallOffice? {
        CityHallData.find(for: selectedMunicipality)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    OfficialCard {
                        VStack(alignment: .leading, spacing: 9) {
                            HStack {
                                Badge(text: item.urgency.rawValue, color: item.urgency.color)
                                Badge(text: item.category.rawValue, color: AppTheme.blue)
                                Spacer()
                            }
                            Text(item.title)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(AppTheme.navy)
                            Text(item.event.summary)
                                .font(.system(size: 13))
                                .foregroundStyle(AppTheme.grayText)
                        }
                    }

                    detailBlock("期限", rows: [item.deadline], symbol: "clock")
                    detailBlock("提出先", rows: [item.office], symbol: "building.2")
                    detailBlock("必要書類", rows: item.documents, symbol: "doc.text")
                    detailBlock("進め方", rows: item.steps, symbol: "list.number")
                    detailBlock("注意点", rows: item.notes, symbol: "exclamationmark.triangle")
                    detailBlock("公式確認先の目安", rows: [item.sourceHint], symbol: "link")
                    cityHallBlock
                }
                .padding(14)
            }
            .background(AppTheme.background)
            .navigationTitle("手続き詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        toggleSave()
                    } label: {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var cityHallBlock: some View {
        if let cityHall {
            OfficialCard {
                VStack(alignment: .leading, spacing: 10) {
                    Label("市役所", systemImage: "building.columns")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AppTheme.navy)

                    Text(cityHall.building)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppTheme.navy)

                    VStack(alignment: .leading, spacing: 7) {
                        infoLine(title: "所在地", value: cityHall.postalAddress)
                        infoLine(title: "電話", value: "\(cityHall.tel)（代表）")
                    }

                    Text("区役所・町村役場は表示していません。政令市の区を選んだ場合も、市役所の代表情報を表示します。")
                        .font(.system(size: 11))
                        .foregroundStyle(AppTheme.grayText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func infoLine(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(title):")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.navy)
                .frame(width: 48, alignment: .leading)
            Text(value)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.grayText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func detailBlock(_ title: String, rows: [String], symbol: String) -> some View {
        OfficialCard {
            VStack(alignment: .leading, spacing: 9) {
                Label(title, systemImage: symbol)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppTheme.navy)

                ForEach(rows, id: \.self) { row in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(AppTheme.blue)
                            .frame(width: 5, height: 5)
                            .padding(.top, 7)
                        Text(row)
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.grayText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
