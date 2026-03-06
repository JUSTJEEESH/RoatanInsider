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
                    List {
                        ForEach(businesses) { business in
                            NavigationLink(value: business) {
                                savedRow(business: business)
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                        .onDelete { offsets in
                            for index in offsets {
                                let business = businesses[index]
                                favoritesStore.removeFavorite(business.id)
                            }
                        }
                    }
                    .listStyle(.plain)
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

    private func savedRow(business: Business) -> some View {
        HStack(spacing: 14) {
            Image(business.images.first ?? "business_placeholder")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(business.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.riDark)
                    .lineLimit(1)

                Text(business.category.displayName)
                    .font(.riCaption(13))
                    .foregroundStyle(Color.riMediumGray)

                HStack(spacing: 4) {
                    Text(business.area.displayName)
                    Text("·")
                    Text(business.priceLabel)
                }
                .font(.riCaption(13))
                .foregroundStyle(Color.riLightGray)
            }

            Spacer()
        }
    }
}
