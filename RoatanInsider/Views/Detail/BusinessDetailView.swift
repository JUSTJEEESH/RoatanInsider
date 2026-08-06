import SwiftUI
import MapKit
import CoreLocation

struct BusinessDetailView: View {
    let business: Business
    @Environment(FavoritesStore.self) private var favoritesStore
    @Environment(DataManager.self) private var dataManager
    @Environment(RecentlyViewedStore.self) private var recentlyViewed
    @Environment(DiveSitesService.self) private var diveSites
    @Environment(LocationManager.self) private var locationManager
    @Environment(\.zoomNamespace) private var zoomNS

    /// Always use the latest version from DataManager (picks up remote updates)
    private var b: Business {
        dataManager.business(withId: business.id) ?? business
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Hero image — parallax: stretches when pulled, scrolls at
                // half rate when reading. `.visualEffect` keeps layout stable
                // (other content doesn't shift); only the rendered transform
                // changes.
                PhotoGallery(images: b.images, categoryIconName: b.categoryIconName, categoryDisplayName: b.categoryDisplayName, slug: b.slug)
                    .visualEffect { content, proxy in
                        let minY = proxy.frame(in: .scrollView).minY
                        let stretch = max(0, minY)
                        let parallax = min(0, minY) * 0.5
                        return content
                            .scaleEffect(1 + stretch / 600, anchor: .top)
                            .offset(y: parallax)
                    }

                VStack(alignment: .leading, spacing: 20) {
                    // Title section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(b.name)
                                .riType(.title)
                                .foregroundStyle(Color.riDark)

                            Spacer()

                            FavoriteButton(businessId: b.id, onPhoto: false)
                        }

                        HStack(spacing: 6) {
                            Text(b.allCategories.map { $0.categoryDisplayName }.joined(separator: " · "))
                            Text("·")
                            Text(b.allAreaStrings.map { $0.replacingOccurrences(of: "_", with: " ").capitalized }.joined(separator: " · "))
                        }
                        .riType(.caption)
                        .foregroundStyle(Color.riLightGray)

                        if b.allCategories.count > 1 {
                            FlowLayout(spacing: 6) {
                                ForEach(b.allCategories, id: \.self) { entry in
                                    HStack(spacing: 4) {
                                        Image(systemName: entry.categoryIconName)
                                            .font(.system(size: 11))
                                        Text(entry.subcategory)
                                    }
                                    .riType(.label)
                                    .foregroundStyle(Color.riMediumGray)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.riOffWhite)
                                    .clipShape(Capsule())
                                }
                            }
                        }

