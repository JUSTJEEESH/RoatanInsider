import SwiftUI
import CoreLocation
import UserNotifications

/// Onboarding 3.0 — branched, context-aware, with a real personalization
/// payoff at the end. Seven steps, each tailored:
///
///   1. Welcome — live conditions tease so the app shows it knows Roatán
///   2. Traveler type — universal
///   3. Context — branches by type (cruise port + boarding, dates + stay,
///      home area + tenure, home area + contribute)
///   4. Interests — universal, pre-seeded with traveler-type defaults
///   5. Preview — three businesses tailored to the answers; tap to save
///   6. Permissions — two rows but framed in the user's language
///   7. Ready — personalized trip card, not a generic "all set"
///
/// Skips are still allowed everywhere except welcome + ready. Every
/// collected field powers a downstream feature so the work the user
/// puts in pays off immediately on Home.
struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @Environment(UserProfileStore.self) private var profileStore
    @Environment(LocationManager.self) private var locationManager
    @Environment(WeatherService.self) private var weatherService
    @Environment(DataManager.self) private var dataManager
    @Environment(FavoritesStore.self) private var favoritesStore

    @State private var step: Step = .welcome

    // Draft state — committed to UserProfile on advance().
    @State private var draftFirstName: String = ""
    @State private var draftType: TravelerType?
    @State private var draftArrival: Date?
    @State private var draftDeparture: Date?
    @State private var hasDates: Bool = false
    @State private var draftInterests: Set<Interest> = []
    @State private var draftStayArea: Area?
    @State private var draftCruisePort: CruiseViewModel.CruisePort = .mahoganyBay
    @State private var draftBoardingTime: Date = Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: .now) ?? .now
    @State private var draftExpatTenure: ExpatTenure?
    @State private var draftContributes: Bool = false
    @State private var draftHeartedIds: Set<String> = []

    var body: some View {
        ZStack {
            Color.riNearBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                progressBar
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                bottomControls
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.25), value: step)
    }

    // MARK: - Progress

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(Step.allCases) { s in
                Capsule()
                    .fill(s.rawValue <= step.rawValue ? Color.riPink : Color.white.opacity(0.15))
                    .frame(height: 4)
            }
        }
    }

    // MARK: - Step routing

    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome:       welcomeStep
        case .name:          nameStep
        case .travelerType:  travelerTypeStep
        case .context:       contextStep
        case .interests:     interestsStep
        case .preview:       previewStep
        case .permissions:   permissionsStep
        case .ready:         readyStep
        }
    }

    // MARK: - Welcome (with live conditions tease)

    private var welcomeStep: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "palm.tree.fill")
                .font(.system(size: 60, weight: .light))
                .foregroundStyle(Color.riMint)

            VStack(spacing: 12) {
                Text("Welcome to\nRoatán Insider")
                    .riDisplayStyle(34)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Roatán, by the people who live here.")
                    .font(.riBody)
                    .foregroundStyle(Color.riLightGray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 24)
            }

            liveTease

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    /// Three real-time data points from WeatherService + SunsetCalculator.
    /// Sets the tone: the app is alive and knows the island right now.
    private var liveTease: some View {
        HStack(spacing: 10) {
            let horizon = SunsetCalculator.nextHorizonEvent()
            liveTeaseChip(icon: "thermometer.medium", value: weatherService.temperatureLabel + "F")
            liveTeaseChip(icon: horizon.symbol, value: horizon.timeString)
            liveTeaseChip(icon: "water.waves", value: weatherService.snorkelLabel)
        }
        .padding(.horizontal, 24)
        .opacity(weatherService.conditions == nil ? 0 : 1)
        .animation(.easeInOut(duration: 0.6), value: weatherService.conditions != nil)
        .task {
            if weatherService.conditions == nil {
                await weatherService.refreshIfNeeded()
            }
        }
    }

    private func liveTeaseChip(icon: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 11, weight: .semibold))
            Text(value)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.08))
        .clipShape(Capsule())
    }

    // MARK: - Name

    @FocusState private var nameFieldFocused: Bool

    private var nameStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            stepHeader(
                title: "What can we call you?",
                subtitle: "So we can say hi when you open the app."
            )

            TextField("", text: $draftFirstName, prompt: Text("First name").foregroundStyle(Color.riLightGray))
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled(true)
                .submitLabel(.done)
                .focused($nameFieldFocused)
                .onSubmit { advance() }
                .padding(.horizontal, 16)
                .frame(height: 56)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        nameFieldFocused = true
                    }
                }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Traveler type

    private var travelerTypeStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            stepHeader(
                title: "How are you visiting?",
                subtitle: "We'll shape the whole app around your answer."
            )

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(TravelerType.allCases) { type in
                        travelerOption(type)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
    }

    private func travelerOption(_ type: TravelerType) -> some View {
        let isSelected = draftType == type
        return Button {
            Haptics.select()
            draftType = type
            // Pre-seed interest defaults so the Interests step is one
            // glance instead of a chore. User can still customise.
            if draftInterests.isEmpty {
                draftInterests = type.defaultInterests
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: type.iconName)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(isSelected ? .white : Color.riMint)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(type.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(type.subtitle)
                        .font(.riCaption(13))
                        .foregroundStyle(Color.riLightGray)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(Color.riPink)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.riPink.opacity(0.18) : Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.riPink : Color.white.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Context (branches by traveler type)

    @ViewBuilder
    private var contextStep: some View {
        switch draftType {
        case .cruiser:                            cruiserContext
        case .vacationer, .longStay:              tripContext
        case .expat:                              expatContext
        case .local:                              localContext
        case nil:                                 tripContext // shouldn't reach
        }
    }

    private var cruiserContext: some View {
        VStack(alignment: .leading, spacing: 24) {
            stepHeader(
                title: "Your cruise day",
                subtitle: "Countdown to boarding, with everything sorted by distance to your ship."
            )

            VStack(alignment: .leading, spacing: 12) {
                fieldLabel("Port")
                cruisePortPicker

                fieldLabel("All aboard by")
                    .padding(.top, 6)
                DatePicker("", selection: $draftBoardingTime, displayedComponents: [.hourAndMinute])
                    .labelsHidden()
                    .colorScheme(.dark)
                    .tint(Color.riPink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var cruisePortPicker: some View {
        VStack(spacing: 8) {
            ForEach(CruiseViewModel.CruisePort.allCases) { port in
                Button {
                    Haptics.select()
                    draftCruisePort = port
                } label: {
                    HStack {
                        Image(systemName: "ferry.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(draftCruisePort == port ? .white : Color.riMint)
                        Text(port.displayName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                        Spacer()
                        if draftCruisePort == port {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.riPink)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(draftCruisePort == port ? Color.riPink.opacity(0.18) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(draftCruisePort == port ? Color.riPink : Color.clear, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var tripContext: some View {
        VStack(alignment: .leading, spacing: 22) {
            stepHeader(
                title: "Your trip",
                subtitle: tripContextSubtitle
            )

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Toggle(isOn: $hasDates.animation()) {
                        Text("I know my dates")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .tint(Color.riPink)

                    if hasDates {
                        VStack(spacing: 12) {
                            datePickerRow(label: "Arrival", date: Binding(
                                get: { draftArrival ?? .now },
                                set: { draftArrival = $0 }
                            ))
                            datePickerRow(label: "Departure", date: Binding(
                                get: { draftDeparture ?? Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now },
                                set: { draftDeparture = $0 }
                            ))

                            if let days = arrivalDaysFromNow(), days > 0 {
                                Text("\(days) days from today")
                                    .font(.riCaption(12))
                                    .foregroundStyle(Color.riMint)
                                    .padding(.top, 2)
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    Divider().background(Color.white.opacity(0.1)).padding(.vertical, 4)

                    fieldLabel("Where are you staying?")
                    areaPicker
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
    }

    private var tripContextSubtitle: String {
        if draftType == .longStay {
            return "We'll tune recommendations for longer-term living — wifi, weekly events, local prices."
        }
        return "Dates power your countdown. Stay area shapes every recommendation."
    }

    private var expatContext: some View {
        VStack(alignment: .leading, spacing: 22) {
            stepHeader(
                title: "Your home",
                subtitle: "New arrivals get essentials. Longtime residents get what's new."
            )

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    fieldLabel("Which area do you live in?")
                    areaPicker

                    fieldLabel("How long have you been here?")
                        .padding(.top, 8)
                    VStack(spacing: 8) {
                        ForEach(ExpatTenure.allCases) { tenure in
                            tenureRow(tenure)
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
    }

    private func tenureRow(_ tenure: ExpatTenure) -> some View {
        let isSelected = draftExpatTenure == tenure
        return Button {
            Haptics.select()
            draftExpatTenure = tenure
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(tenure.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(tenure.subtitle)
                        .font(.riCaption(12))
                        .foregroundStyle(Color.riLightGray)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.riPink)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(isSelected ? Color.riPink.opacity(0.18) : Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.riPink : Color.clear, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var localContext: some View {
        VStack(alignment: .leading, spacing: 22) {
            stepHeader(
                title: "Where in Roatán?",
                subtitle: "We're building this with locals. Your knowledge makes it real."
            )

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    fieldLabel("Your area")
                    areaPicker

                    Toggle(isOn: $draftContributes) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("I want to share what I know")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                            Text("We'll let you flag corrections and add new spots.")
                                .font(.riCaption(12))
                                .foregroundStyle(Color.riLightGray)
                        }
                    }
                    .tint(Color.riPink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Shared context bits

    private func datePickerRow(label: String, date: Binding<Date>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.riLightGray)
            Spacer()
            DatePicker("", selection: date, displayedComponents: .date)
                .labelsHidden()
                .colorScheme(.dark)
                .tint(Color.riPink)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var areaPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Area.allCases) { area in
                    areaChip(area)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func areaChip(_ area: Area) -> some View {
        let isSelected = draftStayArea == area
        return Button {
            Haptics.select()
            draftStayArea = area
        } label: {
            Text(area.displayName)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? .white : Color.riLightGray)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(isSelected ? Color.riPink : Color.white.opacity(0.07))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .tracking(0.5)
            .foregroundStyle(Color.riMint)
    }

    // MARK: - Interests

    private var interestsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                title: "What are you into?",
                subtitle: "We'll lean into these. We've pre-selected some — tweak as you like."
            )

            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(Interest.allCases) { interest in
                        interestChip(interest)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
    }

    private func interestChip(_ interest: Interest) -> some View {
        let isSelected = draftInterests.contains(interest)
        return Button {
            Haptics.select()
            if isSelected { draftInterests.remove(interest) } else { draftInterests.insert(interest) }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: interest.iconName)
                    .font(.system(size: 18, weight: .medium))
                Text(interest.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Spacer(minLength: 0)
            }
            .foregroundStyle(isSelected ? .white : Color.riLightGray)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.riPink : Color.white.opacity(0.06))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.riPink : Color.white.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Preview (the value-delivery moment)

    private var previewStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                title: "Three places to start",
                subtitle: "Picked just for you. Tap the heart to save."
            )

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    ForEach(previewBusinesses) { business in
                        previewCard(business)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
    }

    /// Generates 3 personalised picks based on draft interests + traveler type.
    /// Uses the same candidate ranker that powers the itinerary generator, then
    /// dedups by category so the user sees variety (1 food, 1 activity/beach,
    /// 1 sunset/drink) rather than three restaurants.
    private var previewBusinesses: [Business] {
        let input = TripItineraryGenerator.Input(
            plan: TripPlan(arrivalDate: .now, departureDate: .now, itemsByDate: [:], lastGenerated: nil, lastRationale: nil),
            profile: previewProfile,
            allBusinesses: dataManager.activeBusinesses,
            favoriteIds: []
        )
        let ranked = TripItineraryGenerator.rankedCandidates(for: input, limit: 30)

        // Pick one per top-level category for visual diversity.
        var picks: [Business] = []
        var seenCategories: Set<String> = []
        for biz in ranked where picks.count < 3 {
            if !seenCategories.contains(biz.category) {
                picks.append(biz)
                seenCategories.insert(biz.category)
            }
        }
        // Fill any remaining slots regardless of category overlap.
        for biz in ranked where picks.count < 3 && !picks.contains(where: { $0.id == biz.id }) {
            picks.append(biz)
        }
        return picks
    }

    /// Synthesises a temporary profile so the ranker sees what the user has
    /// drafted, even though they haven't committed yet.
    private var previewProfile: UserProfile {
        var p = profileStore.profile
        p.travelerType = draftType
        p.interests = draftInterests
        p.stayArea = draftStayArea
        return p
    }

    private func previewCard(_ business: Business) -> some View {
        let isHearted = draftHeartedIds.contains(business.id)
        return HStack(spacing: 12) {
            BusinessImageView(business: business)
                .frame(width: 84, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(business.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Text(business.areaDisplayName + " · " + business.categoryDisplayName)
                    .font(.riCaption(12))
                    .foregroundStyle(Color.riLightGray)
                if let tip = business.insiderTip, !tip.isEmpty {
                    Text(tip)
                        .font(.riCaption(12))
                        .foregroundStyle(Color.riMint)
                        .italic()
                        .lineLimit(2)
                        .padding(.top, 2)
                }
            }

            Spacer(minLength: 0)

            Button {
                Haptics.tap()
                if isHearted {
                    draftHeartedIds.remove(business.id)
                } else {
                    draftHeartedIds.insert(business.id)
                }
            } label: {
                Image(systemName: isHearted ? "heart.fill" : "heart")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isHearted ? Color.riPink : Color.white.opacity(0.4))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Permissions (contextual copy)

    private var permissionsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                title: permissionsTitle,
                subtitle: permissionsSubtitle
            )

            permissionRow(
                icon: "location.fill",
                title: "Use your location",
                detail: locationCopy
            ) {
                locationManager.requestPermission()
                profileStore.profile.hasGrantedLocation = true
            }

            permissionRow(
                icon: "bell.badge.fill",
                title: notificationsTitle,
                detail: notificationsCopy
            ) {
                Task {
                    let granted = (try? await UNUserNotificationCenter.current()
                        .requestAuthorization(options: [.alert, .sound, .badge])) ?? false
                    await MainActor.run {
                        profileStore.profile.hasGrantedNotifications = granted
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var permissionsTitle: String {
        draftType == .cruiser ? "Two ways we help on cruise day" : "Two quick permissions"
    }
    private var permissionsSubtitle: String {
        "Both are optional. The app works fully without either."
    }
    private var locationCopy: String {
        switch draftType {
        case .cruiser: return "Show what's walking-distance from your port and sort by distance to the ship."
        case .local, .expat: return "Surface what's open right now near you."
        default: return "Show what's near you and walking directions to anywhere you save."
        }
    }
    private var notificationsTitle: String {
        switch draftType {
        case .cruiser: return "Lock-screen countdown + reminders"
        default: return "Sunset & happy-hour alerts"
        }
    }
    private var notificationsCopy: String {
        switch draftType {
        case .cruiser: return "A countdown on your lock screen so you don't miss the ship."
        default: return "Optional reminders for sunset, live music, and places you've saved. Once a week, max."
        }
    }

    private func permissionRow(icon: String, title: String, detail: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.impact()
            action()
        } label: {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(Color.riMint)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(detail)
                        .font(.riCaption(13))
                        .foregroundStyle(Color.riLightGray)
                        .lineSpacing(3)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
            }
            .padding(16)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Ready (trip card)

    private var readyStep: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    Image(systemName: draftType?.iconName ?? "sparkles")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(Color.riPink)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(tripCardLine1)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                        if let line2 = tripCardLine2 {
                            Text(line2)
                                .font(.riCaption(13))
                                .foregroundStyle(Color.riLightGray)
                        }
                    }
                    Spacer(minLength: 0)
                }

                if !draftInterests.isEmpty {
                    HStack(spacing: 10) {
                        ForEach(Array(draftInterests.prefix(5))) { interest in
                            HStack(spacing: 5) {
                                Image(systemName: interest.iconName)
                                    .font(.system(size: 10, weight: .semibold))
                                Text(interest.displayName)
                                    .font(.system(size: 11, weight: .semibold))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(Color.riMint)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.riMint.opacity(0.12))
                            .clipShape(Capsule())
                        }
                    }
                }

                if !draftHeartedIds.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.riPink)
                        Text("\(draftHeartedIds.count) saved place\(draftHeartedIds.count == 1 ? "" : "s") waiting for you")
                            .font(.riCaption(13))
                            .foregroundStyle(Color.riLightGray)
                    }
                }
            }
            .padding(20)
            .background(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))

            Text(readyFooter)
                .font(.riBody)
                .foregroundStyle(Color.riLightGray)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 24)

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var tripCardLine1: String {
        switch draftType {
        case .cruiser:
            return "Cruise day · \(draftCruisePort.displayName)"
        case .vacationer, .longStay:
            if let area = draftStayArea {
                if let days = arrivalDaysFromNow(), days > 0 {
                    return "\(days) days · \(area.displayName)"
                }
                return area.displayName
            }
            if let days = arrivalDaysFromNow(), days > 0 {
                return "\(days) days to Roatán"
            }
            return "Your Roatán trip"
        case .expat:
            return draftStayArea?.displayName ?? "Roatán resident"
        case .local:
            return draftStayArea?.displayName ?? "Roatán local"
        case nil:
            return "Welcome to Roatán"
        }
    }

    private var tripCardLine2: String? {
        switch draftType {
        case .cruiser:
            let f = DateFormatter()
            f.dateFormat = "h:mm a"
            return "All aboard by \(f.string(from: draftBoardingTime))"
        case .vacationer, .longStay:
            return draftType?.displayName
        case .expat:
            if let tenure = draftExpatTenure { return tenure.displayName }
            return "Living on the island"
        case .local:
            return draftContributes ? "Contributing local" : "Local"
        case nil:
            return nil
        }
    }

    private var readyFooter: String {
        switch draftType {
        case .cruiser:
            return "Cruise mode kicks in the moment you open the app. Your countdown stays on the lock screen all day."
        case .vacationer, .longStay:
            if let days = arrivalDaysFromNow(), days > 0 {
                return "In \(days) days you're on Roatán. We'll sharpen the picks as you get closer."
            }
            return "Pull down on Home for the freshest picks."
        case .expat:
            return "Home is tuned for new openings and what's happening this week. No tourist circuit."
        case .local:
            return "Welcome home. Tap any spot to tell us what's off."
        case nil:
            return "Pull down on Home to see what's open right now."
        }
    }

    // MARK: - Helpers

    private func arrivalDaysFromNow() -> Int? {
        guard let arrival = draftArrival else { return nil }
        return Calendar.current.dateComponents([.day], from: .now, to: arrival).day
    }

    private func stepHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .riDisplayStyle(28)
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.riBody)
                .foregroundStyle(Color.riLightGray)
                .lineSpacing(4)
        }
        .padding(.top, 36)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Bottom controls

    private var bottomControls: some View {
        VStack(spacing: 14) {
            Button {
                Haptics.impact()
                advance()
            } label: {
                Text(primaryButtonLabel)
                    .font(.riButton)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppConstants.buttonHeight)
                    .background(Color.riPink)
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.buttonCornerRadius))
            }
            .disabled(!canAdvance)
            .opacity(canAdvance ? 1 : 0.4)

            if step.allowsSkip {
                Button {
                    Haptics.tap()
                    advance(skip: true)
                } label: {
                    Text("Skip")
                        .font(.riCaption(15))
                        .fontWeight(.medium)
                        .foregroundStyle(Color.riLightGray)
                }
            }
        }
    }

    private var primaryButtonLabel: String {
        switch step {
        case .welcome:       return "Get started"
        case .name:          return "Continue"
        case .travelerType:  return "Continue"
        case .context:       return "Continue"
        case .interests:     return "Continue"
        case .preview:       return draftHeartedIds.isEmpty ? "Continue" : "Save \(draftHeartedIds.count) — continue"
        case .permissions:   return "Continue"
        case .ready:         return "Show me Roatán"
        }
    }

    private var canAdvance: Bool {
        switch step {
        case .welcome, .name, .preview, .permissions, .ready: return true
        case .travelerType: return draftType != nil
        case .context:
            // Each branch has its own minimum-info bar:
            switch draftType {
            case .cruiser:               return true // port + boarding time always have defaults
            case .vacationer, .longStay: return true // dates + stay area both optional
            case .expat:                 return true // tenure + area both optional
            case .local:                 return true // area + contribute both optional
            case nil:                    return false
            }
        case .interests: return !draftInterests.isEmpty
        }
    }

    // MARK: - Step advancement

    private func advance(skip: Bool = false) {
        // Persist whatever we've gathered at this step.
        switch step {
        case .name:
            if !skip { profileStore.setFirstName(draftFirstName) }
            nameFieldFocused = false
        case .travelerType:
            if let t = draftType { profileStore.setTravelerType(t) }
        case .context:
            switch draftType {
            case .cruiser:
                profileStore.setCruiseContext(portRawValue: draftCruisePort.rawValue, boardingTime: draftBoardingTime)
            case .vacationer, .longStay:
                if hasDates {
                    profileStore.setTripDates(arrival: draftArrival, departure: draftDeparture)
                }
                profileStore.setStayArea(draftStayArea)
            case .expat:
                profileStore.setStayArea(draftStayArea)
                profileStore.setExpatTenure(draftExpatTenure)
            case .local:
                profileStore.setStayArea(draftStayArea)
                profileStore.setContributesContent(draftContributes)
            case nil:
                break
            }
        case .interests:
            if !skip { profileStore.setInterests(draftInterests) }
        case .preview:
            if !skip {
                for id in draftHeartedIds {
                    favoritesStore.addFavorite(id)
                }
                Analytics.track(.toolUsed(name: "onboarding_hearted_\(draftHeartedIds.count)"))
            }
        default:
            break
        }

        if let next = step.next() {
            step = next
        } else {
            profileStore.markOnboardingComplete()
            Analytics.track(.toolUsed(name: "onboarding_completed_\(draftType?.rawValue ?? "unknown")"))
            withAnimation(.easeInOut(duration: 0.3)) {
                hasCompletedOnboarding = true
            }
        }
    }
}

// MARK: - Steps

extension OnboardingView {
    enum Step: Int, CaseIterable, Identifiable {
        case welcome
        case name
        case travelerType
        case context
        case interests
        case preview
        case permissions
        case ready

        var id: Int { rawValue }

        var allowsSkip: Bool {
            switch self {
            case .welcome, .ready: return false
            default: return true
            }
        }

        func next() -> Step? {
            Step(rawValue: rawValue + 1)
        }
    }
}
