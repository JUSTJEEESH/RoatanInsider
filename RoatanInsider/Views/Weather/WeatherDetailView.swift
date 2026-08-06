import SwiftUI

/// Marker type for the weather screen.
struct WeatherDestination: Hashable {}

/// Conditions on Roatán, laid out the way iOS Weather lays them out —
/// because that layout is genuinely the best solved version of this problem.
///
/// Three things are borrowed, all structural:
///   - One metric picker driving both the hourly scrubber and the ten-day
///     list, so the same question gets answered at two timescales.
///   - A grid of metric tiles, each pairing a single reading with the
///     sentence that says what to do about it.
///   - Every chart drawn against a scale shared by its whole list, so a week
///     reads as a shape rather than as fourteen numbers.
///
/// Nothing visual is borrowed. iOS Weather is a photographic sky behind
/// translucent glass; this is flat off-white on white with the app's own two
/// accents, because a weather screen that looked like it came from a
/// different product would undo the point of the redesign.
///
/// And one tile exists that iOS Weather has no reason to have: the water.
/// Snorkelling and diving are why most people are on this island, and swell
/// plus wind is the reading that decides their day.
struct WeatherDetailView: View {
    @Environment(WeatherService.self) private var weather

    @State private var metric: WeatherMetric = .conditions

    private let columns = [
        GridItem(.flexible(), spacing: AppConstants.Space.snug),
        GridItem(.flexible(), spacing: AppConstants.Space.snug),
    ]

