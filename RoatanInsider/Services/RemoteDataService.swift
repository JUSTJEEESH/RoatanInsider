import Foundation

/// Generic remote data service that handles fetching, caching, and fallback
/// for any JSON data file hosted in Supabase Storage.
///
/// Each data file has its own version tracked in the manifest.
/// Files are cached independently in Application Support.
final class RemoteDataService {

    private static var cacheDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("app-data", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    // MARK: - Load (synchronous, for app startup)

    /// Load data from cache, falling back to bundle.
    static func loadCachedOrBundled<T: Decodable>(
        filename: String,
        bundleName: String? = nil,
        type: T.Type
    ) -> T? {
        let cachedURL = cacheDirectory.appendingPathComponent(filename)

        // Try cache first
        if FileManager.default.fileExists(atPath: cachedURL.path) {
            do {
                let data = try Data(contentsOf: cachedURL)
                let result = try JSONDecoder().decode(T.self, from: data)
                print("✅ Loaded \(filename) from cache")
                return result
            } catch {
                print("⚠️ Failed to read cached \(filename): \(error.localizedDescription)")
                try? FileManager.default.removeItem(at: cachedURL)
            }
        }

        // Fall back to bundle
        let resource = bundleName ?? filename.replacingOccurrences(of: ".json", with: "")
        if let bundleURL = Bundle.main.url(forResource: resource, withExtension: "json") {
            do {
                let data = try Data(contentsOf: bundleURL)
                let result = try JSONDecoder().decode(T.self, from: data)
                print("✅ Loaded \(filename) from bundle")
                return result
            } catch {
                print("⚠️ Failed to decode bundled \(filename): \(error)")
            }
        }

        return nil
    }

    // MARK: - Remote check (async, background)

    /// URLSession configured to bypass HTTP caching so we always get the latest
    /// files from Supabase Storage.
    private static let noCacheSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        return URLSession(configuration: config)
    }()

    /// Fetches manifest, checks versions, downloads updated files.
    /// Returns a dictionary of filename → Data for files that were updated.
    static func fetchUpdates() async -> RemoteManifest? {
        // Throttle
        let lastFetch = UserDefaults.standard.double(forKey: "remoteDataLastFetch")
        if lastFetch > 0 {
            let elapsed = Date().timeIntervalSince1970 - lastFetch
            if elapsed < AppConstants.dataRefreshMinInterval {
                return nil
            }
        }

        guard let url = URL(string: AppConstants.remoteManifestURL) else { return nil }

        do {
            let (data, response) = try await noCacheSession.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            let manifest = try JSONDecoder().decode(RemoteManifest.self, from: data)
            UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "remoteDataLastFetch")
            return manifest
        } catch {
            print("⚠️ Manifest fetch failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// Downloads a file from Supabase if its remote version is newer than cached.
    /// Returns decoded data if updated, nil if no update needed.
    static func fetchIfNewer<T: Codable>(
        filename: String,
        remoteVersion: Int,
        type: T.Type
    ) async -> T? {
        let versionKey = "remoteVersion_\(filename)"
        let cachedVersion = UserDefaults.standard.integer(forKey: versionKey)

        guard remoteVersion > cachedVersion else { return nil }

        guard let url = URL(string: AppConstants.supabaseDataBaseURL + filename) else { return nil }

        do {
            let (data, response) = try await noCacheSession.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
            let decoded = try JSONDecoder().decode(T.self, from: data)

            // Cache the file
            let cachedURL = cacheDirectory.appendingPathComponent(filename)
            try data.write(to: cachedURL, options: .atomic)
            UserDefaults.standard.set(remoteVersion, forKey: versionKey)

            print("✅ Updated \(filename) to v\(remoteVersion)")
            return decoded
        } catch {
            print("⚠️ Failed to fetch \(filename): \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - Manifest

struct RemoteManifest: Decodable {
    let businesses: FileVersion?
    let categories: FileVersion?
    let areas: FileVersion?
    let essentials: FileVersion?
    let cruiseMahoganyBay: FileVersion?
    let cruiseCoxenHole: FileVersion?
    let askALocal: FileVersion?
    let updatedAt: String?

    // Backwards compatibility: support old flat manifest format
    let version: Int?

    struct FileVersion: Decodable {
        let version: Int
        let file: String
    }

    /// Helper to get business version — supports both old and new manifest formats
    var businessVersion: Int {
        businesses?.version ?? version ?? 0
    }
}
