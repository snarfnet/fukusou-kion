import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var locationService: LocationAddressService
    @EnvironmentObject private var scheduleStore: WasteScheduleStore

    private var upcomingDays: [CollectionDay] {
        scheduleStore.upcomingDays(for: locationService.currentAddress)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    locationPanel
                    schedulePanel
                    rulesPanel
                }
                .padding(18)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("ごみ日カレンダー")
            .toolbarTitleDisplayMode(.inline)
        }
    }

    private var locationPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("現在地")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(locationService.currentAddress?.fullText ?? "未取得")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }

                Spacer()

                Button {
                    Task { await locationService.refresh() }
                } label: {
                    if locationService.isLoading {
                        ProgressView()
                    } else {
                        Image(systemName: "location.fill")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(locationService.isLoading)
                .accessibilityLabel("現在地を取得")
            }

            if let address = locationService.currentAddress {
                HStack(spacing: 8) {
                    Label(address.municipality.isEmpty ? "自治体不明" : address.municipality, systemImage: "building.2")
                    if !address.town.isEmpty {
                        Label(address.town, systemImage: "mappin.and.ellipse")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            if let errorMessage = locationService.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .panelStyle()
    }

    private var schedulePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("次の収集日")
                    .font(.headline)

                Spacer()

                if let address = locationService.currentAddress {
                    Button("仮ルール追加") {
                        scheduleStore.addDemoRules(for: address)
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                }
            }

            if upcomingDays.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("この住所の収集ルールは未登録です。")
                        .font(.subheadline)
                    Text("自治体の公式カレンダーから曜日を登録すると、ここに直近の日程が出ます。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 10)
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(upcomingDays) { day in
                        CollectionDayRow(day: day)
                    }
                }
            }
        }
        .panelStyle()
    }

    private var rulesPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("登録済みルール")
                .font(.headline)

            if scheduleStore.rules.isEmpty {
                Text("まだルールがありません。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 10)
            } else {
                ForEach(scheduleStore.rules) { rule in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(rule.category.tint)
                            .frame(width: 10, height: 10)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(rule.category.rawValue)
                                .font(.subheadline.weight(.semibold))
                            Text("\(rule.municipality) \(rule.townKeyword) / \(weekdayName(rule.weekday))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if !rule.memo.isEmpty {
                                Text(rule.memo)
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                        }

                        Spacer()

                        Button(role: .destructive) {
                            scheduleStore.remove(rule)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .panelStyle()
    }

    private func weekdayName(_ weekday: Int) -> String {
        let symbols = Calendar(identifier: .gregorian).shortWeekdaySymbols
        guard symbols.indices.contains(weekday - 1) else { return "曜日不明" }
        return symbols[weekday - 1]
    }
}

private struct CollectionDayRow: View {
    var day: CollectionDay

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 2) {
                Text(day.dayText)
                    .font(.headline.monospacedDigit())
                Text(day.weekdayText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 54)

            Circle()
                .fill(day.rule.category.tint)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(day.rule.category.rawValue)
                    .font(.subheadline.weight(.semibold))
                if !day.rule.memo.isEmpty {
                    Text(day.rule.memo)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private extension View {
    func panelStyle() -> some View {
        self
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

#Preview {
    ContentView()
        .environmentObject(LocationAddressService())
        .environmentObject(WasteScheduleStore())
}
