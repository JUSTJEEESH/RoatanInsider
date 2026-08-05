import SwiftUI
import UserNotifications

/// Lets users edit everything they entered during onboarding (and a few
/// things they didn't): traveler type, trip dates, interests, units,
/// Insider+ status, notifications, and app metadata.
///
/// Reachable from the gear icon in the Tools tab. Designed as a single
/// scrollable Form so additions remain trivial.
struct SettingsView: View {
    @Environment(UserProfileStore.self) private var profileStore
    @Environment(TripPlanStore.self) private var tripStore
    @Environment(UnitPreference.self) private var unitPreference
    @Environment(PurchaseManager.self) private var purchases
    @Environment(\.dismiss) private var dismiss

    @State private var showPaywall = false
    @State private var notificationsAuthorized: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                membershipSection
                profileSection
                tripSection
                interestsSection
                preferencesSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .task { await refreshNotificationStatus() }
        }
    }

    // MARK: - Sections

    private var membershipSection: some View {
        Section {
            Button {
                Haptics.tap()
                showPaywall = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: purchases.hasPremium ? "checkmark.seal.fill" : "sparkles")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(purchases.hasPremium ? Color.riMint : Color.riPink)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(purchases.hasPremium ? "Insider+ member" : "Insider+")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.riDark)
                        Text(membershipSubtitle)
                            .font(.riCaption(12))
                            .foregroundStyle(Color.riLightGray)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.riLightGray)
                }
            }
        }
    }

    private var membershipSubtitle: String {
        if purchases.isGrandfathered { return "Thanks for being an early supporter — unlocked forever." }
        if purchases.hasPremium { return "All features unlocked. Manage in Settings → Apple ID." }
        return "AI trip planning, unlimited replans, and what's next."
    }

    private var profileSection: some View {
        Section {
            Picker("I'm here as", selection: Binding(
                get: { profileStore.profile.travelerType ?? .vacationer },
                set: { newValue in
                    profileStore.setTravelerType(newValue)
                }
            )) {
                ForEach(TravelerType.allCases) { type in
                    Label(type.displayName, systemImage: type.iconName).tag(type)
                }
            }
        } header: {
            Text("Profile")
        }
    }

    private var tripSection: some View {
        Section {
            DatePicker(
                "Arrival",
                selection: Binding(
                    get: { profileStore.profile.arrivalDate ?? .now },
                    set: { newValue in
                        profileStore.profile.arrivalDate = newValue
                        tripStore.sync(with: profileStore.profile)
                    }
                ),
                displayedComponents: .date
            )

            DatePicker(
                "Departure",
                selection: Binding(
                    get: { profileStore.profile.departureDate ?? Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now },
                    set: { newValue in
                        profileStore.profile.departureDate = newValue
                        tripStore.sync(with: profileStore.profile)
                    }
                ),
                in: (profileStore.profile.arrivalDate ?? .now)...,
                displayedComponents: .date
            )

            if profileStore.profile.arrivalDate != nil || profileStore.profile.departureDate != nil {
                Button(role: .destructive) {
                    profileStore.profile.arrivalDate = nil
                    profileStore.profile.departureDate = nil
                    tripStore.sync(with: profileStore.profile)
                } label: {
                    Label("Clear trip dates", systemImage: "calendar.badge.minus")
                }
            }
        } header: {
            Text("Trip dates")
        } footer: {
            Text("Used for the trip countdown, day-by-day itinerary, and cruise-day timing.")
        }
    }

    private var interestsSection: some View {
        Section {
            ForEach(Interest.allCases) { interest in
                let isOn = profileStore.profile.interests.contains(interest)
                Toggle(isOn: Binding(
                    get: { isOn },
                    set: { newValue in
                        var updated = profileStore.profile.interests
                        if newValue { updated.insert(interest) } else { updated.remove(interest) }
                        profileStore.setInterests(updated)
                    }
                )) {
                    Label(interest.displayName, systemImage: interest.iconName)
                }
            }
        } header: {
            Text("Interests")
        } footer: {
            Text("We use these to shape the home feed and your itinerary.")
        }
    }

    private var preferencesSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { unitPreference.useMetric },
                set: { unitPreference.useMetric = $0 }
            )) {
                Label("Use metric units", systemImage: "ruler")
            }

            HStack {
                Label("Notifications", systemImage: "bell")
                Spacer()
                Text(notificationsAuthorized ? "Allowed" : "Off")
                    .foregroundStyle(Color.riLightGray)
                if !notificationsAuthorized {
                    Button("Enable") {
                        Task { await enableNotifications() }
                    }
                    .font(.riCaption(13))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.riPink)
                }
            }
        } header: {
            Text("Preferences")
        }
    }

    private var aboutSection: some View {
        Section {
            Link(destination: URL(string: AppConstants.privacyURL)!) {
                HStack {
                    Label("Privacy", systemImage: "lock.shield")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(Color.riLightGray)
                }
            }
            // Was labelled "Terms" pointing at a terms page that doesn't
            // exist. Labelled for what's actually there.
            Link(destination: URL(string: AppConstants.supportURL)!) {
                HStack {
                    Label("Support", systemImage: "lifepreserver")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(Color.riLightGray)
                }
            }
            Link(destination: URL(string: "mailto:\(AppConstants.supportEmail)?subject=App%20feedback")!) {
                Label("Send feedback", systemImage: "envelope")
            }
            // Moved off the Home tab, which is built for visitors — an owner
            // looking to get listed comes to Settings for it.
            Link(destination: URL(string: "https://facebook.com/roataninsiderapp")!) {
                HStack {
                    Label("List your business", systemImage: "storefront")
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(Color.riLightGray)
                }
            }
            HStack {
                Label("Version", systemImage: "info.circle")
                Spacer()
                Text(appVersion)
                    .foregroundStyle(Color.riLightGray)
                    .monospacedDigit()
            }
        } header: {
            Text("About")
        }
    }

    // MARK: - Helpers

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(v) (\(b))"
    }

    private func refreshNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            notificationsAuthorized = settings.authorizationStatus == .authorized ||
                                      settings.authorizationStatus == .provisional
        }
    }

    private func enableNotifications() async {
        let granted = await NotificationManager.shared.requestAuthorizationIfNeeded()
        notificationsAuthorized = granted
        await NotificationManager.shared.scheduleAll(profile: profileStore.profile)
    }
}
