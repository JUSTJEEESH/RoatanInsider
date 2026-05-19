import WidgetKit
import SwiftUI

/// "Today on Roatán" — a small widget combining sunset countdown with a
/// curated daily insider pick that the host app writes into the shared
/// App Group defaults.
///
/// App Group setup:
///   1. In both targets (app + widget), enable Capability → App Groups.
///   2. Add a group named `group.com.roataninsider.shared`.
///   3. Anywhere the app wants the widget to pick up a value, write it via
///      `UserDefaults(suiteName: "group.com.roataninsider.shared")`.
///   4. The widget reads from the same suite below.
struct TodayWidget: Widget {
    let kind: String = "TodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayProvider()) { entry in
            TodayWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color(red: 0.18, green: 0.18, blue: 0.18)
                }
        }
        .configurationDisplayName("Today on Roatán")
        .description("Sunset countdown plus today's insider pick.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct TodayEntry: TimelineEntry {
    let date: Date
    let sunsetCountdown: String?
    let temperatureLabel: String?
    let pickName: String?
    let pickArea: String?
}

struct TodayProvider: TimelineProvider {
    private static let appGroup = "group.com.roataninsider.shared"

    func placeholder(in context: Context) -> TodayEntry {
        TodayEntry(date: .now, sunsetCountdown: "2h 14m", temperatureLabel: "84°", pickName: "Sundowners Bar", pickArea: "West End")
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
            sunsetCountdown: sunsetCountdown(at: date),
            temperatureLabel: defaults?.string(forKey: "weather.temperature"),
            pickName: defaults?.string(forKey: "pick.name"),
            pickArea: defaults?.string(forKey: "pick.area")
        )
    }

    private func sunsetCountdown(at date: Date) -> String? {
        let sunset = SunsetCalculator.todaySunset()
        let remaining = sunset.timeIntervalSince(date)
        guard remaining > 0 else { return nil }
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}

struct TodayWidgetView: View {
    let entry: TodayEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemMedium:
            HStack(alignment: .top, spacing: 14) {
                liveColumn
                Divider().background(Color.white.opacity(0.15))
                pickColumn
            }
        default:
            VStack(alignment: .leading, spacing: 8) {
                if let temp = entry.temperatureLabel {
                    Text(temp)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                }

                if let c = entry.sunsetCountdown {
                    HStack(spacing: 4) {
                        Image(systemName: "sunset.fill")
                        Text(c).font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(Color.orange)
                }

                Spacer()

                if let name = entry.pickName {
                    Text("INSIDER PICK")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.5))
                    Text(name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    if let area = entry.pickArea {
                        Text(area)
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
        }
    }

    private var liveColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("RIGHT NOW")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(.white.opacity(0.5))

            if let temp = entry.temperatureLabel {
                Text(temp)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)
            }

            if let c = entry.sunsetCountdown {
                HStack(spacing: 4) {
                    Image(systemName: "sunset.fill")
                    Text("Sunset in \(c)")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(.orange)
            }
            Spacer()
        }
    }

    private var pickColumn: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("INSIDER PICK")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(.white.opacity(0.5))

            Text(entry.pickName ?? "Open the app for today's pick")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(2)

            if let area = entry.pickArea {
                Text(area)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
        }
    }
}
