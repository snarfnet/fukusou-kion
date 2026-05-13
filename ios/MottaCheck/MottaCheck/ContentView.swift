import SwiftData
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("ホーム", systemImage: "checklist") }

            ListLibraryView()
                .tabItem { Label("リスト", systemImage: "tray.full") }

            TemplateView()
                .tabItem { Label("テンプレ", systemImage: "square.grid.2x2") }

            NotificationSettingsView()
                .tabItem { Label("通知", systemImage: "bell") }

            HistoryView()
                .tabItem { Label("履歴", systemImage: "chart.bar") }
        }
        .tint(AppTheme.olive)
    }
}

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PackingList.lastUsedAt, order: .reverse) private var lists: [PackingList]
    @Query(sort: \ForgottenRecord.count, order: .reverse) private var records: [ForgottenRecord]
    @AppStorage("didSeedDefaultLists") private var didSeedDefaultLists = false

    private var todayList: PackingList? {
        lists.first(where: \.isTodayList) ?? lists.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    AdBannerSlot(unitID: AdUnitID.topBanner)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            header

                            if let list = todayList {
                                TodayChecklistPanel(list: list) {
                                    complete(list)
                                } onMissed: { item in
                                    markForgotten(item.name)
                                    item.isChecked = false
                                }
                            } else {
                                EmptyTodayPanel()
                            }

                            FrequentListsPanel(lists: Array(lists.prefix(4))) { selected in
                                makeToday(selected)
                            }
                        }
                        .padding(18)
                    }

                    AdBannerSlot(unitID: AdUnitID.bottomBanner)
                }
            }
            .navigationTitle("持った？")
            .task {
                seedDefaultListsIfNeeded()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("出る前の確認")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(AppTheme.ink)
            Text("今日使うリストを選んで、家を出る前にチェック。")
                .foregroundStyle(AppTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func complete(_ list: PackingList) {
        list.lastUsedAt = .now
        list.items.forEach { $0.isChecked = true }
    }

    private func makeToday(_ selected: PackingList) {
        lists.forEach { $0.isTodayList = false }
        selected.isTodayList = true
        selected.lastUsedAt = .now
    }

    private func markForgotten(_ name: String) {
        if let record = records.first(where: { $0.itemName == name }) {
            record.count += 1
            record.updatedAt = .now
        } else {
            modelContext.insert(ForgottenRecord(itemName: name))
        }
    }

    private func seedDefaultListsIfNeeded() {
        guard !didSeedDefaultLists, lists.isEmpty else { return }
        for (index, template) in PackingTemplate.defaults.enumerated() {
            let list = PackingList(
                title: template.title,
                scene: template.title,
                lastUsedAt: Calendar.current.date(byAdding: .minute, value: -index, to: .now) ?? .now,
                isTodayList: index == 0
            )
            list.replaceItems(with: template.items)
            modelContext.insert(list)
        }
        didSeedDefaultLists = true
    }
}

private struct TodayChecklistPanel: View {
    @Bindable var list: PackingList
    let onComplete: () -> Void
    let onMissed: (PackingItem) -> Void

    private var sortedItems: [PackingItem] {
        list.items.sorted { $0.order < $1.order }
    }

    var body: some View {
        Panel {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(list.title)
                            .font(.title2.weight(.bold))
                        Text("\(list.checkedCount)/\(list.items.count) チェック済み")
                            .foregroundStyle(AppTheme.muted)
                    }
                    Spacer()
                    ProgressRing(progress: list.progress)
                        .frame(width: 58, height: 58)
                }

                ProgressView(value: list.progress)
                    .tint(AppTheme.olive)

                VStack(spacing: 8) {
                    ForEach(sortedItems) { item in
                        HStack(spacing: 12) {
                            Button {
                                item.isChecked.toggle()
                            } label: {
                                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(item.isChecked ? AppTheme.olive : AppTheme.muted)
                            }
                            .buttonStyle(.plain)

                            Text(item.name)
                                .font(.body.weight(.medium))
                                .strikethrough(item.isChecked, color: AppTheme.muted)
                                .foregroundStyle(item.isChecked ? AppTheme.muted : AppTheme.ink)

                            Spacer()

                            Button {
                                onMissed(item)
                            } label: {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundStyle(AppTheme.coral)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(item.name)を忘れやすい物に記録")
                        }
                        .padding(.vertical, 7)
                    }
                }

                Button("全部持った！", action: onComplete)
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
    }
}

private struct ProgressRing: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.black.opacity(0.08), lineWidth: 8)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(AppTheme.olive, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.caption.weight(.bold))
                .foregroundStyle(AppTheme.ink)
        }
    }
}

