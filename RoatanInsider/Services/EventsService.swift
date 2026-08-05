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
    /// top; the rest sort by start time.
    func eventsToday(now: Date = .now) -> [Event] {
        guard let today = Weekday.today else { return [] }
        return events
            .filter { $0.isRecurring && $0.day == today || ($0.date.map(Calendar.current.isDateInToday) ?? false) }
            .sorted(by: Self.featuredFirst)
    }

    /// Events that haven't started yet today, plus those started in the
    /// last hour (so a "Tonight" surface doesn't drop something that just
    /// kicked off ten minutes ago).
    func eventsTonight(now: Date = .now, lookbackMinutes: Int = 60) -> [Event] {
        let calendar = Calendar.current
        let lookback = calendar.date(byAdding: .minute, value: -lookbackMinutes, to: now) ?? now
        return eventsToday(now: now).filter { event in
            guard let start = event.nextOccurrence(after: lookback, calendar: calendar) else { return false }
            return calendar.isDate(start, inSameDayAs: now) && start >= lookback
        }
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
