import SwiftUI

/// "Loved Right Now" — top businesses by community reactions over the last
/// 7 days. Hides itself when there's no signal yet, so an empty backend
/// doesn't leave a sad zero-state on Home.
///
/// Sits in Explore's discovery mode alongside Right Now and Where You Left
/// Off, matching their kicker-and-title shape. The differentiator is a flame
/// badge carrying the reaction count — the "trending" feel without coloured
/// chrome. It's offset clear of the save heart, which claims the same
/// corner.
struct TrendingSection: View {
    @Environment(TrendingReactionsService.self) private var trending
    @Environment(DataManager.self) private var dataManager

    var body: some View {
        if !resolvedBusinesses.isEmpty {
            VStack(alignment: .leading, spacing: AppConstants.Space.snug) {
                VStack(alignment: .leading, spacing: AppConstants.Space.hair) {
                    Text("TRENDING")
                        .riType(.label)
                        .foregroundStyle(Color.riMediumGray)
                    Text("What people are reacting to")
                        .riType(.title)
                        .foregroundStyle(Color.riDark)
                }
                .padding(.horizontal, AppConstants.Space.gutter)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: AppConstants.Space.snug) {
                        ForEach(Array(resolvedBusinesses.enumerated()), id: \.element.business.id) { _, item in
                            ZStack(alignment: .topTrailing) {
                                BusinessCard(business: item.business, style: .compact)
                                // Offset clear of the save heart, which claims
                                // the same corner. Not hit-testable, so it
                                // can't swallow the card's own tap.
                                flameBadge(count: item.entry.total_reactions)
                                    .padding(AppConstants.Space.tight)
                                    .padding(.trailing, AppConstants.minTapTarget - AppConstants.Space.tight)
                                    .allowsHitTesting(false)
                            }
                        }
                    }
                    .padding(.horizontal, AppConstants.Space.gutter)
                }
            }
            .task { trending.refreshIfStale() }
        } else {
            // Still kick off a fetch so the section appears next visit
            // once data arrives. Returning an empty Color keeps the
            // LazyVStack layout from reserving space.
            Color.clear
                .frame(height: 0)
                .task { trending.refreshIfStale() }
        }
    }

    // MARK: - Data resolution

    /// Joins the trending-IDs returned by the backend against the local
    /// business catalog. Drops any IDs we don't know about (rare but
    /// possible if the catalog is out of sync with the backend).
    private var resolvedBusinesses: [(business: Business, entry: TrendingReactionsService.TrendingEntry)] {
        let byId = Dictionary(uniqueKeysWithValues: dataManager.businesses.map { ($0.id, $0) })
        return trending.trending.compactMap { entry in
            guard let business = byId[entry.business_id] else { return nil }
            return (business, entry)
        }
    }

    // MARK: - Flame badge

    private func flameBadge(count: Int) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "flame.fill")
                .font(.system(size: 10, weight: .bold))
            Text("\(count)")
                .riType(.micro)
                .monospacedDigit()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.55))
        .clipShape(Capsule())
    }
}
