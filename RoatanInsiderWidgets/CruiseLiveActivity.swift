import ActivityKit
import WidgetKit
import SwiftUI

/// Cruise day Live Activity. Renders the countdown on the lock screen and
/// in the Dynamic Island so passengers never miss their ship.
///
/// Requires the **shared** `CruiseActivityAttributes.swift` to be added to
/// both the app target AND this widget target.
///
/// Started from the app (LiveActivityManager.startCruiseActivity), updated
/// every minute by a Timer in CruiseViewModel, and ended when the boarding
/// time has passed.
struct CruiseLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CruiseActivityAttributes.self) { context in
            // Lock-screen / banner view
            lockScreenView(state: context.state)
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text("Back on board")
                            .font(.caption2)
                    } icon: {
                        Image(systemName: "ferry.fill")
                            .foregroundStyle(Color(red: 0.89, green: 0.10, blue: 0.30))
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.boardingTime, style: .time)
                        .font(.headline)
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.urgencyMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 8) {
                        Text(context.state.boardingTime, style: .timer)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        Spacer()
                        ProgressView(value: context.state.elapsedFraction)
                            .progressViewStyle(.linear)
                            .tint(progressTint(state: context.state))
                            .frame(maxWidth: 120)
                    }
                }
            } compactLeading: {
                Image(systemName: "ferry.fill")
                    .foregroundStyle(Color(red: 0.89, green: 0.10, blue: 0.30))
            } compactTrailing: {
                Text(context.state.boardingTime, style: .timer)
                    .monospacedDigit()
                    .frame(maxWidth: 50)
            } minimal: {
                Image(systemName: "ferry.fill")
                    .foregroundStyle(Color(red: 0.89, green: 0.10, blue: 0.30))
            }
        }
    }

    private func lockScreenView(state: CruiseActivityAttributes.ContentState) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Cruise day", systemImage: "ferry.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(red: 0.89, green: 0.10, blue: 0.30))
                Spacer()
                Text(state.portName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
            }

            HStack(alignment: .lastTextBaseline) {
                Text(state.boardingTime, style: .timer)
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Back on board")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                    Text(state.boardingTime, style: .time)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }

            ProgressView(value: state.elapsedFraction)
                .progressViewStyle(.linear)
                .tint(progressTint(state: state))

            Text(state.urgencyMessage)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(14)
    }

    private func progressTint(state: CruiseActivityAttributes.ContentState) -> Color {
        if state.elapsedFraction >= 0.9 { return .red }
        if state.elapsedFraction >= 0.75 { return .orange }
        return Color(red: 0.89, green: 0.10, blue: 0.30)
    }
}
