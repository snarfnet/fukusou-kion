import SwiftUI

struct ReportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let spot: Spot
    @State private var reason = "閉店している"
    @State private var note = ""
    @State private var sent = false
    let reasons = ["閉店している", "一般利用できない", "有料になった", "営業時間が違う", "冷房・トイレ・座席の情報が違う", "その他"]
    var body: some View {
        NavigationStack { Form { Section("対象") { Text(spot.name) }; Section("内容") { Picker("理由", selection: $reason) { ForEach(reasons, id: \.self) { Text($0) } }; TextField("補足（任意）", text: $note, axis: .vertical) }; Section { Button("端末に保存") { context.insert(SpotReport(spot: spot, reason: reason, note: note)); sent = true }.frame(maxWidth: .infinity) } footer: { Text("現在は管理サーバーへ自動送信されません。保存した報告は、送信機能の追加後に確認できます。") } }.navigationTitle("情報の修正報告").toolbar { Button("閉じる") { dismiss() } }.alert("報告を保存しました", isPresented: $sent) { Button("OK") { dismiss() } } message: { Text("端末内に確認待ちとして保存しました。") } }
    }
}
