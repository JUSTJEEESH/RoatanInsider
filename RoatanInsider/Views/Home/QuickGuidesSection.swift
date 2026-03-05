import SwiftUI

struct QuickGuidesSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SectionHeader(title: "Quick Guides", lightText: true)

            VStack(spacing: 12) {
                NavigationLink {
                    CruiseDayGuideView()
                } label: {
                    GuideRow(
                        icon: "ferry",
                        title: "Cruise Day Guide",
                        subtitle: "Make the most of your time on the island"
                    )
                }

                NavigationLink {
                    AreaGuideView()
                } label: {
                    GuideRow(
                        icon: "map",
                        title: "Area Guides",
                        subtitle: "Explore all 10 areas of Roatán"
                    )
                }

                NavigationLink {
                    IslandEssentialsView()
                } label: {
                    GuideRow(
                        icon: "lightbulb",
                        title: "Island Essentials",
                        subtitle: "Money, safety, tips, and more"
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct GuideRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(Color.riMint)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.riCaption(13))
                    .foregroundStyle(Color.riLightGray)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.riMediumGray)
        }
        .padding(16)
        .background(Color.riNearBlack)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
