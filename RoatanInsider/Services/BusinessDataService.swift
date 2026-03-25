import Foundation

/// Handles fetching business data from Supabase Storage, caching locally,
/// and falling back to the bundled JSON when offline.
///
/// Flow:
/// 1. On init, loads cached data (or bundled fallback) synchronously
/// 2. `checkForUpdates()` fetches a remote manifest to see if newer data exists
/// 3. If newer, downloads the full JSON, validates it, caches it, and returns it
/// 4. Failures are silent — the app always has data
final class BusinessDataService {

    // MARK: - Cache keys

    private static let versionKey = "remoteBusinessDataVersion"
    private static let lastFetchKey = "remoteBusinessDataLastFetch"

    private static var cacheDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("business-data", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private static var cachedFileURL: URL {
        cacheDirectory.appendingPathComponent("businesses.json")
    }

    // MARK: - Load (synchronous, for app startup)

    /// Returns businesses from cache if available, otherwise from the app bundle.
    static func loadCachedOrBundled() -> [Business] {
        // Try cached file first
        if let cached = loadFromFile(cachedFileURL) {
            print("✅ Loaded \(cached.count) businesses from cache")
            return cached
        }

        // Fall back to bundle
        if let bundled = loadFromBundle() {
            print("✅ Loaded \(bundled.count) businesses from bundle")
            return bundled
        }

        print("⚠️ BusinessDataService: No business data available")
        return []
    }

    // MARK: - Remote check (async, background)

    /// Checks the remote manifest and downloads updated data if available.
    /// Returns the new business array if updated, nil if no update needed.
    static func fetchRemoteIfNeeded() async -> [Business]? {
        // Throttle: skip if last fetch was recent
        let lastFetch = UserDefaults.standard.double(forKey: lastFetchKey)
        if lastFetch > 0 {
            let elapsed = Date().timeIntervalSince1970 - lastFetch
            if elapsed < AppConstants.dataRefreshMinInterval {
                print("⏭️ Skipping remote check — last fetch \(Int(elapsed))s ago")
                return nil
            }
        }

        // Fetch manifest
        guard let manifest = await fetchManifest() else {
            return nil
        }

        // Compare versions
        let cachedVersion = UserDefaults.standard.integer(forKey: versionKey)
        guard manifest.version > cachedVersion else {
            print("✅ Business data is up to date (v\(cachedVersion))")
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastFetchKey)
            return nil
        }

        print("🔄 New business data available: v\(manifest.version) (cached: v\(cachedVersion))")

        // Download the full JSON
        guard let businesses = await downloadBusinesses() else {
            return nil
        }

        // Validate we got reasonable data
        guard businesses.count >= 10 else {
            print("⚠️ Remote data looks invalid (\(businesses.count) businesses) — skipping")
            return nil
        }

        // Cache it
        cacheBusinesses(businesses, version: manifest.version)
        print("✅ Updated to v\(manifest.version) with \(businesses.count) businesses")

        return businesses
    }

    // MARK: - Private helpers

    private static func fetchManifest() async -> RemoteManifest? {
        guard let url = URL(string: AppConstants.remoteManifestURL) else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            return try JSONDecoder().decode(RemoteManifest.self, from: data)
        } catch {
            print("⚠️ Manifest fetch failed: \(error.localizedDescription)")
            return nil
        }
    }

    private static func downloadBusinesses() async -> [Business]? {
        guard let url = URL(string: AppConstants.remoteBusinessesURL) else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            let businesses = try JSONDecoder().decode([Business].self, from: data)
            return businesses
        } catch {
            print("⚠️ Business data download failed: \(error.localizedDescription)")
            return nil
        }
    }

    private static func cacheBusinesses(_ businesses: [Business], version: Int) {
        do {
            let data = try JSONEncoder().encode(businesses)
            try data.write(to: cachedFileURL, options: .atomic)
            UserDefaults.standard.set(version, forKey: versionKey)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastFetchKey)
        } catch {
            print("⚠️ Failed to cache business data: \(error.localizedDescription)")
        }
    }

    private static func loadFromFile(_ url: URL) -> [Business]? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([Business].self, from: data)
        } catch {
            print("⚠️ Failed to read cached businesses: \(error.localizedDescription)")
            try? FileManager.default.removeItem(at: url) // Remove corrupt cache
            return nil
        }
    }

    private static func loadFromBundle() -> [Business]? {
        guard let url = Bundle.main.url(forResource: "businesses", withExtension: "json") else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([Business].self, from: data)
        } catch {
            print("⚠️ Failed to decode bundled businesses.json: \(error)")
            return nil
        }
    }
}

// MARK: - Manifest model

private struct RemoteManifest: Decodable {
    let version: Int
    let updatedAt: String?
}