                        // The decision line. Someone opens this page asking
                        // two things — should I go, and how far is it — and
                        // both used to be scattered: price here, hours four
                        // hundred points down, distance nowhere at all.
                        HStack(spacing: 12) {
                            if let rating = b.rating {
                                HStack(spacing: 4) {
                                    RatingView(rating: rating, size: 14)

                                    if let count = b.reviewCount, count > 0 {
                                        Text("(\(count))")
                                            .riType(.caption)
                                            .foregroundStyle(Color.riLightGray)
                                    }
                                }
                            }
                            PriceRangeView(priceRange: b.priceRange)
                            OpenStatusBadge(business: b)
                            if let travel = TravelEstimate.label(to: b, from: locationManager.userLocation) {
                                Text(travel)
                                    .riType(.caption)
                                    .foregroundStyle(Color.riMediumGray)
                                    .lineLimit(1)
                            }
                        }
                    }

                    happyHourLine(b)

                    // Description
                    Text(b.description)
                        .riType(.body)
                        .foregroundStyle(Color.riMediumGray)
                        .lineSpacing(6)

                    // Insider Tip
                    if let tip = b.insiderTip {
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.riMint)
                                .frame(width: 3)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Insider Tip")
                                    .riType(.caption, weight: .semibold)
                                    .foregroundStyle(Color.riMint)

                                Text(tip)
                                    .riType(.caption)
                                    .foregroundStyle(Color.riMediumGray)
                                    .italic()
                            }
                            .padding(.leading, 12)
                        }
                    }

                    diveSitesBlock(b)

                    // Reactions
                    ReactionStrip(businessId: b.id)

                    // Features
                    if !b.features.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Features")
                                .riType(.body, weight: .semibold)
                                .foregroundStyle(Color.riDark)

                            FlowLayout(spacing: 8) {
                                ForEach(b.features, id: \.self) { feature in
                                    Text(feature)
                                        .riType(.caption)
                                        .foregroundStyle(Color.riMediumGray)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.riOffWhite)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    // Contact actions
                    ContactActions(business: b)

                    // Hours
                    if !b.hours.isEmpty {
                        hoursSection
                    } else if let hoursText = b.hoursText {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Hours")
                                .riType(.body, weight: .semibold)
                                .foregroundStyle(Color.riDark)

                            Text(hoursText)
                                .riType(.caption)
                                .foregroundStyle(Color.riMediumGray)
                        }
                    }

                    // Location(s)
                    VStack(alignment: .leading, spacing: 12) {
                        Text(b.allLocations.count > 1 ? "Locations" : "Location")
                            .riType(.body, weight: .semibold)
                            .foregroundStyle(Color.riDark)

                        ForEach(b.allLocations, id: \.self) { location in
                            VStack(alignment: .leading, spacing: 8) {
                                if b.allLocations.count > 1 {
                                    Text(location.area.displayName)
                                        .riType(.caption, weight: .medium)
                                        .foregroundStyle(Color.riDark)
                                }

                                Text(location.addressDescription)
                                    .riType(.caption)
                                    .foregroundStyle(Color.riMediumGray)

                                MiniMapView(coordinate: location.coordinate, name: b.name)
                                    .frame(height: 180)
                                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.card, style: .continuous))
                            }
                        }
                    }

                    nearbyBlock(b)
                }
                .padding(AppConstants.Space.gutter)
            }
        }
        .background(Color.riWhite)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .modifier(ZoomDestinationModifier(id: b.id, namespace: zoomNS))
        .onAppear {
            recentlyViewed.record(b.id)
            Analytics.track(.businessOpened(id: b.id, source: "detail"))
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Group {
                    // Share a link when there's a real destination; share the
                    // write-up alone when there isn't. Never a dead URL.
                    if let url = AppConstants.businessShareURL(slug: b.slug) {
                        ShareLink(
                            item: url,
                            subject: Text(b.name),
                            message: Text(shareMessage),
                            preview: SharePreview(b.name, image: shareCardImage ?? Image(systemName: "palm.tree"))
                        ) {
                            shareIcon
                        }
                    } else {
                        ShareLink(
                            item: shareMessage,
                            subject: Text(b.name),
                            preview: SharePreview(b.name, image: shareCardImage ?? Image(systemName: "palm.tree"))
                        ) {
                            shareIcon
                        }
                    }
                }
                .accessibilityLabel("Share \(b.name)")
                .simultaneousGesture(TapGesture().onEnded { Haptics.impact() })
            }
        }
    }

    private var shareIcon: some View {
        Image(systemName: "square.and.arrow.up")
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(Color.riDark)
    }

    private var shareMessage: String {
        "\(b.name) — \(b.categoryDisplayName) in \(b.areaDisplayName). \(b.insiderTip ?? String(b.description.prefix(100)))"
    }

    private var shareCardImage: Image? {
        guard let ui = ShareHelper.shareImage(for: b) else { return nil }
        return Image(uiImage: ui)
    }

    /// What else is within a few minutes of here.
    ///
    /// The page had no idea what surrounded it, which is a strange thing for
    /// a page about a place on a small island. Someone reading about a West
    /// End restaurant obviously wants the bar two doors down — and this is
    /// the single best way to keep them moving through the app rather than
    /// bouncing back to a list.
    ///
    /// Walking distance only. A "nearby" list that reaches across the island
    /// is just the directory again.
    @ViewBuilder
    private func nearbyBlock(_ b: Business) -> some View {
        let neighbours = nearby(to: b)
        if !neighbours.isEmpty {
            VStack(alignment: .leading, spacing: AppConstants.Space.snug) {
                Text("A FEW MINUTES AWAY")
                    .riType(.label)
                    .foregroundStyle(Color.riMediumGray)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: AppConstants.Space.snug) {
                        ForEach(neighbours) { neighbour in
                            BusinessCard(business: neighbour, style: .compact)
                        }
                    }
                }
                // Let the rail bleed past the page's gutter the way the
                // horizontal rails elsewhere do, instead of stopping short.
                .padding(.horizontal, -AppConstants.Space.gutter)
                .padding(.leading, AppConstants.Space.gutter)
            }
        }
    }

    /// Closest first, capped at a walk. 700m is about ten minutes on foot,
    /// which on this island usually means "the same stretch of road".
    private func nearby(to business: Business) -> [Business] {
        let origin = CLLocation(latitude: business.latitude, longitude: business.longitude)
        return dataManager.activeBusinesses
            .filter { $0.id != business.id }
            .map { ($0, origin.distance(from: CLLocation(latitude: $0.latitude, longitude: $0.longitude))) }
            .filter { $0.1 <= 700 }
            .sorted { $0.1 < $1.1 }
            .prefix(6)
            .map(\.0)
    }

    /// The sites this shop runs — the other half of the link that makes a
    /// dive site entry worth having. Absent for every business that isn't a
    /// dive shop, and for any shop we haven't recorded sites against.
    @ViewBuilder
    private func diveSitesBlock(_ b: Business) -> some View {
        let sites = diveSites.sites(runBy: b.slug)
        if !sites.isEmpty {
            VStack(alignment: .leading, spacing: AppConstants.Space.snug) {
                Text("SITES THEY RUN")
                    .riType(.label)
                    .foregroundStyle(Color.riMediumGray)

                FlowLayout(spacing: AppConstants.Space.tight) {
                    ForEach(sites) { site in
                        NavigationLink(value: site) {
                            Text(site.name)
                                .riType(.caption, weight: .medium)
                                .foregroundStyle(Color.riDark)
                                .padding(.horizontal, AppConstants.Space.snug)
                                .padding(.vertical, 6)
                                .background(Color.riOffWhite)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    /// Happy hour, stated near the top because it's time-sensitive — it
    /// changes whether you leave now or after dinner. Mint when it's
    /// actually running, plain grey the rest of the day; nothing at all when
    /// we don't hold the times, which is most places.
    @ViewBuilder
    private func happyHourLine(_ b: Business) -> some View {
        if let hh = b.happyHour {
            let isOn = b.isHappyHourNow()
            HStack(spacing: 6) {
                if isOn {
                    Circle().fill(Color.riMint).frame(width: 6, height: 6)
                }
                Text(isOn
                     ? "Happy hour on now, \(hh.untilLabel)"
                     : "Happy hour \(hh.fullLabel)")
                    .riType(.caption, weight: isOn ? .semibold : .regular)
                    .foregroundStyle(isOn ? Color.riMint : Color.riMediumGray)
                if let note = hh.note, !note.isEmpty {
                    Text("· \(note)")
                        .riType(.caption)
                        .foregroundStyle(Color.riMediumGray)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }

    private var hoursSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Hours")
                .riType(.body, weight: .semibold)
                .foregroundStyle(Color.riDark)

            let days = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
            let today = Date().currentDayKey

            ForEach(days, id: \.self) { day in
                HStack {
                    Text(day.capitalized)
                        .riType(.caption)
                        .fontWeight(day == today ? .semibold : .regular)
                        .foregroundStyle(day == today ? Color.riDark : Color.riMediumGray)
                        .frame(width: 100, alignment: .leading)

                    if let hours = b.hours[day] ?? nil {
                        Text("\(formatTime(hours.open)) – \(formatTime(hours.close))")
                            .riType(.caption)
                            .foregroundStyle(day == today ? Color.riDark : Color.riLightGray)
                    } else {
                        Text("Closed")
                            .riType(.caption)
                            .foregroundStyle(Color.riLightGray)
                    }
                }
            }
        }
    }

    /// Converts "14:00" to "2:00 PM", "08:00" to "8:00 AM"
    private func formatTime(_ time: String) -> String {
        let parts = time.split(separator: ":")
        guard parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]) else { return time }

        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        if minute == 0 {
            return "\(displayHour) \(period)"
        }
        return "\(displayHour):\(String(format: "%02d", minute)) \(period)"
    }
}

// Simple flow layout for feature tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
