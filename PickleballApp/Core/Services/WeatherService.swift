import Foundation
import Observation

// MARK: - WMO Weather Code helpers

private func conditionEmoji(code: Int) -> String {
    switch code {
    case 0:        return "☀️"
    case 1, 2:     return "🌤"
    case 3:        return "☁️"
    case 45, 48:   return "🌫"
    case 51...67:  return "🌧"
    case 71...77:  return "🌨"
    case 80...82:  return "🌦"
    case 85, 86:   return "🌨"
    case 95...99:  return "⛈"
    default:       return "🌡"
    }
}

private func conditionLabel(code: Int) -> String {
    switch code {
    case 0:        return "Clear"
    case 1:        return "Mostly Clear"
    case 2:        return "Partly Cloudy"
    case 3:        return "Overcast"
    case 45, 48:   return "Foggy"
    case 51, 53:   return "Light Drizzle"
    case 55:       return "Drizzle"
    case 61, 63:   return "Light Rain"
    case 65:       return "Heavy Rain"
    case 66, 67:   return "Freezing Rain"
    case 71, 73:   return "Light Snow"
    case 75, 77:   return "Heavy Snow"
    case 80:       return "Light Showers"
    case 81:       return "Showers"
    case 82:       return "Heavy Showers"
    case 85, 86:   return "Snow Showers"
    case 95:       return "Thunderstorm"
    case 96, 99:   return "Severe Thunderstorm"
    default:       return "Unknown"
    }
}

private func isRainyCode(_ code: Int) -> Bool {
    (51...82).contains(code) || (95...99).contains(code)
}

// MARK: - Data Models

struct CurrentWeather {
    var temperatureF: Double
    var windSpeedMph: Double
    var weatherCode: Int
    var uvIndex: Double

    var emoji: String { conditionEmoji(code: weatherCode) }
    var label: String { conditionLabel(code: weatherCode) }

    var isRainy: Bool { isRainyCode(weatherCode) }
    var isWindy: Bool { windSpeedMph > 15 }
    var uvLabel: String {
        switch uvIndex {
        case ..<3:   return "Low"
        case 3..<6:  return "Moderate"
        case 6..<8:  return "High"
        case 8..<11: return "Very High"
        default:     return "Extreme"
        }
    }

    // Pickleball playability
    var playabilityEmoji: String {
        if isRainy { return "🌧" }
        if windSpeedMph > 20 { return "💨" }
        if windSpeedMph > 12 { return "🌬" }
        if temperatureF < 45 || temperatureF > 100 { return "🌡" }
        return "✅"
    }

    var playabilityLabel: String {
        if isRainy { return "Rain — courts likely wet" }
        if windSpeedMph > 20 { return "Too windy to play" }
        if windSpeedMph > 12 { return "Breezy — affects lobs" }
        if temperatureF < 45 { return "Cold — dress in layers" }
        if temperatureF > 100 { return "Very hot — hydrate well" }
        if temperatureF >= 65 && temperatureF <= 85 { return "Perfect pickleball weather" }
        return "Decent conditions"
    }

    var isGoodForPlay: Bool {
        !isRainy && windSpeedMph <= 15 && temperatureF >= 50 && temperatureF <= 98
    }
}

struct DayForecast: Identifiable {
    var id: String { dateString }
    var dateString: String    // "2026-03-30"
    var date: Date
    var maxTempF: Double
    var minTempF: Double
    var weatherCode: Int
    var precipProbability: Int

    var emoji: String { conditionEmoji(code: weatherCode) }
    var label: String { conditionLabel(code: weatherCode) }
    var isRainy: Bool { isRainyCode(weatherCode) }

    var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    var isWeekend: Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        return weekday == 1 || weekday == 7 // Sunday=1, Saturday=7
    }

    var playabilityLabel: String {
        if isRainy || precipProbability > 60 { return "Rain likely" }
        if precipProbability > 30 { return "Chance of rain" }
        if maxTempF < 45 { return "Too cold" }
        return "Good to play"
    }

    var playabilityColor: String {
        // Returns color name string for use in the view
        if isRainy || precipProbability > 60 { return "coral" }
        if precipProbability > 30 { return "amber" }
        if maxTempF < 45 { return "sky" }
        return "green"
    }
}

