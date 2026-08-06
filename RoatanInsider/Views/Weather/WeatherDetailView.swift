import SwiftUI

/// Marker type for the weather screen.
struct WeatherDestination: Hashable {}

/// The full conditions picture: the sun's day, the week ahead, the water,
/// and the sun strength.
///
/// Ordered by what a visitor to this island actually acts on. Sunrise and
/// sunset first, because half the reason anyone checks weather here is to
/// know when the light goes. Then the week, because that's when the boat
/// trip gets booked. The water and the UV last — reference, not decision.
struct WeatherDetailView: View {
    @Environment(WeatherService.self) private var weather
    @Environment(UnitPreference.self) private var units

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppConstants.Space.section) {
                if let conditions = weather.conditions {
                    now(conditions)
                    SunArcView()
                    week(conditions)
                    water(conditions)
                    sunStrength(conditions)
                    footer(conditions)
                } else {
                    EmptyStateView(
                        symbol: "cloud.sun",
                        title: "No conditions yet",
                        message: "We haven't been able to reach the forecast. It'll fill in once you're back on a signal."
                    )
                }
            }
            .padding(.bottom, AppConstants.Space.block)
        }
        .navigationTitle("Conditions")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.riWhite)
        .task { await weather.refreshIfNeeded() }
        .refreshable { await weather.refresh() }
    }

    // MARK: - Now

    private func now(_ c: WeatherService.Conditions) -> some View {
        VStack(alignment: .leading, spacing: AppConstants.Space.hair) {
            Text("RIGHT NOW")
                .riType(.label)
                .foregroundStyle(Color.riMediumGray)

            HStack(alignment: .firstTextBaseline, spacing: AppConstants.Space.snug) {
                Text("\(Int(c.temperatureF.rounded()))°")
                    .riType(.figure)
                    .foregroundStyle(Color.riDark)
                VStack(alignment: .leading, spacing: 2) {
                    Text(weather.weatherLabel)
                        .riType(.heading)
                        .foregroundStyle(Color.riDark)
                    Text("Wind \(Int(c.windKph.rounded())) km/h")
                        .riType(.caption)
                        .foregroundStyle(Color.riMediumGray)
                }
            }
        }
        .padding(.horizontal, AppConstants.Space.gutter)
        .padding(.top, AppConstants.Space.snug)
        .accessibilityElement(children: .combine)
    }

    // MARK: - The week

    @ViewBuilder
    private func week(_ c: WeatherService.Conditions) -> some View {
        if !c.daily.isEmpty {
            VStack(alignment: .leading, spacing: AppConstants.Space.snug) {
                Text("THE WEEK")
                    .riType(.label)
                    .foregroundStyle(Color.riMediumGray)

                let range = temperatureRange(c.daily)
                VStack(spacing: 0) {
                    ForEach(Array(c.daily.enumerated()), id: \.element.id) { index, day in
                        if index > 0 {
                            Divider().overlay(Color.riDark.opacity(0.08))
                        }
                        dayRow(day, isToday: index == 0, range: range)
                    }
                }
            }
            .padding(.horizontal, AppConstants.Space.gutter)
        }
    }

    /// High and low sit on a shared scale so the week reads as a shape
    /// rather than fourteen numbers. Without the shared scale each row's bar
    /// would be meaningless on its own.
    private func dayRow(_ day: WeatherService.DayPoint, isToday: Bool, range: ClosedRange<Double>) -> some View {
        HStack(spacing: AppConstants.Space.snug) {
            Text(isToday ? "Today" : Self.weekdayLabel(day.date))
                .riType(.caption, weight: isToday ? .semibold : .regular)
                .foregroundStyle(isToday ? Color.riDark : Color.riMediumGray)
                .frame(width: 56, alignment: .leading)

            Image(systemName: day.symbol)
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(Color.riDark)
                .frame(width: 22)

            Text(day.precipitationChance >= 20 ? "\(day.precipitationChance)%" : " ")
                .riType(.micro, weight: .semibold)
                .monospacedDigit()
                .foregroundStyle(Color.riMint)
                .frame(width: 30, alignment: .leading)

            Text("\(Int(day.lowF.rounded()))°")
                .riType(.caption)
                .monospacedDigit()
                .foregroundStyle(Color.riLightGray)

            temperatureBar(day: day, range: range)

            Text("\(Int(day.highF.rounded()))°")
                .riType(.caption, weight: .semibold)
                .monospacedDigit()
                .foregroundStyle(Color.riDark)
        }
        .padding(.vertical, AppConstants.Space.snug)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(isToday ? "Today" : Self.weekdayLabel(day.date)), \(day.summary), "
            + "high \(Int(day.highF.rounded())), low \(Int(day.lowF.rounded()))"
            + (day.precipitationChance >= 20 ? ", \(day.precipitationChance) percent rain" : "")
        )
    }

    private func temperatureBar(day: WeatherService.DayPoint, range: ClosedRange<Double>) -> some View {
        GeometryReader { geo in
            let span = max(1, range.upperBound - range.lowerBound)
            let leading = (day.lowF - range.lowerBound) / span * geo.size.width
            let width = max(6, (day.highF - day.lowF) / span * geo.size.width)
            ZStack(alignment: .leading) {
                Capsule().fill(Color.riDark.opacity(0.07))
                Capsule()
                    .fill(Color.riDark.opacity(0.45))
                    .frame(width: width)
                    .offset(x: leading)
            }
        }
        .frame(height: 4)
        .frame(maxWidth: .infinity)
    }

    private func temperatureRange(_ days: [WeatherService.DayPoint]) -> ClosedRange<Double> {
        let lows = days.map(\.lowF), highs = days.map(\.highF)
        let low = lows.min() ?? 70, high = highs.max() ?? 90
        return low...max(low + 1, high)
    }

    // MARK: - Water

    private func water(_ c: WeatherService.Conditions) -> some View {
        VStack(alignment: .leading, spacing: AppConstants.Space.snug) {
            Text("THE WATER")
                .riType(.label)
                .foregroundStyle(Color.riMediumGray)

            VStack(alignment: .leading, spacing: AppConstants.Space.hair) {
                Text("Snorkelling \(weather.snorkelLabel.lowercased())")
                    .riType(.heading)
                    .foregroundStyle(Color.riDark)

                Text(waterDetail(c))
                    .riType(.caption)
                    .foregroundStyle(Color.riMediumGray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, AppConstants.Space.gutter)
        .accessibilityElement(children: .combine)
    }

    /// States what the judgement is built from, so it can be argued with.
    /// A bare "Good" from an app nobody can question is worth less than a
    /// number a diver can check against their own eyes.
    private func waterDetail(_ c: WeatherService.Conditions) -> String {
        var parts: [String] = []
        if let waves = c.waveHeightMeters {
            parts.append("Swell about \(String(format: "%.1f", waves)) m")
        }
        parts.append("wind \(Int(c.windKph.rounded())) km/h")
        parts.append("the north shore stays calmer when it blows from the east")
        return parts.joined(separator: " · ")
    }

    // MARK: - Sun strength

    private func sunStrength(_ c: WeatherService.Conditions) -> some View {
        VStack(alignment: .leading, spacing: AppConstants.Space.snug) {
            Text("SUN")
                .riType(.label)
                .foregroundStyle(Color.riMediumGray)

            VStack(alignment: .leading, spacing: AppConstants.Space.hair) {
                Text("UV \(weather.uvIndexValue) · \(weather.uvBandLabel.lowercased())")
                    .riType(.heading)
                    .foregroundStyle(Color.riDark)

                Text(uvAdvice)
                    .riType(.caption)
                    .foregroundStyle(Color.riMediumGray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, AppConstants.Space.gutter)
        .accessibilityElement(children: .combine)
    }

    private var uvAdvice: String {
        switch weather.uvIndexValue {
        case 0..<3:  return "Nothing to plan around."
        case 3..<6:  return "Reef-safe sunscreen if you're out for a while."
        case 6..<8:  return "Burns in under half an hour. Shade between eleven and two."
        case 8..<11: return "Burns fast. A shirt in the water beats reapplying sunscreen."
        default:     return "Extreme. Stay out of open sun in the middle of the day."
        }
    }

    // MARK: - Footer

    private func footer(_ c: WeatherService.Conditions) -> some View {
        VStack(spacing: 2) {
            Text("Open-Meteo, for the middle of the island")
                .riType(.caption)
                .foregroundStyle(Color.riLightGray)
            Text("Updated \(Self.relative(c.fetchedAt)) · pull down to refresh")
                .riType(.caption)
                .foregroundStyle(Color.riLightGray)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppConstants.Space.gutter)
    }

    private static func relative(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: .now)
    }

    static func weekdayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.timeZone = TimeZone(identifier: "America/Tegucigalpa")
        return formatter.string(from: date)
    }
}
