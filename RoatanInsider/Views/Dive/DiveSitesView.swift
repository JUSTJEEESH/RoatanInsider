import SwiftUI

/// The reef, by name.
///
/// An Insider+ feature, per the call that the directory, map, events and
/// tools stay free forever and the things a diver would pay for on the day
/// they need them sit behind the wall. Non-members see the site count and
/// three names, which is enough to know what they'd be buying — a paywall
/// that shows nothing is just a locked door.
///
/// Hides itself entirely when no sites are loaded, so shipping the empty
/// file advertises nothing.
struct DiveSitesView: View {
    @Environment(DiveSitesService.self) private var diveSites
    @Environment(LocationManager.self) private var location
    @Environment(UnitPreference.self) private var units
    @Environment(PurchaseManager.self) private var purchases

    @State private var kind: DiveSiteKind?
    @State private var level: DiveLevel?
    @State private var shoreOnly = false
    @State private var showPaywall = false

    private var results: [DiveSite] {
        diveSites.filtered(
            kind: kind,
            level: level,
            shoreOnly: shoreOnly,
            near: location.userLocation
        )
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppConstants.Space.gutter) {
                header

                if purchases.hasPremium {
                    filters
                    list(results)
                } else {
                    preview
                }
            }
            .padding(.bottom, AppConstants.Space.block)
        }
        .navigationTitle("Dive sites")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.riWhite)
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .onAppear { Analytics.track(.homeSectionViewed(name: "dive_sites")) }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: AppConstants.Space.tight) {
            Text("THE REEF")
                .riType(.label)
                .foregroundStyle(Color.riMint)

            Text("\(diveSites.sites.count) sites, by name")
                .riType(.display)
                .foregroundStyle(Color.riDark)
                .fixedSize(horizontal: false, vertical: true)

            Text("Roatán sits on the second-largest barrier reef in the world. These are the places people come for — where they are, what you'll see, and who runs them.")
                .riType(.caption)
                .foregroundStyle(Color.riMediumGray)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, AppConstants.Space.gutter)
        .padding(.top, AppConstants.Space.snug)
    }

    // MARK: - Filters

    private var filters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppConstants.Space.tight) {
                if diveSites.hasShoreDives {
                    chip(label: "Shore dives", isOn: shoreOnly) { shoreOnly.toggle() }
                }
                ForEach(diveSites.availableLevels) { option in
                    chip(label: option.displayName, isOn: level == option) {
                        level = level == option ? nil : option
                    }
                }
                ForEach(diveSites.availableKinds) { option in
                    chip(label: option.displayName, isOn: kind == option) {
                        kind = kind == option ? nil : option
                    }
                }
            }
            .padding(.horizontal, AppConstants.Space.gutter)
        }
    }

    private func chip(label: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            withAnimation(.easeInOut(duration: 0.15)) { action() }
        } label: {
            Text(label)
                .riType(.caption, weight: isOn ? .semibold : .medium)
                .foregroundStyle(isOn ? .white : Color.riMediumGray)
                .padding(.horizontal, AppConstants.Space.snug + 2)
                .padding(.vertical, AppConstants.Space.tight)
                .background(isOn ? Color.riPink : Color.riOffWhite)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - List

    @ViewBuilder
    private func list(_ sites: [DiveSite]) -> some View {
        if sites.isEmpty {
            EmptyStateView(
                symbol: "water.waves",
                title: "Nothing matches that",
                message: "Try dropping a filter."
            )
        } else {
            VStack(spacing: 0) {
                ForEach(Array(sites.enumerated()), id: \.element.id) { index, site in
                    if index > 0 {
                        Divider().overlay(Color.riDark.opacity(0.08))
                    }
                    NavigationLink(value: site) {
                        row(site, isLocked: false)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppConstants.Space.gutter)
        }
    }

    /// `isLocked` swaps the chevron for a lock. A row that looks tappable
    /// and isn't is indistinguishable from a broken one — which is exactly
    /// how the locked preview read before.
    private func row(_ site: DiveSite, isLocked: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppConstants.Space.snug) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(site.name)
                        .riType(.heading)
                        .foregroundStyle(Color.riDark)
                        .lineLimit(1)
                    if site.shoreAccessible == true {
                        Text("SHORE")
                            .riType(.micro)
                            .foregroundStyle(Color.riMint)
                    }
                }
                Text(site.subtitle(useMetric: units.useMetric))
                    .riType(.caption)
                    .foregroundStyle(Color.riMediumGray)
                    .lineLimit(1)
            }

            Spacer(minLength: AppConstants.Space.tight)

            if let level = site.level {
                Text(level.displayName)
                    .riType(.caption)
                    .foregroundStyle(Color.riLightGray)
                    .layoutPriority(1)
            }

            Image(systemName: isLocked ? "lock" : "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.riLightGray)
        }
        .padding(.vertical, AppConstants.Space.snug)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint(isLocked ? "Insider+ required" : "")
    }

    // MARK: - Locked

    /// Names three sites and then stops. Someone deciding whether to pay
    /// needs to see the shape of what's inside, not a padlock.
    ///
    /// The rows are tappable and open the paywall. They used to carry a
    /// chevron and `allowsHitTesting(false)`, which is the worst of both:
    /// it looks like a link, does nothing when you press it, and gives you
    /// no idea why.
    private var preview: some View {
        VStack(alignment: .leading, spacing: AppConstants.Space.gutter) {
            VStack(spacing: 0) {
                ForEach(Array(diveSites.sites.prefix(3).enumerated()), id: \.element.id) { index, site in
                    if index > 0 {
                        Divider().overlay(Color.riDark.opacity(0.08))
                    }
                    Button {
                        Haptics.tap()
                        showPaywall = true
                    } label: {
                        row(site, isLocked: true)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, AppConstants.Space.gutter)

            VStack(alignment: .leading, spacing: AppConstants.Space.snug) {
                Text("\(max(0, diveSites.sites.count - 3)) more sites with Insider+")
                    .riType(.heading)
                    .foregroundStyle(Color.riDark)

                Text("Depths, levels, what's reachable from shore, and which shops run each site.")
                    .riType(.caption)
                    .foregroundStyle(Color.riMediumGray)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    Haptics.impact()
                    showPaywall = true
                } label: {
                    Text("See Insider+")
                        .riType(.body, weight: .semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: AppConstants.buttonHeight)
                        .background(Color.riPink)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.card, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppConstants.Space.gutter)
        }
    }
}
