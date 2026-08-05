import Foundation

/// Composes the Today list from current app state. Pure function: same
/// inputs → same outputs, no side effects, easy to unit test.
///
/// This is the priority engine behind the whole Today block. Four separate
/// Home sections used to each decide independently that they deserved a
/// slot — ships, cruise banner, arrival banner, and the alert feed — which
/// is why they stacked instead of ranking. Now they compete for the same
/// list and `FeedItem.priority` settles it.
///
/// Adaptivity falls out of composition rather than branching layouts: a
/// cruise passenger gets `.cruiseDay` at priority 0, someone on their last
/// day gets `.lastDay`, someone who hasn't landed gets `.tripCountdown`.
/// Same six blocks on screen, different first thing read.
enum FeedComposer {

    static func compose(
        weather: WeatherService.Conditions?,
        profile: UserProfile,
        businesses: [Business],
        shipsToday: ShipSummary? = nil,
        musicEventsRemainingToday: Int = 0,
        arrivalDetected: Bool = false,
        now: Date = .now
    ) -> [FeedItem] {
        var items: [FeedItem] = []

        // --- Who is this, and what is today for them? ---------------------

        if profile.travelerType == .cruiser || arrivalDetected {
            items.append(.cruiseDay)
        }

        if let arrival = profile.arrivalDate, let departure = profile.departureDate {
            let cal = Calendar.current
            let daysUntilArrival = cal.dateComponents([.day], from: now, to: arrival).day ?? 0
            let daysUntilDeparture = cal.dateComponents([.day], from: now, to: departure).day ?? 0

            if now < cal.startOfDay(for: arrival), daysUntilArrival > 0, daysUntilArrival <= 30 {
                items.append(.tripCountdown(daysUntil: daysUntilArrival))
            } else if now >= cal.startOfDay(for: arrival), now <= departure, daysUntilDeparture <= 1 {
                items.append(.lastDay(daysLeft: max(0, daysUntilDeparture)))
            }
        }

        // --- What is true about the island today? -------------------------

        // Passed in as nil when the cruise schedule can't speak to today,
        // so a stale scraper never produces a confident "quiet day".
        if let ships = shipsToday, ships.count > 0 {
            items.append(.shipsInPort(count: ships.count, passengers: ships.passengers))
        }

        if let c = weather {
            switch c.weatherCode {
            case 61, 63, 65, 80, 81, 82, 95, 96, 99:
                items.append(.weatherAlert(message: "Rain in the forecast — here are covered spots."))
            default:
                break
            }
            if c.windKph >= 35 {
                items.append(.weatherAlert(message: "Windy today — the east side will be choppy."))
            }
            // UV is not here on purpose: HomeHeader already shows it, and
            // only when it's high enough to matter.
        }

        // Sundown only earns a row when it's close enough to act on. The
        // header carries the time itself all day.
        if let remaining = SunsetCalculator.timeUntilSunset(), remaining < 90 * 60,
           let countdown = SunsetCalculator.sunsetCountdown() {
            items.append(.sunsetImminent(remaining: countdown, time: SunsetCalculator.sunsetTimeString()))
        }

        // --- What could you walk into right now? --------------------------

        let happyNow = businesses.filter { biz in
            biz.isActive && biz.isOpenNow() &&
            biz.features.contains { $0.localizedCaseInsensitiveContains("happy hour") }
        }
        if !happyNow.isEmpty {
            items.append(.happyHourNow(count: happyNow.count, firstBusinessId: happyNow.first?.id))
        }

        if musicEventsRemainingToday > 0 {
            items.append(.liveMusicToday(count: musicEventsRemainingToday))
        }

        return items.sorted { $0.priority < $1.priority }
    }

    /// Ships in port today, already reduced to the two numbers the list
    /// shows. Nil rather than zero when the schedule is stale.
    struct ShipSummary {
        let count: Int
        let passengers: Int
    }
}
