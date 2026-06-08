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
                    heroPanel
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
            .navigationTitle("こんな時、どうしたらいい？")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "離婚、ゴミ、騒音、SNS")
        } detail: {
            if let selectedCase, filteredCases.contains(selectedCase) {
                CaseDetailView(item: selectedCase)
            } else {
                ContentUnavailableView(
                    filteredCases.isEmpty ? "事例がありません" : "事例を選んでください",
                    systemImage: filteredCases.isEmpty ? "magnifyingglass" : "list.bullet.rectangle",
                    description: Text(filteredCases.isEmpty ? "検索条件を変えてください。" : "左の一覧から、今の状況に近い事例を選べます。")
                )
            }
        }
        .tint(.blue)
        .overlay {
            if let message = store.loadError {
                ContentUnavailableView("読み込みエラー", systemImage: "exclamationmark.triangle", description: Text(message))
                    .background(.regularMaterial)
            }
        }
    }

    private var heroPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image("HeaderTroubleIllustration")
                .resizable()
                .scaledToFill()
                .frame(height: 126)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(alignment: .bottomLeading) {
                    LinearGradient(
                        colors: [.black.opacity(0.52), .black.opacity(0.18), .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .overlay(alignment: .bottomLeading) {
                    Label("困った時の初動を整理", systemImage: "questionmark.bubble.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(12)
                }
                .accessibilityHidden(true)

            Text("法律判断ではなく、まず何を残し、どこへ相談し、何を避けるかを事例ごとに整理します。離婚、近隣、マンション、事故、契約、SNSなど、日常のトラブルを探しやすくしました。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineSpacing(3)

            Text("このアプリは一般情報の案内です。違法性、請求可否、勝敗の判断はしません。深刻な内容は弁護士、警察、自治体、専門窓口へ相談してください。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
        }
        .padding(.vertical, 8)
    }

    private var filterPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("カテゴリーから探す")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    CategoryChip(
                        category: "全部",
                        count: store.cases.count,
                        isSelected: selectedCategory == "全部"
                    ) {
                        selectedCategory = "全部"
                    }

                    ForEach(store.categories, id: \.self) { category in
                        CategoryChip(
                            category: category,
                            count: store.cases.filter { $0.category == category }.count,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.vertical, 2)
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
            clearSelectionIfNeeded()
        }
        .onChange(of: selectedUrgency) {
            clearSelectionIfNeeded()
        }
        .onChange(of: searchText) {
            clearSelectionIfNeeded()
        }
    }

    private func clearSelectionIfNeeded() {
        if let selectedCase, !filteredCases.contains(selectedCase) {
            self.selectedCase = nil
        }
    }
}

private struct CategoryChip: View {
    let category: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if category == "全部" {
                    Image(systemName: "square.grid.2x2")
                        .font(.subheadline.weight(.bold))
                        .frame(width: 28, height: 28)
                } else {
                    CategoryIcon(category: category, size: 30)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(category)
                        .font(.caption.weight(.bold))
                        .lineLimit(1)
                    Text("\(count)件")
                        .font(.caption2)
                        .foregroundStyle(isSelected ? .white.opacity(0.82) : .secondary)
                }
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                isSelected ? Color.blue.gradient : Color(.secondarySystemBackground).gradient,
                in: RoundedRectangle(cornerRadius: 8)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct CaseRow: View {
    let item: TroubleCase

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            CategoryIcon(category: item.category)

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