private struct EmptyTodayPanel: View {
    var body: some View {
        Panel {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: "bag.badge.questionmark")
                    .font(.largeTitle)
                    .foregroundStyle(AppTheme.olive)
                Text("まだリストがありません")
                    .font(.title3.weight(.bold))
                Text("テンプレートから作るか、自分用のリストを追加してください。")
                    .foregroundStyle(AppTheme.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct FrequentListsPanel: View {
    let lists: [PackingList]
    let onSelect: (PackingList) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("よく使うリスト")
                .font(.headline)
                .foregroundStyle(AppTheme.ink)

            if lists.isEmpty {
                Text("保存したリストがここに出ます。")
                    .foregroundStyle(AppTheme.muted)
            } else {
                ForEach(lists) { list in
                    Button {
                        onSelect(list)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(list.title)
                                    .font(.body.weight(.semibold))
                                Text("\(list.items.count)個の持ち物")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.muted)
                            }
                            Spacer()
                            Image(systemName: list.isTodayList ? "star.fill" : "arrow.right.circle")
                                .foregroundStyle(AppTheme.olive)
                        }
                        .padding(14)
                        .background(.white, in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct ListLibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PackingList.lastUsedAt, order: .reverse) private var lists: [PackingList]
    @State private var showingEditor = false
    @State private var editingList: PackingList?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                List {
                    ForEach(lists) { list in
                        Button {
                            editingList = list
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(list.title)
                                        .font(.headline)
                                    if list.isTodayList {
                                        Image(systemName: "sun.max.fill")
                                            .foregroundStyle(AppTheme.coral)
                                    }
                                }
                                Text(list.items.sorted { $0.order < $1.order }.map(\.name).joined(separator: "、"))
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.muted)
                                    .lineLimit(2)
                            }
                            .padding(.vertical, 5)
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete(perform: delete)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("リスト")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        editingList = nil
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                ListEditorView(list: nil)
            }
            .sheet(item: $editingList) { list in
                ListEditorView(list: list)
            }
        }
    }

    private func delete(_ offsets: IndexSet) {
        offsets.map { lists[$0] }.forEach(modelContext.delete)
    }
}

struct ListEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var title: String
    @State private var itemNames: [String]
    @State private var newItem = ""
    let list: PackingList?

    init(list: PackingList?) {
        self.list = list
        _title = State(initialValue: list?.title ?? "")
        _itemNames = State(initialValue: list?.items.sorted { $0.order < $1.order }.map(\.name) ?? [])
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("リスト名") {
                    TextField("例: 平日の仕事", text: $title)
                }

                Section("持ち物") {
                    ForEach(itemNames.indices, id: \.self) { index in
                        TextField("持ち物", text: binding(for: index))
                    }
                    .onDelete { itemNames.remove(atOffsets: $0) }
                    .onMove { itemNames.move(fromOffsets: $0, toOffset: $1) }

                    HStack {
                        TextField("追加する持ち物", text: $newItem)
                        Button {
                            addItem()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(newItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .navigationTitle(list == nil ? "リスト作成" : "リスト編集")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || itemNames.isEmpty)
                }
                ToolbarItem(placement: .bottomBar) {
                    EditButton()
                }
            }
        }
    }

    private func binding(for index: Int) -> Binding<String> {
        Binding(
            get: { itemNames[index] },
            set: { itemNames[index] = $0 }
        )
    }

    private func addItem() {
        let trimmed = newItem.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        itemNames.append(trimmed)
        newItem = ""
    }

    private func save() {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanItems = itemNames
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if let list {
            list.title = cleanTitle
            list.scene = cleanTitle
            list.lastUsedAt = .now
            list.items.forEach { modelContext.delete($0) }
            list.replaceItems(with: cleanItems)
        } else {
            let created = PackingList(title: cleanTitle, scene: cleanTitle)
            created.replaceItems(with: cleanItems)
            modelContext.insert(created)
        }
    }
}

