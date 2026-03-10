import Foundation

@Observable
final class ExchangeRateService {
    var hnlRate: Double = AppConstants.usdToHnlRate
    var cadRate: Double = AppConstants.usdToCadRate
    var eurRate: Double = AppConstants.usdToEurRate
    var isLive = false
    var lastUpdated: Date?

    /// Convenience alias so existing code still compiles
    var currentRate: Double { hnlRate }

    private static let cacheKey = "cachedExchangeRate"
    private static let cacheTimeKey = "cachedExchangeRateTime"
    private static let cacheCadKey = "cachedCadRate"
    private static let cacheEurKey = "cachedEurRate"

    init() {
        loadCachedRate()
    }

    /// Fetches the latest USD-based rates from a free API.
    /// Falls back to the bundled defaults if the request fails.
    func fetchLatestRate() async {
        guard let url = URL(string: "https://open.er-api.com/v6/latest/USD") else { return }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return }

            let decoded = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)

            let fetchedHnl = decoded.rates["HNL"]
            let fetchedCad = decoded.rates["CAD"]
            let fetchedEur = decoded.rates["EUR"]

            if let hnl = fetchedHnl, hnl > 0 {
                await MainActor.run {
                    self.hnlRate = hnl
                    if let cad = fetchedCad, cad > 0 { self.cadRate = cad }
                    if let eur = fetchedEur, eur > 0 { self.eurRate = eur }
                    self.isLive = true
                    self.lastUpdated = Date()
                    self.cacheRates()
                }
            }
        } catch {
            // Silently fail — use cached or default rates
        }
    }

    /// Returns how many USD one unit of the given currency buys.
    func toUsd(from currency: HomeCurrency) -> Double {
        switch currency {
        case .cad: return 1.0 / cadRate
        case .eur: return 1.0 / eurRate
        }
    }

    var rateSourceLabel: String {
        if isLive, let updated = lastUpdated {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            return "Live rate · updated \(formatter.localizedString(for: updated, relativeTo: Date()))"
        }
        return "Offline rate · may vary"
    }

    // MARK: - Cache

    private func cacheRates() {
        let defaults = UserDefaults.standard
        defaults.set(hnlRate, forKey: Self.cacheKey)
        defaults.set(cadRate, forKey: Self.cacheCadKey)
        defaults.set(eurRate, forKey: Self.cacheEurKey)
        defaults.set(Date().timeIntervalSince1970, forKey: Self.cacheTimeKey)
    }

    private func loadCachedRate() {
        let defaults = UserDefaults.standard
        let cached = defaults.double(forKey: Self.cacheKey)
        let cacheTime = defaults.double(forKey: Self.cacheTimeKey)

        if cached > 0, cacheTime > 0 {
            let age = Date().timeIntervalSince1970 - cacheTime
            if age < 86400 {
                hnlRate = cached
                let cachedCad = defaults.double(forKey: Self.cacheCadKey)
                let cachedEur = defaults.double(forKey: Self.cacheEurKey)
                if cachedCad > 0 { cadRate = cachedCad }
                if cachedEur > 0 { eurRate = cachedEur }
                isLive = true
                lastUpdated = Date(timeIntervalSince1970: cacheTime)
            }
        }
    }
}

// MARK: - Home Currency

enum HomeCurrency: String, CaseIterable, Identifiable {
    case cad = "CAD"
    case eur = "EUR"

    var id: String { rawValue }

    var flag: String {
        switch self {
        case .cad: return "🇨🇦"
        case .eur: return "🇪🇺"
        }
    }

    var label: String {
        switch self {
        case .cad: return "Canadian Dollar"
        case .eur: return "Euro"
        }
    }
}

// MARK: - API Response

private struct ExchangeRateResponse: Decodable {
    let result: String
    let rates: [String: Double]
}
