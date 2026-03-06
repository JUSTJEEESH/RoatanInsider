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
                    }

                    Text(context.headline)
                        .riHeadlineStyle(24)
                        .foregroundStyle(Color.riDark)

                    Text(context.subheadline)
                        .font(.riBody)
                        .foregroundStyle(Color.riMediumGray)
                }
                .padding(.horizontal, 20)

                // Horizontal scroll of recommended businesses
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(recommended.prefix(8)) { business in
                            BusinessCardCompact(business: business)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    private var recommendedBusinesses: [Business] {
        let active = businesses.filter { $0.isActive }
        let open = active.filter { $0.isOpenNow() }
        let pool = open.isEmpty ? active : open

        let filtered = pool.filter { business in
            context.categories.contains(business.category)
        }

        return filtered.isEmpty ? Array(pool.prefix(8)) : Array(filtered.shuffled().prefix(8))
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

    var categories: [Category] {
        switch self {
        case .earlyMorning: return [.eat, .dive, .tours, .beaches]
        case .morning:      return [.dive, .tours, .beaches, .eat]
        case .lunchtime:    return [.eat, .drink, .beaches]
        case .afternoon:    return [.beaches, .shop, .tours, .dive, .drink]
        case .goldenHour:   return [.drink, .eat, .beaches]
        case .evening:      return [.eat, .drink, .nightlife]
        case .lateNight:    return [.nightlife, .drink]
        }
    }
}
