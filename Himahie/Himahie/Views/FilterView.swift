import SwiftUI

struct FilterView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var model: SpotViewModel
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(SpotFacilityType.allCases) { type in
                        Button {
                            model.toggleFacilityType(type)
                        } label: {
                            HStack {
                                Label(type.rawValue, systemImage: type.icon)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: model.selectedFacilityTypes.contains(type) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(model.selectedFacilityTypes.contains(type) ? Theme.blue : .secondary)
                                    .font(.title3)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(model.selectedFacilityTypes.contains(type) ? .isSelected : [])
                    }
                } header: {
                    Text("施設の種類")
                } footer: {
                    Text(model.selectedFacilityTypes.isEmpty ? "未選択の場合は、すべての種類を表示します。" : "チェックした種類のどれかに当てはまる施設を表示します。")
                }
                Section("検索範囲") {
                    Toggle("距離で絞る", isOn: $model.distanceFilterEnabled)
                    if model.distanceFilterEnabled {
                        Slider(value: $model.maxDistance, in: 0.5...100, step: 0.5)
                        Text("\(model.distanceBasisText)で \(model.maxDistance, specifier: "%.1f")km以内")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Section("条件") {
                    Toggle("無料情報がある施設", isOn: $model.freeOnly)
                    Toggle("屋内候補", isOn: $model.indoorOnly)
                    Toggle("座れる", isOn: $model.seatsOnly); Toggle("トイレあり", isOn: $model.toiletOnly); Toggle("Wi-Fiあり", isOn: $model.wifiOnly)
                    Toggle("公式情報で確認済みのみ", isOn: $model.verifiedOnly)
                }
                Section("情報の見方") {
                    Label("「未確認」は情報がない状態です。なしという意味ではありません。", systemImage: "checkmark.circle.trianglebadge.exclamationmark")
                    Label("OpenStreetMap由来の候補は、料金・冷房・営業時間を公式サイトで確認してください。", systemImage: "map")
                }
                Section { Button("すべての条件をリセット", role: .destructive) { model.resetFilters() } }
            }.navigationTitle("絞り込み").toolbar { Button("完了") { dismiss() } }
        }.presentationDetents([.medium, .large])
    }
}
