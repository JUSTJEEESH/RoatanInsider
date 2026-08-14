import WidgetKit
import SwiftUI

/// Sunset countdown, on the home screen and the lock screen.
///
/// The number is the widget. Everything else is a label for it — a kicker
/// above and the clock time below, both quiet, so the countdown is the only
/// thing you read at a glance from a beach chair. That is the whole job: not
/// "here is some weather", but "you have fifty minutes".
///
/// Flat near-black, one mint accent. The previous version filled the
/// container with an orange-to-red `LinearGradient`, which breaks two of
/// this app's design rules at once — no gradients anywhere, and never a
/// third accent colour. It also made the white numerals sit on a mid-tone
/// that shifted under them, which is exactly where legibility goes.
///
/// Lock-screen families are drawn monochrome by the system: it takes the
/// alpha of what you render and tints it. Colour there is not dimmed, it is
/// discarded — so those layouts are built from weight and size alone, and
/// `widgetAccentable` marks the countdown so it picks up the accent tint
/// rather than the flat one.
struct SunsetWidget: Widget {
    let kind: String = "SunsetWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SunsetProvider()) { entry in
            SunsetWidgetView(entry: entry)
                .containerBackground(for: .widget) { Color.riNearBlack }
        }
        .configurationDisplayName("Sunset on Roatán")
        .description("Today's sunset time and a live countdown.")
        .supportedFamilies([.systemSmall, .accessoryRectangular, .accessoryInline])
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

    /// Every five minutes for twelve hours. WidgetKit will not redraw on our
    /// schedule alone, but a dense timeline means the number is never more
    /// than five minutes stale when the system does refresh.
    func getTimeline(in context: Context, completion: @escaping (Timeline<SunsetEntry>) -> Void) {
        var entries: [SunsetEntry] = []
        let now = Date()
        for minute in stride(from: 0, to: 12 * 60, by: 5) {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minute, to: now) ?? now
            entries.append(SunsetEntry(
                date: entryDate,
                sunsetTime: SunsetCalculator.sunsetTimeString(),
                countdown: Self.countdown(at: entryDate)
            ))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    static func countdown(at date: Date) -> String? {
        let sunset = SunsetCalculator.todaySunset()
        let remaining = sunset.timeIntervalSince(date)
        guard remaining > 0 else { return nil }
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }

    private func currentEntry() -> SunsetEntry {
        SunsetEntry(date: .now, sunsetTime: SunsetCalculator.sunsetTimeString(),
                    countdown: Self.countdown(at: .now))
    }
}

struct SunsetWidgetView: View {
    let entry: SunsetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryInline:
            // One line, system-drawn. No custom type — the system owns it.
            Label(inlineText, systemImage: "sunset.fill")

        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Text("SUNSET")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.2)
                    .widgetAccentable()
                Text(entry.countdown ?? "Set")
                    .font(.system(size: 22, weight: .bold))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text(entry.sunsetTime)
                    .font(.system(size: 12, weight: .medium))
                    .opacity(0.7)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        default:
            small
        }
    }

    /// Kicker, figure, footnote. Three sizes, decisively apart — the old
    /// version stacked 22, 26, 12 and 11pt, four near-identical steps that
    /// left nothing looking like the answer.
    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SUNSET")
                .riType(.label)
                .foregroundStyle(Color.riMint)

            Spacer(minLength: 6)

            Text(entry.countdown ?? "Tomorrow")
                .riType(.figure)
                .foregroundStyle(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .allowsTightening(true)

            Text(entry.countdown == nil ? "sun has set" : "to go")
                .riType(.caption)
                .foregroundStyle(.white.opacity(0.55))

            Spacer(minLength: 6)

            Text(entry.sunsetTime)
                .riType(.caption, weight: .semibold)
                .foregroundStyle(.white.opacity(0.8))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var inlineText: String {
        guard let c = entry.countdown else { return "Sunset \(entry.sunsetTime)" }
        return "Sunset in \(c)"
    }
}
