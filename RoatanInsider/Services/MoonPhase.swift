import Foundation

/// The moon's phase for a given date.
///
/// No weather API carries this — Open-Meteo doesn't — but it doesn't need
/// to. The synodic month is a fixed 29.53 days and the phase is pure
/// arithmetic from a known new moon, accurate to well within the half-day
/// resolution a phase name needs.
///
/// It earns its place on a Caribbean island: a full moon over West Bay is
/// something people plan an evening around, and divers ask about it because
/// it moves the currents.
struct MoonPhase: Equatable {

    /// A known new moon: 6 January 2000, 18:14 UTC. The standard epoch for
    /// this calculation.
    private static let referenceNewMoon = Date(timeIntervalSince1970: 947_182_440)

    /// Mean length of one lunation, in days.
    private static let synodicMonth: Double = 29.530588853

    /// 0 at new moon, 0.5 at full, wrapping back to 1 at the next new moon.
    let fraction: Double

    init(date: Date = .now) {
        let days = date.timeIntervalSince(Self.referenceNewMoon) / 86_400
        let cycles = days / Self.synodicMonth
        // Non-negative remainder so dates before the epoch still land in range.
        self.fraction = cycles - cycles.rounded(.down)
    }

    /// How much of the disc is lit, 0 to 1. Peaks at the full moon.
    var illumination: Double {
        (1 - cos(2 * .pi * fraction)) / 2
    }

    var isWaxing: Bool { fraction < 0.5 }

    enum Name: String {
        case new = "New Moon"
        case waxingCrescent = "Waxing Crescent"
        case firstQuarter = "First Quarter"
        case waxingGibbous = "Waxing Gibbous"
        case full = "Full Moon"
        case waningGibbous = "Waning Gibbous"
        case lastQuarter = "Last Quarter"
        case waningCrescent = "Waning Crescent"
    }

    /// Named in eight bands.
    ///
    /// The four principal phases get roughly a one-day window either side
    /// (±0.02 of the cycle) rather than the two-day window a naive
    /// eight-way split gives them. That's the convention iOS Weather
    /// follows, and it's the right one: "Full Moon" should mean tonight, not
    /// most of the week.
    var name: Name {
        switch fraction {
        case ..<0.02:  return .new
        case ..<0.23:  return .waxingCrescent
        case ..<0.27:  return .firstQuarter
        case ..<0.48:  return .waxingGibbous
        case ..<0.52:  return .full
        case ..<0.73:  return .waningGibbous
        case ..<0.77:  return .lastQuarter
        case ..<0.98:  return .waningCrescent
        default:       return .new
        }
    }

    /// The next full moon at or after this date.
    var nextFullMoon: Date {
        let daysToFull = ((0.5 - fraction) + 1).truncatingRemainder(dividingBy: 1) * Self.synodicMonth
        return Date().addingTimeInterval(daysToFull * 86_400)
    }

    /// "Waxing Crescent · 18% lit"
    var summary: String {
        "\(name.rawValue) · \(Int((illumination * 100).rounded()))% lit"
    }
}
