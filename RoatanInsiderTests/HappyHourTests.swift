import Testing
import Foundation
@testable import RoatanInsider

/// Tests for the happy hour window.
///
/// The row this drives once read "Happy hour on now" whenever a bar carrying
/// a Happy Hour tag was open — true for a beach bar from ten in the morning
/// until close, so it was wrong nearly every hour it appeared. These cases
/// exist to keep the replacement honest, because the failure mode is silent:
/// a wrong window doesn't crash, it just sends someone out for a drink deal
/// that finished two hours ago.

@Suite("Happy hour windows")
struct HappyHourTests {

    /// 5 August 2026 is a Wednesday.
    private func wednesday(_ hour: Int, _ minute: Int = 0) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        return cal.date(from: DateComponents(year: 2026, month: 8, day: 5, hour: hour, minute: minute))!
    }

    // MARK: - The basic window

    @Test("on inside the window")
    func onInsideWindow() {
        let hh = HappyHour(start: "16:00", end: "18:00")
        #expect(hh.isOn(now: wednesday(17)))
    }

    @Test("off before it starts")
    func offBeforeStart() {
        let hh = HappyHour(start: "16:00", end: "18:00")
        #expect(!hh.isOn(now: wednesday(15, 59)))
    }

    @Test("off the moment it ends")
    func offAtEnd() {
        let hh = HappyHour(start: "16:00", end: "18:00")
        #expect(hh.isOn(now: wednesday(17, 59)))
        #expect(!hh.isOn(now: wednesday(18)))
    }

    @Test("on at the minute it opens")
    func onAtStart() {
        let hh = HappyHour(start: "16:00", end: "18:00")
        #expect(hh.isOn(now: wednesday(16)))
    }

    // MARK: - Days

    @Test("a windowless day list means every day")
    func emptyDaysMeansDaily() {
        let hh = HappyHour(start: "16:00", end: "18:00")
        #expect(hh.runsEveryDay)
        #expect(hh.isOn(now: wednesday(17)))
    }

    @Test("a day-limited window is off on other days")
    func respectsDays() {
        let friSat = HappyHour(days: ["friday", "saturday"], start: "16:00", end: "18:00")
        #expect(!friSat.isOn(now: wednesday(17)), "Wednesday is not Friday")

        let wed = HappyHour(days: ["wednesday"], start: "16:00", end: "18:00")
        #expect(wed.isOn(now: wednesday(17)))
    }

    // MARK: - Past midnight

    @Test("a late window stays on after midnight")
    func crossesMidnight() {
        let hh = HappyHour(start: "22:00", end: "01:00")
        #expect(hh.isOn(now: wednesday(23)))
        // 00:30 on the Thursday — the window that started Wednesday night.
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        let thursdayEarly = cal.date(from: DateComponents(year: 2026, month: 8, day: 6, hour: 0, minute: 30))!
        #expect(hh.isOn(now: thursdayEarly))
    }

    @Test("a late window's day test follows the night it started")
    func pastMidnightUsesStartingDay() {
        // Wednesdays only, 10pm til 1am. The small hours of Thursday still
        // belong to Wednesday's session.
        let hh = HappyHour(days: ["wednesday"], start: "22:00", end: "01:00")
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        let thursdayEarly = cal.date(from: DateComponents(year: 2026, month: 8, day: 6, hour: 0, minute: 30))!
        #expect(hh.isOn(now: thursdayEarly))

        // But Friday's small hours belong to Thursday, which isn't in the list.
        let fridayEarly = cal.date(from: DateComponents(year: 2026, month: 8, day: 7, hour: 0, minute: 30))!
        #expect(!hh.isOn(now: fridayEarly))
    }

    // MARK: - Malformed data fails closed

    @Test("an unreadable time is never on")
    func malformedTimesAreOff() {
        #expect(!HappyHour(start: "4pm", end: "6pm").isOn(now: wednesday(17)))
        #expect(!HappyHour(start: "", end: "").isOn(now: wednesday(17)))
    }

    // MARK: - The business-level rule

    @Test("no window stated means never claims one")
    func noWindowNeverClaims() {
        let b = Business.fixture(slug: "some-bar", happyHour: nil)
        #expect(!b.isHappyHourNow(now: wednesday(17)))
    }

    @Test("a stated window is honoured when hours are unknown")
    func windowHonouredWithoutHours() {
        // 12 of 94 places have incomplete hours. A stated window shouldn't be
        // suppressed just because we don't hold opening times.
        let b = Business.fixture(
            slug: "some-bar",
            happyHour: HappyHour(start: "16:00", end: "18:00")
        )
        #expect(b.isHappyHourNow(now: wednesday(17)))
    }

    @Test("a window on a day the place is shut does not claim to be on")
    func closedDayBeatsWindow() {
        // The bug this whole field replaces was hours-driven; the inverse
        // matters too. A daily window must not survive the day the bar is dark.
        let b = Business.fixture(
            slug: "some-bar",
            happyHour: HappyHour(start: "16:00", end: "18:00"),
            hours: ["wednesday": nil, "thursday": "10:00-22:00"]
        )
        #expect(!b.isHappyHourNow(now: wednesday(17)))
    }

    @Test("labels read as a person would say them")
    func labels() {
        let hh = HappyHour(start: "16:00", end: "18:30", note: "2-for-1")
        #expect(hh.untilLabel == "until 6:30 PM")
        #expect(hh.windowLabel == "4 PM–6:30 PM")
        #expect(hh.fullLabel == "Daily 4 PM–6:30 PM")

        let friSat = HappyHour(days: ["friday", "saturday"], start: "17:00", end: "19:00")
        #expect(friSat.fullLabel == "Fri, Sat 5 PM–7 PM")
    }
}
