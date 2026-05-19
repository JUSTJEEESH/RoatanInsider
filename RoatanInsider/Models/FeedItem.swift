import Foundation

/// A single item in the "Right Now" timeline. Item types are intentionally
/// fixed (not free-form strings) so the renderer can pick icons, colors,
/// and CTAs deterministically — and so analytics can group by type.
///
/// New item types are cheap to add: extend the enum, add a `cardKind`
/// mapping, and the renderer picks it up.
enum FeedItem: Identifiable, Hashable {
    case sunsetCountdown(remaining: String, time: String)
    case reefConditions(label: String, score: Int)
    case weatherAlert(message: String)
    case happyHourNow(count: Int, firstBusinessId: String?)
    case liveMusicTonight(count: Int, firstBusinessId: String?)
    case tripCountdown(daysUntil: Int)
    case lastDay(daysLeft: Int)

    var id: String {
        switch self {
        case .sunsetCountdown:    return "sunset"
        case .reefConditions:     return "reef"
        case .weatherAlert:       return "weather"
        case .happyHourNow:       return "happyhour"
        case .liveMusicTonight:   return "livemusic"
        case .tripCountdown:      return "tripcountdown"
        case .lastDay:            return "lastday"
        }
    }

    var priority: Int {
        // Lower = more important. Drives sort order.
        switch self {
        case .lastDay:            return 0
        case .weatherAlert:       return 1
        case .sunsetCountdown:    return 2
        case .happyHourNow:       return 3
        case .liveMusicTonight:   return 4
        case .tripCountdown:      return 5
        case .reefConditions:     return 6
        }
    }
}
