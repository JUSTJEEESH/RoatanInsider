import SwiftUI
import CoreLocation

/// "I'm standing here — what's within walking distance, and is it open?"
///
/// This island has no street addresses, which is why every listing carries a
/// landmark description instead. Proximity isn't a convenience feature here
/// the way it is in a city app; it's how anyone orients at all. Until now
/// distance appeared as the third item on a card's metadata line and as a
/// sort option, and neither answers the question someone actually has when
/// they stop walking and open their phone.
///
/// Banded rather than ranked, because "eight minutes away" and "twelve
/// minutes away" are the same decision, while "on this street" and "you'll
/// want a taxi" are not.
struct NearbySheet: View {
    let businesses: [Business]

    @Environment(LocationManager.self) private var location
    @Environment(UnitPreference.self) private var units
    @Environment(\.dismiss) private var dismiss

    @State private var openOnly = true

    /// Roughly a five-minute walk, a fifteen-minute walk, and everything
    /// else on the island.
    private static let bands: [(label: String, detail: String, limit: CLLocationDistance)] = [
        ("RIGHT HERE", "A few minutes on foot", 400),
        ("A SHORT WALK", "Ten to fifteen minutes", 1_200),
        ("WORTH A RIDE", "You'll want a taxi", 8_000),
    ]

    var body: some View {
        NavigationStack {
            Group {
                if location.userLocation == nil {
                    locationOff
                } else if banded.allSatisfy(\.places.isEmpty) {
                    EmptyStateView(
                        symbol: "location.slash",
                        title: openOnly ? "Nothing open near you" : "Nothing close by",
                        message: openOnly
                            ? "Try turning off \"Open now\" — there may be places nearby that are shut at the moment."
                            : "You're a way from the main stretches. The map will show you what's out here."
                    )
                } else {
                    list
                }
            }
            .background(Color.riWhite)
            .navigationTitle("Near me")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.riDark)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - List

    private var list: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppConstants.Space.block) {
                Toggle(isOn: $openOnly) {
                    Text("Open now")
                        .riType(.body, weight: .medium)
                        .foregroundStyle(Color.riDark)
                }
                .tint(Color.riMint)
                .padding(.horizontal, AppConstants.Space.gutter)
                .padding(.top, AppConstants.Space.snug)

                ForEach(banded, id: \.label) { band in
                    if !band.places.isEmpty {
                        VStack(alignment: .leading, spacing: AppConstants.Space.snug) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(band.label)
                                    .riType(.label)
                                    .foregroundStyle(Color.riMediumGray)
                                Text(band.detail)
                                    .riType(.caption)
                                    .foregroundStyle(Color.riLightGray)
                            }

                            VStack(spacing: 0) {
                                ForEach(Array(band.places.enumerated()), id: \.element.business.id) { index, item in
                                    if index > 0 {
                                        Divider().overlay(Color.riDark.opacity(0.08))
                                    }
                                    NavigationLink(value: item.business) {
                                        row(item)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal, AppConstants.Space.gutter)
                    }
                }
            }
            .padding(.bottom, AppConstants.Space.block)
        }
        .navigationDestination(for: Business.self) { business in
            BusinessDetailView(business: business)
        }
    }

    private func row(_ item: Nearby) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppConstants.Space.snug) {
            VStack(alignment: .leading, spacing: 3) {
                Text(item.business.name)
                    .riType(.heading)
                    .foregroundStyle(Color.riDark)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(item.business.categoryDisplayName)
                    OpenStatusBadge(business: item.business)
                }
                .riType(.caption)
                .foregroundStyle(Color.riMediumGray)
                .lineLimit(1)
            }

            Spacer(minLength: AppConstants.Space.tight)

            Text(UnitPreference.formatDistance(meters: item.metres, useMetric: units.useMetric))
                .riType(.caption, weight: .semibold)
                .monospacedDigit()
                .foregroundStyle(Color.riLightGray)
                .layoutPriority(1)
        }
        .padding(.vertical, AppConstants.Space.snug)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private var locationOff: some View {
        EmptyStateView(
            symbol: "location.slash",
            title: "Location is off",
            message: "Turn on location and this becomes a list of what's within walking distance of wherever you're standing.",
            ctaLabel: "Open Settings",
            ctaAction: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        )
    }

    // MARK: - Data

    private struct Nearby {
        let business: Business
        let metres: CLLocationDistance
    }

    private struct Band {
        let label: String
        let detail: String
        let places: [Nearby]
    }

    /// Each place lands in exactly one band — the first whose limit it is
    /// inside — so nothing is listed twice.
    private var banded: [Band] {
        guard let here = location.userLocation else { return [] }

        let candidates = businesses
            .filter { $0.isActive }
            .filter { !openOnly || !$0.hasKnownHours || $0.isOpenNow() }
            .map { business in
                Nearby(
                    business: business,
                    metres: here.distance(from: CLLocation(
                        latitude: business.latitude, longitude: business.longitude
                    ))
                )
            }
            .sorted { $0.metres < $1.metres }

        var remaining = candidates
        return Self.bands.map { band in
            let inside = remaining.filter { $0.metres <= band.limit }
            remaining.removeAll { $0.metres <= band.limit }
            return Band(label: band.label, detail: band.detail, places: Array(inside.prefix(12)))
        }
    }
}
