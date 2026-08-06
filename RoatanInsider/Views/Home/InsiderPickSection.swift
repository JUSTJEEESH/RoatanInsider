import SwiftUI
import CoreLocation

/// "Insider pick" — the screen's one editorial moment.
///
/// The tip is the hero and the photo is evidence, not the other way round.
/// That's a deliberate inversion of the original photo-led spec: the library
/// is 269 mostly-workmanlike shots, and a workmanlike photo blown up reads
/// as louder, not better. The writing is the thing competitors don't have,
/// so the writing gets the large type and the photo gets a tight 4:3 crop
/// where "workmanlike" reads as fine.
///
/// Two pools, weighted four to one. The single list that came before was
/// half places an hour's drive east, which meant the app's most prominent
/// recommendation sent people across the island every other week — while
/// 80% of the directory, and virtually every visitor, sits in the West End
/// and West Bay corridor. A place that takes an hour to reach can still be
/// the right answer; it just can't be the answer half the time.
///
/// And whichever pool it draws from, the card states what the trip costs.
/// A recommendation that hides its distance isn't a recommendation, it's a
/// surprise.
struct InsiderPickSection: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(LocationManager.self) private var location

    var body: some View {
        if let selection = pick, let tip = selection.business.insiderTip, !tip.isEmpty {
            VStack(alignment: .leading, spacing: AppConstants.Space.gutter) {
                Text(selection.isWorthTheTrip ? "WORTH THE TRIP" : "INSIDER PICK")
                    .riType(.label)
                    .foregroundStyle(selection.isWorthTheTrip ? Color.riMint : Color.riMediumGray)

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

                NavigationLink(value: selection.business) {
                    HStack(spacing: AppConstants.Space.snug) {
                        BusinessImageView(business: selection.business, aspectRatio: 4/3)
                            .frame(width: 84, height: 63)
                            .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.small, style: .continuous))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(selection.business.name)
                                .riType(.heading)
                                .foregroundStyle(Color.riDark)
                                .lineLimit(1)
                            Text(subtitleLine(for: selection.business))
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

    // MARK: - The rotation
    //
    // Hand-curated on purpose. Anything with `isInsiderPick` set used to be
    // eligible, which meant the most prominent editorial slot on the app's
    // front page was filled by whatever the data happened to flag. This is
    // the one place a visitor reads a full sentence of Josh's writing, so it
    // should be a deliberate shortlist.
    //
    // Order is rotation order within each pool. A slug that doesn't match an
    // active business is skipped silently, so removing a business from the
    // data can't blank the section.

    /// The West End / West Bay / Sandy Bay corridor, where nearly everyone
    /// staying on this island actually is.
    static let nearbySlugs: [String] = [
        "sundowners-bar-grill",
        "native-sons-diving",
        "calelus",
        "west-bay-water-taxi",
        "roatan-chocolate-factory",
        "la-placita",
        "rusty-fish-recycled-art",
        "coconut-tree-divers",
        "anthonys-chicken",
        "west-bay-beach-bonfire",
        "pazzo-italian",
        "roacrawl",
    ]

    /// The rest of the island — genuinely worth the drive, and shown as the
    /// exception rather than the rule.
    static let worthTheTripSlugs: [String] = [
        "salty-dawg",
        "punta-gorda-garifuna-nights",
        "oak-ridge-snorkel-adventure",
        "coxen-hole-municipal-market",
        "island-brewing-roatan",
        "coconut-bar-coxen-hole",
    ]

    /// How long each pick holds the slot. Three days means a week-long
    /// visitor sees two or three different places and the section never
    /// looks static, while each pick still gets a fair showing.
    static let rotationDays = 3

    /// One slot in every `weighting` is drawn from the far pool. Four to one
    /// roughly matches where the directory and the visitors both are.
    static let weighting = 5

    struct Selection {
        let business: Business
        let isWorthTheTrip: Bool
    }

    /// Deterministic from the calendar, anchored to island time so the pick
    /// turns over at midnight in Roatán rather than mid-afternoon.
    ///
    /// `userLocation` swaps which pool counts as local. Someone reading this
    /// in Oak Ridge or French Harbour is not on a trip when they drive to the
    /// east end — they live there — so for them the weighting inverts and the
    /// far list becomes the everyday one.
    static func pick(
        from businesses: [Business],
        on date: Date = .now,
        userLocation: CLLocation? = nil
    ) -> Selection? {
        let bySlug = Dictionary(
            businesses.map { ($0.slug, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        func resolve(_ slugs: [String]) -> [Business] {
            slugs.compactMap { bySlug[$0] }.filter { !($0.insiderTip ?? "").isEmpty }
        }

        var near = resolve(nearbySlugs)
        var far = resolve(worthTheTripSlugs)

        // If the reader is closer to the far pool's centre of gravity, the
        // two swap roles. After this point "near" simply means the reader's
        // everyday pool and "far" means the one that costs them a drive —
        // which is what the labelling should describe either way.
        if let userLocation, let nearHome = centroid(of: near), let farHome = centroid(of: far),
           userLocation.distance(from: farHome) < userLocation.distance(from: nearHome) {
            swap(&near, &far)
        }

        // Degenerate cases: one pool empty means the other carries the slot.
        if near.isEmpty && far.isEmpty { return nil }
        if near.isEmpty { near = far; far = [] }

        let slot = slotIndex(on: date)

        if !far.isEmpty && mod(slot, weighting) == weighting - 1 {
            return Selection(business: far[mod(floorDiv(slot, weighting), far.count)],
                             isWorthTheTrip: true)
        }
        // Slots that weren't given to the far pool, counted in order.
        let nearOrdinal = slot - floorDiv(slot, weighting)
        return Selection(business: near[mod(nearOrdinal, near.count)],
                         isWorthTheTrip: false)
    }

    private static func centroid(of businesses: [Business]) -> CLLocation? {
        guard !businesses.isEmpty else { return nil }
        let lat = businesses.map(\.latitude).reduce(0, +) / Double(businesses.count)
        let lon = businesses.map(\.longitude).reduce(0, +) / Double(businesses.count)
        return CLLocation(latitude: lat, longitude: lon)
    }

    /// Days since the epoch, divided into rotation windows. Floored division
    /// and a non-negative modulo so a device with its clock set back still
    /// lands on a valid entry rather than crashing on a negative index.
    private static func slotIndex(on date: Date) -> Int {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Tegucigalpa") ?? .current
        guard let epoch = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1)) else { return 0 }
        let days = calendar.dateComponents([.day], from: epoch, to: date).day ?? 0
        return floorDiv(days, rotationDays)
    }

    private static func floorDiv(_ a: Int, _ b: Int) -> Int {
        Int((Double(a) / Double(b)).rounded(.down))
    }

    private static func mod(_ a: Int, _ n: Int) -> Int {
        n <= 0 ? 0 : ((a % n) + n) % n
    }

    private var pick: Selection? {
        Self.pick(
            from: dataManager.activeBusinesses,
            userLocation: location.userLocation
        )
    }

    private func subtitleLine(for business: Business) -> String {
        var parts = [business.categoryDisplayName, business.areaDisplayName]
        if let travel = TravelEstimate.label(to: business, from: location.userLocation) {
            parts.append(travel)
        }
        return parts.joined(separator: " · ")
    }
}
