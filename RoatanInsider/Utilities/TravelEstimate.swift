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
    /// runs longer than the straight line between two points. 1.3 was a
    /// guess and it was too low: on the runs that matter, the road doubles
    /// back around bays a straight line cuts across. Between West Bay and
    /// Mahogany Bay the straight line goes over open water.
    static let windingFactor: Double = 1.45

    /// A door-to-door average, not a speed limit — speed bumps, the crawl
    /// through Coxen Hole and French Harbour, and whatever is parked in the
    /// road. 38 was optimistic by about a third; 32 was pessimistic by a
    /// little once real measurements arrived.
    static let averageSpeedKph: Double = 34

    // Together these give about 2.56 minutes per straight-line kilometre,
    // which is the median of eight routes Josh measured in Google Maps:
    //
    //   West End - Sandy Bay       2.7 km    5 min   1.83 min/km
    //   Coxen Hole - Sandy Bay     3.7 km   10 min   2.72
    //   West End - Coxen Hole      5.6 km   20 min   3.54
    //   West Bay - Coxen Hole      7.5 km   20 min   2.67
    //   Mahogany Bay - West End   10.4 km   30 min   2.88
    //   Coxen Hole - French H.    10.9 km   20 min   1.84
    //   Mahogany Bay - West Bay   12.2 km   30 min   2.47
    //   West Bay - French H.      18.3 km   35 min   1.91
    //
    // The spread is the point: the west corridor runs near 2.7 min/km and
    // the highway east of Coxen Hole near 1.9, so a single figure runs long
    // on eastward trips — by about eight minutes to French Harbour. Worth
    // splitting into two zones if this label ever has to carry more weight
    // than "about 40 min"; not worth it for a hedge.

    /// Where a visitor is assumed to start when we have no location. Nearly
    /// all of them are in this corridor, and saying "from West End" out loud
    /// is what makes the number checkable rather than mysterious.
    static let defaultOrigin = CLLocation(latitude: 16.30488, longitude: -86.59328)
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
