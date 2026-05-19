import Foundation
import ActivityKit

/// Starts, updates, and ends the Cruise Day Live Activity. Wraps ActivityKit
/// so the cruise view model never imports ActivityKit directly — keeps
/// device-feature dependence isolated to one file.
///
/// Live Activities require:
///   - iOS 16.2+ (system requirement)
///   - `NSSupportsLiveActivities = YES` in Info.plist
///   - The shared `CruiseActivityAttributes.swift` file in BOTH the app target
///     and the Widget Extension target.
///   - The Widget Extension target containing `CruiseLiveActivity.swift`.
@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private var activity: Activity<CruiseActivityAttributes>?

    private init() {}

    /// True if the user can show Live Activities right now.
    var areActivitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    /// Start a cruise countdown Live Activity. Replaces any existing one.
    func startCruiseActivity(boardingTime: Date, portName: String, urgency: String, elapsedFraction: Double) {
        guard areActivitiesEnabled else {
            AppLog.app.notice("Live Activities disabled by user — skipping start.")
            return
        }

        endCruiseActivity()

        let attributes = CruiseActivityAttributes(startedAt: .now)
        let state = CruiseActivityAttributes.ContentState(
            boardingTime: boardingTime,
            portName: portName,
            urgencyMessage: urgency,
            elapsedFraction: elapsedFraction
        )

        do {
            // ActivityContent wraps state with a stale-date so iOS can dim it
            // automatically if our app gets backgrounded without updating.
            let content = ActivityContent(state: state, staleDate: boardingTime.addingTimeInterval(60 * 30))
            activity = try Activity.request(attributes: attributes, content: content)
            AppLog.app.notice("Started cruise Live Activity, boarding=\(boardingTime, privacy: .public)")
            Analytics.track(.toolUsed(name: "live_activity_started"))
        } catch {
            AppLog.app.error("Failed to start Live Activity: \(error.localizedDescription)")
        }
    }

    /// Push a new state. Call from a per-minute Timer while cruise mode is
    /// active.
    func updateCruiseActivity(boardingTime: Date, portName: String, urgency: String, elapsedFraction: Double) {
        guard let activity else { return }
        let state = CruiseActivityAttributes.ContentState(
            boardingTime: boardingTime,
            portName: portName,
            urgencyMessage: urgency,
            elapsedFraction: elapsedFraction
        )
        Task {
            let content = ActivityContent(state: state, staleDate: boardingTime.addingTimeInterval(60 * 30))
            await activity.update(content)
        }
    }

    /// End the activity. Call when the user exits cruise mode or when the
    /// boarding time has passed.
    func endCruiseActivity(finalState: CruiseActivityAttributes.ContentState? = nil) {
        guard let activity else { return }
        Task {
            if let finalState {
                let content = ActivityContent(state: finalState, staleDate: nil)
                await activity.end(content, dismissalPolicy: .after(.now.addingTimeInterval(60)))
            } else {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            self.activity = nil
            AppLog.app.notice("Ended cruise Live Activity")
        }
    }
}
