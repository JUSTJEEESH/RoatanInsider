import SwiftUI

struct RatingView: View {
    let rating: Double
    var size: CGFloat = 12

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .font(.system(size: size))
                .foregroundStyle(Color.riGoldStar)

            Text(String(format: "%.1f", rating))
                .font(.system(size: size + 1, weight: .medium))
                .foregroundStyle(Color.riDark)
        }
    }
}
