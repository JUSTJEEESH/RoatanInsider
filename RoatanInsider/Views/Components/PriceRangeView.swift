import SwiftUI

struct PriceRangeView: View {
    let priceRange: Int
    let maxRange: Int = 4

    var body: some View {
        HStack(spacing: 1) {
            ForEach(1...maxRange, id: \.self) { i in
                Text("$")
                    .font(.riCaption(13))
                    .foregroundStyle(i <= priceRange ? Color.riDark : Color.riLightGray.opacity(0.4))
            }
        }
    }
}
