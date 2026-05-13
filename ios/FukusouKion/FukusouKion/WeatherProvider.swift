import CoreLocation
import Foundation
import WeatherKit

struct WeatherProvider {
    private let service = WeatherService.shared

    func snapshot(for location: CLLocation) async throws -> WeatherSnapshot {
        let weather = try await service.weather(for: location)
        let daily = Array(weather.dailyForecast.forecast.prefix(7))
        let week = daily.map(Self.makeDayForecast)
        let today = week.first ?? DayForecast(
            date: .now,
            symbolName: weather.currentWeather.symbolName,
            condition: weather.currentWeather.condition.description,
            high: weather.currentWeather.temperature.converted(to: .celsius).value,
            low: weather.currentWeather.temperature.converted(to: .celsius).value,
            precipitationChance: 0,
            windSpeed: weather.currentWeather.wind.speed.converted(to: .metersPerSecond).value,
            uvIndex: weather.currentWeather.uvIndex.value
        )

        return WeatherSnapshot(
            locationName: "現在地",
            currentTemperature: weather.currentWeather.temperature.converted(to: .celsius).value,
            currentSymbolName: weather.currentWeather.symbolName,
            currentCondition: weather.currentWeather.condition.description,
            today: today,
            week: week
        )
    }

    private static func makeDayForecast(from day: DayWeather) -> DayForecast {
        DayForecast(
            date: day.date,
            symbolName: day.symbolName,
            condition: day.condition.description,
            high: day.highTemperature.converted(to: .celsius).value,
            low: day.lowTemperature.converted(to: .celsius).value,
            precipitationChance: day.precipitationChance,
            windSpeed: day.wind.speed.converted(to: .metersPerSecond).value,
            uvIndex: day.uvIndex.value
        )
    }
}
