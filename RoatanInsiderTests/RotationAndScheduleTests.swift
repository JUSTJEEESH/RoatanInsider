import Testing
import Foundation
@testable import RoatanInsider

/// Tests for the date/time logic that decides what a visitor sees. This is
/// the code that's hardest to eyeball, because verifying it by hand means
/// changing the device clock and relaunching — every one of these bugs
/// would otherwise be found by a user, not by us.
///
/// Everything here is a pure function taking an explicit date, which is why
/// it's testable at all. Anything reading `.now` internally can't be.

// MARK: - Insider pick rotation

@Suite("Insider pick rotation")
struct InsiderPickRotationTests {

    /// Island midnight, so tests don't drift with the machine's time zone.
    private func islandDate(_ y: Int, _ m: Int, _ d: Int, hour: Int = 12) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/Tegucigalpa")!
        return cal.date(from: DateComponents(year: y, month: m, day: d, hour: hour))!
    }

    private func makeBusiness(slug: String, tip: String? = "A tip") -> Business {
        Business.fixture(slug: slug, insiderTip: tip)
    }

    private var pool: [Business] {
        InsiderPickSection.curatedSlugs.map { makeBusiness(slug: $0) }
    }

    @Test("holds the same pick across the rotation window")
    func holdsAcrossWindow() {
        let day1 = InsiderPickSection.pick(from: pool, on: islandDate(2026, 3, 2))
        let day2 = InsiderPickSection.pick(from: pool, on: islandDate(2026, 3, 3))
        #expect(day1?.slug == day2?.slug)
    }

    @Test("changes after the rotation window elapses")
    func changesAfterWindow() {
        let before = InsiderPickSection.pick(from: pool, on: islandDate(2026, 3, 2))
        let after = InsiderPickSection.pick(
            from: pool,
            on: islandDate(2026, 3, 2 + InsiderPickSection.rotationDays)
        )
        #expect(before?.slug != after?.slug)
    }

    @Test("every curated entry gets a turn across a full cycle")
    func fullCycleCoversEveryone() {
        let cycleDays = InsiderPickSection.rotationDays * pool.count
        var seen = Set<String>()
        for offset in 0..<cycleDays {
            let date = islandDate(2026, 1, 1).addingTimeInterval(Double(offset) * 86_400)
            if let slug = InsiderPickSection.pick(from: pool, on: date)?.slug {
                seen.insert(slug)
            }
        }
        #expect(seen.count == pool.count, "every curated pick should appear once per cycle")
    }

    @Test("skips entries with no insider tip rather than showing an empty section")
    func skipsUntipped() {
        let mixed = [
            makeBusiness(slug: InsiderPickSection.curatedSlugs[0], tip: nil),
            makeBusiness(slug: InsiderPickSection.curatedSlugs[1], tip: "Real tip"),
        ]
        for offset in 0..<12 {
            let date = islandDate(2026, 5, 1).addingTimeInterval(Double(offset) * 86_400)
            let picked = InsiderPickSection.pick(from: mixed, on: date)
            #expect(picked?.insiderTip?.isEmpty == false)
        }
    }

    @Test("returns nil when nothing is eligible, so the section hides")
    func emptyPoolHides() {
        #expect(InsiderPickSection.pick(from: [], on: islandDate(2026, 5, 1)) == nil)
    }

    @Test("survives a device clock set before the epoch")
    func handlesPastDates() {
        let picked = InsiderPickSection.pick(from: pool, on: islandDate(2019, 7, 4))
        #expect(picked != nil, "a backdated clock must not crash or blank the section")
    }

    @Test("ignores curated slugs that no longer match a business")
    func ignoresMissingSlugs() {
        let onlyOneReal = [makeBusiness(slug: InsiderPickSection.curatedSlugs[3])]
        let picked = InsiderPickSection.pick(from: onlyOneReal, on: islandDate(2026, 6, 15))
        #expect(picked?.slug == InsiderPickSection.curatedSlugs[3])
    }
}

