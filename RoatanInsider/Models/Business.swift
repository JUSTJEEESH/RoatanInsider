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
    let isInsiderPick: Bool
    let isBestOf: Bool
    let rating: Double?
    let reviewCount: Int?
    let hoursText: String?
    let status: String
    let collections: [String]
    let menuImages: [String]?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        slug = try container.decode(String.self, forKey: .slug)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        insiderTip = try container.decodeIfPresent(String.self, forKey: .insiderTip)
        category = try container.decode(Category.self, forKey: .category)
        subcategory = try container.decode(String.self, forKey: .subcategory)
        area = try container.decode(Area.self, forKey: .area)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        addressDescription = try container.decode(String.self, forKey: .addressDescription)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        whatsapp = try container.decodeIfPresent(String.self, forKey: .whatsapp)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        website = try container.decodeIfPresent(String.self, forKey: .website)
        facebook = try container.decodeIfPresent(String.self, forKey: .facebook)
        instagram = try container.decodeIfPresent(String.self, forKey: .instagram)
        priceRange = try container.decode(Int.self, forKey: .priceRange)
        hours = try container.decode([String: DayHours?].self, forKey: .hours)
        features = try container.decode([String].self, forKey: .features)
        images = try container.decode([String].self, forKey: .images)
        isVerified = try container.decode(Bool.self, forKey: .isVerified)
        isFeatured = try container.decode(Bool.self, forKey: .isFeatured)
        isInsiderPick = try container.decode(Bool.self, forKey: .isInsiderPick)
        isBestOf = try container.decode(Bool.self, forKey: .isBestOf)
        rating = try container.decodeIfPresent(Double.self, forKey: .rating)
        reviewCount = try container.decodeIfPresent(Int.self, forKey: .reviewCount)
        hoursText = try container.decodeIfPresent(String.self, forKey: .hoursText)
        status = try container.decode(String.self, forKey: .status)
        collections = (try? container.decode([String].self, forKey: .collections)) ?? []
        menuImages = try? container.decodeIfPresent([String].self, forKey: .menuImages)
    }

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
