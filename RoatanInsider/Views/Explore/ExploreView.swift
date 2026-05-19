import SwiftUI

struct ExploreView: View {
    @Environment(DataManager.self) private var dataManager
    @State private var viewModel = ExploreViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        @Bindable var searchEngine = viewModel.searchEngine

        NavigationStack {
            VStack(spacing: 0) {
                // Custom header for reliable display on all devices
                VStack(alignment: .leading, spacing: 2) {
                    Text("Explore")
                        .riDisplayStyle(34)
                        .foregroundStyle(Color.riDark)
                    Text("Find your next island adventure")
                        .font(.riCaption(15))
                        .foregroundStyle(Color.riLightGray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)

                SearchBar(text: $searchEngine.searchText)
                    .padding(.horizontal, 20)

                FilterBar(
                    searchEngine: viewModel.searchEngine,
                    allFeatures: SearchEngine.allFeatures(from: dataManager.businesses)
                )
                .padding(.top, 8)

                let results = viewModel.filteredBusinesses(from: dataManager.businesses)
                ScrollView {
                    if results.isEmpty {
                        emptyState
                    } else {
                        HStack {
                            Text("\(results.count) results")
                                .font(.riCaption(13))
                                .foregroundStyle(Color.riLightGray)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(results) { business in
                                BusinessCardGrid(business: business)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
            .background(Color.riWhite)
            .navigationBarHidden(true)
            .navigationDestination(for: Business.self) { business in
                BusinessDetailView(business: business)
            }
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            symbol: "magnifyingglass",
            title: "No results found",
            message: "Try a different word, drop a filter, or zoom out the area."
        )
    }
}
