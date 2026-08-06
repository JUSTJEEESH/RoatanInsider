import Foundation
import CoreLocation

struct DayHours: Codable, Hashable {
    let open: String
    let close: String
}

struct CategoryEntry: Codable, Hashable {
    let category: String
    let subcategory: String

    var categoryEnum: Category? { Category(rawValue: category) }

    var categoryDisplayName: String {
        categoryEnum?.displayName ?? category.replacingOccurrences(of: "_", with: " ").capitalized
    }

    var categoryIconName: String {
        categoryEnum?.iconName ?? "questionmark.circle"
    }
}

/// A stated happy hour window.
///
/// This exists because "is happy hour on" used to be answered with "does
/// this place carry a Happy Hour tag, and is it open" — which is true for a
/// beach bar from ten in the morning until it closes. A tag says a place has
/// one; only a window says it's on.
///
/// Absent for most places, and that's the point: a place with no window
/// stated never claims one. Nothing here is inferred.
struct HappyHour: Codable, Hashable {
    /// Lowercase weekday names. Empty means every day.
    let days: [String]
    let start: String        // 24hr "HH:mm"
    let end: String          // 24hr "HH:mm"
    /// What you actually get — "2-for-1 cocktails". Optional.
    let note: String?

    private enum CodingKeys: String, CodingKey { case days, start, end, note }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        days = ((try? c.decodeIfPresent([String].self, forKey: .days)) ?? [])?
            .map { $0.lowercased() } ?? []
        start = try c.decode(String.self, forKey: .start)
        end = try c.decode(String.self, forKey: .end)
        note = try c.decodeIfPresent(String.self, forKey: .note)
    }

    init(days: [String] = [], start: String, end: String, note: String? = nil) {
        self.days = days.map { $0.lowercased() }
        self.start = start
        self.end = end
        self.note = note
    }

    var runsEveryDay: Bool { days.isEmpty }

    func runs(on weekday: String) -> Bool {
        runsEveryDay || days.contains(weekday.lowercased())
    }

    /// Whether the window is open at `now`. Handles a window that crosses
    /// midnight (a late-night deal starting at 22:00 and ending at 01:00),
    /// in which case the day test applies to the day it started.
    func isOn(now: Date = .now, calendar: Calendar = .current) -> Bool {
        let minutes = Self.minutes(from: now, calendar: calendar)
        guard let from = Self.minutes(of: start), let to = Self.minutes(of: end) else { return false }
        let today = Self.weekdayName(now, calendar: calendar)

        if to > from {
            return runs(on: today) && minutes >= from && minutes < to
        }
        // Crosses midnight: either late on the starting day, or early on the
        // following one.
        if minutes >= from { return runs(on: today) }
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now) else { return false }
        return minutes < to && runs(on: Self.weekdayName(yesterday, calendar: calendar))
    }

    /// "until 6:00 PM" — what someone needs to know once they've been told
    /// it's on.
    var untilLabel: String { "until \(Self.displayTime(end))" }

    var windowLabel: String { "\(Self.displayTime(start))–\(Self.displayTime(end))" }

    /// "Daily 4:00 PM–6:00 PM" / "Fri, Sat 4:00 PM–6:00 PM"
    var fullLabel: String {
        let when = runsEveryDay
            ? "Daily"
            : days.map { $0.prefix(1).uppercased() + $0.dropFirst(1).prefix(2) }.joined(separator: ", ")
        return "\(when) \(windowLabel)"
    }

    private static func minutes(of hhmm: String) -> Int? {
        let parts = hhmm.split(separator: ":")
        guard parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) else { return nil }
        return h * 60 + m
    }

    private static func minutes(from date: Date, calendar: Calendar) -> Int {
        let c = calendar.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) * 60 + (c.minute ?? 0)
    }

    private static func weekdayName(_ date: Date, calendar: Calendar) -> String {
        Weekday.from(calendarWeekday: calendar.component(.weekday, from: date))?.rawValue ?? ""
    }

    static func displayTime(_ raw: String) -> String {
        let parts = raw.split(separator: ":")
        guard parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]) else { return raw }
        let suffix = hour >= 12 ? "PM" : "AM"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return minute == 0
            ? "\(displayHour) \(suffix)"
            : "\(displayHour):\(String(format: "%02d", minute)) \(suffix)"
    }
}

