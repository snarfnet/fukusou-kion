import SwiftUI

struct FormulaLibraryView: View {
    private let sections = [
        FormulaSection(title: "金融", formulas: [
            ("複利", "A = P(1 + r)ⁿ", "元本Pを利率rでn期間運用"),
            ("ローン返済", "M = Pr(1+r)ⁿ / ((1+r)ⁿ−1)", "元利均等返済の月額")
        ]),
        FormulaSection(title: "統計", formulas: [
            ("平均", "x̄ = Σx / n", "合計をデータ数で割る"),
            ("標準偏差", "σ = √(Σ(x−x̄)² / n)", "母集団のばらつき")
        ]),
        FormulaSection(title: "図形", formulas: [
            ("円の面積", "A = πr²", "rは半径"),
            ("三角形の面積", "A = bh / 2", "bは底辺、hは高さ"),
            ("球の体積", "V = 4πr³ / 3", "rは半径")
        ])
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(sections) { section in
                    Section(section.title) {
                        ForEach(Array(section.formulas.enumerated()), id: \.offset) { _, formula in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(formula.0).font(.headline)
                                Text(formula.1)
                                    .font(.system(.body, design: .serif, weight: .semibold))
                                    .foregroundStyle(KazuTheme.cobalt)
                                Text(formula.2).font(.caption).foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(KazuTheme.canvas)
            .navigationTitle("公式")
        }
    }
}

struct HistoryView: View {
    @EnvironmentObject private var store: CalculatorStore
    let onSelect: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                if store.history.isEmpty {
                    ContentUnavailableView("履歴はまだありません", systemImage: "clock",
                                           description: Text("計算結果がここに残ります"))
                } else {
                    List {
                        ForEach(store.history) { entry in
                            Button {
                                store.useHistory(entry)
                                onSelect()
                            } label: {
                                VStack(alignment: .trailing, spacing: 5) {
                                    HStack {
                                        Text(entry.createdAt, format: .dateTime.month().day().hour().minute())
                                            .font(.caption2).foregroundStyle(.secondary)
                                        Spacer()
                                        Text(entry.expression)
                                            .font(.subheadline.monospaced())
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                    Text(entry.result)
                                        .font(.title3.monospacedDigit().weight(.semibold))
                                        .foregroundStyle(KazuTheme.ink)
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete { store.deleteHistory(at: $0) }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(KazuTheme.canvas)
            .navigationTitle("履歴")
            .toolbar {
                if !store.history.isEmpty {
                    Button("すべて消去", role: .destructive) { store.clearHistory() }
                }
            }
        }
    }
}

private struct FormulaSection: Identifiable {
    let id = UUID()
    let title: String
    let formulas: [(String, String, String)]
}
