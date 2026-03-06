import SwiftUI

struct ExploreView: View {
    @Environment(DataManager.self) private var dataManager
    @State private var viewModel = ExploreViewModel()

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchBar(text: $viewModel.searchEngine.searchText)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                FilterBar(searchEngine: viewModel.searchEngine)
                    .padding(.top, 8)

                ScrollView {
                    let results = viewModel.filteredBusinesses(from: dataManager.businesses)
                    if results.isEmpty {
                        emptyState
                    } else {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(results) { business in
                                BusinessCardGrid(business: business)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
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
