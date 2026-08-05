import Foundation
import Observation

/// Loads the event schedule and exposes the queries the UI cares about:
/// tonight, today, this week, by category, by area.
///
/// Source of truth is Blue Wave Radio's Roatán Music Scene
/// (bluewaveradio.live/roatanmusicscene): the `scrape-music-events` Edge
/// Function regenerates `app-data/events.json` from it daily, and this
/// service pulls the fresh copy at most every 6 hours. The bundled file
/// is the offline / first-launch fallback.
@Observable
final class EventsService {
    private(set) var events: [Event] = []

    init() {
        load()
        Task { await refreshFromRemoteIfNeeded() }
    }

    private func load() {
        if let data: [Event] = RemoteDataService.loadCachedOrBundled(
            filename: "events.json", bundleName: "events", type: [Event].self
        ) {
            events = data.filter { $0.isActive }
        }
    }

    /// Pulls a fresh copy from Supabase Storage if our cache is >6h old.
    func refreshFromRemoteIfNeeded() async {
        if let fresh: [Event] = await RemoteDataService.fetchLatest(
            filename: "events.json",
            type: [Event].self
        ) {
            await MainActor.run { self.events = fresh.filter { $0.isActive } }
        }
    }

    // MARK: - Queries

    /// Events happening today. Featured 'Don't Miss' events bubble to the
    /// top; the rest sort by start time. When Keith lists both a recurring
    /// slot and a dated booking for the same venue and time, the dated one
    /// wins (it's this week's specific act).
    func eventsToday(now: Date = .now) -> [Event] {
        guard let today = Weekday.today else { return [] }
        let todays = events.filter {
            $0.isRecurring && $0.day == today || ($0.date.map(Calendar.current.isDateInToday) ?? false)
        }
        let datedSlots = Set(todays.compactMap { e in
            e.date != nil ? "\(e.venue.lowercased())|\(e.startTime)" : nil
        })
        return todays
            .filter { $0.date != nil || !datedSlots.contains("\($0.venue.lowercased())|\($0.startTime)") }
            .sorted(by: Self.featuredFirst)
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
        let tomorrows = events.filter {
            $0.isRecurring && $0.day == day || ($0.date.map { calendar.isDate($0, inSameDayAs: tomorrow) } ?? false)
        }
        return Array(tomorrows.sorted { $0.startTime < $1.startTime }.prefix(limit))
    }

    /// All upcoming events across the next 7 days, sorted by occurrence.
    func eventsThisWeek(now: Date = .now) -> [(date: Date, event: Event)] {
        let calendar = Calendar.current
        return events.compactMap { event -> (Date, Event)? in
            guard let next = event.nextOccurrence(after: now, calendar: calendar) else { return nil }
            let daysAhead = calendar.dateComponents([.day], from: now, to: next).day ?? 0
            return daysAhead < 7 ? (next, event) : nil
        }
        .sorted { $0.0 < $1.0 }
    }

    func events(for day: Weekday) -> [Event] {
        events
            .filter { $0.isRecurring && $0.day == day }
            .sorted(by: Self.featuredFirst)
    }

    /// Featured events bubble up; everything else sorts by start time.
    private static func featuredFirst(_ a: Event, _ b: Event) -> Bool {
        if a.isFeatured != b.isFeatured { return a.isFeatured && !b.isFeatured }
        return a.startTime < b.startTime
    }

    func events(in category: EventCategory) -> [Event] {
        events.filter { $0.category == category }
    }

    func events(inArea area: String) -> [Event] {
        events.filter { $0.area.caseInsensitiveCompare(area) == .orderedSame }
    }

    /// Unified filter+search. If `query` or `category` is non-empty, returns
    /// matching events across ALL weekdays. Otherwise scopes by the
    /// passed-in day.
    func filtered(query: String, category: EventCategory?, day: Weekday?) -> [Event] {
        let hasActiveFilter = !query.isEmpty || category != nil
        var result = events.filter { $0.isRecurring }

        if hasActiveFilter {
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
            result = result.filter { $0.day == day }
        }

        return result.sorted(by: Self.featuredFirst)
    }

    /// The set of categories that actually appear in the loaded events —
    /// avoids showing filter chips that match nothing.
    func availableCategories() -> [EventCategory] {
        let present = Set(events.compactMap { $0.isRecurring ? $0.category : nil })
        return EventCategory.allCases.filter { present.contains($0) }
    }
}
