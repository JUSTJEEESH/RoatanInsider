import Foundation

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

struct AreaGuide: Codable, Identifiable {
    let id: String
    let area: Area
    let overview: String
    let vibe: String
    let bestFor: String
    let topPicks: [String]
    let gettingThere: String
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
