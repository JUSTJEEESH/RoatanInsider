import SwiftUI

struct EmptyFavoritesView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color.riLightGray)

            Text("No favorites yet")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.riDark)

            Text("Explore the island and save\nyour favorites.")
                .font(.riBody)
                .foregroundStyle(Color.riMediumGray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