// MARK: - Event scheduling

@Suite("Event scheduling")
struct EventScheduleTests {

    private func event(
        day: Weekday? = .wednesday,
        date: Date? = nil,
        start: String = "17:00",
        end: String? = nil,
        category: EventCategory = .liveMusic,
        cruiseOnly: Bool = false
    ) -> Event {
        Event.fixture(
            day: day, date: date, startTime: start, endTime: end,
            category: category, cruiseShipDayOnly: cruiseOnly
        )
    }

    private func wednesday(_ hour: Int, _ minute: Int = 0) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        // 5 Aug 2026 is a Wednesday.
        return cal.date(from: DateComponents(year: 2026, month: 8, day: 5, hour: hour, minute: minute))!
    }

    @Test("a set is live once it starts")
    func liveAfterStart() {
        let e = event(start: "17:00", end: "20:00")
        #expect(e.isLiveNow(now: wednesday(18)))
    }

    @Test("a set is not live before it starts")
    func notLiveBeforeStart() {
        let e = event(start: "17:00", end: "20:00")
        #expect(!e.isLiveNow(now: wednesday(16, 59)))
    }

    @Test("a set ends at its stated end time, not a fixed guess")
    func respectsEndTime() {
        let e = event(start: "17:00", end: "19:00")
        #expect(e.isLiveNow(now: wednesday(18, 59)))
        #expect(!e.isLiveNow(now: wednesday(19, 1)))
    }

    @Test("a set running past midnight stays live after 00:00")
    func handlesPastMidnight() {
        // The Captain Jack's case: 20:00 til midnight-ish.
        let e = event(start: "20:00", end: "01:00")
        #expect(e.isLiveNow(now: wednesday(23, 30)))
    }

    @Test("falls back to a duration window when no end time is given")
    func fallsBackToDuration() {
        let e = event(start: "17:00", end: nil)
        #expect(e.isLiveNow(now: wednesday(18)))
        #expect(!e.isLiveNow(now: wednesday(21)))
    }

    @Test("cruise-day-only events are detected from Keith's wording")
    func detectsCruiseOnlyFromText() {
        let tagged = Event.fixture(genre: "Cruise Ship Days Only")
        #expect(tagged.isCruiseDayOnly)

        let normal = Event.fixture(genre: "Pop & Soul Classics")
        #expect(!normal.isCruiseDayOnly)
    }
}

// MARK: - Cruise data freshness

@Suite("Cruise schedule freshness")
struct CruiseFreshnessTests {

    private func arrival(date: String, ship: String = "Test Ship", pax: Int = 3000) -> CruiseArrival {
        CruiseArrival.fixture(date: date, shipName: ship, passengerCount: pax)
    }

    private func todayString(offset: Int = 0) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(secondsFromGMT: -6 * 3600)
        return f.string(from: Date().addingTimeInterval(Double(offset) * 86_400))
    }

    @Test("passenger counts are rounded, never stated precisely")
    func roundsPassengers() {
        // Exact capacity is misleading — not everyone disembarks.
        #expect(CruiseArrival.roundedToNearest500(2124) == 2000)
        #expect(CruiseArrival.roundedToNearest500(5878) == 6000)
        #expect(CruiseArrival.roundedToNearest500(0) == 0)
    }

    @Test("a schedule reaching today counts as current")
    func currentWhenReachingToday() {
        let service = CruiseArrivalsService(arrivals: [arrival(date: todayString())])
        #expect(service.hasCurrentData)
    }

    @Test("a schedule reaching only into the past is NOT current")
    func staleWhenAllPast() {
        // The June-to-August outage: the app must not claim a quiet day.
        let service = CruiseArrivalsService(arrivals: [arrival(date: todayString(offset: -14))])
        #expect(!service.hasCurrentData)
    }

    @Test("an empty schedule is not current")
    func emptyIsNotCurrent() {
        #expect(!CruiseArrivalsService(arrivals: []).hasCurrentData)
    }
}
