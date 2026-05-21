import SwiftUI

struct SavedView: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(FavoritesStore.self) private var favoritesStore
    @State private var viewModel = FavoritesViewModel()

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                // Custom header for reliable display on all devices
                VStack(alignment: .leading, spacing: 2) {
                    Text("Saved")
                        .riDisplayStyle(34)
                        .foregroundStyle(Color.riDark)
                    Text("Your personal island shortlist")
                        .font(.riCaption(15))
                        .foregroundStyle(Color.riLightGray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)

                let businesses = viewModel.favoriteBusinesses(from: dataManager, favoritesStore: favoritesStore)
                if businesses.isEmpty {
                    EmptyFavoritesView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(businesses) { business in
                                BusinessCard(business: business)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            favoritesStore.removeFavorite(business.id)
                                        } label: {
                                            Label("Remove from Favorites", systemImage: "heart.slash")
                                        }
                                    }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
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
}
