import Foundation
import SwiftData
import SwiftUI

/// In-memory cached favorites store backed by SwiftData, optionally synced
/// across devices via CloudKit (configured on the `ModelContainer` upstream).
///
/// Why a cache: `BusinessCard` (and grid/compact variants) all call
/// `isFavorite(_:)` on every render. The original implementation issued a
/// `FetchDescriptor` per call — O(N) SwiftData queries for an N-card list per
/// re-render. With ~200 businesses and multi-section home, this caused jank
/// during favorite toggles. The cache reduces it to O(1) lookup.
///
/// CloudKit duplicate handling: V2 of the schema drops the `.unique`
/// constraint on `businessId` because CloudKit doesn't enforce uniqueness
/// across devices. If the same business gets favorited on two devices
/// before they sync, the merge produces duplicates. `reload()` collapses
/// them — keeping the oldest `dateAdded` and deleting the rest.
@Observable
final class FavoritesStore {
    private var modelContext: ModelContext
    private var favoriteIdSet: Set<String> = []
    private var orderedIds: [String] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        reload()
        // Re-pull when CloudKit pushes remote changes into the local store.
        // SwiftData posts `.NSPersistentStoreRemoteChange` on the persistent
        // coordinator; we observe it and re-derive the cache.
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reload()
        }
    }

    /// Re-reads from SwiftData and collapses any duplicate-businessId rows
    /// that CloudKit sync produced. Idempotent — safe to call repeatedly.
    func reload() {
        let descriptor = FetchDescriptor<Favorite>(
            sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
        )
        let favorites = (try? modelContext.fetch(descriptor)) ?? []

        // Collapse duplicates: when two devices favorite the same business
        // before syncing, CloudKit merges both rows. Keep the earliest
        // dateAdded (that's when the user first hearted it), delete the
        // rest. The .reverse sort above means later rows in the array are
        // older — we walk the array, claim the first sighting of each ID,
        // and delete subsequent ones.
        var seen = Set<String>()
        var orderedKept: [String] = []
        var duplicatesDeleted = 0
        for fav in favorites {
            let id = fav.businessId
            if id.isEmpty { continue }
            if seen.contains(id) {
                modelContext.delete(fav)
                duplicatesDeleted += 1
            } else {
                seen.insert(id)
                orderedKept.append(id)
            }
        }
        if duplicatesDeleted > 0 {
            try? modelContext.save()
            AppLog.persistence.info("Collapsed \(duplicatesDeleted, privacy: .public) duplicate favorites from sync.")
        }

        orderedIds = orderedKept
        favoriteIdSet = seen
    }

    func isFavorite(_ businessId: String) -> Bool {
        favoriteIdSet.contains(businessId)
    }

    func toggleFavorite(_ businessId: String) {
        if favoriteIdSet.contains(businessId) {
            removeFavorite(businessId)
        } else {
            addFavorite(businessId)
        }
    }

    func addFavorite(_ businessId: String) {
        guard !favoriteIdSet.contains(businessId) else { return }
        let favorite = Favorite(businessId: businessId)
        modelContext.insert(favorite)
        try? modelContext.save()
        favoriteIdSet.insert(businessId)
        orderedIds.insert(businessId, at: 0)
    }

    func removeFavorite(_ businessId: String) {
        let descriptor = FetchDescriptor<Favorite>(
            predicate: #Predicate { $0.businessId == businessId }
        )
        if let favorites = try? modelContext.fetch(descriptor) {
            for fav in favorites {
                modelContext.delete(fav)
            }
            try? modelContext.save()
        }
        favoriteIdSet.remove(businessId)
        orderedIds.removeAll { $0 == businessId }
    }

    func allFavoriteIds() -> [String] {
        orderedIds
    }
}
