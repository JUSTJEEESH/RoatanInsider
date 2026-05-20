import SwiftUI
import CoreLocation

/// Single business card with three layout styles. Replaces the trio of
/// near-duplicate views (BusinessCard / BusinessCardCompact / BusinessCardGrid)
/// — a future design tweak now touches one place, not three.
///
/// `darkStyle` is only meaningful for `.compact`; the other styles always
/// render light. Each card opts into the shared zoom namespace via
/// `@Environment(\.zoomNamespace)`, so the card-to-detail transition feels
/// like the photo expanded into the hero (iOS 18+; graceful slide on iOS 17).
struct BusinessCard: View {
    enum Style: Hashable {
        /// Full-width 16:9 photo. Used in lists and "Continue browsing" CTA areas.
        case full
        /// Fixed 260×180, 4:3. Used in horizontal scrolls (Featured, Right Now).
        case compact
        /// Flexible width, 4:3 photo. Used in the Explore 2-column grid.
        case grid
    }

    let business: Business
    var style: Style = .full
    var darkStyle: Bool = false

    @Environment(FavoritesStore.self) private var favoritesStore
    @Environment(LocationManager.self) private var locationManager
    @Environment(UnitPreference.self) private var unitPreference
    @Environment(\.zoomNamespace) private var zoomNS

    var body: some View {
        NavigationLink(value: business) {
            content
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(business.name), \(business.categoryDisplayName) in \(business.areaDisplayName), \(business.priceLabel)")
        .modifier(ZoomSourceModifier(id: business.id, namespace: zoomNS))
    }

    @ViewBuilder
    private var content: some View {
        switch style {
        case .full:    fullContent
        case .compact: compactContent
        case .grid:    gridContent
        }
    }

    // MARK: - Style: full

    private var fullContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                BusinessImageView(business: business, aspectRatio: 16/9)
                    .aspectRatio(16/9, contentMode: .fill)
                    .clipped()

                FavoriteButton(businessId: business.id)
                    .padding(12)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(business.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.riDark)
                    .lineLimit(1)

                metadataRow(fontSize: 14, ratingSize: 12)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .background(Color.riOffWhite)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius))
    }

    // MARK: - Style: compact

    private var compactContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                BusinessImageView(business: business, aspectRatio: 4/3)
                    .frame(width: 260, height: 180)

                FavoriteButton(businessId: business.id)
                    .padding(8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(business.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(darkStyle ? .white : Color.riDark)
                    .lineLimit(1)

                metadataRow(fontSize: 13, ratingSize: 11)
            }
            .padding(10)
        }
        .frame(width: 260)
        .background(darkStyle ? Color.riFixedDark : Color.riOffWhite)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius))
    }

    // MARK: - Style: grid

    private var gridContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                BusinessImageView(business: business, aspectRatio: 4/3)
                    .aspectRatio(4/3, contentMode: .fill)
                    .clipped()

                FavoriteButton(businessId: business.id)
                    .padding(8)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(business.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.riDark)
                    .lineLimit(1)

                metadataRow(fontSize: 12, ratingSize: 10)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
        }
        .background(Color.riOffWhite)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius))
    }

    // MARK: - Shared metadata

    private func metadataRow(fontSize: CGFloat, ratingSize: CGFloat) -> some View {
        HStack(spacing: 4) {
            if let rating = business.rating {
                RatingView(rating: rating, size: ratingSize)
            }
            Text(business.areaDisplayName)
            Text("·")
            Text(business.priceLabel)

            if let distance = distanceText {
                Text("·")
                Text(distance)
            }
        }
        .font(.riCaption(fontSize))
        .foregroundStyle(Color.riLightGray)
        .lineLimit(1)
    }

    private var distanceText: String? {
        guard let userLocation = locationManager.userLocation else { return nil }
        let businessLocation = CLLocation(latitude: business.latitude, longitude: business.longitude)
        let meters = userLocation.distance(from: businessLocation)
        return UnitPreference.formatDistance(meters: meters, useMetric: unitPreference.useMetric)
    }
}

// MARK: - Backwards-compatible factory shorthands

extension BusinessCard {
    /// Old `BusinessCardCompact(business:, darkStyle:)` call sites stay working
    /// — these factories let the new style enum land without touching every
    /// horizontal scroll in the app.
    static func compact(_ business: Business, darkStyle: Bool = false) -> BusinessCard {
        BusinessCard(business: business, style: .compact, darkStyle: darkStyle)
    }

    static func grid(_ business: Business) -> BusinessCard {
        BusinessCard(business: business, style: .grid)
    }
}

/// Deprecated shims so the rest of the codebase keeps compiling. New code
/// should use `BusinessCard(business:, style:)` directly.
@available(*, deprecated, message: "Use BusinessCard(business:, style: .compact, darkStyle:) instead.")
struct BusinessCardCompact: View {
    let business: Business
    var darkStyle: Bool = false

    var body: some View {
        BusinessCard(business: business, style: .compact, darkStyle: darkStyle)
    }
}

@available(*, deprecated, message: "Use BusinessCard(business:, style: .grid) instead.")
struct BusinessCardGrid: View {
    let business: Business

    var body: some View {
        BusinessCard(business: business, style: .grid)
    }
}
