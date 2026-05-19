import WidgetKit
import SwiftUI

/// Sunset countdown widget. Available as a lock-screen rectangular widget,
/// inline (the thin status row), and small-system home-screen widget.
///
/// Entirely local — `SunsetCalculator` is in the shared file in this folder
/// (copy it from the main app into both targets, or embed the source file
/// in both target memberships). No network access required.
struct SunsetWidget: Widget {
    let kind: String = "SunsetWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SunsetProvider()) { entry in
            SunsetWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.45, blue: 0.18),
                                 Color(red: 0.9, green: 0.2, blue: 0.31)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("Sunset on Roatán")
        .description("Today's sunset time and live countdown.")
        .supportedFamilies([
            .systemSmall,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

struct SunsetEntry: TimelineEntry {
    let date: Date
    let sunsetTime: String
    let countdown: String?
}

struct SunsetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SunsetEntry {
        SunsetEntry(date: .now, sunsetTime: "6:00 PM", countdown: "2h 14m")
    }

    func getSnapshot(in context: Context, completion: @escaping (SunsetEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SunsetEntry>) -> Void) {
        // Build a timeline of entries every 5 minutes until tomorrow.
        var entries: [SunsetEntry] = []
        let now = Date()
        for minute in stride(from: 0, to: 12 * 60, by: 5) {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minute, to: now) ?? now
            entries.append(SunsetEntry(
                date: entryDate,
                sunsetTime: SunsetCalculator.sunsetTimeString(),
                countdown: countdown(at: entryDate)
            ))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func countdown(at date: Date) -> String? {
        let sunset = SunsetCalculator.todaySunset()
        let remaining = sunset.timeIntervalSince(date)
        guard remaining > 0 else { return nil }
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }

    private func currentEntry() -> SunsetEntry {
        SunsetEntry(
            date: .now,
            sunsetTime: SunsetCalculator.sunsetTimeString(),
            countdown: countdown(at: .now)
        )
    }
}

struct SunsetWidgetView: View {
    let entry: SunsetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryInline:
            HStack(spacing: 4) {
                Image(systemName: "sunset.fill")
                Text(inlineText)
            }
        case .accessoryRectangular:
            HStack(spacing: 10) {
                Image(systemName: "sunset.fill")
                    .font(.system(size: 22, weight: .semibold))
                VStack(alignment: .leading, spacing: 0) {
                    Text(entry.countdown.map { "Sunset in \($0)" } ?? "Sun has set")
                        .font(.system(size: 14, weight: .bold))
                    Text(entry.sunsetTime)
                        .font(.system(size: 12, weight: .medium))
                        .opacity(0.8)
                }
                Spacer()
            }
        default: // systemSmall
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: "sunset.fill")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(.white)

                Spacer()

                Text(entry.countdown ?? "Tomorrow")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                Text("until sunset")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))

                Text(entry.sunsetTime)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    private var inlineText: String {
        if let c = entry.countdown { return "Sunset \(c)" }
        return "Sunset \(entry.sunsetTime)"
    }
}
