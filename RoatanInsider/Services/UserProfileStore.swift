import Foundation
import Observation

/// Persisted user profile observable. Lives in UserDefaults via Codable JSON
/// rather than SwiftData — the profile is a single small struct read constantly,
/// so the lighter store wins on every dimension.
@Observable
final class UserProfileStore {
    private static let key = "ri.userProfile.v1"

    var profile: UserProfile {
        didSet {
            if profile != oldValue { persist() }
        }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.profile = decoded
        } else {
            // First-ever launch on this device. Stamp the version so future
            // logic (grandfathering, "what's new" sheets) can rely on it.
            var fresh = UserProfile.empty
            fresh.firstLaunchDate = .now
            fresh.firstLaunchAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
            self.profile = fresh
            persist()
        }
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(profile)
            UserDefaults.standard.set(data, forKey: Self.key)
        } catch {
            AppLog.persistence.error("Failed to persist user profile: \(error.localizedDescription)")
        }
    }

    // MARK: - Convenience mutators

    func setTravelerType(_ type: TravelerType) {
        profile.travelerType = type
        if profile.interests.isEmpty {
            profile.interests = type.defaultInterests
        }
    }

    func setInterests(_ interests: Set<Interest>) {
        profile.interests = interests
    }

    func setTripDates(arrival: Date?, departure: Date?) {
        profile.arrivalDate = arrival
        profile.departureDate = departure
    }

    func markOnboardingComplete() {
        profile.hasCompletedOnboarding = true
    }
}
