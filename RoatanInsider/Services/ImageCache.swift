import Foundation
import UIKit
import CryptoKit

/// Two-tier image cache: in-memory (NSCache) + on-disk (Application Support/image-cache).
///
/// Why: AsyncImage relies on URLSession's shared URLCache, which is memory-only and
/// evicts under pressure. For an offline-first travel app, every photo the user has
/// ever scrolled past should be available without a network call.
///
/// The disk cache is intentionally unbounded — Roatán Insider's full photo set is
/// well under 100MB. If that changes, add LRU eviction in `prune(maxBytes:)`.
actor ImageCache {
    static let shared = ImageCache()

    private let memory: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 200
        cache.totalCostLimit = 64 * 1024 * 1024 // ~64MB resident
        return cache
    }()

    private let diskDirectory: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("image-cache", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private var inflight: [URL: Task<UIImage?, Never>] = [:]

    private init() {}

    func image(for url: URL) async -> UIImage? {
        let key = cacheKey(for: url)

        if let cached = memory.object(forKey: key as NSString) {
            return cached
        }

        let diskURL = diskDirectory.appendingPathComponent(key)
        if let data = try? Data(contentsOf: diskURL), let image = UIImage(data: data) {
            memory.setObject(image, forKey: key as NSString, cost: data.count)
            return image
        }

        if let task = inflight[url] {
            return await task.value
        }

        let task = Task<UIImage?, Never> { [diskDirectory] in
            do {
                var request = URLRequest(url: url)
                request.cachePolicy = .returnCacheDataElseLoad
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
                      let image = UIImage(data: data) else {
                    return nil
                }
                let writeURL = diskDirectory.appendingPathComponent(key)
                try? data.write(to: writeURL, options: .atomic)
                return image
            } catch {
                return nil
            }
        }
        inflight[url] = task
        let image = await task.value
        inflight[url] = nil

        if let image, let data = image.jpegData(compressionQuality: 0.9) {
            memory.setObject(image, forKey: key as NSString, cost: data.count)
        }
        return image
    }

    /// Pre-warm a batch of URLs (e.g. featured/hero images during launch).
    func prefetch(_ urls: [URL]) {
        for url in urls {
            Task { _ = await image(for: url) }
        }
    }

    func clearMemory() {
        memory.removeAllObjects()
    }

    func clearDisk() {
        try? FileManager.default.removeItem(at: diskDirectory)
        try? FileManager.default.createDirectory(at: diskDirectory, withIntermediateDirectories: true)
    }

    private func cacheKey(for url: URL) -> String {
        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
