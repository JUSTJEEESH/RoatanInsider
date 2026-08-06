import SwiftUI

/// Conditions, precipitation or wind — one choice, two views.
///
/// This is the idea worth borrowing from iOS Weather, and it's structural
/// rather than decorative: a single segmented control drives both the hourly
/// scrubber and the ten-day list, so the same question gets asked at two
/// timescales and the answer lines up. Three separate sections stacked down
/// the page would carry the same data and be far harder to read.
enum WeatherMetric: String, CaseIterable, Identifiable {
    case conditions, precipitation, wind

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .conditions:    return "cloud.sun.fill"
        case .precipitation: return "drop.fill"
        case .wind:          return "wind"
        }
    }

    var title: String {
        switch self {
        case .conditions:    return "Conditions"
        case .precipitation: return "Precipitation"
        case .wind:          return "Wind"
        }
    }

    var subtitle: String {
        switch self {
        case .conditions:    return "Temperature (°F)"
        case .precipitation: return "Chance of rain"
        case .wind:          return "Speed (mph) · gusts"
        }
    }

    var accessibilityName: String { title }
}

// MARK: - Picker

struct WeatherMetricPicker: View {
    @Binding var selection: WeatherMetric

    var body: some View {
        HStack(spacing: 0) {
            ForEach(WeatherMetric.allCases) { metric in
                Button {
                    Haptics.select()
                    withAnimation(.easeInOut(duration: 0.18)) { selection = metric }
                } label: {
                    Image(systemName: metric.symbol)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(selection == metric ? Color.riDark : Color.riLightGray)
                        .frame(width: 40, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: AppConstants.Radius.small, style: .continuous)
                                .fill(selection == metric ? Color.riWhite : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(metric.accessibilityName)
                .accessibilityAddTraits(selection == metric ? [.isSelected, .isButton] : .isButton)
            }
        }
        .padding(2)
        .background(Color.riDark.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.small + 2, style: .continuous))
    }
}

// MARK: - Hourly scrubber

/// The next twenty-four hours, scrolling sideways, showing whichever metric
/// is selected.
struct HourlyScrubber: View {
    let hours: [WeatherService.HourPoint]
    let metric: WeatherMetric

    private static let columnWidth: CGFloat = 58

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(Array(hours.enumerated()), id: \.element.id) { index, hour in
                    column(hour, isNow: index == 0)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Hourly \(metric.accessibilityName)")
    }

    private func column(_ hour: WeatherService.HourPoint, isNow: Bool) -> some View {
        VStack(spacing: AppConstants.Space.tight) {
            Text(isNow ? "Now" : Self.hourLabel(hour.time))
                .riType(.caption, weight: isNow ? .semibold : .regular)
                .foregroundStyle(isNow ? Color.riDark : Color.riMediumGray)
                .lineLimit(1)

            switch metric {
            case .conditions:
                Image(systemName: hour.symbol)
                    .font(.system(size: 17, weight: .light))
                    .foregroundStyle(Color.riDark)
                    .frame(height: 22)
                Text("\(Int(hour.temperatureF.rounded()))°")
                    .riType(.caption, weight: .semibold)
                    .monospacedDigit()
                    .foregroundStyle(Color.riDark)

            case .precipitation:
                bar(fraction: Double(hour.precipitationChance) / 100, tint: Color.riMint)
                Text(hour.precipitationChance >= 5 ? "\(hour.precipitationChance)%" : "—")
                    .riType(.caption, weight: .semibold)
                    .monospacedDigit()
                    .foregroundStyle(hour.precipitationChance >= 20 ? Color.riMint : Color.riLightGray)

            case .wind:
                bar(fraction: min(1, hour.windMph / 30), tint: Color.riDark.opacity(0.35))
                Text("\(Int(hour.windMph.rounded()))")
                    .riType(.caption, weight: .semibold)
                    .monospacedDigit()
                    .foregroundStyle(Color.riDark)
            }
        }
        .frame(width: Self.columnWidth)
        .padding(.vertical, AppConstants.Space.tight)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Self.label(hour, isNow: isNow, metric: metric))
    }

    /// A column drawn from the bottom, so a row of them reads as a shape
    /// before any of the numbers are read.
    private func bar(fraction: Double, tint: Color) -> some View {
        VStack {
            Spacer(minLength: 0)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(tint)
                .frame(width: 6, height: max(2, CGFloat(fraction) * 22))
        }
        .frame(height: 22)
    }

    static func hourLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        formatter.timeZone = TimeZone(identifier: "America/Tegucigalpa")
        return formatter.string(from: date).replacingOccurrences(of: "AM", with: "AM")
    }

    private static func label(_ hour: WeatherService.HourPoint, isNow: Bool, metric: WeatherMetric) -> String {
        let when = isNow ? "Now" : hourLabel(hour.time)
        switch metric {
        case .conditions:    return "\(when), \(Int(hour.temperatureF.rounded())) degrees"
        case .precipitation: return "\(when), \(hour.precipitationChance) percent chance of rain"
        case .wind:          return "\(when), wind \(Int(hour.windMph.rounded())) miles per hour"
        }
    }
}

// MARK: - Ten day

