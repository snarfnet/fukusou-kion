import SwiftUI

struct HomeView: View {
    @EnvironmentObject var app: AppViewModel; @State private var query = ""
    var results: [PhraseCard] { app.search(query) }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    NavigationLink(destination: EmergencyMenuView()) { Label("Emergency", systemImage: "sos").frame(maxWidth: .infinity, minHeight: 58) }.buttonStyle(.borderedProminent).tint(.red).font(.title3.bold()).accessibilityHint("Opens emergency assistance")
                    if !query.isEmpty { PhraseRows(cards: results) }
                    else {
                        if !app.favorites.isEmpty { SectionTitle("Favorites"); PhraseRows(cards: app.cards.filter{app.favorites.contains($0.id)}.prefixArray(5)) }
                        if !app.recentIDs.isEmpty { SectionTitle("Recent"); PhraseRows(cards: app.recentIDs.compactMap{id in app.cards.first{$0.id == id}}.prefixArray(5)) }
                        SectionTitle("Categories")
                        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 14) {
                            ForEach(app.categories) { category in
                                NavigationLink(destination: PhraseListView(category: category)) {
                                    VStack(spacing: 10) { Image(systemName: category.iconName).font(.title); Text(category.title(in: app.language)).font(.headline).multilineTextAlignment(.center) }.frame(maxWidth: .infinity, minHeight: 110).background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                                }.buttonStyle(.plain).accessibilityLabel(category.title(in: app.language))
                            }
                        }
                    }
                }.padding()
            }.navigationTitle("Show This Japan").searchable(text: $query, prompt: "Search phrases").toolbar { NavigationLink(destination: SettingsView()) { Image(systemName: "gearshape") } }
        }
    }
}

struct SectionTitle: View { let value: String; init(_ value: String){self.value=value}; var body: some View { Text(value).font(.title2.bold()) } }
extension Collection { func prefixArray(_ maxLength: Int) -> [Element] { Array(prefix(maxLength)) } }

struct PhraseListView: View {
    @EnvironmentObject var app: AppViewModel; let category: PhraseCategory; @State private var query = ""
    var cards: [PhraseCard] { app.search(query).filter{$0.categoryID == category.id} }
    var body: some View { List { PhraseRows(cards: cards) }.navigationTitle(category.title(in: app.language)).searchable(text: $query, prompt: "Search") }
}

struct PhraseRows: View {
    @EnvironmentObject var app: AppViewModel; let cards: [PhraseCard]
    var body: some View { ForEach(cards) { card in NavigationLink(destination: PhraseCardView(card: card)) { HStack { Image(systemName: card.iconName).frame(width: 30); VStack(alignment:.leading) { Text(card.text(in: app.language)).font(.headline); Text(card.japaneseText).font(.subheadline).foregroundStyle(.secondary) }; Spacer(); Button { app.toggleFavorite(card.id) } label: { Image(systemName: app.favorites.contains(card.id) ? "star.fill" : "star") }.buttonStyle(.plain).accessibilityLabel(app.favorites.contains(card.id) ? "Remove favorite" : "Add favorite") } } } }
}

#Preview { NavigationStack { HomeView() }.environmentObject(AppViewModel()) }