struct TemplateView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var lists: [PackingList]
    @State private var addedTemplate: PackingTemplate?

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    AdBannerSlot(unitID: AdUnitID.topBanner)

                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                            ForEach(PackingTemplate.defaults) { template in
                                TemplateCard(template: template) {
                                    add(template)
                                }
                            }
                        }
                        .padding(18)
                    }

                    AdBannerSlot(unitID: AdUnitID.bottomBanner)
                }
            }
            .navigationTitle("テンプレート")
            .alert("リストを追加しました", isPresented: Binding(
                get: { addedTemplate != nil },
                set: { if !$0 { addedTemplate = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("テンプレート追加時の広告表示を入れる位置もここです。")
            }
        }
    }

    private func add(_ template: PackingTemplate) {
        lists.forEach { $0.isTodayList = false }
        let list = PackingList(title: template.title, scene: template.title, isTodayList: true)
        list.replaceItems(with: template.items)
        modelContext.insert(list)
        addedTemplate = template
    }
}

private struct TemplateCard: View {
    let template: PackingTemplate
    let onAdd: () -> Void

    var body: some View {
        Button(action: onAdd) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: template.symbol)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.tint(template.tintName), in: RoundedRectangle(cornerRadius: 8))

                Text(template.title)
                    .font(.headline)
                    .foregroundStyle(AppTheme.ink)

                Text(template.items.joined(separator: "、"))
                    .font(.caption)
                    .foregroundStyle(AppTheme.muted)
                    .lineLimit(3)

                Spacer(minLength: 0)

                HStack {
                    Text("\(template.items.count)個")
                        .font(.caption.weight(.semibold))
                    Spacer()
                    Image(systemName: "plus.circle.fill")
                }
                .foregroundStyle(AppTheme.olive)
            }
            .frame(maxWidth: .infinity, minHeight: 170, alignment: .topLeading)
            .padding(14)
            .background(.white, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

struct NotificationSettingsView: View {
    @StateObject private var notifications = NotificationManager()
    @AppStorage("departureHour") private var departureHour = 8
    @AppStorage("departureMinute") private var departureMinute = 0
    @AppStorage("minutesBeforeDeparture") private var minutesBeforeDeparture = 15
    @AppStorage("morningHour") private var morningHour = 7
    @AppStorage("morningMinute") private var morningMinute = 15
    @AppStorage("weekdayMask") private var weekdayMask = 62
    @State private var saved = false

    private let weekdayLabels = [
        (1, "日"), (2, "月"), (3, "火"), (4, "水"), (5, "木"), (6, "金"), (7, "土")
    ]

    private var selectedWeekdays: Set<Int> {
        Set((1...7).filter { weekdayMask & (1 << $0) != 0 })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Panel {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: "bell.badge")
                                        .font(.title2)
                                        .foregroundStyle(AppTheme.olive)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("朝・出発前通知")
                                            .font(.headline)
                                        Text(statusText)
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.muted)
                                    }
                                    Spacer()
                                }

                                DatePicker("朝の確認", selection: morningBinding, displayedComponents: .hourAndMinute)
                                DatePicker("出発時刻", selection: departureBinding, displayedComponents: .hourAndMinute)

                                Stepper("出発\(minutesBeforeDeparture)分前に通知", value: $minutesBeforeDeparture, in: 5...120, step: 5)

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("曜日")
                                        .font(.subheadline.weight(.semibold))

                                    HStack(spacing: 7) {
                                        ForEach(weekdayLabels, id: \.0) { weekday, label in
                                            Button {
                                                toggleWeekday(weekday)
                                            } label: {
                                                Text(label)
                                                    .font(.subheadline.weight(.bold))
                                                    .frame(width: 36, height: 36)
                                                    .background(selectedWeekdays.contains(weekday) ? AppTheme.olive : Color.black.opacity(0.06), in: Circle())
                                                    .foregroundStyle(selectedWeekdays.contains(weekday) ? .white : AppTheme.ink)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }

                                Button("通知を保存", action: saveNotifications)
                                    .buttonStyle(PrimaryButtonStyle())
                            }
                        }

                        Panel {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("将来のリマインダー連携", systemImage: "calendar.badge.plus")
                                    .font(.headline)
                                Text("Apple純正リマインダーに予定を作る場合はEventKitで追加できます。MVPではUser Notificationsだけで通知します。")
                                    .foregroundStyle(AppTheme.muted)
                            }
                        }
                    }
                    .padding(18)
                }
            }
            .navigationTitle("通知")
            .task {
                await notifications.refreshStatus()
            }
            .alert("通知を保存しました", isPresented: $saved) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    private var statusText: String {
        switch notifications.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return "通知は使えます"
        case .denied:
            return "設定アプリで通知を許可してください"
        case .notDetermined:
            return "保存時に通知の許可を確認します"
        @unknown default:
            return "通知設定を確認中です"
        }
    }

    private var morningBinding: Binding<Date> {
        timeBinding(hour: $morningHour, minute: $morningMinute)
    }

    private var departureBinding: Binding<Date> {
        timeBinding(hour: $departureHour, minute: $departureMinute)
    }

    private func timeBinding(hour: Binding<Int>, minute: Binding<Int>) -> Binding<Date> {
        Binding {
            Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: hour.wrappedValue, minute: minute.wrappedValue)) ?? .now
        } set: { date in
            let components = Calendar.current.dateComponents([.hour, .minute], from: date)
            hour.wrappedValue = components.hour ?? 0
            minute.wrappedValue = components.minute ?? 0
        }
    }

    private func toggleWeekday(_ weekday: Int) {
        let bit = 1 << weekday
        if weekdayMask & bit == 0 {
            weekdayMask |= bit
        } else {
            weekdayMask &= ~bit
        }
    }

    private func saveNotifications() {
        let weekdays = selectedWeekdays.isEmpty ? Set(1...7) : selectedWeekdays
        Task {
            await notifications.scheduleDailyNotifications(
                departureHour: departureHour,
                departureMinute: departureMinute,
                minutesBeforeDeparture: minutesBeforeDeparture,
                morningHour: morningHour,
                morningMinute: morningMinute,
                weekdays: weekdays
            )
            saved = true
        }
    }
}

