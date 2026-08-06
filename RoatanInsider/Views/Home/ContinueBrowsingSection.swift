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
            VStack(alignment: .leading, spacing: AppConstants.Space.snug) {
                VStack(alignment: .leading, spacing: AppConstants.Space.hair) {
                    Text("WHERE YOU LEFT OFF")
                        .riType(.label)
                        .foregroundStyle(Color.riMediumGray)
                    Text("Places you looked at")
                        .riType(.title)
                        .foregroundStyle(Color.riDark)
                }
                .padding(.horizontal, AppConstants.Space.gutter)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: AppConstants.Space.snug) {
                        ForEach(recents.prefix(8)) { business in
                            BusinessCard(business: business, style: .compact)
                        }
                    }
                    .padding(.horizontal, AppConstants.Space.gutter)
                }
            }
            .onAppear {
                Analytics.track(.homeSectionViewed(name: "continue_browsing"))
            }
        }
    }
}
