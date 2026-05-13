import Foundation
import WeatherKit

enum TemperatureSense: String, CaseIterable, Identifiable {
    case heatSensitive = "暑がり"
    case normal = "普通"
    case coldSensitive = "寒がり"

    var id: String { rawValue }

    var adjustment: Double {
        switch self {
        case .heatSensitive: 2
        case .normal: 0
        case .coldSensitive: -2
        }
    }
}

enum StyleTarget: String, CaseIterable, Identifiable {
    case shared = "共通"
    case men = "男性向け"
    case women = "女性向け"

    var id: String { rawValue }
}

enum NotificationHour: Int, CaseIterable, Identifiable {
    case seven = 7
    case eight = 8
    case nine = 9

    var id: Int { rawValue }
    var label: String { "\(rawValue):00" }
}

enum UmbrellaAdvice: String {
    case none = "今日は傘なしでよさそう"
    case foldable = "折りたたみ傘があると安心"
    case full = "普通の傘を持って出よう"
}

struct OutfitAdvice: Equatable {
    let title: String
    let details: [String]
    let umbrella: UmbrellaAdvice
    let accent: String
}

struct DayForecast: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let symbolName: String
    let condition: String
    let high: Double
    let low: Double
    let precipitationChance: Double
    let windSpeed: Double
    let uvIndex: Int

    var rainPercent: Int {
        Int((precipitationChance * 100).rounded())
    }
}

struct WeatherSnapshot: Equatable {
    let locationName: String
    let currentTemperature: Double
    let currentSymbolName: String
    let currentCondition: String
    let today: DayForecast
    let week: [DayForecast]

    static let preview = WeatherSnapshot(
        locationName: "現在地",
        currentTemperature: 23,
        currentSymbolName: "cloud.sun.fill",
        currentCondition: "晴れ時々くもり",
        today: DayForecast(
            date: .now,
            symbolName: "cloud.sun.fill",
            condition: "晴れ時々くもり",
            high: 26,
            low: 18,
            precipitationChance: 0.35,
            windSpeed: 4.2,
            uvIndex: 6
        ),
        week: [
            DayForecast(date: .now, symbolName: "cloud.sun.fill", condition: "晴れ", high: 26, low: 18, precipitationChance: 0.35, windSpeed: 4.2, uvIndex: 6),
            DayForecast(date: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now, symbolName: "umbrella.fill", condition: "雨", high: 21, low: 17, precipitationChance: 0.72, windSpeed: 5.1, uvIndex: 2),
            DayForecast(date: Calendar.current.date(byAdding: .day, value: 2, to: .now) ?? .now, symbolName: "sun.max.fill", condition: "晴れ", high: 30, low: 22, precipitationChance: 0.12, windSpeed: 3.0, uvIndex: 8),
            DayForecast(date: Calendar.current.date(byAdding: .day, value: 3, to: .now) ?? .now, symbolName: "cloud.fill", condition: "くもり", high: 19, low: 13, precipitationChance: 0.28, windSpeed: 8.4, uvIndex: 3)
        ]
    )
}

struct OutfitRuleEngine {
    static func advice(
        for forecast: DayForecast,
        sense: TemperatureSense,
        target: StyleTarget
    ) -> OutfitAdvice {
        let effectiveHigh = forecast.high + sense.adjustment
        var title: String
        var details: [String]
        var accent: String

        switch effectiveHigh {
        case 30...:
            title = "半袖と薄手で軽く"
            details = ["通気性のいい服", "帽子や日焼け対策"]
            accent = "暑さ対策"
        case 25..<30:
            title = "半袖か薄手シャツ"
            details = ["朝晩用に薄い羽織りもあり"]
            accent = "身軽"
        case 20..<25:
            title = "長袖シャツがちょうどいい"
            details = ["薄手カーディガンがあると調整しやすい"]
            accent = "調整しやすく"
        case 15..<20:
            title = "パーカーかジャケット"
            details = ["日陰や夜は少し冷えるかも"]
            accent = "軽い防寒"
        case 10..<15:
            title = "コートとニット"
            details = ["首元まで暖かく"]
            accent = "しっかり防寒"
        case 5..<10:
            title = "厚手コートとマフラー"
            details = ["手先の冷えにも注意"]
            accent = "冬支度"
        default:
            title = "ダウン、手袋、マフラー"
            details = ["外に出る前に防寒を足して"]
            accent = "本気の寒さ"
        }

        switch target {
        case .shared:
            break
        case .men:
            details.append("足元は歩きやすい靴で")
        case .women:
            details.append("冷えやすい日はストールも便利")
        }

        if forecast.windSpeed >= 8 {
            details.append("風が強め。髪型と軽い羽織りに注意")
        }

        if forecast.uvIndex >= 6 {
            details.append("UV高め。日焼け止め推奨")
        }

        let umbrella: UmbrellaAdvice
        if forecast.precipitationChance >= 0.70 {
            umbrella = .full
        } else if forecast.precipitationChance >= 0.40 {
            umbrella = .foldable
        } else {
            umbrella = .none
        }

        return OutfitAdvice(title: title, details: details, umbrella: umbrella, accent: accent)
    }
}
