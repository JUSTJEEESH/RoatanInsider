import SwiftUI

// MARK: - Collection Definition

struct CuratedCollection: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let coverImage: String
    let coverCategory: Category
    let filter: (Business) -> Bool

    /// Supabase storage URL for the collection cover image.
    var coverImageURL: URL? {
        guard !coverImage.isEmpty else { return nil }
        return URL(string: AppConstants.supabaseStorageBaseURL + coverImage)
    }

    static let all: [CuratedCollection] = [
        CuratedCollection(
            title: "Best Sunset Spots",
            subtitle: "Chase the golden hour",
            icon: "sunset.fill",
            coverImage: "collection_sunset_spots.jpg",
            coverCategory: .drink
        ) { business in
            (business.category == .drink || business.category == .beaches) &&
            (business.area == .westEnd || business.area == .westBay) &&
            business.isActive
        },
        CuratedCollection(
            title: "Best for Families",
            subtitle: "Fun for the whole crew",
            icon: "figure.2.and.child.holdinghands",
            coverImage: "collection_families.jpg",
            coverCategory: .tours
        ) { business in
            business.features.contains(where: { $0.lowercased().contains("family") }) &&
            business.isActive
        },
        CuratedCollection(
            title: "Top Dive Sites",
            subtitle: "World-class reefs and walls",
            icon: "figure.pool.swim",
            coverImage: "collection_dive_sites.jpg",
            coverCategory: .dive
        ) { business in
            business.category == .dive && business.isActive
        },
        CuratedCollection(
            title: "Cheap Eats",
            subtitle: "Great food, easy prices",
            icon: "fork.knife",
            coverImage: "collection_cheap_eats.jpg",
            coverCategory: .eat
        ) { business in
            business.category == .eat && business.priceRange <= 2 && business.isActive
        },
        CuratedCollection(
            title: "Beach Bars",
            subtitle: "Feet in the sand, drink in hand",
            icon: "wineglass.fill",
            coverImage: "collection_beach_bars.jpg",
            coverCategory: .drink
        ) { business in
            business.category == .drink &&
            business.features.contains(where: { $0.lowercased().contains("beach") || $0.lowercased().contains("waterfront") }) &&
            business.isActive
        },
        CuratedCollection(
            title: "Off the Beaten Path",
            subtitle: "Beyond the tourist zone",
            icon: "map.fill",
            coverImage: "collection_off_beaten_path.jpg",
            coverCategory: .tours
        ) { business in
            let remoteAreas: Set<Area> = [.oakRidge, .puntaGorda, .portRoyal, .campBay]
            return remoteAreas.contains(business.area) && business.isActive
        }
    ]
}

// MARK: - Collections Section

struct CollectionsSection: View {
    let businesses: [Business]

    var body: some View {
        let collections = CuratedCollection.all.filter { collection in
            businesses.filter(collection.filter).count >= 2
        }

        if !collections.isEmpty {
            VStack(alignment: .leading, spacing: 20) {
                SectionHeader(
                    title: "Best of Roatán",
                    subtitle: "Curated by locals"
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(collections) { collection in
                            NavigationLink {
                                CollectionDetailView(
                                    collection: collection,
                                    businesses: businesses.filter(collection.filter)
                                )
                            } label: {
                                CollectionCard(collection: collection)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
}

// MARK: - Collection Card

struct CollectionCard: View {
    let collection: CuratedCollection

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Cover
            ZStack(alignment: .bottomLeading) {
                // Cover image from Supabase, with category placeholder fallback
                if let url = collection.coverImageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            coverPlaceholder
                        case .empty:
                            coverPlaceholder
                                .overlay {
                                    ProgressView()
                                        .tint(Color.riMint)
                                }
                        @unknown default:
                            coverPlaceholder
                        }
                    }
                } else {
                    coverPlaceholder
                }

                // Dark overlay for text readability
                Color.black.opacity(0.3)

                VStack(alignment: .leading, spacing: 4) {
                    Spacer()
                    Text(collection.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)

                    Text(collection.subtitle)
                        .font(.riCaption(13))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .padding(16)
            }
            .frame(width: 240, height: 160)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(collection.title). \(collection.subtitle)")
    }

    private var coverPlaceholder: some View {
        collection.coverCategory.placeholderColor
            .overlay {
                Image(systemName: collection.icon)
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(Color.riMint.opacity(0.4))
            }
    }
}

// MARK: - Collection Detail

struct CollectionDetailView: View {
    let collection: CuratedCollection
    let businesses: [Business]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: collection.icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(Color.riMint)

                    Text(collection.title)
                        .riHeadlineStyle(26)
                        .foregroundStyle(Color.riDark)

                    Text(collection.subtitle)
                        .font(.riBody)
                        .foregroundStyle(Color.riMediumGray)

                    Text("\(businesses.count) places")
                        .font(.riCaption(13))
                        .foregroundStyle(Color.riLightGray)
                        .padding(.top, 4)
                }
                .padding(.top, 20)
                .padding(.bottom, 24)

                LazyVStack(spacing: 16) {
                    ForEach(businesses) { business in
                        NavigationLink(value: business) {
                            BusinessCard(business: business)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(Color.riWhite)
        .navigationBarTitleDisplayMode(.inline)
    }
}
