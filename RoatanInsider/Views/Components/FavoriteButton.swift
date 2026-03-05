import SwiftUI

struct FavoriteButton: View {
    let businessId: String
    @Environment(FavoritesStore.self) private var favoritesStore

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                favoritesStore.toggleFavorite(businessId)
            }
        } label: {
            Image(systemName: favoritesStore.isFavorite(businessId) ? "heart.fill" : "heart")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(favoritesStore.isFavorite(businessId) ? Color.riPink : .white)
                .frame(width: AppConstants.minTapTarget, height: AppConstants.minTapTarget)
        }
    }
}
