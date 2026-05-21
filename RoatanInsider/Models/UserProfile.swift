import Foundation

/// User-supplied preferences gathered during onboarding (and editable later).
/// Powers personalised home sections, smarter "Right Now" recommendations,
/// trip-aware notifications, and ASO-relevant retention loops.
struct UserProfile: Codable, Equatable {
    var firstName: String?
    var travelerType: TravelerType?
    var arrivalDate: Date?
    var departureDate: Date?
    var interests: Set<Interest>
    var hasGrantedLocation: Bool
    var hasGrantedNotifications: Bool
    var hasCompletedOnboarding: Bool
    /// First-ever launch — used to grandfather pre-freemium users.
    var firstLaunchDate: Date
    /// CFBundleShortVersionString of the first install — set once, never changes.
    var firstLaunchAppVersion: String

    // Onboarding 3.0 — context-aware fields. All optional; nil means
    // "the user is the kind of traveler who doesn't need this question."
    /// Where the traveler is staying (vacationer/longStay), where they live
    /// (expat/local), or unset (cruiser — they're on a ship). Powers stay-area
    /// weighted recommendations across the app.
    var stayArea: Area?
    /// Cruise day port. Only relevant for `.cruiser`. Pre-populates Cruise Mode.
    var cruisePortRawValue: String?
    /// Cruise day boarding deadline. Drives the Live Activity countdown.
    var cruiseBoardingTime: Date?
    /// How long an expat has lived on the island. Tunes the home feed —
    /// new arrivals get more "essentials"; longtime residents get more
    /// "what's new this week".
    var expatTenureRawValue: String?
    /// Local resident opt-in to contributing tips / photos. We don't have
    /// the contribution UI yet, but the flag lets us segment messaging
    /// (e.g., "Got a new place to share?" only fires for opted-in locals).
    var contributesContent: Bool

    static let empty = UserProfile(
        firstName: nil,
        travelerType: nil,
        arrivalDate: nil,
        departureDate: nil,
        interests: [],
        hasGrantedLocation: false,
        hasGrantedNotifications: false,
        hasCompletedOnboarding: false,
        firstLaunchDate: .now,
        firstLaunchAppVersion: "",
        stayArea: nil,
        cruisePortRawValue: nil,
        cruiseBoardingTime: nil,
        expatTenureRawValue: nil,
        contributesContent: false
    )

    var daysUntilArrival: Int? {
        guard let arrivalDate else { return nil }
        return Calendar.current.dateComponents([.day], from: .now, to: arrivalDate).day
    }

    var daysUntilDeparture: Int? {
        guard let departureDate else { return nil }
        return Calendar.current.dateComponents([.day], from: .now, to: departureDate).day
    }

    var isCurrentlyOnIsland: Bool {
        guard let a = arrivalDate, let d = departureDate else { return false }
        let now = Date()
        return now >= Calendar.current.startOfDay(for: a) && now <= d
    }
}

enum TravelerType: String, Codable, CaseIterable, Identifiable {
    case cruiser
    case vacationer
    case longStay = "long_stay"
    case expat
    case local

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .cruiser:    return "Cruise day visitor"
        case .vacationer: return "On vacation"
        case .longStay:   return "Staying a few weeks"
        case .expat:      return "Living here"
        case .local:      return "Local resident"
        }
    }

    var subtitle: String {
        switch self {
        case .cruiser:    return "A few hours, then back on the ship"
        case .vacationer: return "A week or so on the island"
        case .longStay:   return "Digital nomad, snowbird, extended trip"
        case .expat:      return "Roatán is home"
        case .local:      return "Born and raised here"
        }
    }

    var iconName: String {
        switch self {
        case .cruiser:    return "ferry.fill"
        case .vacationer: return "beach.umbrella.fill"
        case .longStay:   return "house.lodge.fill"
        case .expat:      return "house.fill"
        case .local:      return "mappin.and.ellipse"
        }
    }

    /// Suggested default interests for this traveler type.
    var defaultInterests: Set<Interest> {
        switch self {
        case .cruiser:    return [.eat, .beach, .snorkel]
        case .vacationer: return [.eat, .beach, .snorkel, .drink, .dive]
        case .longStay:   return [.eat, .wellness, .nature]
        case .expat:      return [.eat, .drink, .wellness]
        case .local:      return [.eat, .drink, .nightlife]
        }
    }
}

enum ExpatTenure: String, Codable, CaseIterable, Identifiable {
    case newArrival     // < 1 year
    case establishing   // 1-3 years
    case longtime       // 3+ years

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .newArrival:   return "Just moved here"
        case .establishing: return "Been here a while"
        case .longtime:     return "I know everyone"
        }
    }

    var subtitle: String {
        switch self {
        case .newArrival:   return "Less than a year"
        case .establishing: return "1 to 3 years"
        case .longtime:     return "More than 3 years"
        }
    }
}

enum Interest: String, Codable, CaseIterable, Identifiable, Hashable {
    case eat
    case drink
    case dive
    case snorkel
    case beach
    case nightlife
    case family
    case wellness
    case photography
    case history
    case nature
    case shopping

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .eat:         return "Food"
        case .drink:       return "Drinks & bars"
        case .dive:        return "Diving"
        case .snorkel:     return "Snorkeling"
        case .beach:       return "Beaches"
        case .nightlife:   return "Nightlife"
        case .family:      return "Family-friendly"
        case .wellness:    return "Wellness & spa"
        case .photography: return "Photography"
        case .history:     return "History & culture"
        case .nature:      return "Nature & wildlife"
        case .shopping:    return "Shopping"
        }
    }

    var iconName: String {
        switch self {
        case .eat:         return "fork.knife"
        case .drink:       return "wineglass"
        case .dive:        return "figure.pool.swim"
        case .snorkel:     return "water.waves"
        case .beach:       return "beach.umbrella"
        case .nightlife:   return "music.note"
        case .family:      return "figure.2.and.child.holdinghands"
        case .wellness:    return "leaf"
        case .photography: return "camera"
        case .history:     return "building.columns"
        case .nature:      return "bird"
        case .shopping:    return "bag"
        }
    }
}
