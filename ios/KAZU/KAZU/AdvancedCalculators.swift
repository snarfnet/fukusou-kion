import SwiftUI

enum SpecialtyMath {
    static func compound(principal: Double, annualRate: Double, years: Double, monthlyDeposit: Double) -> (total: Double, invested: Double) {
        let months = max(Int(years * 12), 0)
        let rate = annualRate / 100 / 12
        let growth = pow(1 + rate, Double(months))
        let deposits = rate == 0 ? monthlyDeposit * Double(months) : monthlyDeposit * (growth - 1) / rate
        return (principal * growth + deposits, principal + monthlyDeposit * Double(months))
    }

    static func bmi(height: Double, weight: Double) -> Double {
        let meters = height / 100
        return meters > 0 ? weight / (meters * meters) : 0
    }

    static func electrical(voltage: Double, current: Double, hours: Double) -> (power: Double, resistance: Double, energy: Double) {
        (voltage * current, current == 0 ? 0 : voltage / current, voltage * current * hours / 1_000)
    }
}

struct CompoundInterestCalculatorView: View {
    @EnvironmentObject private var store: CalculatorStore
    @State private var principal = 1_000_000.0
    @State private var annualRate = 3.0
    @State private var years = 10.0
    @State private var monthlyDeposit = 10_000.0

    private var calculation: (total: Double, invested: Double) {
        SpecialtyMath.compound(principal: max(principal, 0), annualRate: annualRate, years: max(years, 0), monthlyDeposit: max(monthlyDeposit, 0))
    }

    var body: some View {
        SpecialistCard(title: "複利シミュレーション", subtitle: "元金と毎月の積立を計算", result: calculation.total.formatted(.currency(code: "JPY"))) {
            ValueField(title: "元金", value: $principal, suffix: "円")
            ValueField(title: "年利", value: $annualRate, suffix: "%")
            ValueField(title: "期間", value: $years, suffix: "年")
            ValueField(title: "毎月の積立", value: $monthlyDeposit, suffix: "円")
            Metric(label: "運用益", value: (calculation.total - calculation.invested).formatted(.currency(code: "JPY")))
            RecordButton { store.recordSpecial("複利 \(annualRate)%・\(years)年", result: calculation.total) }
        }
    }
}

private enum PercentageMode: String, CaseIterable, Identifiable {
    case discount = "値引き"
    case markup = "上乗せ"
    var id: Self { self }
}

struct PercentageCalculatorView: View {
    @EnvironmentObject private var store: CalculatorStore
    @State private var amount = 10_000.0
    @State private var rate = 10.0
    @State private var mode = PercentageMode.discount

    private var difference: Double { amount * rate / 100 }
    private var result: Double { mode == .discount ? amount - difference : amount + difference }

    var body: some View {
        SpecialistCard(title: "割合・値引き", subtitle: "値引きや上乗せ後の金額", result: result.formatted(.currency(code: "JPY"))) {
            Picker("計算", selection: $mode) {
                ForEach(PercentageMode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            ValueField(title: "元の金額", value: $amount, suffix: "円")
            ValueField(title: "割合", value: $rate, suffix: "%")
            Metric(label: "差額", value: abs(difference).formatted(.currency(code: "JPY")))
            RecordButton { store.recordSpecial("\(rate)%\(mode.rawValue)", result: result) }
        }
    }
}

struct HealthCalculatorView: View {
    @EnvironmentObject private var store: CalculatorStore
    @State private var height = 170.0
    @State private var weight = 65.0

    private var bmi: Double { SpecialtyMath.bmi(height: height, weight: weight) }
    private var standardWeight: Double {
        let meters = max(height, 0) / 100
        return 22 * meters * meters
    }

    var body: some View {
        SpecialistCard(title: "健康指標", subtitle: "BMI・標準体重・体表面積", result: "BMI \(bmi.formatted(.number.precision(.fractionLength(1))))") {
            ValueField(title: "身長", value: $height, suffix: "cm")
            ValueField(title: "体重", value: $weight, suffix: "kg")
            HStack {
                Metric(label: "BMI 22の体重", value: "\(standardWeight.formatted(.number.precision(.fractionLength(1)))) kg")
                Metric(label: "体表面積", value: "\(sqrt(max(height * weight, 0) / 3_600).formatted(.number.precision(.fractionLength(2)))) m²")
            }
            Text("健康指標は目安です。診断には使えません。")
                .font(.caption)
                .foregroundStyle(.secondary)
            RecordButton { store.recordSpecial("BMI \(height)cm・\(weight)kg", result: bmi) }
        }
    }
}

struct ElectricalCalculatorView: View {
    @EnvironmentObject private var store: CalculatorStore
    @State private var voltage = 100.0
    @State private var current = 1.0
    @State private var hours = 1.0

    private var calculation: (power: Double, resistance: Double, energy: Double) {
        SpecialtyMath.electrical(voltage: voltage, current: current, hours: hours)
    }

    var body: some View {
        SpecialistCard(title: "電気計算", subtitle: "電力・抵抗・電力量", result: "\(calculation.power.formatted(.number.precision(.fractionLength(2)))) W") {
            ValueField(title: "電圧", value: $voltage, suffix: "V")
            ValueField(title: "電流", value: $current, suffix: "A")
            ValueField(title: "使用時間", value: $hours, suffix: "時間")
            HStack {
                Metric(label: "抵抗", value: "\(calculation.resistance.formatted(.number.precision(.fractionLength(2)))) Ω")
                Metric(label: "電力量", value: "\(calculation.energy.formatted(.number.precision(.fractionLength(3)))) kWh")
            }
            RecordButton { store.recordSpecial("\(voltage)V × \(current)A", result: calculation.power) }
        }
    }
}
