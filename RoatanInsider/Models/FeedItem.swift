import Foundation

/// A single item in the Today list. Item types are intentionally fixed (not
/// free-form strings) so the renderer can pick treatment deterministically,
/// and so analytics can group by type.
///
/// Ordering is the whole point of this enum: `priority` decides what a
/// visitor reads first, and the first item is what the screen is "about"
/// today. A cruise passenger and a resident open the same screen and get a
/// different lead because their profile changes which items compose.
///
/// Deliberately NOT here: temperature, sunset time, snorkel and UV. Those
/// live in `HomeHeader` as one line of running metadata. Carrying them as
/// list items too is how the old Home showed the same three facts twice, a
/// few hundred points apart.
enum FeedItem: Identifiable, Hashable {
    /// Cruise passengers only — the entry point into Cruise Mode.
    case cruiseDay
    case lastDay(daysLeft: Int)
    case shipsInPort(count: Int, passengers: Int)
    case weatherAlert(message: String)
    /// Only when sundown is close enough to change where you'd walk.
    case sunsetImminent(remaining: String, time: String)
    case happyHourNow(count: Int, firstBusinessId: String?)
    case liveMusicToday(count: Int)
    case tripCountdown(daysUntil: Int)

    var id: String {
        switch self {
        case .cruiseDay:      return "cruiseday"
        case .lastDay:        return "lastday"
        case .shipsInPort:    return "ships"
        case .weatherAlert:   return "weather"
        case .sunsetImminent: return "sunset"
        case .happyHourNow:   return "happyhour"
        case .liveMusicToday: return "livemusic"
        case .tripCountdown:  return "tripcountdown"
        }
    }

    /// Lower reads first.
    var priority: Int {
        switch self {
        case .cruiseDay:      return 0
        case .lastDay:        return 1
        case .shipsInPort:    return 2
        case .weatherAlert:   return 3
        case .sunsetImminent: return 4
        case .happyHourNow:   return 5
        case .liveMusicToday: return 6
        case .tripCountdown:  return 7
        }
    }
}
