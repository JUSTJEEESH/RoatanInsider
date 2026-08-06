import SwiftUI

/// Explore, in two modes.
///
/// Untouched, it has an opinion: what suits this hour, what you were last
/// looking at, what other people are reacting to. Search or filter anything
/// and it becomes a results screen — count, sort, grid. The screen used to
/// be only the second half, so a cruise passenger with six hours ashore and
/// a resident on a Tuesday were handed the identical wall of 94 cards and
/// left to work it out.
///
/// The three opinionated sections were written for Home, pulled off it in
/// the redesign because Home had seven surfaces all answering "which
/// places?", and then sat unreferenced. They belong here, where they work
/// across the whole directory instead of a handful of picks.
struct ExploreView: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(LocationManager.self) private var locationManager
    @State private var viewModel = ExploreViewModel()
    @Namespace private var zoomNS

    private let columns = [
        GridItem(.flexible(), spacing: AppConstants.Space.snug),
        GridItem(.flexible(), spacing: AppConstants.Space.snug),
    ]

    var body: some View {
        @Bindable var searchEngine = viewModel.searchEngine

        NavigationStack {
            VStack(spacing: 0) {
                header

                SearchBar(text: $searchEngine.searchText)
                    .padding(.horizontal, AppConstants.Space.gutter)

                FilterBar(
                    searchEngine: viewModel.searchEngine,
                    allFeatures: SearchEngine.allFeatures(from: dataManager.businesses)
                )
                .padding(.top, AppConstants.Space.tight)

                ScrollView {
                    if viewModel.searchEngine.hasActiveFilters {
                        results
                    } else {
                        discovery
                    }
                }
            }
            .background(Color.riWhite)
            .navigationBarHidden(true)
            .navigationDestination(for: Business.self) { business in
                BusinessDetailView(business: business)
            }
            .navigationDestination(for: CategoryNavID.self) { navID in
                CategoryListView(categoryId: navID.id)
            }
        }
        .environment(\.zoomNamespace, zoomNS)
    }

    // MARK: - Chrome

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Explore")
                .riType(.display)
                .foregroundStyle(Color.riDark)
            Text("94 places, and what suits right now.")
                .riType(.caption)
                .foregroundStyle(Color.riMediumGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppConstants.Space.gutter)
        .padding(.top, AppConstants.Space.snug)
        .padding(.bottom, AppConstants.Space.tight)
    }

    // MARK: - Mode: discovery

    private var discovery: some View {
        LazyVStack(alignment: .leading, spacing: AppConstants.Space.section) {
            RightNowSection(businesses: dataManager.businesses)
            ContinueBrowsingSection()
            TrendingSection()

            allPlaces
        }
        .padding(.top, AppConstants.Space.gutter)
        .padding(.bottom, AppConstants.Space.block)
    }

    /// The full directory still sits underneath the opinionated sections —
    /// browsing everything is a legitimate way to use this app, and burying
    /// it behind a search box would be worse than the wall of cards was.
    private var allPlaces: some View {
        VStack(alignment: .leading, spacing: AppConstants.Space.snug) {
            HStack(alignment: .firstTextBaseline) {
                Text("EVERYWHERE")
                    .riType(.label)
                    .foregroundStyle(Color.riMediumGray)
                Spacer()
                sortMenu
            }
            .padding(.horizontal, AppConstants.Space.gutter)

            grid(viewModel.filteredBusinesses(
                from: dataManager.businesses,
                userLocation: locationManager.userLocation
            ))
        }
    }

    // MARK: - Mode: results

    @ViewBuilder
    private var results: some View {
        let matches = viewModel.filteredBusinesses(
            from: dataManager.businesses,
            userLocation: locationManager.userLocation
        )

        if matches.isEmpty {
            emptyState
        } else {
            VStack(alignment: .leading, spacing: AppConstants.Space.snug) {
                HStack(alignment: .firstTextBaseline) {
                    Text(matches.count == 1 ? "1 place" : "\(matches.count) places")
                        .riType(.caption)
                        .foregroundStyle(Color.riMediumGray)
                    Spacer()
                    sortMenu
                }
                .padding(.horizontal, AppConstants.Space.gutter)

                grid(matches)
            }
            .padding(.top, AppConstants.Space.snug)
            .padding(.bottom, AppConstants.Space.block)
        }
    }

    private func grid(_ businesses: [Business]) -> some View {
        LazyVGrid(columns: columns, spacing: AppConstants.Space.gutter) {
            ForEach(businesses) { business in
                BusinessCard(business: business, style: .grid)
            }
        }
        .padding(.horizontal, AppConstants.Space.gutter)
    }

    /// "Nearest" only appears once we have a location. Offering a sort that
    /// silently does nothing is how the old one shipped broken for months.
    private var sortMenu: some View {
        Menu {
            ForEach(availableSorts) { option in
                Button {
                    Haptics.select()
                    viewModel.searchEngine.sortOption = option
                } label: {
                    Label(option.rawValue, systemImage: option.symbol)
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(viewModel.searchEngine.sortOption.rawValue)
                    .riType(.caption, weight: .semibold)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(Color.riDark)
        }
        .accessibilityLabel("Sort by \(viewModel.searchEngine.sortOption.rawValue)")
    }

    private var availableSorts: [SearchEngine.SortOption] {
        SearchEngine.SortOption.allCases.filter {
            !$0.requiresLocation || locationManager.userLocation != nil
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            symbol: "magnifyingglass",
            title: "Nothing matches that",
            message: "Try a different word, drop a filter, or widen the area."
        )
    }
}
