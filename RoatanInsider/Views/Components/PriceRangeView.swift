import SwiftUI

/// Price as four dollar signs, the spent ones dark and the rest faded.
struct PriceRangeView: View {
    let priceRange: Int
    let maxRange: Int = 4

    var body: some View {
        HStack(spacing: 1) {
            ForEach(1...maxRange, id: \.self) { i in
                Text("$")
                    .riType(.caption, weight: .semibold)
                    .foregroundStyle(i <= priceRange ? Color.riDark : Color.riLightGray.opacity(0.35))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Price \(priceRange) out of \(maxRange)")
    }
}
