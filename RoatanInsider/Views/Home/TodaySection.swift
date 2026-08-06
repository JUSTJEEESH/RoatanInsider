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

    @State private var shipsExpanded = false

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
            VStack(alignment: .leading, spacing: 0) {
                Button {
                    Haptics.tap()
                    withAnimation(.easeInOut(duration: 0.22)) { shipsExpanded.toggle() }
                    if shipsExpanded { Analytics.track(.homeSectionViewed(name: "ships_expanded")) }
                } label: {
                    rowContent(
                        title: count == 1 ? "1 ship in port" : "\(count) ships in port",
                        detail: "About \(rounded(passengers)) visitors ashore — West Bay and West End run busier.",
                        disclosureOpen: shipsExpanded
                    )
                }
                .buttonStyle(.plain)
                .accessibilityHint(shipsExpanded ? "Collapses the ship list" : "Shows which ships and when they leave")

                if shipsExpanded { shipDetail }
            }

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
        showsChevron: Bool = false,
        disclosureOpen: Bool? = nil
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
            if let disclosureOpen {
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.riLightGray)
                    .rotationEffect(.degrees(disclosureOpen ? 180 : 0))
            } else if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.riLightGray)
            }
        }
        .padding(.vertical, AppConstants.Space.snug)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    // MARK: - Ships, expanded
    //
    // Every arrival record already carried the ship's name, its port and its
    // hours; the list rendered two numbers from all of it and showed the rest
    // nowhere in the app. Which port is the part worth knowing — the two
    // serve different ends of the island — and the last departure is the
    // answer to "when does it get quiet again".

    private var shipDetail: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(cruise.arrivalsToday()) { ship in
                HStack(alignment: .firstTextBaseline, spacing: AppConstants.Space.snug) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(ship.shipName)
                            .riType(.caption, weight: .semibold)
                            .foregroundStyle(Color.riDark)
                            .lineLimit(1)
                        Text(ship.port)
                            .riType(.caption)
                            .foregroundStyle(Color.riLightGray)
                            .lineLimit(1)
                    }

                    Spacer(minLength: AppConstants.Space.tight)

                    Text(ship.hoursLabel)
                        .riType(.caption)
                        .monospacedDigit()
                        .foregroundStyle(Color.riMediumGray)
                        .layoutPriority(1)
                }
                .padding(.vertical, AppConstants.Space.tight)
                .accessibilityElement(children: .combine)
            }

            if let closing = lastDepartureLabel {
                Text(closing)
                    .riType(.caption)
                    .foregroundStyle(Color.riMediumGray)
                    .padding(.top, AppConstants.Space.tight)
            }

            if let tomorrow = tomorrowLabel {
                Text(tomorrow)
                    .riType(.caption)
                    .foregroundStyle(Color.riLightGray)
                    .padding(.top, 2)
            }
        }
        .padding(.leading, AppConstants.Space.snug)
        .padding(.bottom, AppConstants.Space.snug)
        .transition(.opacity)
    }

    private var lastDepartureLabel: String? {
        guard let last = cruise.arrivalsToday().max(by: { $0.departureTime < $1.departureTime }) else {
            return nil
        }
        return "Quiet again after \(last.departureLabel)."
    }

    /// Only stated when the schedule genuinely reaches tomorrow. A silent
    /// row beats "no ships tomorrow" derived from a schedule that simply
    /// stops there.
    private var tomorrowLabel: String? {
        guard cruise.hasDataThroughTomorrow else { return nil }
        let ships = cruise.arrivalsTomorrow()
        guard !ships.isEmpty else { return "Tomorrow: none scheduled." }
        let count = ships.count == 1 ? "1 ship" : "\(ships.count) ships"
        return "Tomorrow: \(count), about \(rounded(cruise.totalPassengersTomorrow()))."
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
