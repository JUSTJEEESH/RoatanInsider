import Foundation
import WidgetKit

/// Bridge that publishes a tiny snapshot of state into the shared App Group
/// so the `TodayWidget` and any future widget can read it without
/// re-fetching weather or recomputing picks.
///
/// **Setup once in Xcode:**
///   1. Both the app and Widget Extension targets must include the
///      "App Groups" capability and share a group named below.
///   2. Add `com.apple.security.application-groups` with the same value
///      to both `.entitlements` files.
///
/// `HomeView` calls `publish(...)` when it appears and whenever the weather
/// changes. Call it from anywhere else that learns something the widget
/// shows; it is cheap to call and does nothing when nothing has changed.
enum WidgetSharedData {
    static let appGroup = "group.com.roataninsider.shared"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroup)
    }

    /// Writes the snapshot and reloads timelines only if a value actually
    /// moved.
    ///
    /// WidgetKit gives each widget a daily reload budget and spends it on
    /// requests, not on changes — so an unconditional reload on every Home
    /// appearance burns the allowance re-rendering the same pixels, and the
    /// widget goes stale later in the day when there is something new to
    /// say. The temperature changes a few times an hour and the pick every
    /// three days; that is how often this should cost anything.
    static func publish(
        temperatureLabel: String?,
        pickName: String?,
        pickArea: String?,
        pickId: String?
    ) {
        guard let defaults else {
            AppLog.app.warning("App Group defaults unavailable (\(appGroup, privacy: .public)). Add the App Group capability to both targets.")
            return
        }

        let incoming: [String: String?] = [
            "weather.temperature": temperatureLabel,
            "pick.name": pickName,
            "pick.area": pickArea,
            "pick.id": pickId,
        ]
        guard incoming.contains(where: { defaults.string(forKey: $0.key) != $0.value }) else { return }

        for (key, value) in incoming {
            if let value {
                defaults.set(value, forKey: key)
            } else {
                defaults.removeObject(forKey: key)
            }
        }

        WidgetCenter.shared.reloadAllTimelines()
    }

    static func clear() {
        guard let defaults else { return }
        defaults.removeObject(forKey: "weather.temperature")
        defaults.removeObject(forKey: "pick.name")
        defaults.removeObject(forKey: "pick.area")
        defaults.removeObject(forKey: "pick.id")
        WidgetCenter.shared.reloadAllTimelines()
    }
}
