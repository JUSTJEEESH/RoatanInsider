import SwiftUI

/// Replaces the old marketing hero with a one-line personal greeting and
/// a context-aware subtitle that earns its space by reflecting onboarding
/// answers back to the user.
struct HomeGreeting: View {
    @Environment(UserProfileStore.self) private var profileStore

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(greeting)
                .riDisplayStyle(32)
                .foregroundStyle(Color.riDark)

            Text(subtitle)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color.riLightGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

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

    private var subtitle: String {
        let profile = profileStore.profile

        if profile.travelerType == .cruiser {
            return "Cruise day on Roatán."
        }

        if profile.isCurrentlyOnIsland,
           let arrival = profile.arrivalDate,
           let departure = profile.departureDate {
            let total = max(1, daysBetween(arrival, departure) + 1)
            let dayNumber = min(total, max(1, daysBetween(arrival, .now) + 1))
            return "Day \(dayNumber) of \(total) on Roatán."
        }

        if let days = profile.daysUntilArrival, days > 0 {
            return days == 1 ? "1 day until Roatán." : "\(days) days until Roatán."
        }

        return "\(weekdayName()) on Roatán."
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
