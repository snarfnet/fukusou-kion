import SwiftUI
import SwiftData

struct CaseListView: View {
    @Query(sort: \LostItemCase.updatedAt, order: .reverse) private var cases: [LostItemCase]
    let select: (UUID) -> Void
    var body: some View { Group { if cases.isEmpty { ContentUnavailableView("cases.empty", systemImage: "tray", description: Text("cases.emptyDetail")) } else { List(cases) { item in Button { select(item.id) } label: { HStack { Image(systemName: item.categories.first?.icon ?? "shippingbox").font(.title2).frame(width: 44); VStack(alignment: .leading) { Text(item.categories.map(\.title).joined(separator: ", ")).font(.headline); Text(item.location.name.isEmpty ? item.location.category.title : item.location.name).foregroundStyle(.secondary); Text(item.updatedAt, style: .relative).font(.caption) }; Spacer(); Text(L10n.text("status.\(item.statusRawValue)")).font(.caption).padding(6).background(.blue.opacity(0.12), in: Capsule()) } }.buttonStyle(.plain) } } }.navigationTitle("cases.title") }
}

struct CaseDetailView: View {
    @Query private var results: [LostItemCase]
    init(caseID: UUID) { _results = Query(filter: #Predicate<LostItemCase> { $0.id == caseID }) }
    var body: some View { Group { if let item = results.first { CaseDetailContent(item: item) } else { ContentUnavailableView("cases.notFound", systemImage: "exclamationmark.triangle") } }.navigationTitle("case.detail") }
}

private struct CaseDetailContent: View {
    let item: LostItemCase
    @State private var showCard = false
    private var plan: RecoveryPlan { RecoveryRuleEngine().generatePlan(categories: item.categories, location: item.location, lostDate: item.location.lastSeenAt, currentDate: Date()) }
    var body: some View { ScrollView { VStack(alignment: .leading, spacing: 22) { VStack(alignment: .leading, spacing: 8) { Text(item.title).font(.largeTitle.bold()); Label(item.location.name.isEmpty ? item.location.category.title : item.location.name, systemImage: "mappin"); Text(item.location.lastSeenAt.formatted(date: .long, time: .shortened)).foregroundStyle(.secondary) }; RecoveryPlanSection(plan: plan); Button { showCard = true } label: { Label("card.show", systemImage: "character.bubble").frame(maxWidth: .infinity) }.buttonStyle(PrimaryButtonStyle()) }.padding() }.sheet(isPresented: $showCard) { NavigationStack { JapaneseCardView(item: item) } } }
}

private struct RecoveryPlanSection: View {
    let plan: RecoveryPlan
    var body: some View { VStack(alignment: .leading, spacing: 16) { Text("plan.title").font(.title2.bold()); ActionCard(label: "plan.now", action: plan.now); ForEach(plan.next) { ActionCard(label: "plan.next", action: $0) }; ActionCard(label: "plan.ifNotFound", action: plan.ifNotFound); if let action = plan.beforeDeparture { ActionCard(label: "plan.beforeDeparture", action: action) } } }
}

private struct ActionCard: View {
    let label: LocalizedStringKey; let action: RecoveryAction
    var body: some View { VStack(alignment: .leading, spacing: 5) { Text(label).font(.caption.bold()).foregroundStyle(action.isUrgent ? Color.red : Color.brandBlue); Text(action.title).font(.headline); Text(action.detail).foregroundStyle(.secondary) }.frame(maxWidth: .infinity, alignment: .leading).padding().background(.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14)).accessibilityElement(children: .combine) }
}
