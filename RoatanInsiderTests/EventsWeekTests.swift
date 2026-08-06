import Testing
import Foundation
@testable import RoatanInsider

/// Tests for how a week of music is assembled.
///
/// Keith's feed carries two kinds of row: recurring weekly slots that name a
/// venue and a time, and dated one-offs that name who is actually playing on
/// a given night. The app has to merge them, and it used to filter on
/// `recurring` alone — which meant the Events list showed the skeleton of the
/// week and silently dropped every real booking in it.
///
/// These are the cases that would otherwise only surface on someone's phone,
/// standing outside a bar.

@Suite("Events week resolution")
struct EventsWeekTests {

    /// Wednesday 5 August 2026, midday.
    ///
    /// Midday, not midnight: dated events decode at island midnight (UTC-6)
    /// while day comparisons run in the device's calendar, so anchoring at
    /// noon keeps both on the same date for any machine within six hours of
    /// the island — which covers Roatán itself and a UTC CI box.
    private static func wednesday(hour: Int = 12) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        return cal.date(from: DateComponents(year: 2026, month: 8, day: 5, hour: hour))!
    }

    private static func day(_ offset: Int, from now: Date = wednesday()) -> Date {
        Calendar.current.date(byAdding: .day, value: offset, to: now)!
    }

    /// A service holding an explicit schedule — no bundle, no network.
    private func service(_ events: [Event]) -> EventsService {
        EventsService(events: events)
    }

    // MARK: - Dated bookings reach the list

    @Test("a dated booking appears on its weekday, not just recurring slots")
    func datedBookingsAppear() {
        let now = Self.wednesday()
        let dated = Event.fixture(
            id: "dated-thu", venue: "Blue Bahia", performer: "Maia Karagozlu",
            day: .thursday, date: Self.day(1), startTime: "18:00"
        )
        let recurring = Event.fixture(
            id: "rec-thu", venue: "Sundowners", performer: "Open Mic",
            day: .thursday, startTime: "19:00"
        )
        let result = service([dated, recurring]).events(for: .thursday, now: now)
        #expect(result.map(\.id).sorted() == ["dated-thu", "rec-thu"])
    }

    @Test("a dated booking supersedes the recurring slot at the same venue and time")
    func datedSupersedesRecurring() {
        let now = Self.wednesday()
        let recurring = Event.fixture(
            id: "rec", venue: "Sundowners", performer: "Live Music",
            day: .friday, startTime: "19:00"
        )
        let dated = Event.fixture(
            id: "dated", venue: "Sundowners", performer: "The Londoners",
            day: .friday, date: Self.day(2), startTime: "19:00"
        )
        let result = service([recurring, dated]).events(for: .friday, now: now)
        #expect(result.map(\.id) == ["dated"], "the named act beats the empty slot")
    }

    @Test("a dated booking for a different time does NOT hide the recurring slot")
    func datedDoesNotHideOtherSlots() {
        let now = Self.wednesday()
        let recurring = Event.fixture(
            id: "rec", venue: "Sundowners", performer: "Sunset Set",
            day: .friday, startTime: "17:00"
        )
        let dated = Event.fixture(
            id: "dated", venue: "Sundowners", performer: "The Londoners",
            day: .friday, date: Self.day(2), startTime: "19:00"
        )
        let result = service([recurring, dated]).events(for: .friday, now: now)
        #expect(result.count == 2, "two different sets at one venue are two events")
    }

    // MARK: - Stale data cannot resurface

    @Test("a dated booking from last week never shows again")
    func pastDatedIsDropped() {
        let now = Self.wednesday()
        // Last Thursday — same weekday, seven days behind.
        let stale = Event.fixture(
            id: "stale", venue: "Blue Bahia", performer: "Gone Last Week",
            day: .thursday, date: Self.day(-6), startTime: "18:00"
        )
        let result = service([stale]).events(for: .thursday, now: now)
        #expect(result.isEmpty, "a gig that already happened is not on this week")
    }

    @Test("a dated booking a year out is not mistaken for this week")
    func farFutureDatedIsExcluded() {
        let now = Self.wednesday()
        let far = Event.fixture(
            id: "far", venue: "Blue Bahia", performer: "Next August",
            day: .thursday, date: Self.day(365), startTime: "18:00"
        )
        #expect(service([far]).events(for: .thursday, now: now).isEmpty)
    }

    @Test("today's dated booking still counts as today")
    func todaysDatedIsToday() {
        let now = Self.wednesday()
        let tonight = Event.fixture(
            id: "tonight", venue: "Sundowners", performer: "Tommy Morris",
            day: .wednesday, date: now, startTime: "19:00"
        )
        let result = service([tonight]).events(for: .wednesday, now: now)
        #expect(result.map(\.id) == ["tonight"])
    }

    // MARK: - The week as a whole

    @Test("the week spans seven days starting today")
    func weekSpansSevenDaysFromToday() {
        let now = Self.wednesday()
        let events = (0..<7).map { offset in
            Event.fixture(
                id: "d\(offset)", venue: "Venue \(offset)", performer: "Act \(offset)",
                day: Weekday.from(calendarWeekday: Calendar.current.component(
                    .weekday, from: Self.day(offset)))!,
                date: Self.day(offset), startTime: "18:00"
            )
        }
        let week = service(events).upcomingWeek(now: now)
        #expect(week.count == 7)
        #expect(week.first?.id == "d0", "today comes first")
        #expect(week.last?.id == "d6", "a week out comes last")
    }

    @Test("each event appears exactly once across the week")
    func noDuplicatesAcrossTheWeek() {
        let now = Self.wednesday()
        let events = [
            Event.fixture(id: "rec-mon", venue: "A", day: .monday, startTime: "18:00"),
            Event.fixture(id: "rec-fri", venue: "B", day: .friday, startTime: "18:00"),
            Event.fixture(id: "dated-fri", venue: "C", day: .friday,
                          date: Self.day(2), startTime: "20:00"),
        ]
        let ids = service(events).upcomingWeek(now: now).map(\.id)
        #expect(Set(ids).count == ids.count, "no event should be listed twice")
        #expect(Set(ids) == ["rec-mon", "rec-fri", "dated-fri"])
    }

    // MARK: - Search and filters see the real week

    @Test("search finds a dated booking, not only recurring slots")
    func searchReachesDatedBookings() {
        let now = Self.wednesday()
        let dated = Event.fixture(
            id: "dated", venue: "Blue Bahia", performer: "Maia Karagozlu",
            day: .thursday, date: Self.day(1), startTime: "18:00"
        )
        let result = service([dated]).filtered(
            query: "maia", category: nil, day: nil, now: now
        )
        #expect(result.map(\.id) == ["dated"])
    }

    @Test("category chips reflect what is actually on this week")
    func categoriesComeFromTheRealWeek() {
        let now = Self.wednesday()
        let events = [
            Event.fixture(id: "k", venue: "A", day: .thursday,
                          date: Self.day(1), startTime: "20:00", category: .karaoke),
            Event.fixture(id: "m", venue: "B", day: .friday, startTime: "19:00",
                          category: .liveMusic),
        ]
        let categories = service(events).availableCategories(now: now)
        #expect(Set(categories) == [.karaoke, .liveMusic],
                "a karaoke night that only exists as a dated row still needs its chip")
    }

    @Test("filtering by day ignores the rest of the week")
    func dayFilterScopes() {
        let now = Self.wednesday()
        let events = [
            Event.fixture(id: "mon", venue: "A", day: .monday, startTime: "18:00"),
            Event.fixture(id: "fri", venue: "B", day: .friday, startTime: "18:00"),
        ]
        let result = service(events).filtered(
            query: "", category: nil, day: .friday, now: now
        )
        #expect(result.map(\.id) == ["fri"])
    }

    // MARK: - Today

    @Test("today's list is today's weekday, merged")
    func todayMerges() {
        let now = Self.wednesday()
        let recurring = Event.fixture(
            id: "rec", venue: "Sundowners", performer: "Live Music",
            day: .wednesday, startTime: "19:00"
        )
        let dated = Event.fixture(
            id: "dated", venue: "Sundowners", performer: "Tommy Morris",
            day: .wednesday, date: now, startTime: "19:00"
        )
        let other = Event.fixture(
            id: "thu", venue: "Elsewhere", day: .thursday, startTime: "19:00"
        )
        let result = service([recurring, dated, other]).eventsToday(now: now)
        #expect(result.map(\.id) == ["dated"], "the named act, and only today")
    }
}
