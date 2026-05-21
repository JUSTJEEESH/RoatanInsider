import Foundation
import Observation

/// Lightweight favorites for events. UserDefaults-backed rather than
/// SwiftData/CloudKit since events are smaller-volume than businesses
/// and don't need the same multi-device sync urgency yet. We can graduate
/// to SwiftData later without changing the API.
@Observable
final class EventFavoritesStore {
    private static let storageKey = "ri.event.favorites.v1"

    private(set) var favoriteIDs: Set<String> = []

    init() {
        load()
    }

    func isFavorited(_ event: Event) -> Bool {
        favoriteIDs.contains(event.id)
    }

    func isFavorited(id: String) -> Bool {
        favoriteIDs.contains(id)
    }

    func toggle(_ event: Event) {
        if favoriteIDs.contains(event.id) {
            favoriteIDs.remove(event.id)
        } else {
            favoriteIDs.insert(event.id)
        }
        persist()
    }

    func remove(id: String) {
        favoriteIDs.remove(id)
        persist()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let ids = try? JSONDecoder().decode(Set<String>.self, from: data) else {
            return
        }
        favoriteIDs = ids
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(favoriteIDs) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }
}
