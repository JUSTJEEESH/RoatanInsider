import Foundation
import CoreLocation
import Observation

/// Detects when the user opens the app while physically on Roatán and
/// hasn't set up a trip yet — the classic cruise-passenger pattern.
/// Surfaces a banner on Home that opens Cruise Mode in one tap.
///
/// Conditions to fire:
///   1. LocationManager has any authorization (we never *request* permission
///      just for this; if the user said no, the banner never appears)
///   2. Current location is inside the Roatán bounding box
///   3. The user hasn't set trip dates, OR their trip dates are in the past
///   4. The banner hasn't been dismissed this session
///
/// We don't second-guess users who've gone through onboarding with real
/// trip dates — they know what they're here for.
@Observable
final class ArrivalDetector {
    private(set) var isOnIsland: Bool = false
    private(set) var dismissedThisSession: Bool = false

    private static let roatanLatMin = AppConstants.roatanCenter.latitude - AppConstants.roatanSpanLat / 2
    private static let roatanLatMax = AppConstants.roatanCenter.latitude + AppConstants.roatanSpanLat / 2
    private static let roatanLonMin = AppConstants.roatanCenter.longitude - AppConstants.roatanSpanLon / 2
    private static let roatanLonMax = AppConstants.roatanCenter.longitude + AppConstants.roatanSpanLon / 2

    /// Pure check — does this banner apply right now given the current
    /// inputs? Called by the Home view to decide whether to render.
    func shouldShow(location: CLLocation?, profile: UserProfile) -> Bool {
        guard !dismissedThisSession else { return false }
        guard let location else { return false }
        guard Self.isInRoatan(location) else { return false }

        // The banner copy assumes a cruise day — only fire for cruisers
        // (and pre-onboarding users, who get a soft default nudge).
        switch profile.travelerType {
        case .local, .expat, .longStay, .vacationer:
            return false
        case .cruiser, nil:
            break
        }

        // Skip users with an active or future trip — they're already
        // planned. Only nudge the "arrived without a plan" case.
        if let departure = profile.departureDate,
           Calendar.current.startOfDay(for: departure) >= Calendar.current.startOfDay(for: .now) {
            return false
        }
        return true
    }

    func dismiss() {
        dismissedThisSession = true
    }

    /// Public so other surfaces (Tools, etc.) can reuse the geofence
    /// without duplicating the constants.
    static func isInRoatan(_ location: CLLocation) -> Bool {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        return lat >= roatanLatMin && lat <= roatanLatMax
            && lon >= roatanLonMin && lon <= roatanLonMax
    }
}
