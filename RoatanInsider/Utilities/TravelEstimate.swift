import Foundation
import CoreLocation

/// How long it takes to get somewhere on Roatán, stated as an estimate.
///
/// Roatán is 48 miles of island served essentially by one road, so travel
/// time tracks distance along that road closely enough to be useful — which
/// is the whole point here. A recommendation that doesn't say "this is an
/// hour away" isn't advice, it's a trap for someone with six hours ashore.
///
/// Everything is derived from two constants below, both stated openly and
/// both easy to retune. The output is always hedged ("about 50 min") and
/// rounded to five minutes, because a estimate presented to the minute
/// claims a precision this cannot have.
enum TravelEstimate {

    /// The main road follows the coast and bends with it, so road distance
    /// runs longer than the straight line between two points. 1.3 is a
    /// conservative allowance for that.
    static let windingFactor: Double = 1.3

    /// Realistic average including the slow stretches through Coxen Hole and
    /// French Harbour. Not a speed limit — a door-to-door average.
    static let averageSpeedKph: Double = 38

    /// Where a visitor is assumed to start when we have no location. Nearly
    /// all of them are in this corridor, and saying "from West End" out loud
    /// is what makes the number checkable rather than mysterious.
    static let defaultOrigin = CLLocation(latitude: 16.2985, longitude: -86.6110)
    static let defaultOriginName = "West End"

    /// Below this, "how long is the drive" isn't the question — you're
    /// already there, and a two-minute estimate is noise.
    static let negligibleMetres: Double = 2_500

    /// "about 50 min away" with a location, "about 50 min from West End"
    /// without one. Nil when it's close enough not to matter.
    static func label(to business: Business, from userLocation: CLLocation?) -> String? {
        let destination = CLLocation(latitude: business.latitude, longitude: business.longitude)
        let origin = userLocation ?? defaultOrigin
        let metres = origin.distance(from: destination)
        guard metres >= negligibleMetres else { return nil }

        let minutes = estimatedMinutes(straightLineMetres: metres)
        let suffix = userLocation == nil ? "from \(defaultOriginName)" : "away"
        return "about \(minutes) min \(suffix)"
    }

    /// Rounded to five minutes, floored at five so nothing past the
    /// negligible threshold reads as zero.
    static func estimatedMinutes(straightLineMetres: Double) -> Int {
        let roadKm = (straightLineMetres / 1000) * windingFactor
        let rawMinutes = roadKm / averageSpeedKph * 60
        return max(5, Int((rawMinutes / 5).rounded()) * 5)
    }
}