struct BusinessLocation: Codable, Hashable {
    let area: Area
    let latitude: Double
    let longitude: Double
    let addressDescription: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct Business: Identifiable, Codable, Hashable {
    let id: String
    let slug: String
    let name: String
    let description: String
    let insiderTip: String?
    let category: String
    let subcategory: String
    let area: String

    var categoryEnum: Category? { Category(rawValue: category) }
    var categoryDisplayName: String {
        categoryEnum?.displayName ?? category.replacingOccurrences(of: "_", with: " ").capitalized
    }
    var categoryIconName: String {
        categoryEnum?.iconName ?? "questionmark.circle"
    }

    var areaEnum: Area? { Area(rawValue: area) }
    var areaDisplayName: String {
        areaEnum?.displayName ?? area.replacingOccurrences(of: "_", with: " ").capitalized
    }
    let latitude: Double
    let longitude: Double
    let addressDescription: String
    let phone: String?
    let whatsapp: String?
    let email: String?
    let website: String?
    let facebook: String?
    let instagram: String?
    let priceRange: Int
    let hours: [String: DayHours?]
    let features: [String]
    let images: [String]
    let isVerified: Bool
    let isFeatured: Bool
    let isInsiderPick: Bool
    let isBestOf: Bool
    let rating: Double?
    let reviewCount: Int?
    let hoursText: String?
    let status: String
    let collections: [String]
    let menuImages: [String]?
    let additionalCategories: [CategoryEntry]
    let additionalLocations: [BusinessLocation]
    let happyHour: HappyHour?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        slug = try container.decode(String.self, forKey: .slug)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        insiderTip = try container.decodeIfPresent(String.self, forKey: .insiderTip)
        category = try container.decode(String.self, forKey: .category)
        subcategory = try container.decode(String.self, forKey: .subcategory)
        area = try container.decode(String.self, forKey: .area)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        addressDescription = try container.decode(String.self, forKey: .addressDescription)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        whatsapp = try container.decodeIfPresent(String.self, forKey: .whatsapp)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        website = try container.decodeIfPresent(String.self, forKey: .website)
        facebook = try container.decodeIfPresent(String.self, forKey: .facebook)
        instagram = try container.decodeIfPresent(String.self, forKey: .instagram)
        priceRange = try container.decode(Int.self, forKey: .priceRange)
        hours = try container.decode([String: DayHours?].self, forKey: .hours)
        features = try container.decode([String].self, forKey: .features)
        images = try container.decode([String].self, forKey: .images)
        isVerified = try container.decode(Bool.self, forKey: .isVerified)
        isFeatured = try container.decode(Bool.self, forKey: .isFeatured)
        isInsiderPick = try container.decode(Bool.self, forKey: .isInsiderPick)
        isBestOf = try container.decode(Bool.self, forKey: .isBestOf)
        rating = try container.decodeIfPresent(Double.self, forKey: .rating)
        reviewCount = try container.decodeIfPresent(Int.self, forKey: .reviewCount)
        hoursText = try container.decodeIfPresent(String.self, forKey: .hoursText)
        status = try container.decode(String.self, forKey: .status)
        collections = (try? container.decode([String].self, forKey: .collections)) ?? []
        menuImages = try? container.decodeIfPresent([String].self, forKey: .menuImages)
        additionalCategories = (try? container.decode([CategoryEntry].self, forKey: .additionalCategories)) ?? []
        additionalLocations = (try? container.decode([BusinessLocation].self, forKey: .additionalLocations)) ?? []
        happyHour = try? container.decodeIfPresent(HappyHour.self, forKey: .happyHour)
    }

    // MARK: - Happy hour

    /// True only when a window is stated AND we're inside it AND the place
    /// isn't recorded as shut. All three, because each on its own has been
    /// wrong: a tag alone said nothing about time, a window alone would
    /// survive the one day a week the bar is dark, and hours alone are the
    /// old bug.
    func isHappyHourNow(now: Date = .now) -> Bool {
        guard let happyHour, happyHour.isOn(now: now) else { return false }
        return !hasKnownHours || isOpenNow(now: now)
    }

    // MARK: - All categories (primary + additional)

    var allCategories: [CategoryEntry] {
        var result = [CategoryEntry(category: category, subcategory: subcategory)]
        result.append(contentsOf: additionalCategories)
        return result
    }

    /// Check if this business belongs to a given category (by string ID)
    func hasCategory(_ catId: String) -> Bool {
        category == catId || additionalCategories.contains { $0.category == catId }
    }

    /// Check if this business belongs to a given category (by enum, for backward compat)
    func hasCategory(_ cat: Category) -> Bool {
        hasCategory(cat.rawValue)
    }

