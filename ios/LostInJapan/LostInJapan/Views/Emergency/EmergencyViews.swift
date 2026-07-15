import SwiftUI

struct EmergencyGuideView: View {
    private let guides: [(title: String, detail: String, icon: String)] = [
        ("emergency.passport", "emergency.passport.detail", "book.closed"),
        ("emergency.wallet", "emergency.wallet.detail", "wallet.bifold"),
        ("emergency.phone", "emergency.phone.detail", "iphone"),
        ("emergency.card", "emergency.card.detail", "creditcard"),
        ("emergency.medicine", "emergency.medicine.detail", "pills"),
        ("emergency.child", "emergency.child.detail", "figure.and.child.holdinghands"),
        ("emergency.theft", "emergency.theft.detail", "exclamationmark.shield"),
        ("emergency.departure", "emergency.departure.detail", "airplane.departure")
    ]

    var body: some View {
        List(guides, id: \.title) { guide in
            NavigationLink {
                EmergencyGuideDetailView(titleKey: guide.title, detailKey: guide.detail, icon: guide.icon)
            } label: {
                Label(LocalizedStringKey(guide.title), systemImage: guide.icon)
                    .padding(.vertical, 8)
            }
        }
        .navigationTitle("home.emergency")
        .safeAreaInset(edge: .bottom) {
            Text("emergency.warning")
                .font(.footnote)
                .padding()
                .frame(maxWidth: .infinity)
                .background(.orange.opacity(0.14))
        }
    }
}

private struct EmergencyGuideDetailView: View {
    let titleKey: String
    let detailKey: String
    let icon: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Image(systemName: icon)
                    .font(.system(size: 64))
                    .foregroundStyle(Color.brandBlue)
                    .frame(maxWidth: .infinity)
                Text(LocalizedStringKey(detailKey))
                    .font(.title3)
                    .lineSpacing(7)
                Label("emergency.callPolice", systemImage: "phone.fill")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.orange.opacity(0.14), in: RoundedRectangle(cornerRadius: 14))
            }
            .padding()
        }
        .navigationTitle(LocalizedStringKey(titleKey))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FoundSomethingView: View {
    var body: some View {
        List {
            Section("found.doNow") {
                Label("found.station", systemImage: "tram")
                Label("found.store", systemImage: "storefront")
                Label("found.street", systemImage: "building.columns")
                Label("found.transport", systemImage: "bus")
                Label("found.facility", systemImage: "building.2")
                Label("found.cash", systemImage: "banknote")
                Label("found.valuable", systemImage: "wallet.bifold")
                Label("found.dangerous", systemImage: "exclamationmark.triangle")
                Label("found.dontInspect", systemImage: "eye.slash")
            }
            Section("found.card") {
                Text(JapaneseCardService.foundItemText)
                    .font(.title2.bold())
                    .padding(.vertical)
            }
        }
        .navigationTitle("home.found")
    }
}
