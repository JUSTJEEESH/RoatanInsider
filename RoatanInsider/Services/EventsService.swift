import Foundation
import Observation

/// Loads the event schedule and exposes the queries the UI cares about:
/// tonight, today, this week, by category, by area.
///
/// Source of truth is Blue Wave Radio's Roatán Music Scene
/// (bluewaveradio.live/roatanmusicscene): the `scrape-music-events` Edge
/// Function regenerates `app-data/events.json` from it every two hours, and
/// this service pulls the fresh copy on every return to foreground, at most
/// hourly. The bundled file is the offline / first-launch fallback.
///
/// Keith's feed carries two kinds of row. Most are recurring weekly slots
/// ("Sundowners, every Wednesday, 7pm") — the skeleton of the week. The rest
/// are dated one-offs carrying who is actually booked on a specific night.
/// A dated row for a slot supersedes the recurring row for the same venue and
/// time: it names this week's act where the recurring row only names the slot.
@Observable
final class EventsService {
    private(set) var events: [Event] = []

    /// When the schedule was last pulled from Supabase. Nil means we have
    /// never reached the network on this device and are running on the
    /// bundled copy.
    private(set) var lastRefreshed: Date?

    /// How long a fetched schedule is considered fresh. The scraper runs
    /// every two hours, so an hour here means a visitor who reopens the app
    /// is never looking at data more than about three hours behind Keith.
    private static let refreshInterval: TimeInterval = 3600

    init() {
        load()
        lastRefreshed = Self.storedRefreshDate()
        Task { await refreshFromRemoteIfNeeded() }
    }

    /// Seam for tests: a service holding an explicit schedule, with no disk
    /// read and no network. Everything below takes an explicit `now`, so a
    /// test can state both the week and the day it is being read on.
    init(events: [Event]) {
        self.events = events.filter { $0.isActive }
    }

    private func load() {
        if let data: [Event] = RemoteDataService.loadCachedOrBundled(
            filename: "events.json", bundleName: "events", type: [Event].self
        ) {
            events = data.filter { $0.isActive }
        }
    }

    /// Pulls a fresh copy from Supabase Storage if our cache is over an hour
    /// old. Called at launch and on every return to foreground.
    func refreshFromRemoteIfNeeded() async {
        await refresh(maxAge: Self.refreshInterval)
    }

    /// Unconditional refetch, for pull-to-refresh. Ignores the throttle:
    /// a visitor who deliberately pulls is telling us they doubt the screen.
    func refreshNow() async {
        await refresh(maxAge: 0)
    }

    private func refresh(maxAge: TimeInterval) async {
        if let fresh: [Event] = await RemoteDataService.fetchLatest(
            filename: "events.json",
            maxAge: maxAge,
            type: [Event].self
        ) {
            await MainActor.run {
                self.events = fresh.filter { $0.isActive }
                self.lastRefreshed = Self.storedRefreshDate()
            }
        }
    }

    private static func storedRefreshDate() -> Date? {
        let stamp = UserDefaults.standard.double(forKey: "remoteDataLastFetch_events.json")
        return stamp > 0 ? Date(timeIntervalSince1970: stamp) : nil
    }

    // MARK: - Resolving a day

    /// The calendar date the given weekday next falls on, counting today as
    /// day zero. "Friday" on a Friday means today, not next week.
    static func nextDate(of day: Weekday, from now: Date, calendar: Calendar = .current) -> Date {
        let daysAhead = (day.calendarWeekday - calendar.component(.weekday, from: now) + 7) % 7
        let today = calendar.startOfDay(for: now)
        return calendar.date(byAdding: .day, value: daysAhead, to: today) ?? today
    }

    private static func slotKey(_ event: Event) -> String {
        "\(event.venue.lowercased())|\(event.startTime)"
    }

    /// Everything on for the given weekday, resolved against the actual date
    /// that weekday falls on this coming week.
    ///
    /// Dated rows are matched by date, so a one-off that has already been and
    /// gone can never reappear — and where a dated row and a recurring row
    /// claim the same venue and time, the dated one wins.
    private func resolved(for day: Weekday, now: Date, calendar: Calendar = .current) -> [Event] {
        let target = Self.nextDate(of: day, from: now, calendar: calendar)
        let candidates = events.filter { event in
            if let date = event.date {
                return calendar.isDate(date, inSameDayAs: target)
            }
            return event.isRecurring && event.day == day
        }
        let supersededSlots = Set(candidates.compactMap { $0.date != nil ? Self.slotKey($0) : nil })
        return candidates.filter { $0.date != nil || !supersededSlots.contains(Self.slotKey($0)) }
    }

    /// The next seven days of schedule, resolved and deduped — today first.
    /// This is "the week" everywhere the UI says the week.
    func upcomingWeek(now: Date = .now) -> [Event] {
        let calendar = Calendar.current
        guard let today = Weekday.from(calendarWeekday: calendar.component(.weekday, from: now)) else {
            return []
        }
        let order = Weekday.allCases.sorted {
            ($0.calendarWeekday - today.calendarWeekday + 7) % 7
                < ($1.calendarWeekday - today.calendarWeekday + 7) % 7
        }
        return order.flatMap { resolved(for: $0, now: now, calendar: calendar) }
    }

