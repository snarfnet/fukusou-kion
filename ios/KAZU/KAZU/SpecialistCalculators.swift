import SwiftUI

struct FinanceCalculatorView: View {
    @EnvironmentObject private var store: CalculatorStore
    @State private var principal = 30_000_000.0
    @State private var annualRate = 1.2
    @State private var years = 35.0

    private var monthlyPayment: Double {
        let count = max(years * 12, 1)
        let rate = annualRate / 100 / 12
        if rate == 0 { return principal / count }
        return principal * rate * pow(1 + rate, count) / (pow(1 + rate, count) - 1)
    }

    var body: some View {
        SpecialistCard(title: "ローン返済", subtitle: "元利均等返済の月額を計算", result: monthlyPayment.formatted(.currency(code: "JPY"))) {
            ValueField(title: "借入額", value: $principal, suffix: "円")
            ValueField(title: "年利", value: $annualRate, suffix: "%")
            ValueField(title: "返済期間", value: $years, suffix: "年")
            RecordButton {
                store.recordSpecial("ローン \(NumberFormatter.display(principal))円・\(annualRate)%・\(years)年",
                                    result: monthlyPayment)
            }
        }
    }
}

struct ConversionCalculatorView: View {
    @EnvironmentObject private var store: CalculatorStore
    @State private var category: ConversionCategory = .length
    @State private var input = 1.0
    @State private var fromIndex = 0
    @State private var toIndex = 1

    private var result: Double {
        let source = category.units[fromIndex]
        let target = category.units[toIndex]
        return input * source.toBase / target.toBase
    }

    var body: some View {
        SpecialistCard(title: "単位換算", subtitle: "長さ・重さ・データ量をすぐ換算",
                       result: "\(NumberFormatter.display(result)) \(category.units[toIndex].symbol)") {
            Picker("種類", selection: $category) {
                ForEach(ConversionCategory.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .onChange(of: category) { _, _ in fromIndex = 0; toIndex = 1 }
            ValueField(title: "値", value: $input, suffix: category.units[fromIndex].symbol)
            HStack {
                UnitPicker(title: "変換元", index: $fromIndex, units: category.units)
                Button {
                    swap(&fromIndex, &toIndex)
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                        .frame(width: 44, height: 44)
                        .background(KazuTheme.paleBlue, in: Circle())
                }
                .buttonStyle(.plain)
                UnitPicker(title: "変換先", index: $toIndex, units: category.units)
            }
            RecordButton {
                store.recordSpecial("\(input) \(category.units[fromIndex].symbol) → \(category.units[toIndex].symbol)",
                                    result: result)
            }
        }
    }
}

struct DateCalculatorView: View {
    @EnvironmentObject private var store: CalculatorStore
    @State private var start = Date()
    @State private var end = Calendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now

    private var days: Int {
        Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: start),
                                        to: Calendar.current.startOfDay(for: end)).day ?? 0
    }

    var body: some View {
        SpecialistCard(title: "日付の差", subtitle: "2つの日付の間隔", result: "\(abs(days)) 日") {
            DatePicker("開始", selection: $start, displayedComponents: .date)
            DatePicker("終了", selection: $end, displayedComponents: .date)
            Text(days >= 0 ? "終了日は開始日の \(days) 日後です" : "終了日は開始日の \(abs(days)) 日前です")
                .font(.footnote)
                .foregroundStyle(.secondary)
            RecordButton {
                store.recordSpecial("日付差 \(start.formatted(date: .numeric, time: .omitted)) → \(end.formatted(date: .numeric, time: .omitted))",
                                    result: Double(abs(days)))
            }
        }
    }
}

struct StatisticsCalculatorView: View {
    @EnvironmentObject private var store: CalculatorStore
    @State private var input = "12, 18, 21, 21, 28"

    private var values: [Double] {
        input.split(whereSeparator: { ",、 \n".contains($0) }).compactMap { Double($0) }
    }
    private var mean: Double { values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count) }
    private var median: Double {
        let sorted = values.sorted()
        guard !sorted.isEmpty else { return 0 }
        let middle = sorted.count / 2
        return sorted.count.isMultiple(of: 2) ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle]
    }
    private var deviation: Double {
        guard !values.isEmpty else { return 0 }
        return sqrt(values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count))
    }

    var body: some View {
        SpecialistCard(title: "統計", subtitle: "数値をカンマか空白で区切って入力", result: "平均 \(NumberFormatter.display(mean))") {
            TextField("例: 12, 18, 21", text: $input, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numbersAndPunctuation)
                .lineLimit(2...4)
            HStack {
                Metric(label: "個数", value: "\(values.count)")
                Metric(label: "中央値", value: NumberFormatter.display(median))
                Metric(label: "標準偏差", value: NumberFormatter.display(deviation))
            }
            RecordButton { store.recordSpecial("平均 \(values)", result: mean) }
        }
    }
}

