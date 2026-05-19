import SwiftUI

/// "Continue browsing" — a personal, soft-launch surface that only appears
/// once the user has opened at least one business. Cheap retention win:
/// returning users see something that recognises them by their second visit.
struct ContinueBrowsingSection: View {
    @Environment(RecentlyViewedStore.self) private var recentlyViewed
    @Environment(DataManager.self) private var dataManager

    private var items: [Business] {
        recentlyViewed.ids.compactMap { id in
            dataManager.businesses.first(where: { $0.id == id && $0.isActive })
        }
    }

    var body: some View {
        let recents = items
        if !recents.isEmpty {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CONTINUE BROWSING")
                            .font(.system(size: 12, weight: .bold))
                            .tracking(1.5)
                            .foregroundStyle(Color.riMint)
                        Text("Pick up where you left off")
                            .riHeadlineStyle(22)
                            .foregroundStyle(Color.riDark)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(recents.prefix(8)) { business in
                            BusinessCardCompact(business: business)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
            .onAppear {
                Analytics.track(.homeSectionViewed(name: "continue_browsing"))
            }
        }
    }
}
