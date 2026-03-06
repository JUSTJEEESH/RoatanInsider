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
                SearchBar(text: $searchEngine.searchText)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

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
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Business.self) { business in
                BusinessDetailView(business: business)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Color.riLightGray)

            Text("No results found")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.riDark)

            Text("Try adjusting your search or filters")
                .font(.riBody)
                .foregroundStyle(Color.riLightGray)
        }
        .padding(.top, 60)
    }
}
