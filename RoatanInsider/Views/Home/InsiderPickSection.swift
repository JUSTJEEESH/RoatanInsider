import SwiftUI

/// "Insider pick" — the screen's one editorial moment.
///
/// Replaces `InsiderPicksSection` (a rail of four cards) and
/// `InsiderTipsFeedSection` (a rail of tips). Both were rails of business
/// cards among six such rails, so neither read as special. One pick,
/// stated once, does.
///
/// The tip is the hero and the photo is evidence, not the other way round.
/// That's a deliberate inversion of the original photo-led spec: the
/// library is 269 mostly-workmanlike shots, and a workmanlike photo blown
/// up reads as louder, not better. The writing is the thing competitors
/// don't have, so the writing gets the large type and the photo gets a
/// tight 4:3 crop where "workmanlike" reads as fine.
///
/// Rotation is weekly and deterministic — derived from the ISO week, so
/// every user sees the same pick, it changes on Monday, and nothing needs
/// to be stored. Weekly rather than daily so 94 places last a year and a
/// half instead of three months.
struct InsiderPickSection: View {
    @Environment(DataManager.self) private var dataManager

    var body: some View {
        if let business = pick, let tip = business.insiderTip, !tip.isEmpty {
            VStack(alignment: .leading, spacing: AppConstants.Space.gutter) {
                Text("INSIDER PICK")
                    .riType(.label)
                    .foregroundStyle(Color.riMediumGray)

                // The tip, set large, with the mint rule this app already
                // uses to mark insider voice.
                HStack(alignment: .top, spacing: AppConstants.Space.snug) {
                    Rectangle()
                        .fill(Color.riMint)
                        .frame(width: 3)
                    Text(tip)
                        .riType(.title)
                        .foregroundStyle(Color.riDark)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .fixedSize(horizontal: false, vertical: true)

                NavigationLink(value: business) {
                    HStack(spacing: AppConstants.Space.snug) {
                        BusinessImageView(business: business, aspectRatio: 4/3)
                            .frame(width: 84, height: 63)
                            .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.small))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(business.name)
                                .riType(.heading)
                                .foregroundStyle(Color.riDark)
                                .lineLimit(1)
                            Text("\(business.categoryDisplayName) · \(business.areaDisplayName)")
                                .riType(.caption)
                                .foregroundStyle(Color.riMediumGray)
                                .lineLimit(1)
                        }

                        Spacer(minLength: AppConstants.Space.tight)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.riLightGray)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppConstants.Space.gutter)
            .onAppear { Analytics.track(.homeSectionViewed(name: "insider_pick")) }
        }
    }

    /// THE ROTATION — edit this list to change what can be featured.
    ///
    /// Hand-curated on purpose. Anything with `isInsiderPick` set used to be
    /// eligible, which meant the most prominent editorial slot on the app's
    /// front page was filled by whatever the data happened to flag. This is
    /// the one place a visitor reads a full sentence of Josh's writing, so
    /// it should be a deliberate shortlist.
    ///
    /// Order is the rotation order: the ISO week walks this list, so entry 0
    /// runs one week, entry 1 the next, wrapping at the end. A slug that
    /// doesn't match an active business is skipped silently, so removing a
    /// business from the data can't blank the section.
    static let curatedSlugs: [String] = [
        "salty-dawg",
        "native-sons-diving",
        "calelus",
        "punta-gorda-garifuna-nights",
        "roatan-chocolate-factory",
        "oak-ridge-snorkel-adventure",
        "island-brewing-roatan",
        "rusty-fish-recycled-art",
        "coxen-hole-municipal-market",
        "anthonys-chicken",
        "coconut-bar-coxen-hole",
        "roacrawl",
    ]

    /// How long each pick holds the slot. Three days keeps all twelve in
    /// rotation on a 36-day cycle, so a week-long visitor sees two or three
    /// different places and the section never looks static — while each
    /// pick still gets a fair showing. Change this one number to retune.
    static let rotationDays = 3

    /// Deterministic from the calendar, anchored to island time so the pick
    /// turns over at midnight in Roatán rather than mid-afternoon. Everyone
    /// sees the same pick on the same day with nothing stored.
    static func pick(from businesses: [Business], on date: Date = .now) -> Business? {
        let bySlug = Dictionary(
            businesses.map { ($0.slug, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let eligible = curatedSlugs
            .compactMap { bySlug[$0] }
            .filter { !($0.insiderTip ?? "").isEmpty }
        guard !eligible.isEmpty else { return nil }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Tegucigalpa") ?? .current
        guard let epoch = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1)) else {
            return eligible.first
        }
        let days = calendar.dateComponents([.day], from: epoch, to: date).day ?? 0

        // floorDiv + non-negative modulo so dates before the epoch (a device
        // with its clock set back) still land on a valid entry.
        let slot = Int((Double(days) / Double(rotationDays)).rounded(.down))
        let index = ((slot % eligible.count) + eligible.count) % eligible.count
        return eligible[index]
    }

    private var pick: Business? {
        Self.pick(from: dataManager.activeBusinesses)
    }
}
