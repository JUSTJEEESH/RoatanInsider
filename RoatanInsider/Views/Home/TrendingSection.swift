import SwiftUI

/// "Loved Right Now" — top businesses by community reactions over the last
/// 7 days. Hides itself when there's no signal yet, so an empty backend
/// doesn't leave a sad zero-state on Home.
///
/// Layout matches the other horizontal-scroll sections (Featured,
/// Continue Browsing): SectionHeader + LazyHStack of compact cards.
/// The differentiator is a flame badge on each card showing the total
/// reaction count — earns the "trending" feel without colored chrome.
struct TrendingSection: View {
    @Environment(TrendingReactionsService.self) private var trending
    @Environment(DataManager.self) private var dataManager

    var body: some View {
        if !resolvedBusinesses.isEmpty {
            VStack(alignment: .leading, spacing: 20) {
                SectionHeader(title: "Loved right now", lightText: false)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(resolvedBusinesses.enumerated()), id: \.element.business.id) { _, item in
                            NavigationLink(value: item.business) {
                                ZStack(alignment: .topTrailing) {
                                    BusinessCard(business: item.business, style: .compact)
                                    flameBadge(count: item.entry.total_reactions)
                                        .padding(10)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
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
                .font(.system(size: 11, weight: .bold))
                .monospacedDigit()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.55))
        .clipShape(Capsule())
    }
}
