import SwiftUI

struct InsiderTipsFeedSection: View {
    let businesses: [Business]

    private var tipsWithBusinesses: [(business: Business, tip: String)] {
        businesses
            .filter { $0.insiderTip != nil && $0.isActive }
            .compactMap { business in
                guard let tip = business.insiderTip else { return nil }
                return (business: business, tip: tip)
            }
            .shuffled()
            .prefix(10)
            .map { $0 }
    }

    var body: some View {
        let tips = tipsWithBusinesses
        if !tips.isEmpty {
            VStack(alignment: .leading, spacing: 20) {
                SectionHeader(
                    title: "Local Secrets",
                    subtitle: "Tips you won't find on Google",
                    lightText: true
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(tips, id: \.business.id) { item in
                            NavigationLink(value: item.business) {
                                TipCard(
                                    tip: item.tip,
                                    businessName: item.business.name,
                                    category: item.business.category,
                                    area: item.business.area
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}

// MARK: - Tip Card

struct TipCard: View {
    let tip: String
    let businessName: String
    let category: Category
    let area: Area

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Quote mark
            Image(systemName: "quote.opening")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color.riMint)

            // Tip text
            Text(tip)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.white.opacity(0.9))
                .lineSpacing(4)
                .lineLimit(4)

            Spacer()

            // Attribution
            VStack(alignment: .leading, spacing: 4) {
                Text(businessName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: category.iconName)
                        .font(.system(size: 11, weight: .medium))
                    Text(area.displayName)
                        .font(.riCaption(12))
                }
                .foregroundStyle(Color.riMint)
            }
        }
        .padding(18)
        .frame(width: 260, height: 200)
        .background(Color.riNearBlack)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius)
                .stroke(Color.riMediumGray.opacity(0.2), lineWidth: 0.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Insider tip for \(businessName): \(tip)")
    }
}
