import SwiftUI

struct MapPopupCard: View {
    let business: Business
    let onDismiss: () -> Void

    var body: some View {
        NavigationLink(value: business) {
            HStack(spacing: 12) {
                BusinessImageView(business: business, aspectRatio: 1)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(business.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.riDark)
                        .lineLimit(1)

                    Text(business.category.displayName)
                        .font(.riCaption(13))
                        .foregroundStyle(Color.riLightGray)

                    HStack(spacing: 4) {
                        Text(business.area.displayName)
                        Text("·")
                        Text(business.priceLabel)
                    }
                    .font(.riCaption(13))
                    .foregroundStyle(Color.riLightGray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.riLightGray)
            }
            .padding(12)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
