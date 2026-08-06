import SwiftUI

/// A star and a number. The star is the one place gold is allowed in this
/// app, per the palette rules — everywhere else is black, white, grey, pink
/// and mint.
///
/// `size` is a parameter rather than a scale step because this sits inside
/// other components at their scale — a rating on a grid card and one on a
/// detail header are the same component drawn to two different hosts.
struct RatingView: View {
    let rating: Double
    var size: CGFloat = 12

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "star.fill")
                .font(.system(size: size))
                .foregroundStyle(Color.riGoldStar)

            Text(String(format: "%.1f", rating))
                .font(.system(size: size + 1, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(Color.riDark)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rated \(String(format: "%.1f", rating)) out of 5")
    }
}
