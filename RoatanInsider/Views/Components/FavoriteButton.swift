import SwiftUI

struct FavoriteButton: View {
    let businessId: String
    var onPhoto: Bool = true
    @Environment(FavoritesStore.self) private var favoritesStore

    var body: some View {
        let isSaved = favoritesStore.isFavorite(businessId)

        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                favoritesStore.toggleFavorite(businessId)
            }
        } label: {
            Image(systemName: isSaved ? "heart.fill" : "heart")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(isSaved ? Color.riPink : (onPhoto ? .white : Color.riLightGray))
                .scaleEffect(isSaved ? 1.0 : 0.9)
                .frame(width: AppConstants.minTapTarget, height: AppConstants.minTapTarget)
        }
    }
}
