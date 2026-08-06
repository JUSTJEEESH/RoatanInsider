import SwiftUI
import MapKit

/// One dive site.
///
/// Ordered by what a diver decides with: can I do it, how deep, do I need a
/// boat — then what it's actually like, then who takes you. Every block
/// disappears when its data is missing, so a half-recorded site reads as a
/// short entry rather than a form with holes in it.
struct DiveSiteDetailView: View {
    let site: DiveSite

    @Environment(DiveSitesService.self) private var diveSites
    @Environment(DataManager.self) private var dataManager
    @Environment(UnitPreference.self) private var units

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppConstants.Space.block) {
                header
                facts
                summaryBlock
                tipBlock
                lifeBlock
                operatorsBlock
                mapBlock
            }
            .padding(.bottom, AppConstants.Space.block)
        }
        .navigationTitle(site.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.riWhite)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: AppConstants.Space.tight) {
            Text(site.areaDisplayName.uppercased())
                .riType(.label)
                .foregroundStyle(Color.riMint)

            Text(site.name)
                .riType(.display)
                .foregroundStyle(Color.riDark)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, AppConstants.Space.gutter)
        .padding(.top, AppConstants.Space.snug)
    }

    // MARK: - The facts a diver checks first

    @ViewBuilder
    private var facts: some View {
        let items = factItems
        if !items.isEmpty {
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    if index > 0 {
                        Divider().overlay(Color.riDark.opacity(0.08))
                    }
                    HStack(alignment: .firstTextBaseline, spacing: AppConstants.Space.snug) {
                        Text(item.label)
                            .riType(.caption)
                            .foregroundStyle(Color.riMediumGray)
                            .frame(width: 92, alignment: .leading)
                        Text(item.value)
                            .riType(.body, weight: .medium)
                            .foregroundStyle(Color.riDark)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, AppConstants.Space.snug)
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.horizontal, AppConstants.Space.gutter)
        }
    }

    /// Only what's recorded. Depth and level are safety information — a
    /// missing one is left out rather than filled with a plausible default.
    private var factItems: [(label: String, value: String)] {
        var items: [(String, String)] = []
        if let kind = site.kind { items.append(("Type", kind.displayName)) }
        if let depth = site.depthLabel(useMetric: units.useMetric) {
            items.append(("Depth", depth))
        }
        if let level = site.level {
            items.append(("Level", "\(level.displayName) — \(level.explanation)"))
        }
        if let shore = site.shoreAccessible {
            items.append(("Access", shore ? "Reachable from shore" : "Boat dive"))
        }
        return items
    }

    // MARK: - Words

    @ViewBuilder
    private var summaryBlock: some View {
        if let summary = site.summary, !summary.isEmpty {
            Text(summary)
                .riType(.body)
                .foregroundStyle(Color.riMediumGray)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, AppConstants.Space.gutter)
        }
    }

    @ViewBuilder
    private var tipBlock: some View {
        if let tip = site.insiderTip, !tip.isEmpty {
            HStack(alignment: .top, spacing: AppConstants.Space.snug) {
                Rectangle()
                    .fill(Color.riMint)
                    .frame(width: 3)
                VStack(alignment: .leading, spacing: AppConstants.Space.hair) {
                    Text("Insider tip")
                        .riType(.caption, weight: .semibold)
                        .foregroundStyle(Color.riMint)
                    Text(tip)
                        .riType(.body)
                        .foregroundStyle(Color.riDark)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, AppConstants.Space.gutter)
        }
    }

    @ViewBuilder
    private var lifeBlock: some View {
        if !site.marineLife.isEmpty {
            VStack(alignment: .leading, spacing: AppConstants.Space.snug) {
                Text("WHAT YOU'LL SEE")
                    .riType(.label)
                    .foregroundStyle(Color.riMediumGray)

                FlowLayout(spacing: AppConstants.Space.tight) {
                    ForEach(site.marineLife, id: \.self) { creature in
                        Text(creature)
                            .riType(.caption)
                            .foregroundStyle(Color.riMediumGray)
                            .padding(.horizontal, AppConstants.Space.snug)
                            .padding(.vertical, 6)
                            .background(Color.riOffWhite)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, AppConstants.Space.gutter)
        }
    }

    // MARK: - Who takes you

    @ViewBuilder
    private var operatorsBlock: some View {
        let shops = diveSites.operators(for: site, in: dataManager.businesses)
        if !shops.isEmpty {
            VStack(alignment: .leading, spacing: AppConstants.Space.snug) {
                Text("WHO RUNS IT")
                    .riType(.label)
                    .foregroundStyle(Color.riMediumGray)

                VStack(spacing: 0) {
                    ForEach(Array(shops.enumerated()), id: \.element.id) { index, shop in
                        if index > 0 {
                            Divider().overlay(Color.riDark.opacity(0.08))
                        }
                        NavigationLink(value: shop) {
                            HStack(spacing: AppConstants.Space.snug) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(shop.name)
                                        .riType(.body, weight: .semibold)
                                        .foregroundStyle(Color.riDark)
                                        .lineLimit(1)
                                    Text(shop.areaDisplayName)
                                        .riType(.caption)
                                        .foregroundStyle(Color.riMediumGray)
                                }
                                Spacer(minLength: AppConstants.Space.tight)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color.riLightGray)
                            }
                            .padding(.vertical, AppConstants.Space.snug)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, AppConstants.Space.gutter)
        }
    }

    // MARK: - Where

    private var mapBlock: some View {
        VStack(alignment: .leading, spacing: AppConstants.Space.snug) {
            Text("WHERE IT IS")
                .riType(.label)
                .foregroundStyle(Color.riMediumGray)

            Map(initialPosition: .region(MKCoordinateRegion(
                center: site.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
            ))) {
                Marker(site.name, systemImage: site.kind?.iconName ?? "water.waves",
                       coordinate: site.coordinate)
                    .tint(Color.riPink)
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.card, style: .continuous))
            .allowsHitTesting(false)

            Text("Approximate — for orientation, not navigation. Your boat captain knows the mooring.")
                .riType(.caption)
                .foregroundStyle(Color.riLightGray)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, AppConstants.Space.gutter)
    }
}
