import Foundation
import Observation

/// Capped, ordered list of recently-opened business IDs. Persisted to
/// UserDefaults as a tiny JSON array — overkill to put this in SwiftData
/// when the entire list is at most 20 strings.
///
/// Drives the "Continue browsing" surface on Home and provides natural
/// fallback content during cold starts before any search/favorite history
/// has been built.
@Observable
final class RecentlyViewedStore {
    private static let key = "ri.recentlyViewed.v1"
    private static let maxItems = 20

    private(set) var ids: [String] = []

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            ids = decoded
        }
    }

    func record(_ id: String) {
        var updated = ids.filter { $0 != id }
        updated.insert(id, at: 0)
        if updated.count > Self.maxItems {
            updated = Array(updated.prefix(Self.maxItems))
        }
        ids = updated
        persist()
    }

    func clear() {
        ids = []
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(ids) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }
}