/// The ten-day outlook, in whichever metric is selected.
///
/// Every row is drawn against a scale shared by the whole list, so the week
/// reads as a shape. Without the shared scale each bar means nothing on its
/// own — which is the difference between a chart and decoration.
struct TenDayList: View {
    let days: [WeatherService.DayPoint]
    let metric: WeatherMetric

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(days.enumerated()), id: \.element.id) { index, day in
                if index > 0 {
                    Divider().overlay(Color.riDark.opacity(0.08))
                }
                row(day, isToday: index == 0)
            }
        }
    }

    private func row(_ day: WeatherService.DayPoint, isToday: Bool) -> some View {
        HStack(spacing: AppConstants.Space.snug) {
            Text(isToday ? "Today" : Self.weekdayLabel(day.date))
                .riType(.caption, weight: isToday ? .semibold : .regular)
                .foregroundStyle(isToday ? Color.riDark : Color.riMediumGray)
                .frame(width: 52, alignment: .leading)

            VStack(spacing: 1) {
                Image(systemName: day.symbol)
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(Color.riDark)
                if day.precipitationChance >= 20 {
                    Text("\(day.precipitationChance)%")
                        .riType(.micro, weight: .semibold)
                        .monospacedDigit()
                        .foregroundStyle(Color.riMint)
                }
            }
            .frame(width: 32)

            switch metric {
            case .conditions:   temperatureRow(day)
            case .precipitation: precipitationRow(day)
            case .wind:          windRow(day)
            }
        }
        .padding(.vertical, AppConstants.Space.snug)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Self.label(day, isToday: isToday, metric: metric))
    }

    // MARK: Per-metric rows

    private func temperatureRow(_ day: WeatherService.DayPoint) -> some View {
        HStack(spacing: AppConstants.Space.snug) {
            Text("\(Int(day.lowF.rounded()))°")
                .riType(.caption)
                .monospacedDigit()
                .foregroundStyle(Color.riLightGray)
                .frame(width: 30, alignment: .trailing)

            rangeBar(low: day.lowF, high: day.highF, range: temperatureScale)

            Text("\(Int(day.highF.rounded()))°")
                .riType(.caption, weight: .semibold)
                .monospacedDigit()
                .foregroundStyle(Color.riDark)
                .frame(width: 30, alignment: .leading)
        }
    }

    private func precipitationRow(_ day: WeatherService.DayPoint) -> some View {
        HStack(spacing: AppConstants.Space.snug) {
            proportionBar(fraction: Double(day.precipitationChance) / 100, tint: Color.riMint)

            Text(day.precipitationInches >= 0.01
                 ? String(format: "%.2f\"", day.precipitationInches)
                 : "—")
                .riType(.caption, weight: .semibold)
                .monospacedDigit()
                .foregroundStyle(day.precipitationInches >= 0.01 ? Color.riDark : Color.riLightGray)
                .frame(width: 52, alignment: .trailing)
        }
    }

    private func windRow(_ day: WeatherService.DayPoint) -> some View {
        HStack(spacing: AppConstants.Space.snug) {
            proportionBar(fraction: min(1, day.windMaxMph / 30), tint: Color.riDark.opacity(0.35))

            Text("\(Int(day.windMaxMph.rounded()))–\(Int(day.gustMaxMph.rounded())) mph")
                .riType(.caption, weight: .semibold)
                .monospacedDigit()
                .foregroundStyle(Color.riDark)
                .frame(width: 86, alignment: .trailing)
        }
    }

    // MARK: Bars

    private func rangeBar(low: Double, high: Double, range: ClosedRange<Double>) -> some View {
        GeometryReader { geo in
            let span = max(1, range.upperBound - range.lowerBound)
            let leading = (low - range.lowerBound) / span * geo.size.width
            let width = max(6, (high - low) / span * geo.size.width)
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

    private func proportionBar(fraction: Double, tint: Color) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.riDark.opacity(0.07))
                Capsule()
                    .fill(tint)
                    .frame(width: max(3, CGFloat(fraction) * geo.size.width))
            }
        }
        .frame(height: 4)
        .frame(maxWidth: .infinity)
    }

    private var temperatureScale: ClosedRange<Double> {
        let low = days.map(\.lowF).min() ?? 70
        let high = days.map(\.highF).max() ?? 90
        return low...max(low + 1, high)
    }

    // MARK: Labels

    static func weekdayLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        formatter.timeZone = TimeZone(identifier: "America/Tegucigalpa")
        return formatter.string(from: date)
    }

    private static func label(_ day: WeatherService.DayPoint, isToday: Bool, metric: WeatherMetric) -> String {
        let when = isToday ? "Today" : weekdayLabel(day.date)
        switch metric {
        case .conditions:
            return "\(when), \(day.summary), high \(Int(day.highF.rounded())), low \(Int(day.lowF.rounded()))"
        case .precipitation:
            return "\(when), \(day.precipitationChance) percent chance, "
                + String(format: "%.2f inches", day.precipitationInches)
        case .wind:
            return "\(when), wind \(Int(day.windMaxMph.rounded())) gusting \(Int(day.gustMaxMph.rounded())) miles per hour"
        }
    }
}
