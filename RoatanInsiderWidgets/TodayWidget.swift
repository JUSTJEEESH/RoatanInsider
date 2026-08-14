import WidgetKit
import SwiftUI

/// "Today on Roatán" — the conditions and one place worth going.
///
/// Two things, not five. A widget is read in about a second from four
/// inches away, so it gets one number and one name; anything else is a
/// second app icon's worth of clutter. Temperature answers "what is it
/// like out", the pick answers "so where do I go".
///
/// Everything the app can't supply simply doesn't draw. A fresh install
/// before the host app has ever written to the App Group shows the kicker
/// and an invitation, not a grid of placeholder dashes pretending to be
/// data.
///
/// App Group setup, required for the pick to appear at all:
///   1. Both targets: Signing & Capabilities → + App Groups.
///   2. Add `group.com.roataninsider.shared` to each.
///   3. The app writes via `UserDefaults(suiteName:)`; this reads the same
///      suite. Without the capability the reads return nil and the widget
///      falls back to conditions only — it does not break.
struct TodayWidget: Widget {
    let kind: String = "TodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayProvider()) { entry in
            TodayWidgetView(entry: entry)
                .containerBackground(for: .widget) { Color.riNearBlack }
        }
        .configurationDisplayName("Today on Roatán")
        .description("Conditions now, and today's insider pick.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct TodayEntry: TimelineEntry {
    let date: Date
    let sunsetCountdown: String?
    let temperatureLabel: String?
    let pickName: String?
    let pickArea: String?

    var hasPick: Bool { !(pickName ?? "").isEmpty }
}

struct TodayProvider: TimelineProvider {
    private static let appGroup = "group.com.roataninsider.shared"

    func placeholder(in context: Context) -> TodayEntry {
        TodayEntry(date: .now, sunsetCountdown: "2h 14m", temperatureLabel: "84°",
                   pickName: "Sundowners Bar", pickArea: "West End")
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        completion(buildEntry(at: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        var entries: [TodayEntry] = []
        let now = Date()
        for minute in stride(from: 0, to: 6 * 60, by: 15) {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minute, to: now) ?? now
            entries.append(buildEntry(at: entryDate))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func buildEntry(at date: Date) -> TodayEntry {
        let defaults = UserDefaults(suiteName: Self.appGroup)
        return TodayEntry(
            date: date,
            sunsetCountdown: SunsetProvider.countdown(at: date),
            temperatureLabel: defaults?.string(forKey: "weather.temperature"),
            pickName: defaults?.string(forKey: "pick.name"),
            pickArea: defaults?.string(forKey: "pick.area")
        )
    }
}

struct TodayWidgetView: View {
    let entry: TodayEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemMedium: medium
        default: small
        }
    }

    // MARK: - Small: conditions, then the pick underneath

    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            conditions
            Spacer(minLength: 8)
            pick(titleLines: 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Medium: side by side, split by a hairline

    /// A hairline rather than a `Divider()`: the system divider draws at the
    /// container's tint and reads heavier than anything else here, which
    /// makes the split the loudest element on a widget whose whole point is
    /// one number and one name.
    private var medium: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                conditions
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Rectangle()
                .fill(.white.opacity(0.12))
                .frame(width: 1)

            VStack(alignment: .leading, spacing: 0) {
                pick(titleLines: 3)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Blocks

    private var conditions: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("RIGHT NOW")
                .riType(.label)
                .foregroundStyle(Color.riMint)

            if let temp = entry.temperatureLabel {
                Text(temp)
                    .riType(.display)
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }

            if let c = entry.sunsetCountdown {
                Text("Sunset in \(c)")
                    .riType(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            } else {
                Text("Sun has set")
                    .riType(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    @ViewBuilder
    private func pick(titleLines: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("INSIDER PICK")
                .riType(.label)
                .foregroundStyle(Color.riPink)

            if entry.hasPick {
                Text(entry.pickName ?? "")
                    .riType(.heading)
                    .foregroundStyle(.white)
                    .lineLimit(titleLines)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)

                if let area = entry.pickArea, !area.isEmpty {
                    Text(area)
                        .riType(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                }
            } else {
                Text("Open the app to set today's pick")
                    .riType(.caption)
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(titleLines)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
