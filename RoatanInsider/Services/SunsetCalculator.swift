import Foundation

enum SunsetCalculator {
    // Roatán coordinates
    private static let latitude = 16.33
    private static let longitude = -86.52
    private static let timezoneOffset = -6.0 // CST (UTC-6)

    /// Returns today's sunset time as a Date
    static func todaySunset() -> Date {
        date(forHour: solarHour(dayOfYear: dayOfYearForNow(), event: .sunset), reference: .now)
    }

    /// Returns today's sunrise time as a Date
    static func todaySunrise() -> Date {
        date(forHour: solarHour(dayOfYear: dayOfYearForNow(), event: .sunrise), reference: .now)
    }

    /// Returns tomorrow's sunrise time as a Date
    static func tomorrowSunrise() -> Date {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: tomorrow) ?? 1
        return date(forHour: solarHour(dayOfYear: dayOfYear, event: .sunrise), reference: tomorrow)
    }

    /// Time remaining until sunset, nil if sunset has passed
    static func timeUntilSunset() -> TimeInterval? {
        let remaining = todaySunset().timeIntervalSinceNow
        return remaining > 0 ? remaining : nil
    }

    /// Formatted countdown string until sunset (sunset-specific)
    static func sunsetCountdown() -> String? {
        guard let remaining = timeUntilSunset() else { return nil }
        return countdownString(from: remaining)
    }

    /// Formatted sunset time string
    static func sunsetTimeString() -> String {
        formattedTime(todaySunset())
    }

    /// The next horizon event from now: today's sunrise if pre-dawn,
    /// today's sunset if daytime, tomorrow's sunrise if past sunset.
    static func nextHorizonEvent(now: Date = .now) -> HorizonEvent {
        let sunriseToday = todaySunrise()
        let sunsetToday = todaySunset()

        if sunriseToday > now {
            return HorizonEvent(kind: .sunrise, date: sunriseToday)
        }
        if sunsetToday > now {
            return HorizonEvent(kind: .sunset, date: sunsetToday)
        }
        return HorizonEvent(kind: .sunrise, date: tomorrowSunrise())
    }

    // MARK: - Shared helpers

    private static func dayOfYearForNow() -> Int {
        Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 1
    }

    private static func date(forHour solarHour: Double, reference: Date) -> Date {
        let calendar = Calendar.current
        let hour = Int(solarHour)
        let minute = Int((solarHour - Double(hour)) * 60)

        var components = calendar.dateComponents([.year, .month, .day], from: reference)
        components.hour = hour
        components.minute = minute
        components.second = 0
        components.timeZone = TimeZone(secondsFromGMT: Int(timezoneOffset * 3600))

        return calendar.date(from: components) ?? reference
    }

    private static func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.timeZone = TimeZone(secondsFromGMT: Int(timezoneOffset * 3600))
        return formatter.string(from: date)
    }

    fileprivate static func countdownString(from remaining: TimeInterval) -> String {
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    // MARK: - Solar Calculation

    private enum SolarEvent { case sunrise, sunset }

    /// Sunset or sunrise hour for a given day of year (local time)
    private static func solarHour(dayOfYear: Int, event: SolarEvent) -> Double {
        let latRad = latitude * .pi / 180.0

        let declination = -23.45 * cos(2.0 * .pi / 365.0 * Double(dayOfYear + 10))
        let decRad = declination * .pi / 180.0

        let cosHourAngle = -tan(latRad) * tan(decRad)
        let hourAngle = acos(max(-1, min(1, cosHourAngle))) * 180.0 / .pi

        // Roatán is at -86.52, CST center is -90
        let longitudeCorrection = (longitude - (timezoneOffset * 15)) / 15.0
        let solarNoon = 12.0 - longitudeCorrection

        let halfDay = hourAngle / 15.0
        return event == .sunset ? solarNoon + halfDay : solarNoon - halfDay
    }
}

struct HorizonEvent {
    enum Kind { case sunrise, sunset }

    let kind: Kind
    let date: Date

    var label: String {
        switch kind {
        case .sunrise: return "Sunrise"
        case .sunset:  return "Sunset"
        }
    }

    var symbol: String {
        switch kind {
        case .sunrise: return "sunrise.fill"
        case .sunset:  return "sunset.fill"
        }
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.timeZone = TimeZone(secondsFromGMT: -6 * 3600)
        return formatter.string(from: date)
    }

    var countdown: String? {
        let remaining = date.timeIntervalSinceNow
        guard remaining > 0 else { return nil }
        return SunsetCalculator.countdownString(from: remaining)
    }
}
