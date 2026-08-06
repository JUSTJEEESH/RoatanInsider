import SwiftUI

/// The next ten hours, hour by hour.
///
/// The header line above this carries the summary — temperature, sunset,
/// snorkel — and it earns its space by being the fastest read on the screen.
/// What it can't do is show change over time, which is the entire reason a
/// weather app is worth opening. On this island the question that actually
/// moves plans is whether the afternoon squall lands before the boat goes
/// out, and only an hourly view answers it.
///
/// So: the same hourly scrubber the weather screen uses, in its conditions
/// mode. Sharing the component rather than drawing a second, simpler version
/// means an hour looks like the same object on both screens and neither can
/// drift. A row of static chips reporting four numbers — which is what stood
/// here before the last pass — could do none of this.
struct ConditionsBand: View {
    @Environment(WeatherService.self) private var weather

    /// Below this, "10% chance" is noise dressed up as information.
    private static let notableRainChance = 20
    private static let hoursShown = 10

    var body: some View {
        if let conditions = weather.conditions, !conditions.hourly.isEmpty {
            let hours = upcoming(from: conditions.hourly)
            if !hours.isEmpty {
                VStack(alignment: .leading, spacing: AppConstants.Space.snug) {
                    header(rainPeak: hours.max(by: { $0.precipitationChance < $1.precipitationChance }))

                    // The same scrubber the weather screen uses, so the
                    // hourly strip is one object drawn twice rather than two
                    // drawings that can drift apart.
                    HourlyScrubber(hours: hours, metric: .conditions)
                        .padding(.horizontal, AppConstants.Space.gutter - 8)
                }
                .onAppear { Analytics.track(.homeSectionViewed(name: "conditions")) }
            }
        }
    }

    // MARK: - Header

    /// Names the one thing worth knowing about the next ten hours, rather
    /// than restating the temperature the line above already gave.
    private func header(rainPeak: WeatherService.HourPoint?) -> some View {
        NavigationLink(value: WeatherDestination()) {
            HStack(alignment: .firstTextBaseline, spacing: AppConstants.Space.tight) {
                Text("NEXT FEW HOURS")
                    .riType(.label)
                    .foregroundStyle(Color.riMediumGray)

                if let rainPeak, rainPeak.precipitationChance >= Self.notableRainChance {
                    Text("· \(rainPeak.precipitationChance)% rain around \(HourlyScrubber.hourLabel(rainPeak.time))")
                        .riType(.caption)
                        .foregroundStyle(Color.riMediumGray)
                        .lineLimit(1)
                }

                Spacer(minLength: AppConstants.Space.hair)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.riLightGray)
            }
            .padding(.horizontal, AppConstants.Space.gutter)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Data

    /// From the current hour forward. The API returns the whole day
    /// including hours already gone, and a strip that starts at midnight is
    /// a strip nobody reads.
    private func upcoming(from hourly: [WeatherService.HourPoint]) -> [WeatherService.HourPoint] {
        let cutoff = Calendar.current.date(byAdding: .hour, value: -1, to: .now) ?? .now
        return Array(hourly.filter { $0.time > cutoff }.prefix(Self.hoursShown))
    }
}
