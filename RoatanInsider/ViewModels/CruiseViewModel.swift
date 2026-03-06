import Foundation
import CoreLocation

@Observable
final class CruiseViewModel {
    var isActive = false
    var selectedPort: CruisePort = .mahoganyBay
    var boardingTime: Date = CruiseViewModel.defaultBoardingTime()
    var showPortPicker = false

    enum CruisePort: String, CaseIterable, Identifiable {
        case mahoganyBay = "mahogany_bay"
        case coxenHole = "coxen_hole"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .mahoganyBay: return "Mahogany Bay"
            case .coxenHole: return "Coxen Hole"
            }
        }

        var subtitle: String {
            switch self {
            case .mahoganyBay: return "Dixon Cove · East of Coxen Hole"
            case .coxenHole: return "Town Center · Near West End"
            }
        }

        var coordinate: CLLocationCoordinate2D {
            switch self {
            // Mahogany Bay cruise terminal is in Dixon Cove, east of Coxen Hole
            case .mahoganyBay: return CLLocationCoordinate2D(latitude: 16.3248, longitude: -86.4959)
            // Town Center port in Coxen Hole, closer to western tourist areas
            case .coxenHole: return CLLocationCoordinate2D(latitude: 16.3170, longitude: -86.5370)
            }
        }

        var location: CLLocation {
            CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }

        /// Areas ordered by proximity to the port
        var nearbyAreas: [Area] {
            switch self {
            case .mahoganyBay:
                return [.dixonCove, .frenchHarbour, .coxenHole, .palmettoBay, .sandyBay, .flowersBay]
            case .coxenHole:
                return [.coxenHole, .sandyBay, .flowersBay, .westEnd, .westBay, .dixonCove]
            }
        }
    }

    // MARK: - Time

    var timeRemaining: TimeInterval {
        boardingTime.timeIntervalSinceNow
    }

    var timeRemainingFormatted: String {
        let remaining = max(0, timeRemaining)
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    /// Under 30 min — critical
    var isCritical: Bool {
        timeRemaining > 0 && timeRemaining < 1800
    }

    /// 30–60 min — urgent, start heading back
    var isUrgent: Bool {
        timeRemaining > 0 && timeRemaining < 3600
    }

    var isExpired: Bool {
        timeRemaining <= 0
    }

    enum UrgencyLevel {
        case expired, critical, urgent, moderate, relaxed

        var color: Color {
            switch self {
            case .expired: return .riPink
            case .critical: return .riPink
            case .urgent: return .orange
            case .moderate: return .riMint
            case .relaxed: return .riMint
            }
        }

        var icon: String {
            switch self {
            case .expired: return "exclamationmark.octagon.fill"
            case .critical: return "exclamationmark.triangle.fill"
            case .urgent: return "exclamationmark.triangle.fill"
            case .moderate: return "clock.fill"
            case .relaxed: return "clock.fill"
            }
        }

        var message: String {
            switch self {
            case .expired: return "You should be at the port!"
            case .critical: return "Head to port NOW"
            case .urgent: return "Start heading back soon"
            case .moderate: return "Keep an eye on the time"
            case .relaxed: return "You have time — enjoy!"
            }
        }
    }

    var urgencyLevel: UrgencyLevel {
        if isExpired { return .expired }
        if timeRemaining < 1800 { return .critical }
        if timeRemaining < 3600 { return .urgent }
        if timeRemaining < 7200 { return .moderate }
        return .relaxed
    }

    // MARK: - Business Filtering

    func filteredBusinesses(_ businesses: [Business]) -> [Business] {
        let portLocation = selectedPort.location

        var result = businesses
            .filter { $0.isActive }
            .filter { selectedPort.nearbyAreas.contains($0.area) }

        // When time is short, restrict to closer businesses only
        if timeRemaining < 3600 {
            // Under 1 hour: only businesses within ~3km
            result = result.filter { business in
                let loc = CLLocation(latitude: business.latitude, longitude: business.longitude)
                return portLocation.distance(from: loc) < 3000
            }
        } else if timeRemaining < 7200 {
            // Under 2 hours: businesses within ~8km
            result = result.filter { business in
                let loc = CLLocation(latitude: business.latitude, longitude: business.longitude)
                return portLocation.distance(from: loc) < 8000
            }
        }

        return result.sorted { b1, b2 in
            let d1 = portLocation.distance(from: CLLocation(latitude: b1.latitude, longitude: b1.longitude))
            let d2 = portLocation.distance(from: CLLocation(latitude: b2.latitude, longitude: b2.longitude))
            return d1 < d2
        }
    }

    func distanceFromPort(_ business: Business) -> String {
        let portLocation = selectedPort.location
        let businessLocation = CLLocation(latitude: business.latitude, longitude: business.longitude)
        let distance = portLocation.distance(from: businessLocation)

        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }

    func rawDistanceFromPort(_ business: Business) -> Double {
        let portLocation = selectedPort.location
        let businessLocation = CLLocation(latitude: business.latitude, longitude: business.longitude)
        return portLocation.distance(from: businessLocation)
    }

    func travelTimeMinutes(_ business: Business) -> Int {
        let distance = rawDistanceFromPort(business)
        // Roatán roads are slow — roughly 25km/h average by taxi, plus 5min wait/buffer
        return max(5, Int(distance / 420) + 5)
    }

    func travelTime(_ business: Business) -> String {
        let minutes = travelTimeMinutes(business)
        return "~\(minutes) min"
    }

    func canVisitAndReturn(_ business: Business) -> Bool {
        let minutes = travelTimeMinutes(business)
        // Round-trip travel + 30 min minimum at the location
        let minimumNeeded = Double(minutes * 2 + 30) * 60
        return timeRemaining > minimumNeeded
    }

    // MARK: - Helpers

    private static func defaultBoardingTime() -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 16
        components.minute = 30
        return calendar.date(from: components) ?? Date()
    }
}
