import Foundation
import SwiftUI

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

    /// Muted, dark-toned placeholder background per category — no bright colors
    var placeholderColor: Color {
        switch self {
        case .eat:       return Color(red: 0.22, green: 0.18, blue: 0.16)
        case .drink:     return Color(red: 0.20, green: 0.16, blue: 0.22)
        case .dive:      return Color(red: 0.12, green: 0.20, blue: 0.26)
        case .tours:     return Color(red: 0.18, green: 0.22, blue: 0.18)
        case .shop:      return Color(red: 0.22, green: 0.20, blue: 0.18)
        case .stay:      return Color(red: 0.20, green: 0.18, blue: 0.20)
        case .rentals:   return Color(red: 0.18, green: 0.18, blue: 0.20)
        case .transport: return Color(red: 0.18, green: 0.18, blue: 0.18)
        case .beaches:   return Color(red: 0.14, green: 0.22, blue: 0.24)
        case .nightlife: return Color(red: 0.22, green: 0.16, blue: 0.20)
        }
    }
}
