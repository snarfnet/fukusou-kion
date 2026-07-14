import SwiftUI

struct HomeView: View {
    let navigate: (AppRoute) -> Void
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Image(systemName: "mappin.and.ellipse").font(.title).foregroundStyle(.brandBlue)
                    VStack(alignment: .leading) { Text("app.name").font(.title2.bold()); Text("app.subtitle").font(.caption).foregroundStyle(.secondary) }
                    Spacer()
                    Button { navigate(.settings) } label: { Image(systemName: "gearshape").frame(width: 44, height: 44) }.accessibilityLabel("home.settings")
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("home.helpNow").font(.headline).foregroundStyle(.secondary)
                    Button { navigate(.register) } label: {
                        Label("home.lost", systemImage: "magnifyingglass").font(.title2.bold()).frame(maxWidth: .infinity, minHeight: 88)
                    }.buttonStyle(PrimaryButtonStyle())
                }
                LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 14) {
                    HomeTile(title: "home.cases", icon: "tray.full") { navigate(.cases) }
                    HomeTile(title: "home.police", icon: "map") { navigate(.police) }
                    HomeTile(title: "home.emergency", icon: "cross.case") { navigate(.emergency) }
                    HomeTile(title: "home.found", icon: "hand.raised") { navigate(.found) }
                }
                Text("home.offlineNote").font(.footnote).foregroundStyle(.secondary)
            }.padding()
        }.navigationBarHidden(true)
    }
}

private struct HomeTile: View {
    let title: LocalizedStringKey; let icon: String; let action: () -> Void
    var body: some View { Button(action: action) { VStack(spacing: 12) { Image(systemName: icon).font(.title); Text(title).font(.headline).multilineTextAlignment(.center) }.frame(maxWidth: .infinity, minHeight: 120).background(.background, in: RoundedRectangle(cornerRadius: 18)).overlay(RoundedRectangle(cornerRadius: 18).stroke(.quaternary)) }.buttonStyle(.plain) }
}

#Preview { NavigationStack { HomeView { _ in } } }

