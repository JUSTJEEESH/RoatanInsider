import Foundation
import CoreLocation

struct DayHours: Codable, Hashable {
    let open: String
    let close: String
}

struct CategoryEntry: Codable, Hashable {
    let category: Category
    let subcategory: String
}

struct BusinessLocation: Codable, Hashable {
    let area: Area
    let latitude: Double
    let longitude: Double
    let addressDescription: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
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
    let additionalCategories: [CategoryEntry]
    let additionalLocations: [BusinessLocation]

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
        isVerified = (try? container.decode(Bool.self, forKey: .isVerified)) ?? false
        isFeatured = (try? container.decode(Bool.self, forKey: .isFeatured)) ?? false
        isInsiderPick = (try? container.decode(Bool.self, forKey: .isInsiderPick)) ?? false
        isBestOf = (try? container.decode(Bool.self, forKey: .isBestOf)) ?? false
        rating = try container.decodeIfPresent(Double.self, forKey: .rating)
        reviewCount = try container.decodeIfPresent(Int.self, forKey: .reviewCount)
        hoursText = try container.decodeIfPresent(String.self, forKey: .hoursText)
        status = try container.decode(String.self, forKey: .status)
        collections = (try? container.decode([String].self, forKey: .collections)) ?? []
        menuImages = try? container.decodeIfPresent([String].self, forKey: .menuImages)
        additionalCategories = (try? container.decode([CategoryEntry].self, forKey: .additionalCategories)) ?? []
        additionalLocations = (try? container.decode([BusinessLocation].self, forKey: .additionalLocations)) ?? []
    }

    // MARK: - All categories (primary + additional)

    var allCategories: [CategoryEntry] {
        var result = [CategoryEntry(category: category, subcategory: subcategory)]
        result.append(contentsOf: additionalCategories)
        return result
    }

    /// Check if this business belongs to a given category
    func hasCategory(_ cat: Category) -> Bool {
        category == cat || additionalCategories.contains { $0.category == cat }
    }

    /// Get the subcategory label for a specific category context
    func subcategory(for cat: Category) -> String {
        if category == cat { return subcategory }
        return additionalCategories.first { $0.category == cat }?.subcategory ?? subcategory
    }

    // MARK: - All locations (primary + additional)

    var allLocations: [BusinessLocation] {
        var result = [BusinessLocation(area: area, latitude: latitude, longitude: longitude, addressDescription: addressDescription)]
        result.append(contentsOf: additionalLocations)
        return result
    }

    /// All unique areas this business is in
    var allAreas: [Area] {
        var areas = [area]
        for loc in additionalLocations {
            if !areas.contains(loc.area) {
                areas.append(loc.area)
            }
        }
        return areas
    }

    /// Check if this business is in a given area
    func isInArea(_ a: Area) -> Bool {
        area == a || additionalLocations.contains { $0.area == a }
    }

    // MARK: - Existing computed properties

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
        let timeString = now.currentTimeString

        // Check today's hours
        if let dayHours = hours[dayKey] ?? nil {
            if dayHours.close >= dayHours.open {
                // Normal hours (e.g., 08:00–22:00)
                if timeString >= dayHours.open && timeString <= dayHours.close {
                    return true
                }
            } else {
                // Past-midnight hours (e.g., 18:00–02:00) — open from open until midnight
                if timeString >= dayHours.open {
                    return true
                }
            }
        }

        // Check if yesterday's hours extend past midnight into now
        let yesterdayKey = now.previousDayKey
        if let yesterdayHours = hours[yesterdayKey] ?? nil {
            if yesterdayHours.close < yesterdayHours.open {
                // Yesterday had past-midnight hours — check if we're still in the closing window
                if timeString <= yesterdayHours.close {
                    return true
                }
            }
        }

        return false
    }
}
