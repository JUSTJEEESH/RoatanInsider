import SwiftUI

/// The deeper reading, at the bottom of Home where it belongs — nobody
/// opens a travel app to read a guide first.
///
/// Four hairline rows, matching Today. Each guide used to be a dark card
/// carrying a mint glyph in a tinted rounded square; four of those stacked
/// read as a settings screen dropped into the middle of a travel app, and
/// the icon-in-a-tinted-box is the pattern this redesign is systematically
/// removing. What's left is a title, a line saying what's inside, and a
/// chevron — which is all a link needs to be.
struct QuickGuidesSection: View {
    @Environment(DiveSitesService.self) private var diveSites

    private struct Guide: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let destination: Destination

        enum Destination { case cruise, areas, essentials, askALocal, diveSites }
    }

    /// Dive sites appear only once there are sites loaded — an entry point
    /// to an empty screen is worse than no entry point.
    private var guides: [Guide] {
        var list = Self.always
        if diveSites.hasSites {
            list.insert(
                .init(title: "Dive Sites",
                      subtitle: "\(diveSites.sites.count) named sites on the reef.",
                      destination: .diveSites),
                at: 1
            )
        }
        return list
    }

    private static let always: [Guide] = [
        .init(title: "Cruise Day Guide",
              subtitle: "Six hours ashore, planned by port.",
              destination: .cruise),
        .init(title: "Area Guides",
              subtitle: "What each stretch of the island is actually like.",
              destination: .areas),
        .init(title: "Island Essentials",
              subtitle: "Money, safety, water, language.",
              destination: .essentials),
        .init(title: "Ask a Local",
              subtitle: "The fifteen questions every visitor asks.",
              destination: .askALocal),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.Space.snug) {
            Text("GUIDES")
                .riType(.label)
                .foregroundStyle(Color.riMediumGray)

            VStack(spacing: 0) {
                ForEach(Array(guides.enumerated()), id: \.element.id) { index, guide in
                    if index > 0 {
                        Divider().overlay(Color.riDark.opacity(0.08))
                    }
                    NavigationLink {
                        destinationView(for: guide.destination)
                    } label: {
                        row(guide)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, AppConstants.Space.gutter)
        .onAppear { Analytics.track(.homeSectionViewed(name: "guides")) }
    }

    private func row(_ guide: Guide) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppConstants.Space.snug) {
            VStack(alignment: .leading, spacing: 3) {
                Text(guide.title)
                    .riType(.heading)
                    .foregroundStyle(Color.riDark)
                Text(guide.subtitle)
                    .riType(.caption)
                    .foregroundStyle(Color.riMediumGray)
                    .fixedSize(horizontal: false, vertical: true)
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

    @ViewBuilder
    private func destinationView(for destination: Guide.Destination) -> some View {
        switch destination {
        case .cruise:     CruiseDayGuideView()
        case .areas:      AreaGuideView()
        case .essentials: IslandEssentialsView()
        case .askALocal:  AskALocalView()
        case .diveSites:  DiveSitesView()
        }
    }
}
