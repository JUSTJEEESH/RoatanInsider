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

    /// The remote pipeline (scrape-music-events) writes calendar dates as
    /// plain "yyyy-MM-dd" strings, which the default JSONDecoder Date
    /// handling can't read — so dates are decoded by hand. Times are
    /// anchored to island midnight (UTC-6) so "today" checks behave for
    /// users on Roatán and stay same-day for visitors' home time zones.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        venue = try c.decode(String.self, forKey: .venue)
        venueId = try c.decodeIfPresent(String.self, forKey: .venueId)
        area = try c.decode(String.self, forKey: .area)
        category = try c.decode(EventCategory.self, forKey: .category)
        performer = try c.decode(String.self, forKey: .performer)
        day = try c.decodeIfPresent(Weekday.self, forKey: .day)
        date = Self.parseDay(try? c.decodeIfPresent(String.self, forKey: .date))
        startTime = try c.decode(String.self, forKey: .startTime)
        endTime = try c.decodeIfPresent(String.self, forKey: .endTime)
        genre = try c.decodeIfPresent(String.self, forKey: .genre)
        notes = try c.decodeIfPresent(String.self, forKey: .notes)
        recurring = try c.decodeIfPresent(Bool.self, forKey: .recurring)
        recurringRule = try c.decodeIfPresent(String.self, forKey: .recurringRule)
        specialEvent = try c.decodeIfPresent(Bool.self, forKey: .specialEvent)
        featured = try c.decodeIfPresent(Bool.self, forKey: .featured)
        cruiseShipDayOnly = try c.decodeIfPresent(Bool.self, forKey: .cruiseShipDayOnly)
        weatherDependent = try c.decodeIfPresent(Bool.self, forKey: .weatherDependent)
        contact = try c.decodeIfPresent(String.self, forKey: .contact)
        active = try c.decodeIfPresent(Bool.self, forKey: .active)
        lastUpdated = Self.parseDay(try? c.decodeIfPresent(String.self, forKey: .lastUpdated))
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(venue, forKey: .venue)
        try c.encodeIfPresent(venueId, forKey: .venueId)
        try c.encode(area, forKey: .area)
        try c.encode(category, forKey: .category)
        try c.encode(performer, forKey: .performer)
        try c.encodeIfPresent(day, forKey: .day)
        try c.encodeIfPresent(date.map(Self.dayFormatter.string(from:)), forKey: .date)
        try c.encode(startTime, forKey: .startTime)
        try c.encodeIfPresent(endTime, forKey: .endTime)
        try c.encodeIfPresent(genre, forKey: .genre)
        try c.encodeIfPresent(notes, forKey: .notes)
        try c.encodeIfPresent(recurring, forKey: .recurring)
        try c.encodeIfPresent(recurringRule, forKey: .recurringRule)
        try c.encodeIfPresent(specialEvent, forKey: .specialEvent)
        try c.encodeIfPresent(featured, forKey: .featured)
        try c.encodeIfPresent(cruiseShipDayOnly, forKey: .cruiseShipDayOnly)
        try c.encodeIfPresent(weatherDependent, forKey: .weatherDependent)
        try c.encodeIfPresent(contact, forKey: .contact)
        try c.encodeIfPresent(active, forKey: .active)
        try c.encodeIfPresent(lastUpdated.map(Self.dayFormatter.string(from:)), forKey: .lastUpdated)
    }

    private enum CodingKeys: String, CodingKey {
        case id, venue, venueId, area, category, performer, day, date
        case startTime, endTime, genre, notes, recurring, recurringRule
        case specialEvent, featured, cruiseShipDayOnly, weatherDependent
        case contact, active, lastUpdated
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "America/Tegucigalpa")
        return formatter
    }()

    private static func parseDay(_ raw: String??) -> Date? {
        guard let value = raw ?? nil else { return nil }
        return dayFormatter.date(from: value)
    }

    var isRecurring: Bool       { recurring ?? false }
    var isSpecial: Bool         { specialEvent ?? false }
    var isFeatured: Bool        { featured ?? false }
    var isCruiseDayOnly: Bool   { cruiseShipDayOnly ?? false }
    var isWeatherDependent: Bool { weatherDependent ?? false }
    var isActive: Bool          { active ?? true }

    /// True when this event started within the last `durationHours` and is
    /// likely still going. Used for the 'LIVE NOW' badge on rows.
    func isLiveNow(now: Date = .now, durationHours: Int = 3, calendar: Calendar = .current) -> Bool {
        // Only events scheduled for today.
        if let date {
            guard calendar.isDate(date, inSameDayAs: now) else { return false }
        } else if let day, let today = Weekday.from(calendarWeekday: calendar.component(.weekday, from: now)) {
            guard day == today else { return false }
        } else {
            return false
        }

        // Today's start time as a Date.
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
              let start = nextOccurrence(after: yesterday, calendar: calendar),
              calendar.isDate(start, inSameDayAs: now) else {
            return false
        }
        let elapsed = now.timeIntervalSince(start)
        return elapsed >= 0 && elapsed < TimeInterval(durationHours * 3600)
    }

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
