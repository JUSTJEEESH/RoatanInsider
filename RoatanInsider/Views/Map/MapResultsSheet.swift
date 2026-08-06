import SwiftUI

/// What's under the current view of the map, as a list.
///
/// The standard move here is Apple's "search this area" button, but that
/// solves a problem this app doesn't have — the whole directory is already
/// loaded and the whole island fits on one screen. The useful version is the
/// other direction: pan to French Harbour, see that seven places are under
/// you, and get the list without pinch-hunting for each pin.
struct MapResultsSheet: View {
    let businesses: [Business]
    let diveSites: [DiveSite]

    @Environment(UnitPreference.self) private var units
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(businesses.enumerated()), id: \.element.id) { index, business in
                        if index > 0 {
                            Divider().overlay(Color.riDark.opacity(0.08))
                        }
                        NavigationLink(value: business) {
                            businessRow(business)
                        }
                        .buttonStyle(.plain)
                    }

                    ForEach(Array(diveSites.enumerated()), id: \.element.id) { index, site in
                        if index > 0 || !businesses.isEmpty {
                            Divider().overlay(Color.riDark.opacity(0.08))
                        }
                        NavigationLink(value: site) {
                            diveRow(site)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppConstants.Space.gutter)
                .padding(.bottom, AppConstants.Space.block)
            }
            .background(Color.riWhite)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Business.self) { BusinessDetailView(business: $0) }
            .navigationDestination(for: DiveSite.self) { DiveSiteDetailView(site: $0) }
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

    private var title: String {
        let total = businesses.count + diveSites.count
        return total == 1 ? "1 here" : "\(total) here"
    }

    private func businessRow(_ business: Business) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppConstants.Space.snug) {
            VStack(alignment: .leading, spacing: 3) {
                Text(business.name)
                    .riType(.heading)
                    .foregroundStyle(Color.riDark)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text("\(business.categoryDisplayName) · \(business.priceLabel)")
                    OpenStatusBadge(business: business)
                }
                .riType(.caption)
                .foregroundStyle(Color.riMediumGray)
                .lineLimit(1)
            }
            Spacer(minLength: AppConstants.Space.tight)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.riLightGray)
        }
        .padding(.vertical, AppConstants.Space.snug)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private func diveRow(_ site: DiveSite) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppConstants.Space.snug) {
            VStack(alignment: .leading, spacing: 3) {
                Text(site.name)
                    .riType(.heading)
                    .foregroundStyle(Color.riDark)
                    .lineLimit(1)
                Text(site.subtitle(useMetric: units.useMetric))
                    .riType(.caption)
                    .foregroundStyle(Color.riMediumGray)
                    .lineLimit(1)
            }
            Spacer(minLength: AppConstants.Space.tight)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.riLightGray)
        }
        .padding(.vertical, AppConstants.Space.snug)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
