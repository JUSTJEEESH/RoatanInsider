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
            case .mahoganyBay: return "Near West Bay & West End"
            case .coxenHole: return "Town Center Port"
            }
        }

        var coordinate: CLLocationCoordinate2D {
            switch self {
            case .mahoganyBay: return CLLocationCoordinate2D(latitude: 16.3120, longitude: -86.5530)
            case .coxenHole: return CLLocationCoordinate2D(latitude: 16.3170, longitude: -86.5370)
            }
        }

        var location: CLLocation {
            CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        }

        var nearbyAreas: [Area] {
            switch self {
            case .mahoganyBay: return [.westBay, .westEnd, .sandyBay, .dixonCove, .coxenHole]
            case .coxenHole: return [.coxenHole, .sandyBay, .westEnd, .westBay, .dixonCove]
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

    var isUrgent: Bool {
        timeRemaining < 3600 && timeRemaining > 0
    }

    var isExpired: Bool {
        timeRemaining <= 0
    }

    var urgencyMessage: String {
        if isExpired {
            return "Time to head back!"
        } else if timeRemaining < 1800 {
            return "Head to port NOW"
        } else if timeRemaining < 3600 {
            return "Start heading back soon"
        } else {
            return "You have time — enjoy!"
        }
    }

    // MARK: - Business Filtering

    func filteredBusinesses(_ businesses: [Business]) -> [Business] {
        let portLocation = selectedPort.location
        let nearby = selectedPort.nearbyAreas

        return businesses
            .filter { $0.isActive }
            .filter { nearby.contains($0.area) }
            .sorted { b1, b2 in
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

    func travelTime(_ business: Business) -> String {
        let portLocation = selectedPort.location
        let businessLocation = CLLocation(latitude: business.latitude, longitude: business.longitude)
        let distance = portLocation.distance(from: businessLocation)

        // Rough estimate: taxi ~30km/h, add 5min buffer
        let minutes = Int(distance / 500) + 5
        return "~\(minutes) min"
    }

    func canVisitAndReturn(_ business: Business) -> Bool {
        let portLocation = selectedPort.location
        let businessLocation = CLLocation(latitude: business.latitude, longitude: business.longitude)
        let distance = portLocation.distance(from: businessLocation)

        // Need round-trip travel time + minimum 30 min at location
        let travelMinutes = Double(Int(distance / 500) + 5)
        let minimumNeeded = (travelMinutes * 2 + 30) * 60
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
