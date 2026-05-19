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
/// Call `WidgetSharedData.publish(...)` from the app whenever weather or
/// today's pick changes, then call `WidgetCenter.shared.reloadAllTimelines()`
/// so the widget grabs the new snapshot on its next refresh.
enum WidgetSharedData {
    static let appGroup = "group.com.roataninsider.shared"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroup)
    }

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
        defaults.set(temperatureLabel, forKey: "weather.temperature")
        defaults.set(pickName, forKey: "pick.name")
        defaults.set(pickArea, forKey: "pick.area")
        defaults.set(pickId, forKey: "pick.id")

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
