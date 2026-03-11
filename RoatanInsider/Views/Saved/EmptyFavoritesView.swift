import SwiftUI

struct EmptyFavoritesView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "heart")
                .font(.system(size: 52, weight: .thin))
                .foregroundStyle(Color.riLightGray)

            VStack(spacing: 8) {
                Text("No favorites yet")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.riDark)

                Text("Tap the heart on any business to\nsave it here for quick access.")
                    .font(.riBody)
                    .foregroundStyle(Color.riMediumGray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }

            Spacer()

            Text("Tip: Long-press a favorite to remove it")
                .font(.riCaption(13))
                .foregroundStyle(Color.riLightGray)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
}
