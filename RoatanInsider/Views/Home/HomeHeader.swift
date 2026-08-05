import SwiftUI

/// The top of Home: one warm line, then everything true about right now on
/// a single quiet line beneath it.
///
/// Replaces `HomeGreeting` + `LiveConditionsStrip`. The old pairing spent a
/// greeting card and a 2×2 grid of four icon chips — roughly a third of the
/// first screen — to deliver five short facts. Facts are not worth chrome:
/// they're set as one line of running metadata, so the first real content
/// starts above the fold instead of below it.
///
/// UV only appears when it's high enough to change behaviour. A chip that
/// reads "UV 4 moderate" is decoration; "UV 11 extreme" is advice.
struct HomeHeader: View {
    @Environment(UserProfileStore.self) private var profileStore
    @Environment(WeatherService.self) private var weather

    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.Space.tight) {
            Text(greeting)
                .riType(.display)
                .foregroundStyle(Color.riDark)

            Text(contextLine)
                .riType(.caption)
                .foregroundStyle(Color.riMediumGray)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppConstants.Space.gutter)
        .padding(.top, AppConstants.Space.gutter)
        .task { await weather.refreshIfNeeded() }
    }

    // MARK: - Greeting

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        let timeOfDay: String
        switch hour {
        case 5..<12:  timeOfDay = "Good morning"
        case 12..<17: timeOfDay = "Good afternoon"
        case 17..<21: timeOfDay = "Good evening"
        default:      timeOfDay = "Hello"
        }

        if let name = profileStore.profile.firstName, !name.isEmpty {
            return "\(timeOfDay), \(name)."
        }
        return "\(timeOfDay)."
    }

    // MARK: - Context + conditions, one line

    /// Where the user is in their trip, then the conditions that matter,
    /// joined with middots. Pieces drop out silently when unknown rather
    /// than rendering an empty slot.
    private var contextLine: String {
        var parts: [String] = [tripContext]

        if weather.conditions != nil {
            parts.append(weather.temperatureLabel)
            let horizon = SunsetCalculator.nextHorizonEvent()
            parts.append("\(horizon.label) \(horizon.timeString)")
            parts.append("Snorkel \(weather.snorkelLabel.lowercased())")

            // Only when it changes what you'd do.
            if weather.uvIndexValue >= 8 {
                parts.append("UV \(weather.uvIndexValue) \(weather.uvBandLabel.lowercased())")
            }
        }

        return parts.filter { !$0.isEmpty }.joined(separator: " · ")
    }

    private var tripContext: String {
        let profile = profileStore.profile

        if profile.travelerType == .cruiser {
            return "Cruise day"
        }

        if profile.isCurrentlyOnIsland,
           let arrival = profile.arrivalDate,
           let departure = profile.departureDate {
            let total = max(1, daysBetween(arrival, departure) + 1)
            let dayNumber = min(total, max(1, daysBetween(arrival, .now) + 1))
            return "Day \(dayNumber) of \(total)"
        }

        if let days = profile.daysUntilArrival, days > 0 {
            return days == 1 ? "1 day out" : "\(days) days out"
        }

        return weekdayName()
    }

    private func weekdayName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: .now)
    }

    private func daysBetween(_ start: Date, _ end: Date) -> Int {
        let calendar = Calendar.current
        let s = calendar.startOfDay(for: start)
        let e = calendar.startOfDay(for: end)
        return calendar.dateComponents([.day], from: s, to: e).day ?? 0
    }
}
