import Testing
import Foundation
import CoreLocation
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

    /// Island midday, so tests don't drift with the machine's time zone.
    private func islandDate(_ y: Int, _ m: Int, _ d: Int, hour: Int = 12) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "America/Tegucigalpa")!
        return cal.date(from: DateComponents(year: y, month: m, day: d, hour: hour))!
    }

    /// West End and Oak Ridge, roughly. The pools are told apart by where
    /// their members are, so fixtures need real coordinates.
    private static let westEnd = (lat: 16.2985, lon: -86.6110)
    private static let oakRidge = (lat: 16.3670, lon: -86.3690)

    private func nearby(_ slug: String, tip: String? = "A tip") -> Business {
        Business.fixture(slug: slug, insiderTip: tip,
                         latitude: Self.westEnd.lat, longitude: Self.westEnd.lon)
    }

    private func far(_ slug: String, tip: String? = "A tip") -> Business {
        Business.fixture(slug: slug, insiderTip: tip, area: "oak_ridge",
                         latitude: Self.oakRidge.lat, longitude: Self.oakRidge.lon)
    }

    private var pool: [Business] {
        InsiderPickSection.nearbySlugs.map { nearby($0) }
            + InsiderPickSection.worthTheTripSlugs.map { far($0) }
    }

    // MARK: The weighting is the whole point

    @Test("four of every five slots are close by")
    func weightingFavoursNearby() {
        // One full pass through the weighting cycle, sampled at every slot.
        var nearCount = 0, farCount = 0
        for slot in 0..<(InsiderPickSection.weighting * 6) {
            let date = islandDate(2026, 1, 1)
                .addingTimeInterval(Double(slot * InsiderPickSection.rotationDays) * 86_400)
            guard let picked = InsiderPickSection.pick(from: pool, on: date) else { continue }
            picked.isWorthTheTrip ? (farCount += 1) : (nearCount += 1)
        }
        #expect(farCount * 4 == nearCount,
                "expected a 4:1 split, got \(nearCount) near to \(farCount) far")
    }

    @Test("a week-long stay is never sent across the island twice")
    func weekLongVisitorSeesAtMostOneFarPick() {
        // Every seven-day window across a full cycle, counting distinct far
        // places rather than days — being shown the same one on Tuesday and
        // Wednesday is one recommendation, not two.
        let cycleDays = InsiderPickSection.weighting
            * InsiderPickSection.worthTheTripSlugs.count
            * InsiderPickSection.rotationDays
        for startDay in 0..<cycleDays {
            var farSeen = Set<String>()
            for dayOffset in 0..<7 {
                let date = islandDate(2026, 1, 1)
                    .addingTimeInterval(Double(startDay + dayOffset) * 86_400)
                if let picked = InsiderPickSection.pick(from: pool, on: date), picked.isWorthTheTrip {
                    farSeen.insert(picked.business.slug)
                }
            }
            #expect(farSeen.count <= 1,
                    "a one-week stay was pointed across the island \(farSeen.count) times")
        }
    }

    // MARK: Rotation mechanics

    @Test("holds the same pick across the rotation window")
    func holdsAcrossWindow() {
        let day1 = InsiderPickSection.pick(from: pool, on: islandDate(2026, 3, 2))
        let day2 = InsiderPickSection.pick(from: pool, on: islandDate(2026, 3, 3))
        #expect(day1?.business.slug == day2?.business.slug)
    }

    @Test("changes after the rotation window elapses")
    func changesAfterWindow() {
        let before = InsiderPickSection.pick(from: pool, on: islandDate(2026, 3, 2))
        let after = InsiderPickSection.pick(
            from: pool,
            on: islandDate(2026, 3, 2 + InsiderPickSection.rotationDays)
        )
        #expect(before?.business.slug != after?.business.slug)
    }

    @Test("every nearby entry gets a turn")
    func everyNearbyEntryAppears() {
        var seen = Set<String>()
        let slots = InsiderPickSection.weighting * InsiderPickSection.nearbySlugs.count
        for slot in 0..<slots {
            let date = islandDate(2026, 1, 1)
                .addingTimeInterval(Double(slot * InsiderPickSection.rotationDays) * 86_400)
            if let picked = InsiderPickSection.pick(from: pool, on: date), !picked.isWorthTheTrip {
                seen.insert(picked.business.slug)
            }
        }
        #expect(seen.count == InsiderPickSection.nearbySlugs.count)
    }

    @Test("every far entry gets a turn")
    func everyFarEntryAppears() {
        var seen = Set<String>()
        let slots = InsiderPickSection.weighting * InsiderPickSection.worthTheTripSlugs.count
        for slot in 0..<slots {
            let date = islandDate(2026, 1, 1)
                .addingTimeInterval(Double(slot * InsiderPickSection.rotationDays) * 86_400)
            if let picked = InsiderPickSection.pick(from: pool, on: date), picked.isWorthTheTrip {
                seen.insert(picked.business.slug)
            }
        }
        #expect(seen.count == InsiderPickSection.worthTheTripSlugs.count)
    }

    // MARK: Where the reader is

    @Test("someone living out east gets the east pool as their everyday one")
    func locationInvertsTheWeighting() {
        let inOakRidge = CLLocation(latitude: Self.oakRidge.lat, longitude: Self.oakRidge.lon)
        var eastCount = 0
        for slot in 0..<(InsiderPickSection.weighting * 4) {
            let date = islandDate(2026, 1, 1)
                .addingTimeInterval(Double(slot * InsiderPickSection.rotationDays) * 86_400)
            guard let picked = InsiderPickSection.pick(
                from: pool, on: date, userLocation: inOakRidge
            ) else { continue }
            if picked.business.area == "oak_ridge" { eastCount += 1 }
        }
        #expect(eastCount > InsiderPickSection.weighting * 2,
                "an Oak Ridge reader should mostly get Oak Ridge picks")
    }

    @Test("a West Bay reader keeps the standard weighting")
    func westReaderKeepsDefault() {
        let inWestBay = CLLocation(latitude: 16.2940, longitude: -86.6180)
        var farCount = 0
        for slot in 0..<(InsiderPickSection.weighting * 4) {
            let date = islandDate(2026, 1, 1)
                .addingTimeInterval(Double(slot * InsiderPickSection.rotationDays) * 86_400)
            if InsiderPickSection.pick(from: pool, on: date, userLocation: inWestBay)?.isWorthTheTrip == true {
                farCount += 1
            }
        }
        #expect(farCount == 4, "one far pick per weighting cycle, four cycles")
    }

    // MARK: Degenerate data

    @Test("skips entries with no insider tip rather than showing an empty section")
    func skipsUntipped() {
        let mixed = [
            nearby(InsiderPickSection.nearbySlugs[0], tip: nil),
            nearby(InsiderPickSection.nearbySlugs[1], tip: "Real tip"),
        ]
        for offset in 0..<12 {
            let date = islandDate(2026, 5, 1).addingTimeInterval(Double(offset) * 86_400)
            let picked = InsiderPickSection.pick(from: mixed, on: date)
            #expect(picked?.business.insiderTip?.isEmpty == false)
        }
    }

    @Test("returns nil when nothing is eligible, so the section hides")
    func emptyPoolHides() {
        #expect(InsiderPickSection.pick(from: [], on: islandDate(2026, 5, 1)) == nil)
    }

    @Test("carries on when only the far pool resolves")
    func farOnlyStillPicks() {
        let onlyFar = InsiderPickSection.worthTheTripSlugs.map { far($0) }
        #expect(InsiderPickSection.pick(from: onlyFar, on: islandDate(2026, 5, 1)) != nil)
    }

    @Test("survives a device clock set before the epoch")
    func handlesPastDates() {
        let picked = InsiderPickSection.pick(from: pool, on: islandDate(2019, 7, 4))
        #expect(picked != nil, "a backdated clock must not crash or blank the section")
    }

    @Test("ignores curated slugs that no longer match a business")
    func ignoresMissingSlugs() {
        let onlyOneReal = [nearby(InsiderPickSection.nearbySlugs[3])]
        let picked = InsiderPickSection.pick(from: onlyOneReal, on: islandDate(2026, 6, 15))
        #expect(picked?.business.slug == InsiderPickSection.nearbySlugs[3])
    }
}

