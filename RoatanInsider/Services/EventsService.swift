import Foundation
import Observation

/// Loads the recurring event schedule from the bundled `events.json` (with
/// remote-cache override support via `RemoteDataService`), and exposes
/// the queries the UI cares about: tonight, today, this week, by category,
/// by area.
///
/// V1 ships with the bundled schedule from the PRD. Live integration with
/// bluewaveradio.live/roatanmusicscene lands in a future phase; when it
/// does, the cached file at `events.json` becomes the live source of
/// truth and the bundled file is the offline fallback.
@Observable
final class EventsService {
    private(set) var events: [Event] = []

    init() {
        load()
    }

    private func load() {
        if let data: [Event] = RemoteDataService.loadCachedOrBundled(
            filename: "events.json", bundleName: "events", type: [Event].self
        ) {
            events = data.filter { $0.isActive }
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
}