struct HistoryView: View {
    @Query(sort: \ForgottenRecord.count, order: .reverse) private var records: [ForgottenRecord]
    @State private var rewardUnlocked = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Panel {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("忘れやすい持ち物ランキング")
                                    .font(.headline)

                                if records.isEmpty {
                                    Text("ホームで三角アイコンを押すと、忘れやすい物として記録します。")
                                        .foregroundStyle(AppTheme.muted)
                                } else {
                                    ForEach(Array(records.prefix(10).enumerated()), id: \.element.id) { index, record in
                                        HStack {
                                            Text("\(index + 1)")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(.white)
                                                .frame(width: 26, height: 26)
                                                .background(AppTheme.olive, in: Circle())

                                            Text(record.itemName)
                                                .font(.body.weight(.semibold))

                                            Spacer()

                                            Text("\(record.count)回")
                                                .foregroundStyle(AppTheme.muted)
                                        }
                                        .padding(.vertical, 5)
                                    }
                                }
                            }
                        }

                        Panel {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("デザインテーマ", systemImage: rewardUnlocked ? "paintpalette.fill" : "lock.fill")
                                    .font(.headline)
                                Text(rewardUnlocked ? "新しいテーマを使える状態です。" : "リワード広告を見たあとに解放する想定の枠です。")
                                    .foregroundStyle(AppTheme.muted)

                                Button {
                                    rewardUnlocked = true
                                } label: {
                                    Label("テーマを解放", systemImage: "play.rectangle.fill")
                                }
                                .buttonStyle(PrimaryButtonStyle())
                            }
                        }

                        Panel {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("広告なし課金", systemImage: "crown.fill")
                                    .font(.headline)
                                Text("将来はここに広告なし課金を追加できます。MVPでは広告枠だけ入れています。")
                                    .foregroundStyle(AppTheme.muted)
                            }
                        }
                    }
                    .padding(18)
                }
            }
            .navigationTitle("履歴")
        }
    }
}
