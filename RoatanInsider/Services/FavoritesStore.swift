import Foundation
import SwiftData

@Observable
final class FavoritesStore {
    private var modelContext: ModelContext
    // Incremented on every mutation so SwiftUI views re-render
    private(set) var version: Int = 0

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func isFavorite(_ businessId: String) -> Bool {
        _ = version
        let descriptor = FetchDescriptor<Favorite>(
            predicate: #Predicate { $0.businessId == businessId }
        )
        return (try? modelContext.fetchCount(descriptor)) ?? 0 > 0
    }

    func toggleFavorite(_ businessId: String) {
        if isFavorite(businessId) {
            removeFavorite(businessId)
        } else {
            addFavorite(businessId)
        }
    }

    func addFavorite(_ businessId: String) {
        let favorite = Favorite(businessId: businessId)
        modelContext.insert(favorite)
        try? modelContext.save()
        version += 1
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
            version += 1
        }
    }

    func allFavoriteIds() -> [String] {
        _ = version
        let descriptor = FetchDescriptor<Favorite>(
            sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
        )
        let favorites = (try? modelContext.fetch(descriptor)) ?? []
        return favorites.map(\.businessId)
    }
}
