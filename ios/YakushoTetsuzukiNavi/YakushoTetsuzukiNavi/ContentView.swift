import SwiftUI

struct ContentView: View {
    @State private var selectedTab: MainTab = .home
    @State private var selectedEvent: LifeEvent = .moving
    @State private var selectedItem: ProcedureItem?
    @State private var searchText = ""
    @State private var savedIDs: Set<String> = ["move-002", "birth-002", "inherit-007"]

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
                HeaderView(searchText: $searchText)

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
                            SettingsView()
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
            ProcedureDetailView(item: item, isSaved: savedIDs.contains(item.id)) {
                if savedIDs.contains(item.id) {
                    savedIDs.remove(item.id)
                } else {
                    savedIDs.insert(item.id)
                }
            }
        }
    }

    private var eventItems: [ProcedureItem] {
        ProcedureData.items.filter { $0.event == selectedEvent }
    }
}

struct HeaderView: View {
    @Binding var searchText: String

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

                Image(systemName: "bell.badge")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(.white)
            }

            HStack(spacing: 8) {
                Label("東京都 新宿区", systemImage: "mappin.and.ellipse")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.navy)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("自治体変更")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.blue)
            }
            .padding(10)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

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
    var body: some View {
        VStack(spacing: 12) {
            OfficialCard {
                VStack(alignment: .leading, spacing: 12) {
                    SectionTitle("設定", caption: "試作版の想定項目")
                    SettingLine(symbol: "building.2", title: "自治体", value: "東京都 新宿区")
                    SettingLine(symbol: "bell", title: "期限通知", value: "7日前・前日")
                    SettingLine(symbol: "icloud.and.arrow.down", title: "データ更新", value: "公式情報を確認")
                    SettingLine(symbol: "yensign.circle", title: "価格", value: "App Store 100円")
                    SettingLine(symbol: "hand.raised", title: "プライバシー", value: "個人情報は端末内")
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

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .foregroundStyle(AppTheme.blue)
                .frame(width: 24)
            Text(title)
                .font(.system(size: 14, weight: .bold))
            Spacer()
            Text(value)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.grayText)
        }
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
                Text("この試作の情報は一般的な案内です。実際の期限、必要書類、オンライン可否は自治体や本人の状況で変わります。リリース時は公式リンクと更新日を各手続きに追加してください。")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.grayText)
                    .lineSpacing(2)
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
    let isSaved: Bool
    let toggleSave: () -> Void
    @Environment(\.dismiss) private var dismiss

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
