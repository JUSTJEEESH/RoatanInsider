import Foundation
import Observation
import SwiftUI

/// Live weather + marine conditions for Roatán, fed by Open-Meteo
/// (https://open-meteo.com). No API key, no rate limits at our volume, and
/// a clean JSON shape.
///
/// We expose a single `Conditions` snapshot plus a derived `reefScore` /
/// `snorkelLabel` so the Home strip can render decisively ("Snorkel: Good")
/// rather than dumping raw numbers on the user.
///
/// Persistence: latest snapshot is cached in `Application Support/weather.json`
/// and reused on launch so the strip always has *something* to display, even
/// offline. A background fetch refreshes when the app foregrounds.
@Observable
final class WeatherService {
    struct Conditions: Codable, Equatable {
        var temperatureF: Double
        var weatherCode: Int
        var windMph: Double
        var uvIndex: Double
        var waveHeightMeters: Double?
        var fetchedAt: Date
        /// The next day or so, hour by hour. Empty on a cache written by an
        /// older build, which is why every reader guards for it.
        var hourly: [HourPoint] = []
        /// Today onward. Empty for the same reason.
        var daily: [DayPoint] = []
    }

    /// One hour of forecast. The rain chance is the reason this exists: on
    /// Roatán the question that actually changes plans is whether the
    /// afternoon squall lands before the boat goes out, and no single
    /// "current conditions" number can answer it.
    struct HourPoint: Codable, Equatable, Identifiable {
        var time: Date
        var temperatureF: Double
        var precipitationChance: Int
        var weatherCode: Int
        var feelsLikeF: Double = 0
        var precipitationInches: Double = 0
        var windMph: Double = 0
        var gustMph: Double = 0
        var windDegrees: Double = 0
        var uvIndex: Double = 0
        var visibilityMiles: Double = 0

        var id: Date { time }
        var symbol: String { WeatherService.weatherSymbol(code: weatherCode, at: time) }
    }

    struct DayPoint: Codable, Equatable, Identifiable {
        var date: Date
        var highF: Double
        var lowF: Double
        var precipitationChance: Int
        var weatherCode: Int
        var uvIndexMax: Double
        var precipitationInches: Double = 0
        var windMaxMph: Double = 0
        var gustMaxMph: Double = 0
        var sunrise: Date?
        var sunset: Date?

        var id: Date { date }
        var symbol: String { WeatherService.weatherSymbol(code: weatherCode) }
        var summary: String { WeatherService.weatherDescription(code: weatherCode) }
    }

    private(set) var conditions: Conditions?
    private(set) var isRefreshing: Bool = false

