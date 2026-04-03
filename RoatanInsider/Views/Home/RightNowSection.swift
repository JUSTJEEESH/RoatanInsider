import SwiftUI

struct RightNowSection: View {
    let businesses: [Business]
    private let context = TimeContext.current

    var body: some View {
        let recommended = recommendedBusinesses
        if !recommended.isEmpty {
            VStack(alignment: .leading, spacing: 20) {
                // Contextual header
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: context.icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.riMint)

                        Text("RIGHT NOW")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.riMint)
                            .tracking(1.5)

                        Spacer()

                        // Sunset countdown
                        if let countdown = SunsetCalculator.sunsetCountdown() {
                            HStack(spacing: 4) {
                                Image(systemName: "sunset.fill")
                                    .font(.system(size: 12, weight: .medium))
                                Text("Sunset \(countdown)")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundStyle(Color.riMediumGray)
                            .accessibilityLabel("Sunset in \(countdown)")
                        }
                    }

                    Text(context.headline)
                        .riHeadlineStyle(24)
                        .foregroundStyle(Color.riDark)
                        .accessibilityAddTraits(.isHeader)

                    Text(context.subheadline)
                        .font(.riBody)
                        .foregroundStyle(Color.riMediumGray)
                }
                .padding(.horizontal, 20)

                // Horizontal scroll of recommended businesses
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(recommended.prefix(8)) { business in
                            BusinessCardCompact(business: business, darkStyle: true)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    private var recommendedBusinesses: [Business] {
        let active = businesses.filter { $0.isActive }

        // Tourist-heavy areas
        let touristAreas: Set<String> = ["west_bay", "west_end", "sandy_bay", "coxen_hole", "dixon_cove"]

        // Categories that should NEVER appear in Right Now (not activity-based)
        let excludedCategories = context.excludedCategories

        // West-facing sunset areas
        let sunsetAreas: Set<String> = ["west_bay", "west_end", "sandy_bay"]
        let sunsetFeatures: Set<String> = ["Sunset Views", "Waterfront", "Ocean View", "Beachfront"]

        let scored = active.compactMap { business -> (Business, Double)? in
            // Hard exclude categories that don't belong in "what to do right now"
            if excludedCategories.contains(business.category) { return nil }

            var score: Double = 0

            // --- OPEN/CLOSED (most important) ---
            let hasHoursData = !business.hours.isEmpty && business.hours.values.contains(where: { $0 != nil })
            if business.isOpenNow() {
                score += 50
            } else if hasHoursData {
                return nil // Confirmed closed — exclude entirely
            } else {
                score -= 20 // Unknown hours — penalize but don't exclude
            }

            // --- CATEGORY RELEVANCE (very important) ---
            let matchingCategory = context.categoryIds.contains(business.category)
            if matchingCategory {
                score += 30 // Strong boost for right category at right time
            } else {
                score -= 15 // Wrong category for this time — penalize
            }

            // --- TIME-SPECIFIC BONUSES ---
            switch context {
            case .goldenHour:
                // Sunset time: heavily prefer west-facing waterfront spots
                if sunsetAreas.contains(business.area) {
                    score += 15
                }
                if !sunsetFeatures.isDisjoint(with: Set(business.features)) {
                    score += 20
                }
                // Bars and restaurants with views are ideal
                if business.category == "drink" { score += 10 }

            case .earlyMorning:
                // Coffee shops, bakeries, dive shops prepping
                if business.features.contains("Coffee") || business.features.contains("Breakfast") {
                    score += 20
                }
                if business.category == "dive" { score += 10 }

            case .morning:
                // Dive, tours, active stuff
                if business.category == "dive" || business.category == "tours" {
                    score += 15
                }

            case .lunchtime:
                // Restaurants are king
                if business.category == "eat" { score += 15 }
                if business.features.contains("Lunch") { score += 10 }

            case .afternoon:
                // Beaches, snorkeling, shopping, frozen drinks
                if business.category == "beaches" { score += 15 }
                if business.category == "shop" { score += 5 }

            case .evening:
                // Dinner restaurants, live music, bars
                if business.category == "eat" { score += 15 }
                if business.features.contains("Live Music") { score += 15 }
                if business.category == "nightlife" { score += 10 }
                if business.features.contains("Dinner") || business.features.contains("Date Night") {
                    score += 10
                }

            case .lateNight:
                // Bars and nightlife only
                if business.category == "nightlife" { score += 20 }
                if business.category == "drink" { score += 15 }
                if business.features.contains("Late Night") { score += 10 }
            }

            // --- LOCATION ---
            if touristAreas.contains(business.area) {
                score += 15
            }

            // --- QUALITY SIGNALS ---
            if business.isFeatured { score += 12 }
            if business.isInsiderPick { score += 8 }
            if let rating = business.rating { score += rating }
            if let reviews = business.reviewCount, reviews > 50 { score += 3 }

            // Has a real photo (looks better in the card)
            if let img = business.images.first, img != "business_placeholder" {
                score += 3
            }

            return (business, score)
        }

        return scored
            .sorted { $0.1 > $1.1 }
            .prefix(8)
            .map { $0.0 }
    }
}

// MARK: - Time Context

enum TimeContext {
    case earlyMorning   // 5-8am
    case morning        // 8-11am
    case lunchtime      // 11am-2pm
    case afternoon      // 2-5pm
    case goldenHour     // 5-7pm
    case evening        // 7-10pm
    case lateNight      // 10pm-5am

