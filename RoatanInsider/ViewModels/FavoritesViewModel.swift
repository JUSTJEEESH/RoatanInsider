import Foundation

@Observable
final class FavoritesViewModel {
    func favoriteBusinesses(from dataManager: DataManager, favoritesStore: FavoritesStore) -> [Business] {
        let ids = favoritesStore.allFavoriteIds()
        return ids.compactMap { dataManager.business(withId: $0) }
    }
}
