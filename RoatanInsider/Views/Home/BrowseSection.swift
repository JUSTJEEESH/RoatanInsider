import SwiftUI

/// "Browse" — the deliberate handoff from Home to Explore.
///
/// Merges `CategoryGridSection`, `CollectionsSection` and `FeaturedSection`
/// under a single heading. Those were three consecutive blocks each with
/// its own header, each answering "which places?" — the same question, three
/// times, in three different shapes. Featured is gone entirely: "places the
/// app likes" was indistinguishable from Insider Picks and Best Of, and the
/// curated collections say it better.
///
/// Categories first because that's the query people actually arrive with
/// ("where do I eat?"), collections second as the editorial alternative
/// for people who don't know what they want yet.
struct BrowseSection: View {
    @Environment(DataManager.self) private var dataManager
    let businesses: [Business]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: AppConstants.Space.snug), count: 5)

    var body: some View {
        let collections = CuratedCollection.all.filter { collection in
            businesses.filter(collection.filter).count >= 2
        }

        VStack(alignment: .leading, spacing: AppConstants.Space.block) {
            VStack(alignment: .leading, spacing: AppConstants.Space.hair) {
                Text("BROWSE")
                    .riType(.label)
                    .foregroundStyle(Color.riMint)
                Text("Find your way around")
                    .riType(.title)
                    .foregroundStyle(Color.riWhite)
            }
            .padding(.horizontal, AppConstants.Space.gutter)

            LazyVGrid(columns: columns, spacing: AppConstants.Space.gutter) {
                ForEach(dataManager.categoryInfos) { info in
                    NavigationLink(value: CategoryNavID(id: info.id)) {
                        CategoryIcon(categoryInfo: info, lightText: true)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(info.displayName)
                }
            }
            .padding(.horizontal, AppConstants.Space.gutter)

            if !collections.isEmpty {
                VStack(alignment: .leading, spacing: AppConstants.Space.snug) {
                    Text("Best of Roatán")
                        .riType(.heading)
                        .foregroundStyle(Color.riWhite)
                        .padding(.horizontal, AppConstants.Space.gutter)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppConstants.Space.snug) {
                            ForEach(collections) { collection in
                                NavigationLink(value: collection) {
                                    CollectionCard(collection: collection)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, AppConstants.Space.gutter)
                    }
                }
            }
        }
        .onAppear { Analytics.track(.homeSectionViewed(name: "browse")) }
    }
}