// MARK: - Travel estimates

@Suite("Travel estimates")
struct TravelEstimateTests {

    @Test("a place you can walk to says nothing at all")
    func nearbyIsSilent() {
        let downTheRoad = Business.fixture(slug: "close", latitude: 16.2990, longitude: -86.6115)
        #expect(TravelEstimate.label(to: downTheRoad, from: nil) == nil)
    }

    @Test("the far end of the island reads as about an hour")
    func oakRidgeIsAnHour() {
        let saltyDawg = Business.fixture(slug: "salty-dawg", area: "oak_ridge",
                                         latitude: 16.3670, longitude: -86.3690)
        let label = TravelEstimate.label(to: saltyDawg, from: nil)
        #expect(label == "about 60 min from West End")
    }

    @Test("says 'away' rather than 'from West End' when it knows where you are")
    func phrasingFollowsLocation() {
        let saltyDawg = Business.fixture(slug: "salty-dawg", area: "oak_ridge",
                                         latitude: 16.3670, longitude: -86.3690)
        let inWestBay = CLLocation(latitude: 16.2940, longitude: -86.6180)
        let label = TravelEstimate.label(to: saltyDawg, from: inWestBay)
        #expect(label?.hasSuffix("away") == true)
    }

    @Test("estimates are rounded to five minutes and never claim zero")
    func roundsToFives() {
        #expect(TravelEstimate.estimatedMinutes(straightLineMetres: 2_600) % 5 == 0)
        #expect(TravelEstimate.estimatedMinutes(straightLineMetres: 2_600) >= 5)
        #expect(TravelEstimate.estimatedMinutes(straightLineMetres: 100) == 5)
    }

    @Test("longer distances estimate longer, monotonically")
    func monotonic() {
        var last = 0
        for km in stride(from: 3.0, through: 40.0, by: 1.0) {
            let minutes = TravelEstimate.estimatedMinutes(straightLineMetres: km * 1000)
            #expect(minutes >= last)
            last = minutes
        }
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
