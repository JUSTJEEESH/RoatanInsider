import Foundation

@Observable
final class ExchangeRateService {
    var currentRate: Double = AppConstants.usdToHnlRate
    var isLive = false
    var lastUpdated: Date?

    private static let cacheKey = "cachedExchangeRate"
    private static let cacheTimeKey = "cachedExchangeRateTime"

    init() {
        loadCachedRate()
    }

    /// Fetches the latest USD→HNL rate from a free API.
    /// Falls back to the bundled default if the request fails.
    func fetchLatestRate() async {
        // Use the free exchangerate.host API (no key required)
        guard let url = URL(string: "https://open.er-api.com/v6/latest/USD") else { return }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else { return }

            let decoded = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)

            if let hnlRate = decoded.rates["HNL"], hnlRate > 0 {
                await MainActor.run {
                    self.currentRate = hnlRate
                    self.isLive = true
                    self.lastUpdated = Date()
                    self.cacheRate(hnlRate)
                }
            }
        } catch {
            // Silently fail — use cached or default rate
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

    private func cacheRate(_ rate: Double) {
        UserDefaults.standard.set(rate, forKey: Self.cacheKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Self.cacheTimeKey)
    }

    private func loadCachedRate() {
        let cached = UserDefaults.standard.double(forKey: Self.cacheKey)
        let cacheTime = UserDefaults.standard.double(forKey: Self.cacheTimeKey)

        // Use cached rate if it's less than 24 hours old and non-zero
        if cached > 0, cacheTime > 0 {
            let age = Date().timeIntervalSince1970 - cacheTime
            if age < 86400 { // 24 hours
                currentRate = cached
                isLive = true
                lastUpdated = Date(timeIntervalSince1970: cacheTime)
            }
        }
    }
}

// MARK: - API Response

private struct ExchangeRateResponse: Decodable {
    let result: String
    let rates: [String: Double]
}
