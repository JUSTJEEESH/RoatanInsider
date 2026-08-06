import SwiftUI
import CoreLocation

/// Single business card with three layout styles.
///
/// The photo is the card. There is no filled panel behind the text and no
/// rounded rectangle around the whole thing — the name and its one metadata
/// line sit directly on the page, the way Airbnb and Apple set a grid. The
/// old version wrapped every card in an off-white box, which is what made a
/// screen of them read as a template: twelve identical grey rectangles
/// competing with twelve photos.
///
/// One metadata line, and it is ranked, not concatenated. Area and price are
/// always there because they are how someone decides; rating and distance
/// join only when we actually know them. The old row printed four items
/// unconditionally and truncated on narrow cards.
///
/// `darkStyle` is only meaningful for `.compact`; the other styles always
/// render on the page ground. Each card opts into the shared zoom namespace
/// via `@Environment(\.zoomNamespace)`, so the card-to-detail transition
/// feels like the photo expanded into the hero (iOS 18+; graceful slide on
/// iOS 17).
struct BusinessCard: View {
    enum Style: Hashable {
        /// Full-width 16:9 photo. Used in lists and "Continue browsing" CTA areas.
        case full
        /// Fixed 260-wide, 4:3. Used in horizontal scrolls (Featured, Right Now).
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
        .accessibilityLabel(accessibilityDescription)
        .modifier(ZoomSourceModifier(id: business.id, namespace: zoomNS))
    }

    @ViewBuilder
    private var content: some View {
        switch style {
        case .full:    card(aspect: 16/9, titleLines: 1, width: nil)
        case .compact: card(aspect: 4/3, titleLines: 2, width: 260)
        case .grid:    card(aspect: 4/3, titleLines: 2, width: nil)
        }
    }

    // MARK: - One card, three proportions

    private func card(aspect: CGFloat, titleLines: Int, width: CGFloat?) -> some View {
        VStack(alignment: .leading, spacing: AppConstants.Space.snug) {
            ZStack(alignment: .topTrailing) {
                photo(aspect: aspect, width: width)

                FavoriteButton(businessId: business.id)
                    .padding(AppConstants.Space.tight)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(business.name)
                    .riType(style == .full ? .heading : .body, weight: .semibold)
                    .foregroundStyle(darkStyle ? .white : Color.riDark)
                    .lineLimit(titleLines)
                    // Reserving the second line keeps a grid row's photos on
                    // one baseline whether or not a name wraps.
                    .frame(
                        minHeight: titleLines > 1 ? twoLineHeight : nil,
                        alignment: .topLeading
                    )
                    .fixedSize(horizontal: false, vertical: true)

                metadataRow
            }
        }
        .frame(width: width)
    }

    /// `BusinessImageView` expands to whatever it is given, so the frame has
    /// to come from here. A transparent shape holds the aspect ratio and the
    /// photo fills it — the reliable way to get a proportional box in a
    /// flexible-width column, where `.aspectRatio(_, contentMode: .fill)` on
    /// the image itself leaves the height unresolved.
    private func photo(aspect: CGFloat, width: CGFloat?) -> some View {
        Color.clear
            .aspectRatio(aspect, contentMode: .fit)
            .frame(width: width, height: width.map { $0 / aspect })
            .overlay {
                BusinessImageView(business: business, aspectRatio: aspect)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.card, style: .continuous))
    }

    private var twoLineHeight: CGFloat { RIType.body.size * 2 * 1.2 }

    // MARK: - Metadata

    /// Area and price always; rating and distance only when known. Joined
    /// with middots at render time so an unknown value leaves no orphaned
    /// separator behind it.
    private var metadataRow: some View {
        HStack(spacing: AppConstants.Space.hair) {
            if let rating = business.rating {
                RatingView(rating: rating, size: 11)
                Text("·")
            }
            Text(metadataText)
        }
        .riType(.caption)
        .foregroundStyle(darkStyle ? Color.white.opacity(0.6) : Color.riLightGray)
        .lineLimit(1)
    }

    private var metadataText: String {
        var parts = [business.areaDisplayName, business.priceLabel]
        if let distance = distanceText { parts.append(distance) }
        return parts.joined(separator: " · ")
    }

    private var distanceText: String? {
        guard let userLocation = locationManager.userLocation else { return nil }
        let businessLocation = CLLocation(latitude: business.latitude, longitude: business.longitude)
        let meters = userLocation.distance(from: businessLocation)
        return UnitPreference.formatDistance(meters: meters, useMetric: unitPreference.useMetric)
    }

    private var accessibilityDescription: String {
        var parts = [
            business.name,
            business.categoryDisplayName,
            "in \(business.areaDisplayName)",
            business.priceLabel,
        ]
        if let distance = distanceText { parts.append(distance) }
        return parts.joined(separator: ", ")
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
