import SwiftUI

struct ContentView: View {
    @StateObject private var store = CaseStore()
    @State private var searchText = ""
    @State private var selectedCategory = "全部"
    @State private var selectedUrgency: Urgency?
    @State private var selectedCase: TroubleCase?

    private var filteredCases: [TroubleCase] {
        store.cases.filter { item in
            let matchesCategory = selectedCategory == "全部" || item.category == selectedCategory
            let matchesUrgency = selectedUrgency == nil || item.urgency == selectedUrgency
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !query.isEmpty else { return matchesCategory && matchesUrgency }

            let searchable = ([item.title, item.category, item.summary] + item.tags + item.steps + item.avoid + item.evidence + item.contacts).joined(separator: " ")
            return matchesCategory && matchesUrgency && searchable.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedCase) {
                Section {
                    legalNotice
                    filterPanel
                }

                Section("\(filteredCases.count)件") {
                    ForEach(filteredCases) { item in
                        NavigationLink(value: item) {
                            CaseRow(item: item)
                        }
                    }
                }
            }
            .navigationTitle("初動ナビ")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "離婚 ゴミ 騒音 SNS")
        } detail: {
            if let selectedCase {
                CaseDetailView(item: selectedCase)
            } else if let first = filteredCases.first {
                CaseDetailView(item: first)
            } else {
                ContentUnavailableView("事例がありません", systemImage: "magnifyingglass", description: Text("検索条件を変えてください。"))
            }
        }
        .tint(.brown)
        .onAppear {
            if selectedCase == nil {
                selectedCase = store.cases.first
            }
        }
        .overlay {
            if let message = store.loadError {
                ContentUnavailableView("読み込みエラー", systemImage: "exclamationmark.triangle", description: Text(message))
                    .background(.regularMaterial)
            }
        }
    }

    private var legalNotice: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("法律相談ではありません", systemImage: "shield.lefthalf.filled")
                .font(.headline)
            Text("初動、証拠、相談先、専門家に話す内容を整理します。違法性、請求可否、金額、勝敗は判断しません。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }

    private var filterPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("カテゴリ", selection: $selectedCategory) {
                ForEach(store.categories, id: \.self) { category in
                    Text(category).tag(category)
                }
            }

            Picker("緊急度", selection: $selectedUrgency) {
                Text("全部").tag(nil as Urgency?)
                ForEach(Urgency.allCases, id: \.self) { urgency in
                    Text(urgency.title).tag(urgency as Urgency?)
                }
            }
            .pickerStyle(.segmented)
        }
        .onChange(of: selectedCategory) {
            selectedCase = filteredCases.first
        }
        .onChange(of: selectedUrgency) {
            selectedCase = filteredCases.first
        }
        .onChange(of: searchText) {
            selectedCase = filteredCases.first
        }
    }
}

private struct CaseRow: View {
    let item: TroubleCase

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.urgency.title)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(color(for: item.urgency), in: Capsule())
                Text(item.category)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(item.title)
                .font(.headline)
                .lineLimit(2)
            Text(item.summary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }

    private func color(for urgency: Urgency) -> Color {
        switch urgency {
        case .high: return .red
        case .medium: return .blue
        case .low: return .green
        }
    }
}

#Preview {
    ContentView()
}
