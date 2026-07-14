import SwiftUI

struct EmergencyGuideView: View {
    let guides: [(String, String)] = [("emergency.passport", "book.closed"), ("emergency.wallet", "wallet.bifold"), ("emergency.phone", "iphone"), ("emergency.card", "creditcard"), ("emergency.medicine", "pills"), ("emergency.child", "figure.and.child.holdinghands"), ("emergency.theft", "exclamationmark.shield"), ("emergency.departure", "airplane.departure")]
    var body: some View { List(guides, id: \.0) { key, icon in Label(LocalizedStringKey(key), systemImage: icon) }.navigationTitle("home.emergency").safeAreaInset(edge: .bottom) { Text("emergency.warning").font(.footnote).padding().frame(maxWidth: .infinity).background(.orange.opacity(0.14)) } }
}

struct FoundSomethingView: View {
    var body: some View { List { Section("found.doNow") { Label("found.station", systemImage: "tram"); Label("found.store", systemImage: "storefront"); Label("found.street", systemImage: "building.columns"); Label("found.dontInspect", systemImage: "eye.slash") } Section("found.card") { Text(JapaneseCardService.foundItemText).font(.title2.bold()).padding(.vertical) } }.navigationTitle("home.found") }
}
