import Foundation

/// Composes the Right Now feed items from current app state. Pure function:
/// same inputs → same outputs, no side effects, easy to unit test.
///
/// Derived from existing data only — no new APIs to integrate:
///   - SunsetCalculator (already shipped)
///   - WeatherService (already shipped)
///   - UserProfile (already shipped)
///   - DataManager.activeBusinesses + their feature flags
enum FeedComposer {

    /// Build up to ~5 timely items. Caller renders them as a vertical
    /// timeline above the existing RightNowSection.
    static func compose(
        weather: WeatherService.Conditions?,
        reefScore: Int,
        snorkelLabel: String,
        profile: UserProfile,
        businesses: [Business]
    ) -> [FeedItem] {
        var items: [FeedItem] = []

        // Trip-stage items (most personal first).
        if let arrival = profile.arrivalDate, let departure = profile.departureDate {
            let cal = Calendar.current
            let now = Date()
            let daysUntilArrival = cal.dateComponents([.day], from: now, to: arrival).day ?? 0
            let daysUntilDeparture = cal.dateComponents([.day], from: now, to: departure).day ?? 0

            if now < cal.startOfDay(for: arrival), daysUntilArrival > 0, daysUntilArrival <= 30 {
                items.append(.tripCountdown(daysUntil: daysUntilArrival))
            } else if now >= cal.startOfDay(for: arrival) && now <= departure, daysUntilDeparture <= 1 {
                items.append(.lastDay(daysLeft: max(0, daysUntilDeparture)))
            }
        }

        // Sunset — only relevant in afternoon and evening, gated to within
        // 4 hours of sundown.
        if let remaining = SunsetCalculator.timeUntilSunset(), remaining < 4 * 3600 {
            if let countdown = SunsetCalculator.sunsetCountdown() {
                items.append(.sunsetCountdown(remaining: countdown, time: SunsetCalculator.sunsetTimeString()))
            }
        }

        // Weather alert — rain, heat, or strong wind.
        if let c = weather {
            switch c.weatherCode {
            case 61, 63, 65, 80, 81, 82, 95, 96, 99:
                items.append(.weatherAlert(message: "Rain in the forecast. Here are covered spots."))
            default:
                break
            }
            if c.uvIndex >= 9 {
                items.append(.weatherAlert(message: "UV is extreme. Snorkel before 10 or after 3."))
            }
            if c.windKph >= 35 {
                items.append(.weatherAlert(message: "Windy day — east side will be choppy."))
            }
        }

        // Happy hour now — businesses with "Happy Hour" feature that are open.
        let happyNow = businesses.filter { biz in
            biz.isActive && biz.isOpenNow() &&
            biz.features.contains(where: { $0.localizedCaseInsensitiveContains("happy hour") })
        }
        if !happyNow.isEmpty {
            items.append(.happyHourNow(count: happyNow.count, firstBusinessId: happyNow.first?.id))
        }

        // Live music tonight — businesses tagged with Live Music that open in
        // the evening.
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 14 && hour <= 23 {
            let liveTonight = businesses.filter { biz in
                biz.isActive &&
                biz.features.contains(where: { $0.localizedCaseInsensitiveContains("live music") })
            }
            if !liveTonight.isEmpty {
                items.append(.liveMusicTonight(count: liveTonight.count, firstBusinessId: liveTonight.first?.id))
            }
        }

        // Reef conditions — always include if we have weather, as a baseline
        // useful chip when the rest of the feed is quiet.
        if weather != nil {
            items.append(.reefConditions(label: snorkelLabel, score: reefScore))
        }

        return items.sorted { $0.priority < $1.priority }
    }
}
