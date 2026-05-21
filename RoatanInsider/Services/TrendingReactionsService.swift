import Foundation
import Observation

/// Fetches the top-reacted businesses across all devices for the last 7 days.
/// Used by the Home tab's "Trending" section to surface what's actually
/// resonating with users right now, in addition to our curated picks.
///
/// Backed by the `business_reactions_trending` Postgres view in Supabase
/// (one row per business with reaction counts + last activity timestamp).
/// We cache the result for `refreshInterval` so the section is instant on
/// every Home appearance without spamming the network.
///
/// Empty / no-network state: the service degrades silently to `[]` — the
/// Home section observes the result and just hides itself when empty.
@Observable
final class TrendingReactionsService {

    struct TrendingEntry: Identifiable, Codable, Hashable {
        let business_id: String
        let total_reactions: Int
        let heart_count: Int
        let fire_count: Int
        let thumbs_count: Int
        let device_count: Int

        var id: String { business_id }
    }

    /// Ordered top-to-bottom; rank 0 is the most-reacted business.
    private(set) var trending: [TrendingEntry] = []
    private(set) var isLoading: Bool = false

    private let refreshInterval: TimeInterval = 60 * 60  // 1 hour
    private let cacheKey = "ri.trending.v1"
    private let cacheTimestampKey = "ri.trending.fetchedAt.v1"
    private let limit: Int = 12

    init() {
        loadFromCache()
    }

    /// Idempotent. Hits the network only if the cached payload is older than
    /// `refreshInterval`, or if `force` is true (used by pull-to-refresh).
    func refreshIfStale(force: Bool = false) {
        guard !AppConstants.supabaseAnonKey.isEmpty else { return }
        if !force, let last = cachedTimestamp, Date().timeIntervalSince(last) < refreshInterval {
            return
        }
        Task { await fetch() }
    }

    // MARK: - Networking

    private func fetch() async {
        guard let url = URL(string: "\(AppConstants.supabaseRESTBaseURL)/business_reactions_trending?select=*&limit=\(limit)") else { return }

        await MainActor.run { self.isLoading = true }
        defer { Task { @MainActor in self.isLoading = false } }

        var request = URLRequest(url: url)
        request.setValue(AppConstants.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(AppConstants.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 8

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return }
            let decoded = try JSONDecoder().decode([TrendingEntry].self, from: data)
            await MainActor.run {
                self.trending = decoded
                self.persistToCache(decoded)
            }
        } catch {
            AppLog.network.debug("Trending fetch failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Cache

    private var cachedTimestamp: Date? {
        let raw = UserDefaults.standard.double(forKey: cacheTimestampKey)
        return raw > 0 ? Date(timeIntervalSince1970: raw) : nil
    }

    private func loadFromCache() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let decoded = try? JSONDecoder().decode([TrendingEntry].self, from: data) else { return }
        trending = decoded
    }

    private func persistToCache(_ entries: [TrendingEntry]) {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: cacheTimestampKey)
        }
    }
}
