import SwiftUI

struct FilterView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var model: SpotViewModel
    var body: some View {
        NavigationStack {
            Form {
                Section("検索範囲") {
                    Toggle("距離で絞る", isOn: $model.distanceFilterEnabled)
                    if model.distanceFilterEnabled {
                        Slider(value: $model.maxDistance, in: 0.5...100, step: 0.5)
                        Text("基準地点から \(model.maxDistance, specifier: "%.1f") km以内")
                    }
                }
                Section("条件") {
                    Toggle("完全無料", isOn: $model.freeOnly); Toggle("屋内", isOn: $model.indoorOnly)
                    Toggle("座れる", isOn: $model.seatsOnly); Toggle("トイレあり", isOn: $model.toiletOnly); Toggle("Wi-Fiあり", isOn: $model.wifiOnly)
                    Toggle("公式情報で確認済み", isOn: $model.verifiedOnly)
                }
                Section { Button("すべての条件をリセット", role: .destructive) { model.resetFilters() } }
            }.navigationTitle("絞り込み").toolbar { Button("完了") { dismiss() } }
        }.presentationDetents([.medium, .large])
    }
}
