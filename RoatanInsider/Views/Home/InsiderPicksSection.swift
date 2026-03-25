import SwiftUI

struct InsiderPicksSection: View {
    let businesses: [Business]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(
                title: "Insider Picks",
                subtitle: "Curated by locals who know the island best"
            )

            VStack(spacing: 24) {
                ForEach(businesses.prefix(4)) { business in
                    InsiderPickCard(business: business)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct InsiderPickCard: View {
    let business: Business
    @Environment(FavoritesStore.self) private var favoritesStore

    var body: some View {
        NavigationLink(value: business) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    Color.clear
                        .aspectRatio(16/9, contentMode: .fit)
                        .background {
                            BusinessImageView(business: business, aspectRatio: 16/9)
                        }
                        .clipped()

                    FavoriteButton(businessId: business.id)
                        .padding(12)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(business.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.riDark)

                    HStack(spacing: 4) {
                        Text(business.category.displayName)
                        Text("·")
                        Text(business.area.displayName)
                        Text("·")
                        Text(business.priceLabel)
                    }
                    .font(.riCaption(13))
                    .foregroundStyle(Color.riLightGray)

                    if let tip = business.insiderTip {
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.riMint)
                                .frame(width: 3)

                            Text(tip)
                                .font(.riCaption(14))
                                .foregroundStyle(Color.riMediumGray)
                                .italic()
                                .padding(.leading, 12)
                                .padding(.vertical, 4)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.riOffWhite)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius))
        }
        .buttonStyle(.plain)
    }
}
