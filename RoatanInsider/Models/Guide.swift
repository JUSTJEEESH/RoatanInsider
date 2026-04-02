import Foundation
import CoreLocation

struct CruiseGuide: Codable, Identifiable {
    let id: String
    let portName: String
    let portDescription: String
    let latitude: Double
    let longitude: Double
    let itineraries: [Itinerary]
    let safetyTips: [String]
    let returnReminder: String
}

struct Itinerary: Codable, Identifiable {
    let id: String
    let duration: String
    let title: String
    let steps: [ItineraryStep]
}

struct ItineraryStep: Codable, Identifiable {
    let id: String
    let time: String
    let title: String
    let description: String
    let estimatedCost: String?
    let tip: String?
}

struct AreaGuide: Codable, Identifiable, Hashable {
    let id: String
    let area: String
    let displayName: String
    let overview: String
    let vibe: String
    let bestFor: String
    let topPicks: [String]
    let gettingThere: String
    let latitude: Double?
    let longitude: Double?
    let areaDescription: String?
    let nearbyPorts: [String]

    /// The Area enum value, if this is a known area
    var areaEnum: Area? { Area(rawValue: area) }

    /// Display name with fallback
    var name: String {
        if !displayName.isEmpty { return displayName }
        return areaEnum?.displayName ?? area.replacingOccurrences(of: "_", with: " ").capitalized
    }

    /// Coordinate from guide data or Area enum fallback
    var coordinate: CLLocationCoordinate2D {
        if let lat = latitude, let lon = longitude, lat != 0, lon != 0 {
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        return areaEnum?.coordinate ?? CLLocationCoordinate2D(latitude: 16.33, longitude: -86.52)
    }

    /// Description with fallback
    var descriptionText: String {
        areaDescription ?? areaEnum?.description ?? overview
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        // Decode area as string regardless of whether it's a known Area enum value
        area = try container.decode(String.self, forKey: .area)
        displayName = (try? container.decode(String.self, forKey: .displayName)) ?? ""
        overview = (try? container.decode(String.self, forKey: .overview)) ?? ""
        vibe = (try? container.decode(String.self, forKey: .vibe)) ?? ""
        bestFor = (try? container.decode(String.self, forKey: .bestFor)) ?? ""
        topPicks = (try? container.decode([String].self, forKey: .topPicks)) ?? []
        gettingThere = (try? container.decode(String.self, forKey: .gettingThere)) ?? ""
        latitude = try? container.decode(Double.self, forKey: .latitude)
        longitude = try? container.decode(Double.self, forKey: .longitude)
        areaDescription = try? container.decode(String.self, forKey: .areaDescription)
        nearbyPorts = (try? container.decode([String].self, forKey: .nearbyPorts)) ?? []
    }
}

struct EssentialTopic: Codable, Identifiable {
    let id: String
    let title: String
    let icon: String
    let content: String
    let tips: [String]
}

struct EssentialsGuide: Codable {
    let topics: [EssentialTopic]
}