struct GeometryCalculatorView: View {
    @EnvironmentObject private var store: CalculatorStore
    @State private var shape: ShapeKind = .circle
    @State private var first = 10.0
    @State private var second = 6.0

    private var area: Double {
        switch shape {
        case .circle: .pi * first * first
        case .rectangle: first * second
        case .triangle: first * second / 2
        }
    }

    var body: some View {
        SpecialistCard(title: "面積", subtitle: "図形と寸法を選んで計算", result: "\(NumberFormatter.display(area)) ㎠") {
            Picker("図形", selection: $shape) {
                ForEach(ShapeKind.allCases) { Label($0.rawValue, systemImage: $0.symbol).tag($0) }
            }
            .pickerStyle(.segmented)
            ValueField(title: shape == .circle ? "半径" : "底辺・幅", value: $first, suffix: "cm")
            if shape != .circle {
                ValueField(title: shape == .triangle ? "高さ" : "高さ", value: $second, suffix: "cm")
            }
            RecordButton { store.recordSpecial("\(shape.rawValue)の面積", result: area) }
        }
    }
}

private struct SpecialistCard<Content: View>: View {
    let title: String
    let subtitle: String
    let result: String
    let content: Content

    init(title: String, subtitle: String, result: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.result = result
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.title3.bold()).foregroundStyle(KazuTheme.ink)
                Text(subtitle).font(.footnote).foregroundStyle(.secondary)
            }
            Text(result)
                .font(.system(.title, design: .rounded, weight: .semibold))
                .foregroundStyle(KazuTheme.cobalt)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
            Divider()
            content
        }
        .kazuCard()
    }
}

private struct ValueField: View {
    let title: String
    @Binding var value: Double
    let suffix: String

    var body: some View {
        HStack {
            Text(title).font(.subheadline.weight(.medium))
            Spacer()
            TextField(title, value: $value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 145)
            Text(suffix).foregroundStyle(.secondary).frame(minWidth: 24, alignment: .leading)
        }
    }
}

private struct RecordButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Label("履歴に保存", systemImage: "clock.badge.checkmark")
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(KazuTheme.ink, in: RoundedRectangle(cornerRadius: 13))
                .foregroundStyle(.white)
        }
    }
}

private struct Metric: View {
    let label: String
    let value: String
    var body: some View {
        VStack(spacing: 4) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline.monospacedDigit()).lineLimit(1).minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(KazuTheme.paleBlue.opacity(0.62), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct UnitPicker: View {
    let title: String
    @Binding var index: Int
    let units: [ConversionUnit]
    var body: some View {
        Picker(title, selection: $index) {
            ForEach(Array(units.enumerated()), id: \.offset) { index, unit in
                Text(unit.symbol).tag(index)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ConversionUnit {
    let symbol: String
    let toBase: Double
}

private enum ConversionCategory: String, CaseIterable, Identifiable {
    case length = "長さ"
    case mass = "重さ"
    case data = "データ"
    var id: Self { self }
    var units: [ConversionUnit] {
        switch self {
        case .length: [.init(symbol: "m", toBase: 1), .init(symbol: "km", toBase: 1000),
                       .init(symbol: "cm", toBase: 0.01), .init(symbol: "in", toBase: 0.0254),
                       .init(symbol: "ft", toBase: 0.3048)]
        case .mass: [.init(symbol: "kg", toBase: 1), .init(symbol: "g", toBase: 0.001),
                     .init(symbol: "lb", toBase: 0.45359237), .init(symbol: "oz", toBase: 0.0283495)]
        case .data: [.init(symbol: "B", toBase: 1), .init(symbol: "KB", toBase: 1000),
                     .init(symbol: "MB", toBase: 1_000_000), .init(symbol: "GB", toBase: 1_000_000_000)]
        }
    }
}

private enum ShapeKind: String, CaseIterable, Identifiable {
    case circle = "円"
    case rectangle = "長方形"
    case triangle = "三角形"
    var id: Self { self }
    var symbol: String {
        switch self { case .circle: "circle"; case .rectangle: "rectangle"; case .triangle: "triangle" }
    }
}
