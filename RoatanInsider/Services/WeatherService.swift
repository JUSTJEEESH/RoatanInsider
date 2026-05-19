import Foundation
import Observation

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
        var windKph: Double
        var uvIndex: Double
        var waveHeightMeters: Double?
        var fetchedAt: Date
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
            windKph: f.windKph,
            uvIndex: f.uvIndex,
            waveHeightMeters: m?.waveHeightMeters,
            fetchedAt: .now
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
        guard let c = conditions else { return "—" }
        let n = Int(c.uvIndex.rounded())
        let band: String
        switch n {
        case 0..<3:   band = "Low"
        case 3..<6:   band = "Moderate"
        case 6..<8:   band = "High"
        case 8..<11:  band = "Very High"
        default:      band = "Extreme"
        }
        return "UV \(n) · \(band)"
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
        // Wind above 25 km/h kicks up chop.
        if c.windKph > 25 {
            score -= min(30, (c.windKph - 25) * 1.5)
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
        let current: Current
    }

    private struct MarineResponse: Decodable {
        struct Current: Decodable {
            let wave_height: Double
        }
        let current: Current
    }

    private struct ForecastTuple {
        let temperatureF: Double
        let weatherCode: Int
        let windKph: Double
        let uvIndex: Double
    }

    private func fetchForecast() async -> ForecastTuple? {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: "16.33"),
            URLQueryItem(name: "longitude", value: "-86.52"),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code,wind_speed_10m,uv_index"),
            URLQueryItem(name: "temperature_unit", value: "fahrenheit"),
            URLQueryItem(name: "wind_speed_unit", value: "kmh"),
            URLQueryItem(name: "timezone", value: "auto"),
        ]
        guard let url = components.url else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(ForecastResponse.self, from: data)
            return ForecastTuple(
                temperatureF: decoded.current.temperature_2m,
                weatherCode: decoded.current.weather_code,
                windKph: decoded.current.wind_speed_10m,
                uvIndex: decoded.current.uv_index ?? 0
            )
        } catch {
            AppLog.network.warning("Weather forecast fetch failed: \(error.localizedDescription)")
            return nil
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

    private static func weatherDescription(code: Int) -> String {
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

    private static func weatherSymbol(code: Int) -> String {
        switch code {
        case 0:        return "sun.max.fill"
        case 1, 2:     return "cloud.sun.fill"
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
