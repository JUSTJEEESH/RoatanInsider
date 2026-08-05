import SwiftUI

/// "Today" — one prioritized list of what is actually true about today.
///
/// Replaces four separate Home sections that each decided independently
/// that they deserved a slot: `RightNowFeedSection`, `ShipsInPortSection`,
/// `ArrivalBanner` and `CruiseBanner`. They now compete for one list and
/// `FeedComposer` ranks them, which is why a cruise passenger and a
/// resident see a different first row on the same screen.
///
/// Rendered as hairline-separated rows rather than a stack of cards. The
/// old feed put every item in its own rounded rectangle behind an icon in
/// a tinted circle — the single most generated-looking pattern in the app,
/// and it made five short facts occupy most of a screen.
struct TodaySection: View {
    @Environment(WeatherService.self) private var weather
    @Environment(UserProfileStore.self) private var profileStore
    @Environment(DataManager.self) private var dataManager
    @Environment(EventsService.self) private var events
    @Environment(CruiseArrivalsService.self) private var cruise
    @Environment(ArrivalDetector.self) private var arrival
    @Environment(LocationManager.self) private var location

    @Binding var showCruiseMode: Bool

    var body: some View {
        let items = composed
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: AppConstants.Space.snug) {
                Text("TODAY")
                    .riType(.label)
                    .foregroundStyle(Color.riMediumGray)

                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        if index > 0 {
                            Divider().overlay(Color.riDark.opacity(0.08))
                        }
                        row(for: item)
                    }
                }
            }
            .padding(.horizontal, AppConstants.Space.gutter)
            .onAppear { Analytics.track(.homeSectionViewed(name: "today")) }
        }
    }

    // MARK: - Composition

    private var composed: [FeedItem] {
        FeedComposer.compose(
            weather: weather.conditions,
            profile: profileStore.profile,
            businesses: dataManager.activeBusinesses,
            shipsToday: shipSummary,
            musicEventsRemainingToday: musicCount,
            arrivalDetected: arrival.shouldShow(
                location: location.userLocation,
                profile: profileStore.profile
            )
        )
    }

    /// Nil when the cruise schedule can't speak to today — a stale scraper
    /// must never produce a confident "no ships".
    private var shipSummary: FeedComposer.ShipSummary? {
        guard cruise.hasCurrentData else { return nil }
        let today = cruise.arrivalsToday()
        guard !today.isEmpty else { return nil }
        return .init(count: today.count, passengers: cruise.totalPassengersToday())
    }

    private var musicCount: Int {
        let shipsIn = cruise.hasCurrentData ? !cruise.arrivalsToday().isEmpty : true
        let remaining = events.happeningNow(cruiseShipInPort: shipsIn)
            + events.upNextToday(cruiseShipInPort: shipsIn)
        return remaining.filter { $0.category == .liveMusic || $0.category == .dj }.count
    }

    // MARK: - Rows

    @ViewBuilder
    private func row(for item: FeedItem) -> some View {
        switch item {
        case .cruiseDay:
            Button {
                Haptics.impact()
                showCruiseMode = true
            } label: {
                rowContent(
                    title: "Cruise day on Roatán",
                    detail: "Open your plan — hours ashore, and how to get back on time.",
                    showsChevron: true
                )
            }
            .buttonStyle(.plain)

        case .lastDay(let daysLeft):
            rowContent(
                title: daysLeft == 0 ? "Last day on the island" : "Final day tomorrow",
                detail: "Make it count. The good places stay open late."
            )

        case .shipsInPort(let count, let passengers):
            rowContent(
                title: count == 1 ? "1 ship in port" : "\(count) ships in port",
                detail: "About \(rounded(passengers)) visitors ashore — West Bay and West End run busier.",
                trailing: rounded(passengers)
            )

        case .weatherAlert(let message):
            rowContent(title: "Heads up", detail: message)

        case .sunsetImminent(let remaining, let time):
            rowContent(
                title: "Sunset in \(remaining)",
                detail: "Golden hour at \(time). Grab a west-facing seat.",
                trailing: time
            )

        case .happyHourNow(let count, _):
            rowContent(
                title: "Happy hour on now",
                detail: count == 1 ? "One place within reach." : "\(count) places within reach."
            )

        case .liveMusicToday(let count):
            NavigationLink(value: EventsListDestination()) {
                rowContent(
                    title: count == 1 ? "1 set still to come" : "\(count) sets still to come",
                    detail: "Live music and DJs across the island today.",
                    showsChevron: true
                )
            }
            .buttonStyle(.plain)

        case .tripCountdown(let days):
            rowContent(
                title: days == 1 ? "One day until you land" : "\(days) days until you land",
                detail: "Save places as you find them — your plan builds itself.",
                trailing: "\(days)"
            )
        }
    }

    private func rowContent(
        title: String,
        detail: String,
        trailing: String? = nil,
        showsChevron: Bool = false
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppConstants.Space.snug) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .riType(.heading)
                    .foregroundStyle(Color.riDark)
                Text(detail)
                    .riType(.caption)
                    .foregroundStyle(Color.riMediumGray)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: AppConstants.Space.tight)

            if let trailing {
                Text(trailing)
                    .riType(.caption)
                    .foregroundStyle(Color.riLightGray)
                    .monospacedDigit()
            }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.riLightGray)
            }
        }
        .padding(.vertical, AppConstants.Space.snug)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    /// Exact capacity is misleading — not everyone disembarks — so the list
    /// says "about 11,500", never "11,482".
    private func rounded(_ passengers: Int) -> String {
        let n = CruiseArrival.roundedToNearest500(passengers)
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}
