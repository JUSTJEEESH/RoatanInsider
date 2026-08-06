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
/// So: a temperature line you can read as a shape, and a rain bar that only
/// draws when there's rain worth mentioning. A row of static chips reporting
/// four numbers — which is what stood here before the last pass — cannot do
/// either.
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

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .bottom, spacing: 0) {
                            ForEach(Array(hours.enumerated()), id: \.element.id) { index, hour in
                                column(hour, isNow: index == 0)
                            }
                        }
                        .padding(.horizontal, AppConstants.Space.gutter)
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Hourly forecast")
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
                    Text("· \(rainPeak.precipitationChance)% rain around \(Self.hourLabel(rainPeak.time))")
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

    // MARK: - One hour

    private func column(_ hour: WeatherService.HourPoint, isNow: Bool) -> some View {
        VStack(spacing: AppConstants.Space.tight) {
            Text(isNow ? "Now" : Self.hourLabel(hour.time))
                .riType(.caption, weight: isNow ? .semibold : .regular)
                .foregroundStyle(isNow ? Color.riDark : Color.riMediumGray)
                .lineLimit(1)

            Image(systemName: hour.symbol)
                .font(.system(size: 17, weight: .light))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(Color.riDark)
                .frame(height: 22)

            Text("\(Int(hour.temperatureF.rounded()))°")
                .riType(.caption, weight: .semibold)
                .monospacedDigit()
                .foregroundStyle(Color.riDark)

            rainMark(hour.precipitationChance)
        }
        .frame(width: 54)
        .padding(.vertical, AppConstants.Space.tight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Self.accessibilityLabel(hour, isNow: isNow))
    }

    /// A bar whose height is the chance of rain, and nothing at all below the
    /// threshold — an empty slot reads as "dry" faster than "5%" does.
    @ViewBuilder
    private func rainMark(_ chance: Int) -> some View {
        if chance >= Self.notableRainChance {
            VStack(spacing: 3) {
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(Color.riMint)
                    .frame(width: 3, height: max(4, CGFloat(chance) / 100 * 20))
                Text("\(chance)%")
                    .riType(.micro, weight: .semibold)
                    .monospacedDigit()
                    .foregroundStyle(Color.riMint)
            }
            .frame(height: 34, alignment: .bottom)
        } else {
            Color.clear.frame(height: 34)
        }
    }

    // MARK: - Data

    /// From the current hour forward. The API returns the whole day
    /// including hours already gone, and a strip that starts at midnight is
    /// a strip nobody reads.
    private func upcoming(from hourly: [WeatherService.HourPoint]) -> [WeatherService.HourPoint] {
        let cutoff = Calendar.current.date(byAdding: .hour, value: -1, to: .now) ?? .now
        return Array(hourly.filter { $0.time > cutoff }.prefix(Self.hoursShown))
    }

    static func hourLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        formatter.timeZone = TimeZone(identifier: "America/Tegucigalpa")
        return formatter.string(from: date)
    }

    private static func accessibilityLabel(_ hour: WeatherService.HourPoint, isNow: Bool) -> String {
        var parts = [
            isNow ? "Now" : hourLabel(hour.time),
            "\(Int(hour.temperatureF.rounded())) degrees",
        ]
        if hour.precipitationChance >= notableRainChance {
            parts.append("\(hour.precipitationChance) percent chance of rain")
        }
        return parts.joined(separator: ", ")
    }
}
