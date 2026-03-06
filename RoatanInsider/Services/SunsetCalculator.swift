import Foundation

enum SunsetCalculator {
    // Roatán coordinates
    private static let latitude = 16.33
    private static let longitude = -86.52
    private static let timezoneOffset = -6.0 // CST (UTC-6)

    /// Returns today's sunset time as a Date
    static func todaySunset() -> Date {
        let calendar = Calendar.current
        let now = Date()
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: now) ?? 1

        let sunsetHour = solarSunsetHour(dayOfYear: dayOfYear)
        let hour = Int(sunsetHour)
        let minute = Int((sunsetHour - Double(hour)) * 60)

        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = minute
        components.second = 0
        components.timeZone = TimeZone(secondsFromGMT: Int(timezoneOffset * 3600))

        return calendar.date(from: components) ?? now
    }

    /// Time remaining until sunset, nil if sunset has passed
    static func timeUntilSunset() -> TimeInterval? {
        let remaining = todaySunset().timeIntervalSinceNow
        return remaining > 0 ? remaining : nil
    }

    /// Formatted countdown string
    static func sunsetCountdown() -> String? {
        guard let remaining = timeUntilSunset() else { return nil }
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    /// Formatted sunset time string
    static func sunsetTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.timeZone = TimeZone(secondsFromGMT: Int(timezoneOffset * 3600))
        return formatter.string(from: todaySunset())
    }

    // MARK: - Solar Calculation

    /// Simplified sunset hour calculation (local time)
    private static func solarSunsetHour(dayOfYear: Int) -> Double {
        let latRad = latitude * .pi / 180.0

        // Solar declination (simplified)
        let declination = -23.45 * cos(2.0 * .pi / 365.0 * Double(dayOfYear + 10))
        let decRad = declination * .pi / 180.0

        // Hour angle at sunset
        let cosHourAngle = -tan(latRad) * tan(decRad)
        let hourAngle = acos(max(-1, min(1, cosHourAngle))) * 180.0 / .pi

        // Solar noon adjustment for longitude within timezone
        // Roatán is at -86.52, CST center is -90
        let longitudeCorrection = (longitude - (timezoneOffset * 15)) / 15.0
        let solarNoon = 12.0 - longitudeCorrection

        // Sunset = solar noon + half-day length
        return solarNoon + hourAngle / 15.0
    }
}