    /// Get the subcategory label for a specific category context (by string ID)
    func subcategory(for catId: String) -> String {
        if category == catId { return subcategory }
        return additionalCategories.first { $0.category == catId }?.subcategory ?? subcategory
    }

    /// Get the subcategory label for a specific category context (by enum)
    func subcategory(for cat: Category) -> String {
        subcategory(for: cat.rawValue)
    }

    // MARK: - All locations (primary + additional)

    var allLocations: [BusinessLocation] {
        let primaryArea = areaEnum ?? .westBay
        var result = [BusinessLocation(area: primaryArea, latitude: latitude, longitude: longitude, addressDescription: addressDescription)]
        result.append(contentsOf: additionalLocations)
        return result
    }

    /// All unique area strings this business is in
    var allAreaStrings: [String] {
        var areas = [area]
        for loc in additionalLocations {
            let locArea = loc.area.rawValue
            if !areas.contains(locArea) {
                areas.append(locArea)
            }
        }
        return areas
    }

    /// Check if this business is in a given area (by enum)
    func isInArea(_ a: Area) -> Bool {
        area == a.rawValue || additionalLocations.contains { $0.area == a }
    }

    /// Check if this business is in a given area (by string)
    func isInArea(_ areaId: String) -> Bool {
        area == areaId || additionalLocations.contains { $0.area.rawValue == areaId }
    }

    // MARK: - Existing computed properties

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var priceLabel: String {
        String(repeating: "$", count: priceRange)
    }

    /// Diacritic-folded, lowercased blob containing everything we want to
    /// search against. Built once via the cache below — `lowercased()` +
    /// `folding()` on 200 businesses every keystroke is wasteful.
    var searchHaystack: String {
        BusinessSearchHaystackCache.shared.haystack(for: self)
    }

    var isActive: Bool {
        status == "active"
    }

    /// Whether we hold real opening hours for this place. `isOpenNow()`
    /// returns false both for "closed right now" and for "we have no idea",
    /// which are very different things to tell a visitor — callers that show
    /// status to a human should check this first.
    var hasKnownHours: Bool {
        hours.contains { $0.value != nil }
    }

    /// `now` is a parameter rather than a call to `Date()` so that anything
    /// built on top of this — happy hour, "open now" filters — can be tested
    /// against a fixed clock instead of whatever day the test machine is on.
    func isOpenNow(now: Date = Date()) -> Bool {
        let dayKey = now.currentDayKey
        let timeString = now.currentTimeString

        // Check today's hours
        if let dayHours = hours[dayKey] ?? nil {
            if dayHours.close >= dayHours.open {
                // Normal hours (e.g., 08:00–22:00)
                if timeString >= dayHours.open && timeString <= dayHours.close {
                    return true
                }
            } else {
                // Past-midnight hours (e.g., 18:00–02:00) — open from open until midnight
                if timeString >= dayHours.open {
                    return true
                }
            }
        }

        // Check if yesterday's hours extend past midnight into now
        let yesterdayKey = now.previousDayKey
        if let yesterdayHours = hours[yesterdayKey] ?? nil {
            if yesterdayHours.close < yesterdayHours.open {
                // Yesterday had past-midnight hours — check if we're still in the closing window
                if timeString <= yesterdayHours.close {
                    return true
                }
            }
        }

        return false
    }
}

/// Per-business search haystack cache. Keyed on business id so a remote update
/// can invalidate via `purgeAll()`. Diacritic-folded and lowercased once.
final class BusinessSearchHaystackCache: @unchecked Sendable {
    static let shared = BusinessSearchHaystackCache()
    private var storage: [String: String] = [:]
    private let queue = DispatchQueue(label: "ri.haystack", attributes: .concurrent)

    private init() {}

    func haystack(for business: Business) -> String {
        if let cached = queue.sync(execute: { storage[business.id] }) {
            return cached
        }
        let built = Self.build(for: business)
        queue.async(flags: .barrier) { self.storage[business.id] = built }
        return built
    }

    func purgeAll() {
        queue.async(flags: .barrier) { self.storage.removeAll() }
    }

    private static func build(for b: Business) -> String {
        var parts: [String] = [b.name, b.description, b.subcategory, b.area, b.addressDescription]
        parts.append(contentsOf: b.features)
        parts.append(contentsOf: b.allCategories.map { $0.subcategory })
        parts.append(contentsOf: b.allAreaStrings.map { $0.replacingOccurrences(of: "_", with: " ") })
        return parts.joined(separator: " ").normalisedForSearch
    }
}
