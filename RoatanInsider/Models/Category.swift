import Foundation
import SwiftUI

enum Category: String, Codable, CaseIterable, Identifiable {
    case eat, drink, dive, tours, shop, stay, rentals, transport, beaches, nightlife
    case realEstate = "real_estate"
    case services
    case wellness
    case groceries
    case photography
    case health
    case fitness
    case marina
    case events
    case family

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .eat: return "Eat"
        case .drink: return "Drink"
        case .dive: return "Dive"
        case .tours: return "Tours"
        case .shop: return "Shop"
        case .stay: return "Stay"
        case .rentals: return "Rentals"
        case .transport: return "Transport"
        case .beaches: return "Beaches"
        case .nightlife: return "Nightlife"
        case .realEstate: return "Real Estate"
        case .services: return "Services"
        case .wellness: return "Wellness"
        case .groceries: return "Groceries"
        case .photography: return "Photography"
        case .health: return "Health & Medical"
        case .fitness: return "Fitness & Gym"
        case .marina: return "Marina & Boating"
        case .events: return "Events & Weddings"
        case .family: return "Kids & Family"
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
        case .realEstate: return "house.and.flag"
        case .services: return "scissors"
        case .wellness: return "leaf.circle"
        case .groceries: return "cart"
        case .photography: return "camera.aperture"
        case .health: return "cross.case"
        case .fitness: return "dumbbell"
        case .marina: return "sailboat"
        case .events: return "party.popper"
        case .family: return "figure.2.and.child.holdinghands"
        }
    }

    var mapSearchTerms: [String] {
        switch self {
        case .eat: return ["restaurants", "food"]
        case .drink: return ["bars", "coffee"]
        case .dive: return ["scuba diving", "snorkeling"]
        case .tours: return ["tours", "activities"]
        case .shop: return ["shopping"]
        case .stay: return ["hotels", "resorts"]
        case .rentals: return ["car rental", "scooter rental"]
        case .transport: return ["taxi", "transportation"]
        case .beaches: return ["beach"]
        case .nightlife: return ["nightclub", "nightlife"]
        case .realEstate: return ["real estate", "property"]
        case .services: return ["services", "repair"]
        case .wellness: return ["spa", "wellness"]
        case .groceries: return ["grocery", "supermarket"]
        case .photography: return ["photography", "photo"]
        case .health: return ["hospital", "clinic", "pharmacy"]
        case .fitness: return ["gym", "fitness"]
        case .marina: return ["marina", "boat"]
        case .events: return ["events", "wedding"]
        case .family: return ["family", "kids"]
        }
    }

    /// Light mint background for category placeholders
    var placeholderColor: Color {
        Color.riMint.opacity(0.15)
    }
}

// MARK: - CategoryNavID (wrapper for NavigationStack destinations)

/// A lightweight wrapper so that category navigation doesn't collide with other String-based destinations.
struct CategoryNavID: Hashable {
    let id: String
}

// MARK: - CategoryInfo (data-driven category from Supabase)

struct CategoryInfo: Codable, Identifiable, Hashable {
    let id: String          // e.g., "eat", "real_estate"
    let displayName: String // e.g., "Eat", "Real Estate"
    let iconName: String    // SF Symbol name
    let sortOrder: Int

    var placeholderColor: Color {
        Color.riMint.opacity(0.15)
    }

    /// Build a CategoryInfo from a known Category enum case
    init(from category: Category, sortOrder: Int) {
        self.id = category.rawValue
        self.displayName = category.displayName
        self.iconName = category.iconName
        self.sortOrder = sortOrder
    }

    init(id: String, displayName: String, iconName: String, sortOrder: Int) {
        self.id = id
        self.displayName = displayName
        self.iconName = iconName
        self.sortOrder = sortOrder
    }

    /// Default category infos from the enum, used as fallback when no remote data is available
    static let defaults: [CategoryInfo] = Category.allCases.enumerated().map { index, cat in
        CategoryInfo(from: cat, sortOrder: index)
    }
}
