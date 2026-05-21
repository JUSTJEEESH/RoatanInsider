import Foundation

/// A single event on the island — either a recurring weekly slot
/// (most of the schedule) or a one-off special. Bundled at launch from
/// `events.json` and queried by `EventsService`.
struct Event: Identifiable, Codable, Hashable {
    let id: String
    let venue: String
    let venueId: String?
    let area: String
    let category: EventCategory
    let performer: String
    let day: Weekday?
    let date: Date?
    let startTime: String   // 24hr "HH:mm"
    let endTime: String?
    let genre: String?
    let notes: String?
    let recurring: Bool?
    let recurringRule: String?
    let specialEvent: Bool?
    let featured: Bool?
    let cruiseShipDayOnly: Bool?
    let weatherDependent: Bool?
    let contact: String?
    let active: Bool?
    let lastUpdated: Date?

    var isRecurring: Bool       { recurring ?? false }
    var isSpecial: Bool         { specialEvent ?? false }
    var isFeatured: Bool        { featured ?? false }
    var isCruiseDayOnly: Bool   { cruiseShipDayOnly ?? false }
    var isWeatherDependent: Bool { weatherDependent ?? false }
    var isActive: Bool          { active ?? true }

    /// Start time of THIS event today, anchored to current calendar day.
    /// For recurring events without a specific date, returns the next
    /// occurrence on the matching weekday.
    func nextOccurrence(after reference: Date = .now, calendar: Calendar = .current) -> Date? {
        if let date {
            return Self.combine(date: date, time: startTime, calendar: calendar)
        }
        guard let day else { return nil }
        let targetWeekday = day.calendarWeekday
        var components = calendar.dateComponents([.year, .month, .day], from: reference)
        let currentWeekday = calendar.component(.weekday, from: reference)
        let daysAhead = (targetWeekday - currentWeekday + 7) % 7
        guard let dayStart = calendar.date(from: components),
              let target = calendar.date(byAdding: .day, value: daysAhead, to: dayStart),
              let combined = Self.combine(date: target, time: startTime, calendar: calendar) else {
            return nil
        }
        _ = components
        // If today and the slot has already passed, push to next week.
        if daysAhead == 0 && combined < reference {
            return calendar.date(byAdding: .day, value: 7, to: combined)
        }
        return combined
    }

    private static func combine(date: Date, time: String, calendar: Calendar) -> Date? {
        let parts = time.split(separator: ":")
        guard parts.count == 2,
              let hour = Int(parts[0]),
              let minute = Int(parts[1]) else { return nil }
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)
    }

    /// "7:00 PM" for display.
    var displayTime: String {
        let parts = startTime.split(separator: ":")
        guard parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]) else {
            return startTime
        }
        let suffix = hour >= 12 ? "PM" : "AM"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return minute == 0
            ? "\(displayHour):00 \(suffix)"
            : "\(displayHour):\(String(format: "%02d", minute)) \(suffix)"
    }
}

enum EventCategory: String, Codable, CaseIterable, Identifiable {
    case liveMusic = "Live Music"
    case dj = "DJ"
    case karaoke = "Karaoke"
    case trivia = "Trivia"
    case movieNight = "Movie Night"
    case familyEvent = "Family Event"
    case gameNight = "Game Night"
    case fireShow = "Fire Show"
    case specialEvent = "Special Event"
    case danceShow = "Dance Show"
    case culturalEvent = "Cultural Event"
    case foodAndDrink = "Food & Drink"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .liveMusic:      return "music.note"
        case .dj:             return "headphones"
        case .karaoke:        return "mic.fill"
        case .trivia:         return "brain.head.profile"
        case .movieNight:     return "film.fill"
        case .familyEvent:    return "figure.2.and.child.holdinghands"
        case .gameNight:      return "dice.fill"
        case .fireShow:       return "flame.fill"
        case .specialEvent:   return "sparkles"
        case .danceShow:      return "figure.dance"
        case .culturalEvent:  return "building.columns"
        case .foodAndDrink:   return "fork.knife"
        }
    }
}

enum Weekday: String, Codable, CaseIterable, Identifiable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }

    /// Calendar.component(.weekday, …) returns Sunday=1, Monday=2, ... Saturday=7.
    var calendarWeekday: Int {
        switch self {
        case .sunday:    return 1
        case .monday:    return 2
        case .tuesday:   return 3
        case .wednesday: return 4
        case .thursday:  return 5
        case .friday:    return 6
        case .saturday:  return 7
        }
    }

    static func from(calendarWeekday: Int) -> Weekday? {
        switch calendarWeekday {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return nil
        }
    }

    static var today: Weekday? {
        from(calendarWeekday: Calendar.current.component(.weekday, from: .now))
    }
}
