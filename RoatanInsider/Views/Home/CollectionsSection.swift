import SwiftUI

// MARK: - Collection Definition

struct CuratedCollection: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let coverImage: String
    let coverCategory: String
    let collectionKey: String

    var filter: (Business) -> Bool {
        let key = collectionKey
        return { business in
            business.collections.contains(key) && business.isActive
        }
    }

    static func == (lhs: CuratedCollection, rhs: CuratedCollection) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    /// Supabase storage URL for the collection cover image.
    var coverImageURL: URL? {
        guard !coverImage.isEmpty else { return nil }
        return URL(string: AppConstants.supabaseStorageBaseURL + coverImage)
    }

    static let all: [CuratedCollection] = [
        CuratedCollection(id: "sunset_spots", title: "Best Sunset Spots", subtitle: "Chase the golden hour", icon: "sunset.fill", coverImage: "collection_sunset_spots.jpg", coverCategory: "drink", collectionKey: "sunset_spots"),
        CuratedCollection(id: "families", title: "Best for Families", subtitle: "Fun for the whole crew", icon: "figure.2.and.child.holdinghands", coverImage: "collection_families.jpg", coverCategory: "tours", collectionKey: "families"),
        CuratedCollection(id: "cheap_eats", title: "Cheap Eats", subtitle: "Great food, easy prices", icon: "fork.knife", coverImage: "collection_cheap_eats.jpg", coverCategory: "eat", collectionKey: "cheap_eats"),
        CuratedCollection(id: "beach_bars", title: "Beach Bars", subtitle: "Feet in the sand, drink in hand", icon: "wineglass.fill", coverImage: "collection_beach_bars.jpg", coverCategory: "drink", collectionKey: "beach_bars"),
        CuratedCollection(id: "off_beaten_path", title: "Off the Beaten Path", subtitle: "Beyond the tourist zone", icon: "map.fill", coverImage: "collection_off_beaten_path.jpg", coverCategory: "tours", collectionKey: "off_beaten_path"),
        CuratedCollection(id: "cruise_must_dos", title: "Cruise Day Must-Dos", subtitle: "Make the most of your port day", icon: "ferry.fill", coverImage: "collection_cruise_must_dos.jpg", coverCategory: "tours", collectionKey: "cruise_must_dos"),
        CuratedCollection(id: "late_night", title: "Late Night", subtitle: "Where the island comes alive after dark", icon: "moon.stars.fill", coverImage: "collection_late_night.jpg", coverCategory: "nightlife", collectionKey: "late_night"),
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
                            NavigationLink(value: collection) {
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
        Color.riMint.opacity(0.15)
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
