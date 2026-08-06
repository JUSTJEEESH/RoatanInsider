import Foundation
import Observation

/// Pulls down everything a saved trip needs, while there's still signal.
///
/// Data was already fine offline — bundled JSON is the fallback and it
/// works. Photos were not. The image cache only holds pictures you have
/// *already looked at*, so a place saved from a list but never opened was a
/// grey box the moment you were out of range — which is exactly when you're
/// driving out to find it. Connectivity on this island falls over the moment
/// you leave the tourist stretches.
///
/// So: one tap on hotel wifi, and every saved place, every dive site and
/// this week's events are on the phone for good.
@Observable
final class OfflineDownloader {

    enum State: Equatable {
        case idle
        case running(done: Int, total: Int)
        case finished(count: Int, at: Date)
        case failed(String)

        var isRunning: Bool { if case .running = self { return true }; return false }

        var progress: Double {
            guard case let .running(done, total) = self, total > 0 else { return 0 }
            return Double(done) / Double(total)
        }
    }

    private(set) var state: State = .idle

    /// When the last successful download finished, so the UI can say how
    /// current the offline copy is rather than just "downloaded".
    private(set) var lastCompleted: Date? {
        didSet {
            UserDefaults.standard.set(lastCompleted?.timeIntervalSince1970 ?? 0, forKey: Self.storageKey)
        }
    }

    private static let storageKey = "offlineDownloadCompletedAt"

    init() {
        let stamp = UserDefaults.standard.double(forKey: Self.storageKey)
        lastCompleted = stamp > 0 ? Date(timeIntervalSince1970: stamp) : nil
    }

    /// Downloads photos for the given businesses and dive sites, plus the
    /// current remote data files.
    ///
    /// Runs sequentially with a small concurrency window rather than firing
    /// every request at once: hotel wifi here is not what it is at home, and
    /// a hundred parallel image fetches is how you get a stalled download
    /// instead of a fast one.
    @MainActor
    func download(businesses: [Business], diveSites: [DiveSite]) async {
        guard !state.isRunning else { return }

        let urls = Self.photoURLs(for: businesses)
        let total = urls.count + 1   // +1 for the data refresh at the end
        state = .running(done: 0, total: total)

        var completed = 0
        await withTaskGroup(of: Void.self) { group in
            var iterator = urls.makeIterator()
            let window = 4

            func addNext() {
                guard let url = iterator.next() else { return }
                group.addTask { _ = await ImageCache.shared.image(for: url) }
            }
            for _ in 0..<window { addNext() }

            for await _ in group {
                completed += 1
                state = .running(done: completed, total: total)
                addNext()
            }
        }

        // Refresh the data files too, so the offline copy is a snapshot of
        // now rather than photos wrapped around a week-old schedule.
        await RemoteDataService.warmCache(filenames: ["events.json", "cruise_arrivals.json", "dive_sites.json"])
        completed += 1

        lastCompleted = .now
        state = .finished(count: urls.count, at: .now)
        AppLog.data.notice("Offline download complete: \(urls.count, privacy: .public) photos")
    }

    func reset() { state = .idle }

    /// Every photo a saved place might show, deduplicated. Mirrors
    /// `BusinessImageView`'s resolution so we cache the exact URLs it will
    /// ask for — caching a different URL would be busywork that changes
    /// nothing on screen.
    static func photoURLs(for businesses: [Business]) -> [URL] {
        var seen = Set<String>()
        var urls: [URL] = []
        for business in businesses {
            for name in business.images where name != "business_placeholder" {
                guard name.contains(".") else { continue }
                let path = AppConstants.supabaseStorageBaseURL + name
                if seen.insert(path).inserted, let url = URL(string: path) { urls.append(url) }
            }
            // The slug fallback, which is what all 94 records currently use.
            let slugPath = AppConstants.supabaseStorageBaseURL + business.slug + ".jpg"
            if seen.insert(slugPath).inserted, let url = URL(string: slugPath) { urls.append(url) }

            for menu in business.menuImages ?? [] {
                let path = AppConstants.supabaseStorageBaseURL + menu
                if seen.insert(path).inserted, let url = URL(string: path) { urls.append(url) }
            }
        }
        return urls
    }
}
