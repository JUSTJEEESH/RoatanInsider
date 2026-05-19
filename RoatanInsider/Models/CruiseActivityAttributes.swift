import Foundation
import ActivityKit

/// Shared between the app target and the Widget Extension target.
/// **Add this file's target membership to BOTH targets in Xcode.**
///
/// `Attributes` is the static part of the activity (set on `request`).
/// `ContentState` is the live, mutable part — update it via
/// `Activity.update(...)` to drive the lock-screen countdown.
struct CruiseActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var boardingTime: Date
        var portName: String
        var urgencyMessage: String
        /// 0.0–1.0 fraction of the cruise day that has passed.
        var elapsedFraction: Double
    }

    var startedAt: Date
}
