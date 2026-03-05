import SwiftUI

struct BusinessCard: View {
    let business: Business
    @Environment(FavoritesStore.self) private var favoritesStore

    var body: some View {
        NavigationLink(value: business) {
            VStack(alignment: .leading, spacing: 0) {
                // Photo
                ZStack(alignment: .topTrailing) {
                    Image(business.images.first ?? "business_placeholder")
                        .resizable()
                        .aspectRatio(16/9, contentMode: .fill)
                        .clipped()

                    FavoriteButton(businessId: business.id)
                        .padding(12)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(business.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.riDark)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Text(business.area.displayName)
                        Text("·")
                        Text(business.priceLabel)
                    }
                    .font(.riCaption(14))
                    .foregroundStyle(Color.riLightGray)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius))
        }
        .buttonStyle(.plain)
    }
}

// Compact card for horizontal scrolling
struct BusinessCardCompact: View {
    let business: Business
    @Environment(FavoritesStore.self) private var favoritesStore

    var body: some View {
        NavigationLink(value: business) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    Image(business.images.first ?? "business_placeholder")
                        .resizable()
                        .aspectRatio(4/3, contentMode: .fill)
                        .frame(width: 260, height: 180)
                        .clipped()

                    FavoriteButton(businessId: business.id)
                        .padding(8)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(business.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.riDark)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Text(business.area.displayName)
                        Text("·")
                        Text(business.priceLabel)
                    }
                    .font(.riCaption(13))
                    .foregroundStyle(Color.riLightGray)
                }
                .padding(10)
            }
            .frame(width: 260)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius))
        }
        .buttonStyle(.plain)
    }
}
