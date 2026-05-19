import Foundation

/// User's day-by-day trip plan. Persisted in UserDefaults as Codable JSON via
/// TripPlanStore. The plan is keyed on yyyy-MM-dd date strings so date math
/// stays the responsibility of `Calendar.current`, not of timezones-in-JSON.
///
/// The plan is rebuilt automatically when the user changes their arrival or
/// departure dates in UserProfile. Items added by the user are preserved
/// across regenerations as long as the date is still in range.
struct TripPlan: Codable, Equatable {
    var arrivalDate: Date
    var departureDate: Date
    /// Keyed by `TripPlan.dateKey(for:)`. Value is an ordered list of business IDs.
    var itemsByDate: [String: [String]]
    var lastGenerated: Date?

    static func dateKey(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone.current
        return f.string(from: date)
    }

    /// Ordered list of days from arrival to departure inclusive.
    var days: [ItineraryDay] {
        var result: [ItineraryDay] = []
        let cal = Calendar.current
        var cursor = cal.startOfDay(for: arrivalDate)
        let end = cal.startOfDay(for: departureDate)
        var dayNumber = 1
        while cursor <= end {
            let key = TripPlan.dateKey(for: cursor)
            result.append(ItineraryDay(
                dayNumber: dayNumber,
                dateKey: key,
                date: cursor,
                itemIds: itemsByDate[key] ?? []
            ))
            guard let next = cal.date(byAdding: .day, value: 1, to: cursor) else { break }
            cursor = next
            dayNumber += 1
        }
        return result
    }

    var totalItems: Int {
        itemsByDate.values.reduce(0) { $0 + $1.count }
    }
}

struct ItineraryDay: Identifiable, Hashable {
    let dayNumber: Int
    let dateKey: String
    let date: Date
    let itemIds: [String]

    var id: String { dateKey }

    var dayLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEE, MMM d"
        return f.string(from: date)
    }
}
