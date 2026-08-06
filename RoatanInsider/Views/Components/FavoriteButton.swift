import SwiftUI

/// The save heart. White when unsaved, pink when saved — one of the four
/// places pink is allowed.
///
/// Over a photo it carries a soft drop shadow. Without it the white heart
/// disappears against pale sand and sky, which is most of the photo library
/// on this island. Shadows are off-limits on cards; this is a floating
/// control on top of an image, which is the case the rules allow.
struct FavoriteButton: View {
    let businessId: String
    var onPhoto: Bool = true
    @Environment(FavoritesStore.self) private var favoritesStore

    var body: some View {
        let isSaved = favoritesStore.isFavorite(businessId)

        Button {
            Haptics.impact()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                favoritesStore.toggleFavorite(businessId)
            }
            Analytics.track(.businessFavorited(id: businessId, isFavorite: favoritesStore.isFavorite(businessId)))
        } label: {
            Image(systemName: isSaved ? "heart.fill" : "heart")
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(isSaved ? Color.riPink : (onPhoto ? .white : Color.riLightGray))
                .shadow(color: .black.opacity(onPhoto ? 0.28 : 0), radius: 3, y: 1)
                .scaleEffect(isSaved ? 1.0 : 0.92)
                .frame(width: AppConstants.minTapTarget, height: AppConstants.minTapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isSaved ? "Remove from saved" : "Save")
    }
}
