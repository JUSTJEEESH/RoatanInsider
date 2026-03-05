import SwiftUI

struct SavedView: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(FavoritesStore.self) private var favoritesStore
    @State private var viewModel = FavoritesViewModel()

    var body: some View {
        NavigationStack {
            Group {
                let businesses = viewModel.favoriteBusinesses(from: dataManager, favoritesStore: favoritesStore)
                if businesses.isEmpty {
                    EmptyFavoritesView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(businesses) { business in
                                BusinessCard(business: business)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            favoritesStore.removeFavorite(business.id)
                                        } label: {
                                            Label("Remove", systemImage: "heart.slash")
                                        }
                                    }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .background(Color.riWhite)
            .navigationTitle("Saved")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: Business.self) { business in
                BusinessDetailView(business: business)
            }
        }
    }
}