    private static let cacheURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("weather.json")
    }()

    /// Re-fetch only if cached data is older than this. Open-Meteo updates
    /// hourly so anything tighter is wasteful.
    private static let refreshInterval: TimeInterval = 30 * 60

    init() {
        loadCached()
    }

    /// Fetch live conditions if the cache is stale. Safe to call frequently.
    @MainActor
    func refreshIfNeeded() async {
        if let last = conditions?.fetchedAt, Date().timeIntervalSince(last) < Self.refreshInterval {
            return
        }
        await refresh()
    }

    @MainActor
    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        async let forecast = fetchForecast()
        async let marine = fetchMarine()
        let (f, m) = await (forecast, marine)
        guard let f else { return }

        let snapshot = Conditions(
            temperatureF: f.temperatureF,
            weatherCode: f.weatherCode,
            windMph: f.windMph,
            uvIndex: f.uvIndex,
            waveHeightMeters: m?.waveHeightMeters,
            fetchedAt: .now,
            hourly: f.hourly,
            daily: f.daily
        )
        conditions = snapshot
        persist(snapshot)
    }

    // MARK: - Derived display values

    var temperatureLabel: String {
        guard let c = conditions else { return "—" }
        return "\(Int(c.temperatureF.rounded()))°"
    }

    var weatherLabel: String {
        guard let c = conditions else { return "—" }
        return Self.weatherDescription(code: c.weatherCode)
    }

    var weatherSymbol: String {
        guard let c = conditions else { return "questionmark.circle" }
        return Self.weatherSymbol(code: c.weatherCode)
    }

    var uvLabel: String {
        "UV \(uvIndexValue) · \(uvBandLabel)"
    }

    var uvIndexValue: Int {
        guard let c = conditions else { return 0 }
        return Int(c.uvIndex.rounded())
    }

    var uvBandLabel: String {
        guard conditions != nil else { return "—" }
        switch uvIndexValue {
        case 0..<3:   return "Low"
        case 3..<6:   return "Moderate"
        case 6..<8:   return "High"
        case 8..<11:  return "Very High"
        default:      return "Extreme"
        }
    }

    var uvBandColor: Color {
        switch uvIndexValue {
        case 0..<3:   return .green
        case 3..<6:   return .yellow
        case 6..<8:   return .orange
        case 8..<11:  return .red
        default:      return .purple
        }
    }

    /// Composite reef/snorkel quality 0-100 from wave height + wind.
    /// Calmer is better — derived from local diveshop heuristics, not science.
    var reefScore: Int {
        guard let c = conditions else { return 50 }
        var score = 100.0
        if let waves = c.waveHeightMeters {
            // 0.0m = great. 0.5m = ok. >1.0m = poor.
            score -= min(60, waves * 80)
        }
        // Wind past about 15 mph kicks up chop. (Was expressed in km/h
        // before the API moved to mph — 25 km/h is 15.5 mph, and the slope
        // is rescaled to match, so the score is unchanged.)
        if c.windMph > 15.5 {
            score -= min(30, (c.windMph - 15.5) * 2.4)
        }
        return max(0, min(100, Int(score.rounded())))
    }

    var snorkelLabel: String {
        switch reefScore {
        case 80...100: return "Excellent"
        case 60..<80:  return "Good"
        case 40..<60:  return "Fair"
        case 20..<40:  return "Choppy"
        default:       return "Rough"
        }
    }

    // MARK: - Caching

    private func loadCached() {
        guard let data = try? Data(contentsOf: Self.cacheURL),
              let cached = try? JSONDecoder().decode(Conditions.self, from: data) else { return }
        self.conditions = cached
    }

    private func persist(_ snapshot: Conditions) {
        if let data = try? JSONEncoder().encode(snapshot) {
            try? data.write(to: Self.cacheURL, options: .atomic)
        }
    }

    // MARK: - Network

    private struct ForecastResponse: Decodable {
        struct Current: Decodable {
            let temperature_2m: Double
            let weather_code: Int
            let wind_speed_10m: Double
            let uv_index: Double?
        }
        struct Hourly: Decodable {
            let time: [String]
            let temperature_2m: [Double]
            let precipitation_probability: [Int?]
            let weather_code: [Int]
            let apparent_temperature: [Double]?
            let precipitation: [Double]?
            let wind_speed_10m: [Double]?
            let wind_gusts_10m: [Double]?
            let wind_direction_10m: [Double]?
            let uv_index: [Double]?
            let visibility: [Double]?
        }
        struct Daily: Decodable {
            let time: [String]
            let weather_code: [Int]
            let temperature_2m_max: [Double]
            let temperature_2m_min: [Double]
            let precipitation_probability_max: [Int?]
            let uv_index_max: [Double?]
            let precipitation_sum: [Double]?
            let wind_speed_10m_max: [Double]?
            let wind_gusts_10m_max: [Double]?
            let sunrise: [String]?
            let sunset: [String]?
        }
        let current: Current
        let hourly: Hourly?
        let daily: Daily?
    }

    /// Open-Meteo returns local wall-clock stamps with no offset when asked
    /// for `timezone=auto`, so they're parsed against island time rather than
    /// the device's — otherwise a visitor still on New York time would see
    /// the strip shifted an hour.
    private static let apiDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd'T'HH:mm"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "America/Tegucigalpa")
        return f
    }()

    private static let apiDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "America/Tegucigalpa")
        return f
    }()

    private struct MarineResponse: Decodable {
        struct Current: Decodable {
            let wave_height: Double
        }
        let current: Current
    }

    private struct ForecastTuple {
        let temperatureF: Double
        let weatherCode: Int
        let windMph: Double
        let uvIndex: Double
        let hourly: [HourPoint]
        let daily: [DayPoint]
    }

    private func fetchForecast() async -> ForecastTuple? {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: "16.33"),
            URLQueryItem(name: "longitude", value: "-86.52"),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code,wind_speed_10m,uv_index"),
            URLQueryItem(name: "hourly", value: "temperature_2m,apparent_temperature,precipitation_probability,precipitation,weather_code,wind_speed_10m,wind_gusts_10m,wind_direction_10m,uv_index,visibility"),
            URLQueryItem(name: "daily", value: "weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,precipitation_sum,uv_index_max,wind_speed_10m_max,wind_gusts_10m_max,sunrise,sunset"),
            URLQueryItem(name: "forecast_days", value: "10"),
            URLQueryItem(name: "temperature_unit", value: "fahrenheit"),
            URLQueryItem(name: "wind_speed_unit", value: "mph"),
            URLQueryItem(name: "precipitation_unit", value: "inch"),
            URLQueryItem(name: "timezone", value: "auto"),
        ]
        guard let url = components.url else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(ForecastResponse.self, from: data)
            return ForecastTuple(
                temperatureF: decoded.current.temperature_2m,
                weatherCode: decoded.current.weather_code,
                windMph: decoded.current.wind_speed_10m,
                uvIndex: decoded.current.uv_index ?? 0,
                hourly: Self.hourPoints(from: decoded.hourly),
                daily: Self.dayPoints(from: decoded.daily)
            )
        } catch {
            AppLog.network.warning("Weather forecast fetch failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// Zips the parallel arrays Open-Meteo returns into points, dropping any
    /// row whose arrays don't line up rather than trusting an index.
    private static func hourPoints(from hourly: ForecastResponse.Hourly?) -> [HourPoint] {
        guard let hourly else { return [] }
        let count = min(hourly.time.count, hourly.temperature_2m.count, hourly.weather_code.count)
        return (0..<count).compactMap { i in
            guard let time = apiDateFormatter.date(from: hourly.time[i]) else { return nil }
            let chance = i < hourly.precipitation_probability.count
                ? (hourly.precipitation_probability[i] ?? 0) : 0
            func at(_ array: [Double]?) -> Double {
                guard let array, i < array.count else { return 0 }
                return array[i]
            }
            return HourPoint(
                time: time,
                temperatureF: hourly.temperature_2m[i],
                precipitationChance: chance,
                weatherCode: hourly.weather_code[i],
                feelsLikeF: at(hourly.apparent_temperature),
                precipitationInches: at(hourly.precipitation),
                windMph: at(hourly.wind_speed_10m),
                gustMph: at(hourly.wind_gusts_10m),
                windDegrees: at(hourly.wind_direction_10m),
                uvIndex: at(hourly.uv_index),
                // Open-Meteo reports visibility in metres regardless of the
                // unit parameters, which only cover temperature, wind and
                // precipitation.
                visibilityMiles: at(hourly.visibility) / 1609.34
            )
        }
    }

    private static func dayPoints(from daily: ForecastResponse.Daily?) -> [DayPoint] {
        guard let daily else { return [] }
        let count = min(
            daily.time.count, daily.weather_code.count,
            daily.temperature_2m_max.count, daily.temperature_2m_min.count
        )
        return (0..<count).compactMap { i in
            guard let date = apiDayFormatter.date(from: daily.time[i]) else { return nil }
            func at(_ array: [Double]?) -> Double {
                guard let array, i < array.count else { return 0 }
                return array[i]
            }
            func stamp(_ array: [String]?) -> Date? {
                guard let array, i < array.count else { return nil }
                return apiDateFormatter.date(from: array[i])
            }
            return DayPoint(
                date: date,
                highF: daily.temperature_2m_max[i],
                lowF: daily.temperature_2m_min[i],
                precipitationChance: i < daily.precipitation_probability_max.count
                    ? (daily.precipitation_probability_max[i] ?? 0) : 0,
                weatherCode: daily.weather_code[i],
                uvIndexMax: i < daily.uv_index_max.count ? (daily.uv_index_max[i] ?? 0) : 0,
                precipitationInches: at(daily.precipitation_sum),
                windMaxMph: at(daily.wind_speed_10m_max),
                gustMaxMph: at(daily.wind_gusts_10m_max),
                sunrise: stamp(daily.sunrise),
                sunset: stamp(daily.sunset)
            )
        }
    }

    private struct MarineTuple {
        let waveHeightMeters: Double
    }

    private func fetchMarine() async -> MarineTuple? {
        var components = URLComponents(string: "https://marine-api.open-meteo.com/v1/marine")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: "16.33"),
            URLQueryItem(name: "longitude", value: "-86.52"),
            URLQueryItem(name: "current", value: "wave_height"),
            URLQueryItem(name: "timezone", value: "auto"),
        ]
        guard let url = components.url else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(MarineResponse.self, from: data)
            return MarineTuple(waveHeightMeters: decoded.current.wave_height)
        } catch {
            // Marine API can fail for some grids without the forecast also
            // failing; gracefully degrade.
            AppLog.network.debug("Marine fetch failed: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - WMO weather codes

    static func weatherDescription(code: Int) -> String {
        switch code {
        case 0:        return "Clear"
        case 1, 2:     return "Mostly sunny"
        case 3:        return "Cloudy"
        case 45, 48:   return "Foggy"
        case 51...57:  return "Drizzle"
        case 61, 63:   return "Rain"
        case 65:       return "Heavy rain"
        case 71...77:  return "Snow"
        case 80, 81:   return "Showers"
        case 82:       return "Heavy showers"
        case 95:       return "Storms"
        case 96, 99:   return "Severe storms"
        default:       return "—"
        }
    }

    /// `at` lets a night-time hour use the moon variants, which is the
    /// detail that separates a weather view that looks made from one that
    /// looks generated.
    static func weatherSymbol(code: Int, at date: Date? = nil) -> String {
        let isNight: Bool = {
            guard let date else { return false }
            let hour = Calendar.current.component(.hour, from: date)
            return hour < 6 || hour >= 18
        }()
        switch code {
        case 0:        return isNight ? "moon.stars.fill" : "sun.max.fill"
        case 1, 2:     return isNight ? "cloud.moon.fill" : "cloud.sun.fill"
        case 3:        return "cloud.fill"
        case 45, 48:   return "cloud.fog.fill"
        case 51...57:  return "cloud.drizzle.fill"
        case 61, 63:   return "cloud.rain.fill"
        case 65:       return "cloud.heavyrain.fill"
        case 71...77:  return "cloud.snow.fill"
        case 80, 81:   return "cloud.rain.fill"
        case 82:       return "cloud.heavyrain.fill"
        case 95:       return "cloud.bolt.rain.fill"
        case 96, 99:   return "cloud.bolt.rain.fill"
        default:       return "questionmark.circle"
        }
    }
}