    static var current: TimeContext {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<8:     return .earlyMorning
        case 8..<11:    return .morning
        case 11..<14:   return .lunchtime
        case 14..<17:   return .afternoon
        case 17..<19:   return .goldenHour
        case 19..<22:   return .evening
        default:        return .lateNight
        }
    }

    var headline: String {
        switch self {
        case .earlyMorning: return "Early bird? Good call."
        case .morning:      return "Perfect morning for an adventure."
        case .lunchtime:    return "Time to eat — here's where locals go."
        case .afternoon:    return "Beat the heat. Here's what's open."
        case .goldenHour:   return "Golden hour. Don't miss the sunset."
        case .evening:      return "The island comes alive at night."
        case .lateNight:    return "Still up? So are these spots."
        }
    }

    var subheadline: String {
        switch self {
        case .earlyMorning: return "Coffee, sunrise walks, and early dives before the crowds."
        case .morning:      return "Dive boats are heading out and the reef is calling."
        case .lunchtime:    return "Fresh catch, baleadas, and cold beers right now."
        case .afternoon:    return "Snorkel, shop, or grab a frozen drink and chill."
        case .goldenHour:   return "Grab a seat facing west. Sundowner time."
        case .evening:      return "Dinner, live music, and island nightlife."
        case .lateNight:    return "Late-night bars and beachside vibes."
        }
    }

    var icon: String {
        switch self {
        case .earlyMorning: return "sunrise"
        case .morning:      return "sun.and.horizon"
        case .lunchtime:    return "fork.knife"
        case .afternoon:    return "sun.max"
        case .goldenHour:   return "sunset"
        case .evening:      return "moon.stars"
        case .lateNight:    return "sparkles"
        }
    }

    var categoryIds: [String] {
        switch self {
        case .earlyMorning: return ["eat", "dive", "tours", "beaches"]
        case .morning:      return ["dive", "tours", "beaches", "eat"]
        case .lunchtime:    return ["eat", "drink", "beaches"]
        case .afternoon:    return ["beaches", "shop", "tours", "dive", "drink"]
        case .goldenHour:   return ["drink", "eat", "beaches"]
        case .evening:      return ["eat", "drink", "nightlife"]
        case .lateNight:    return ["nightlife", "drink"]
        }
    }

    /// Categories that should NEVER appear for this time slot
    var excludedCategories: Set<String> {
        // These never make sense in "Right Now" regardless of time
        let always: Set<String> = ["stay", "real_estate", "health", "services", "transport", "rentals"]

        switch self {
        case .earlyMorning:
            // Sunrise: no nightlife, bars, shopping, events, fitness, marina, photography
            return always.union(["nightlife", "drink", "shop", "events", "fitness", "marina", "photography", "groceries", "family"])
        case .morning:
            // Morning: no nightlife, late-night stuff
            return always.union(["nightlife"])
        case .lunchtime:
            // Lunchtime: no nightlife, dive (they're already out)
            return always.union(["nightlife"])
        case .afternoon:
            // Afternoon: no nightlife
            return always.union(["nightlife"])
        case .goldenHour:
            // Sunset: focused on drinks, food, views — no dive, tours, shopping
            return always.union(["dive", "tours", "shop", "groceries", "fitness", "marina", "photography", "family"])
        case .evening:
            // Dinner/nightlife: no dive, tours, beaches, shopping
            return always.union(["dive", "tours", "beaches", "shop", "groceries", "fitness", "marina", "photography"])
        case .lateNight:
            // Late night: only bars and nightlife — exclude everything else
            return always.union(["eat", "dive", "tours", "beaches", "shop", "groceries", "fitness", "marina", "photography", "events", "family", "wellness"])
        }
    }
}