// MARK: - Open-Meteo Decodable Response

private struct OpenMeteoResponse: Decodable {
    struct Current: Decodable {
        let temperature2m: Double
        let weathercode: Int
        let windspeed10m: Double
        let uvIndex: Double?

        enum CodingKeys: String, CodingKey {
            case temperature2m = "temperature_2m"
            case weathercode
            case windspeed10m = "windspeed_10m"
            case uvIndex = "uv_index"
        }
    }

    struct Daily: Decodable {
        let time: [String]
        let temperature2mMax: [Double]
        let temperature2mMin: [Double]
        let weathercode: [Int]
        let precipitationProbabilityMax: [Int]

        enum CodingKeys: String, CodingKey {
            case time
            case temperature2mMax = "temperature_2m_max"
            case temperature2mMin = "temperature_2m_min"
            case weathercode
            case precipitationProbabilityMax = "precipitation_probability_max"
        }
    }

    let current: Current
    let daily: Daily
}

// MARK: - WeatherService

@Observable
final class WeatherService {
    static let shared = WeatherService()
    private init() {}

    var current: CurrentWeather? = nil
    var forecast: [DayForecast] = []
    var isLoading = false
    var lastUpdated: Date? = nil
    var error: String? = nil

    // Refresh at most every 15 minutes
    func fetch(latitude: Double, longitude: Double) async {
        if let last = lastUpdated, Date().timeIntervalSince(last) < 900 {
            return // cached
        }
        isLoading = true
        defer { isLoading = false }
        error = nil

        let urlString = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=\(latitude)&longitude=\(longitude)"
            + "&current=temperature_2m,weathercode,windspeed_10m,uv_index"
            + "&daily=temperature_2m_max,temperature_2m_min,weathercode,precipitation_probability_max"
            + "&temperature_unit=fahrenheit&windspeed_unit=mph&timezone=auto&forecast_days=7"

        guard let url = URL(string: urlString) else { return }

        guard let (data, _) = try? await URLSession.shared.data(from: url) else {
            error = "Could not reach weather service"
            return
        }

        let decoder = JSONDecoder()
        guard let response = try? decoder.decode(OpenMeteoResponse.self, from: data) else {
            error = "Could not parse weather data"
            return
        }

        let c = response.current
        current = CurrentWeather(
            temperatureF: c.temperature2m,
            windSpeedMph: c.windspeed10m,
            weatherCode: c.weathercode,
            uvIndex: c.uvIndex ?? 0
        )

        let dateParser = DateFormatter()
        dateParser.dateFormat = "yyyy-MM-dd"
        dateParser.timeZone = TimeZone(identifier: "UTC")

        let d = response.daily
        forecast = zip(d.time.indices, d.time).compactMap { i, dateStr -> DayForecast? in
            guard i < d.temperature2mMax.count,
                  i < d.temperature2mMin.count,
                  i < d.weathercode.count,
                  i < d.precipitationProbabilityMax.count,
                  let date = dateParser.date(from: dateStr) else { return nil }
            return DayForecast(
                dateString: dateStr,
                date: date,
                maxTempF: d.temperature2mMax[i],
                minTempF: d.temperature2mMin[i],
                weatherCode: d.weathercode[i],
                precipProbability: d.precipitationProbabilityMax[i]
            )
        }

        lastUpdated = Date()
    }

    // Convenience: weekend days from forecast
    var weekendForecast: [DayForecast] {
        forecast.filter { $0.isWeekend }.prefix(2).map { $0 }
    }

    // Best play window message
    var bestPlayWindowToday: String {
        guard let c = current else { return "Check back soon" }
        if c.isRainy { return "Rain expected today" }
        if c.isWindy { return "Windy today — indoor preferred" }
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 10 { return "Morning window looks great" }
        if hour < 17 { return "This afternoon looks good" }
        return "Evening session perfect"
    }
}
