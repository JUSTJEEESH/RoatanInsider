import ActivityKit
import WidgetKit
import SwiftUI

/// Cruise day, on the lock screen and in the Dynamic Island.
///
/// This is the highest-stakes surface in the app. Everything else costs a
/// wasted afternoon when it's wrong; this one costs a missed ship. So it is
/// built around a single question — how long have I got — and answers it
/// with a live timer big enough to read at arm's length, on a black field,
/// with nothing competing.
///
/// `.timer` rather than a string the app has to keep pushing: the system
/// ticks it down every second even while the activity is not being updated,
/// so the number is never stale. A pushed countdown is only as fresh as the
/// last update to arrive, which on hotel wifi is not fresh enough for this.
///
/// Colour carries urgency and nothing else. Mint while there's time, pink
/// once it's tight. The old version used red at 90% and orange at 75%,
/// which put two colours in the app that exist nowhere else in it — and
/// the palette is two accents on purpose, so a third reads as a different
/// product. Pink is already this app's "pay attention" colour.
struct CruiseLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CruiseActivityAttributes.self) { context in
            lockScreen(state: context.state)
                .activityBackgroundTint(Color.riNearBlack)
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label("Cruise day", systemImage: "ferry.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Self.urgencyColor(context.state))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.boardingTime, style: .time)
                        .font(.system(size: 13, weight: .semibold))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.75))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(context.state.boardingTime, style: .timer)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)

                        progressBar(context.state)

                        Text(context.state.urgencyMessage)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                }
            } compactLeading: {
                Image(systemName: "ferry.fill")
                    .foregroundStyle(Self.urgencyColor(context.state))
            } compactTrailing: {
                Text(context.state.boardingTime, style: .timer)
                    .monospacedDigit()
                    .foregroundStyle(Self.urgencyColor(context.state))
                    .frame(maxWidth: 52)
            } minimal: {
                Image(systemName: "ferry.fill")
                    .foregroundStyle(Self.urgencyColor(context.state))
            }
        }
    }

    // MARK: - Lock screen

    private func lockScreen(state: CruiseActivityAttributes.ContentState) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "ferry.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text("BACK ON BOARD")
                    .riType(.label)
                Spacer(minLength: 8)
                Text(state.portName)
                    .riType(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }
            .foregroundStyle(Self.urgencyColor(state))

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(state.boardingTime, style: .timer)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Spacer(minLength: 0)

                Text(state.boardingTime, style: .time)
                    .riType(.heading)
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.75))
            }

            progressBar(state)

            Text(state.urgencyMessage)
                .riType(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
    }

    /// Drawn rather than `ProgressView`, which renders its track at a system
    /// grey that sits at a different lightness from everything around it and
    /// carries a default corner treatment we don't control.
    private func progressBar(_ state: CruiseActivityAttributes.ContentState) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.15))
                Capsule()
                    .fill(Self.urgencyColor(state))
                    .frame(width: max(0, min(1, state.elapsedFraction)) * geo.size.width)
            }
        }
        .frame(height: 4)
    }

    /// Mint until three quarters of the day is gone, pink after. Two colours,
    /// both already in the app.
    static func urgencyColor(_ state: CruiseActivityAttributes.ContentState) -> Color {
        state.elapsedFraction >= 0.75 ? .riPink : .riMint
    }
}
