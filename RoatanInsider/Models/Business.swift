import Foundation
import CoreLocation

struct DayHours: Codable, Hashable {
    let open: String
    let close: String
}

struct Business: Identifiable, Codable, Hashable {
    let id: String
    let slug: String
    let name: String
    let description: String
    let insiderTip: String?
    let category: Category
    let subcategory: String
    let area: Area
    let latitude: Double
    let longitude: Double
    let addressDescription: String
    let phone: String?
    let whatsapp: String?
    let email: String?
    let website: String?
    let facebook: String?
    let instagram: String?
    let priceRange: Int
    let hours: [String: DayHours?]
    let features: [String]
    let images: [String]
    let isVerified: Bool
    let isFeatured: Bool
    let status: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var priceLabel: String {
        String(repeating: "$", count: priceRange)
    }

    var isActive: Bool {
        status == "active"
    }

    func isOpenNow() -> Bool {
        let now = Date()
        let dayKey = now.currentDayKey
        guard let dayHours = hours[dayKey] ?? nil else { return false }

        let timeString = now.currentTimeString
        return timeString >= dayHours.open && timeString <= dayHours.close
    }
}
