import Foundation
import SwiftData

/// In-memory cached favorites store backed by SwiftData.
///
/// Why a cache: `BusinessCard` (and grid/compact variants) all call
/// `isFavorite(_:)` on every render. The original implementation issued a
/// `FetchDescriptor` per call — O(N) SwiftData queries for an N-card list per
/// re-render. With ~200 businesses and multi-section home, this caused jank
/// during favorite toggles. The cache reduces it to O(1) lookup.
@Observable
final class FavoritesStore {
    private var modelContext: ModelContext
    private var favoriteIdSet: Set<String> = []
    private var orderedIds: [String] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        reload()
    }

    /// Re-reads from SwiftData. Call after major mutations from outside the
    /// store (e.g. iCloud sync, future).
    func reload() {
        let descriptor = FetchDescriptor<Favorite>(
            sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
        )
        let favorites = (try? modelContext.fetch(descriptor)) ?? []
        orderedIds = favorites.map(\.businessId)
        favoriteIdSet = Set(orderedIds)
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