    // MARK: - Queries

    /// Events happening today. Featured 'Don't Miss' events bubble to the
    /// top; the rest sort by start time.
    func eventsToday(now: Date = .now) -> [Event] {
        let calendar = Calendar.current
        guard let today = Weekday.from(calendarWeekday: calendar.component(.weekday, from: now)) else {
            return []
        }
        return resolved(for: today, now: now, calendar: calendar).sorted(by: Self.featuredFirst)
    }

    /// Events in progress right now — started, and still inside their run
    /// (until endTime when known, otherwise a 3-hour window). Chronological.
    func happeningNow(now: Date = .now, cruiseShipInPort: Bool = true) -> [Event] {
        let calendar = Calendar.current
        return eventsToday(now: now)
            .filter { cruiseShipInPort || !$0.isCruiseDayOnly }
            .filter { $0.isLiveNow(now: now, calendar: calendar) }
            .sorted { $0.startTime < $1.startTime }
    }

    /// Today's events that haven't started yet. Pure start-time order —
    /// "what's actually next" beats editorial pinning here; featured events
    /// keep their badge wherever they land.
    func upNextToday(now: Date = .now, cruiseShipInPort: Bool = true) -> [Event] {
        let calendar = Calendar.current
        return eventsToday(now: now)
            .filter { cruiseShipInPort || !$0.isCruiseDayOnly }
            .compactMap { event -> (Date, Event)? in
                guard let start = event.nextOccurrence(after: now, calendar: calendar),
                      calendar.isDate(start, inSameDayAs: now), start > now else { return nil }
                return (start, event)
            }
            .sorted { $0.0 < $1.0 }
            .map(\.1)
    }

    /// Tomorrow's first few events — the late-night answer when today is
    /// played out.
    func tomorrowPreview(now: Date = .now, limit: Int = 3) -> [Event] {
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now),
              let day = Weekday.from(calendarWeekday: calendar.component(.weekday, from: tomorrow)) else {
            return []
        }
        let tomorrows = resolved(for: day, now: now, calendar: calendar)
        return Array(tomorrows.sorted { $0.startTime < $1.startTime }.prefix(limit))
    }

    /// All upcoming events across the next 7 days, paired with the date they
    /// land on. Occurrences already past are dropped.
    func eventsThisWeek(now: Date = .now) -> [(date: Date, event: Event)] {
        let calendar = Calendar.current
        return upcomingWeek(now: now).compactMap { event -> (Date, Event)? in
            guard let next = event.nextOccurrence(after: now, calendar: calendar),
                  next >= calendar.startOfDay(for: now) else { return nil }
            let daysAhead = calendar.dateComponents([.day], from: now, to: next).day ?? 0
            return daysAhead < 7 ? (next, event) : nil
        }
        .sorted { $0.0 < $1.0 }
    }

    func events(for day: Weekday, now: Date = .now) -> [Event] {
        resolved(for: day, now: now).sorted(by: Self.featuredFirst)
    }

    /// Featured events bubble up; everything else sorts by start time.
    private static func featuredFirst(_ a: Event, _ b: Event) -> Bool {
        if a.isFeatured != b.isFeatured { return a.isFeatured && !b.isFeatured }
        return a.startTime < b.startTime
    }

    func events(in category: EventCategory, now: Date = .now) -> [Event] {
        upcomingWeek(now: now).filter { $0.category == category }
    }

    func events(inArea area: String, now: Date = .now) -> [Event] {
        upcomingWeek(now: now).filter { $0.area.caseInsensitiveCompare(area) == .orderedSame }
    }

    /// Unified filter+search. If `query` or `category` is non-empty, returns
    /// matching events across the whole coming week. Otherwise scopes by the
    /// passed-in day.
    func filtered(query: String, category: EventCategory?, day: Weekday?, now: Date = .now) -> [Event] {
        let hasActiveFilter = !query.isEmpty || category != nil
        var result: [Event]

        if hasActiveFilter {
            result = upcomingWeek(now: now)
            if let category {
                result = result.filter { $0.category == category }
            }
            if !query.isEmpty {
                let q = query.lowercased()
                result = result.filter { event in
                    event.venue.lowercased().contains(q)
                        || event.performer.lowercased().contains(q)
                        || event.area.lowercased().contains(q)
                        || event.category.rawValue.lowercased().contains(q)
                        || (event.genre?.lowercased().contains(q) ?? false)
                }
            }
        } else if let day {
            result = resolved(for: day, now: now)
        } else {
            result = upcomingWeek(now: now)
        }

        return result.sorted(by: Self.featuredFirst)
    }

    /// The set of categories that actually appear this week — avoids showing
    /// filter chips that match nothing.
    func availableCategories(now: Date = .now) -> [EventCategory] {
        let present = Set(upcomingWeek(now: now).map(\.category))
        return EventCategory.allCases.filter { present.contains($0) }
    }
}
