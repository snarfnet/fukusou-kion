import Foundation

@MainActor
final class WeatherAppModel: ObservableObject {
    @Published var snapshot: WeatherSnapshot = .preview
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var selectedTab: AppTab = .home

    @Published var temperatureSense: TemperatureSense {
        didSet { UserDefaults.standard.set(temperatureSense.rawValue, forKey: "temperatureSense") }
    }

    @Published var styleTarget: StyleTarget {
        didSet { UserDefaults.standard.set(styleTarget.rawValue, forKey: "styleTarget") }
    }

    @Published var notificationHour: NotificationHour {
        didSet { UserDefaults.standard.set(notificationHour.rawValue, forKey: "notificationHour") }
    }

    @Published var notificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled") }
    }

    private let locationService = LocationService()
    private let weatherProvider = WeatherProvider()

    init() {
        let senseRaw = UserDefaults.standard.string(forKey: "temperatureSense") ?? TemperatureSense.normal.rawValue
        temperatureSense = TemperatureSense(rawValue: senseRaw) ?? .normal

        let targetRaw = UserDefaults.standard.string(forKey: "styleTarget") ?? StyleTarget.women.rawValue
        styleTarget = StyleTarget(rawValue: targetRaw) ?? .shared

        let hourRaw = UserDefaults.standard.integer(forKey: "notificationHour")
        notificationHour = NotificationHour(rawValue: hourRaw) ?? .seven
        notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil

        do {
            let location = try await locationService.requestLocation()
            snapshot = try await weatherProvider.snapshot(for: location)
        } catch {
            errorMessage = "天気を取得できませんでした。位置情報とWeatherKit設定を確認してください。"
        }

        isLoading = false
    }

    func advice(for forecast: DayForecast) -> OutfitAdvice {
        OutfitRuleEngine.advice(for: forecast, sense: temperatureSense, target: styleTarget)
    }

    func updateNotification() async {
        do {
            if notificationsEnabled {
                try await NotificationService.scheduleMorningReminder(hour: notificationHour)
            } else {
                NotificationService.cancelMorningReminder()
            }
        } catch {
            errorMessage = "通知を設定できませんでした。"
        }
    }
}

enum AppTab {
    case home
    case week
    case notifications
    case settings
}
