import Foundation

enum Category: String, Codable, CaseIterable, Identifiable {
    case eat, drink, dive, tours, shop, stay, rentals, transport, beaches, nightlife

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .eat: return "Eat"
        case .drink: return "Drink"
        case .dive: return "Dive & Snorkel"
        case .tours: return "Tours & Activities"
        case .shop: return "Shop"
        case .stay: return "Stay"
        case .rentals: return "Rentals"
        case .transport: return "Transport"
        case .beaches: return "Beaches"
        case .nightlife: return "Nightlife"
        }
    }

    var iconName: String {
        switch self {
        case .eat: return "fork.knife"
        case .drink: return "wineglass"
        case .dive: return "figure.pool.swim"
        case .tours: return "binoculars"
        case .shop: return "bag"
        case .stay: return "bed.double"
        case .rentals: return "key"
        case .transport: return "car"
        case .beaches: return "beach.umbrella"
        case .nightlife: return "music.note"
        }
    }
}