    var body: some View {
        ScrollView {
            if let conditions = weather.conditions {
                VStack(alignment: .leading, spacing: AppConstants.Space.block) {
                    hero(conditions)
                    forecastPanel(conditions)
                    tiles(conditions)
                    footer(conditions)
                }
                .padding(.bottom, AppConstants.Space.block)
            } else {
                EmptyStateView(
                    symbol: "cloud.sun",
                    title: "No conditions yet",
                    message: "We haven't reached the forecast. It'll fill in once you're back on a signal."
                )
            }
        }
        .navigationTitle("Conditions")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.riWhite)
        .task { await weather.refreshIfNeeded() }
        .refreshable { await weather.refresh() }
    }

    // MARK: - Hero

    private func hero(_ c: WeatherService.Conditions) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("ROATÁN")
                .riType(.label)
                .foregroundStyle(Color.riMediumGray)

            Text("\(Int(c.temperatureF.rounded()))°")
                .font(.system(size: 76, weight: .thin))
                .tracking(-2)
                .foregroundStyle(Color.riDark)

            Text(weather.weatherLabel)
                .riType(.heading)
                .foregroundStyle(Color.riDark)

            if let today = c.daily.first {
                Text("H:\(Int(today.highF.rounded()))°  L:\(Int(today.lowF.rounded()))°")
                    .riType(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Color.riMediumGray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppConstants.Space.gutter)
        .padding(.top, AppConstants.Space.snug)
        .accessibilityElement(children: .combine)
    }

    // MARK: - The panel that changes

    @ViewBuilder
    private func forecastPanel(_ c: WeatherService.Conditions) -> some View {
        let hours = upcomingHours(c.hourly)
        if !hours.isEmpty || !c.daily.isEmpty {
            VStack(alignment: .leading, spacing: AppConstants.Space.snug) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(metric.title)
                            .riType(.heading)
                            .foregroundStyle(Color.riDark)
                        Text(metric.subtitle)
                            .riType(.caption)
                            .foregroundStyle(Color.riMediumGray)
                    }
                    Spacer(minLength: AppConstants.Space.tight)
                    WeatherMetricPicker(selection: $metric)
                }
                .padding(.horizontal, AppConstants.Space.gutter)

                if !hours.isEmpty {
                    HourlyScrubber(hours: hours, metric: metric)
                        .padding(.horizontal, AppConstants.Space.gutter - 8)
                }

                if !c.daily.isEmpty {
                    TenDayList(days: c.daily, metric: metric)
                        .padding(.horizontal, AppConstants.Space.gutter)
                        .padding(.top, AppConstants.Space.tight)
                }
            }
        }
    }

    // MARK: - Metric tiles

    private func tiles(_ c: WeatherService.Conditions) -> some View {
        LazyVGrid(columns: columns, spacing: AppConstants.Space.snug) {
            waterTile(c)
            uvTile(c)
            windTile(c)
            sunTile(c)
            feelsLikeTile(c)
            moonTile()
            rainTile(c)
            visibilityTile(c)
        }
        .padding(.horizontal, AppConstants.Space.gutter)
    }

    /// First, because it's the reading most people on this island are
    /// actually here for.
    private func waterTile(_ c: WeatherService.Conditions) -> some View {
        WeatherMetricTile(
            icon: "water.waves",
            label: "The water",
            footnote: waterFootnote(c)
        ) {
            WeatherMetricValue(value: weather.snorkelLabel)
        }
    }

    private func uvTile(_ c: WeatherService.Conditions) -> some View {
        WeatherMetricTile(icon: "sun.max", label: "UV index", footnote: uvAdvice) {
            VStack(alignment: .leading, spacing: AppConstants.Space.snug) {
                WeatherMetricValue(
                    value: "\(weather.uvIndexValue)",
                    caption: weather.uvBandLabel
                )
                UVScaleBar(index: weather.uvIndexValue)
            }
        }
    }

    private func windTile(_ c: WeatherService.Conditions) -> some View {
        WeatherMetricTile(
            icon: "wind",
            label: "Wind",
            footnote: "From the \(WindCompass.cardinal(currentWindDegrees(c)))"
                + (currentGust(c) > c.windMph ? " · gusting \(Int(currentGust(c).rounded()))" : "")
        ) {
            WindCompass(
                degrees: currentWindDegrees(c),
                speed: "\(Int(c.windMph.rounded())) mph"
            )
            .frame(height: 64)
        }
    }

    private func sunTile(_ c: WeatherService.Conditions) -> some View {
        let horizon = SunsetCalculator.nextHorizonEvent()
        return WeatherMetricTile(
            icon: horizon.symbol,
            label: horizon.label,
            footnote: horizon.kind == .sunset
                ? "Sunrise \(SunArcView.timeLabel(SunsetCalculator.todaySunrise()))"
                : "Sunset \(SunArcView.timeLabel(SunsetCalculator.todaySunset()))"
        ) {
            VStack(alignment: .leading, spacing: AppConstants.Space.tight) {
                Text(horizon.timeString)
                    .riType(.title)
                    .monospacedDigit()
                    .foregroundStyle(Color.riDark)
                SunArcMini()
                    .frame(height: 38)
            }
        }
    }

    private func feelsLikeTile(_ c: WeatherService.Conditions) -> some View {
        let feels = currentFeelsLike(c)
        let delta = feels - c.temperatureF
        return WeatherMetricTile(
            icon: "thermometer.medium",
            label: "Feels like",
            footnote: abs(delta) < 1.5
                ? "About the same as the actual temperature."
                : (delta > 0
                   ? "Humidity is making it feel warmer."
                   : "The breeze is taking the edge off.")
        ) {
            WeatherMetricValue(value: "\(Int(feels.rounded()))°")
        }
    }

    private func moonTile() -> some View {
        let phase = MoonPhase()
        return WeatherMetricTile(
            icon: "moon",
            label: phase.name.rawValue,
            footnote: "\(Int((phase.illumination * 100).rounded()))% lit"
        ) {
            MoonPhaseDisc(phase: phase)
                .frame(height: 62)
        }
    }

    private func rainTile(_ c: WeatherService.Conditions) -> some View {
        let today = c.daily.first
        let tomorrow = c.daily.dropFirst().first
        return WeatherMetricTile(
            icon: "drop",
            label: "Rain today",
            footnote: tomorrow.map { day in
                day.precipitationInches >= 0.01
                    ? String(format: "%.2f\" expected tomorrow.", day.precipitationInches)
                    : "Nothing much expected tomorrow."
            }
        ) {
            WeatherMetricValue(
                value: (today?.precipitationInches ?? 0) >= 0.01
                    ? String(format: "%.2f\"", today?.precipitationInches ?? 0)
                    : "None",
                caption: today.map { "\($0.precipitationChance)% chance" }
            )
        }
    }

    private func visibilityTile(_ c: WeatherService.Conditions) -> some View {
        let miles = currentVisibility(c)
        return WeatherMetricTile(
            icon: "eye",
            label: "Visibility",
            footnote: miles >= 10
                ? "Clear across to the mainland on a good day."
                : (miles >= 4 ? "Hazy out over the water." : "Murky — squalls about.")
        ) {
            WeatherMetricValue(value: "\(Int(miles.rounded())) mi")
        }
    }

    // MARK: - Readings for right now
    //
    // The `current` block from Open-Meteo carries temperature, wind and UV
    // but not the rest, so anything else comes from the hour we're standing
    // in. Falling back to the first available hour keeps the tile populated
    // rather than showing a zero.

    private func currentHour(_ c: WeatherService.Conditions) -> WeatherService.HourPoint? {
        let now = Date()
        return c.hourly.last { $0.time <= now } ?? c.hourly.first
    }

    private func currentFeelsLike(_ c: WeatherService.Conditions) -> Double {
        let feels = currentHour(c)?.feelsLikeF ?? 0
        return feels > 0 ? feels : c.temperatureF
    }

    private func currentWindDegrees(_ c: WeatherService.Conditions) -> Double {
        currentHour(c)?.windDegrees ?? 0
    }

    private func currentGust(_ c: WeatherService.Conditions) -> Double {
        currentHour(c)?.gustMph ?? 0
    }

    private func currentVisibility(_ c: WeatherService.Conditions) -> Double {
        let miles = currentHour(c)?.visibilityMiles ?? 0
        return miles > 0 ? miles : 10
    }

    /// From the current hour forward. The API returns the whole day
    /// including hours already gone.
    private func upcomingHours(_ hourly: [WeatherService.HourPoint]) -> [WeatherService.HourPoint] {
        let cutoff = Calendar.current.date(byAdding: .hour, value: -1, to: .now) ?? .now
        return Array(hourly.filter { $0.time > cutoff }.prefix(24))
    }

    // MARK: - Copy

    /// States what the judgement is built from, so it can be argued with. A
    /// bare "Good" from an app nobody can question is worth less than a
    /// number a diver can check against their own eyes.
    private func waterFootnote(_ c: WeatherService.Conditions) -> String {
        var parts: [String] = []
        if let waves = c.waveHeightMeters {
            parts.append(String(format: "Swell %.1fm", waves))
        }
        parts.append("wind \(Int(c.windMph.rounded())) mph")
        return parts.joined(separator: " · ")
    }

    private var uvAdvice: String {
        switch weather.uvIndexValue {
        case 0..<3:  return "Nothing to plan around."
        case 3..<6:  return "Reef-safe sunscreen if you're out a while."
        case 6..<8:  return "Burns in under half an hour. Shade at midday."
        case 8..<11: return "Burns fast. A shirt in the water beats reapplying."
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
}
