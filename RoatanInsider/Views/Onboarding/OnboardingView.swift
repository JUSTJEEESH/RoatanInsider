import SwiftUI
import CoreLocation
import UserNotifications

/// Personalised onboarding flow. Six steps, each one optional except the
/// welcome screen. The skip path collects nothing but still marks onboarding
/// complete so the user isn't blocked. Every collected field powers a
/// downstream feature: traveler type tunes RightNow + Home, dates drive
/// countdown widgets + reminders, interests rank Featured + Insider Picks,
/// permissions unlock map + push.
struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @Environment(UserProfileStore.self) private var profileStore
    @Environment(LocationManager.self) private var locationManager

    @State private var step: Step = .welcome
    @State private var draftType: TravelerType?
    @State private var draftArrival: Date?
    @State private var draftDeparture: Date?
    @State private var hasDates: Bool = false
    @State private var draftInterests: Set<Interest> = []

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

    // MARK: - Step content

    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome:       welcomeStep
        case .travelerType:  travelerTypeStep
        case .dates:         datesStep
        case .interests:     interestsStep
        case .permissions:   permissionsStep
        case .ready:         readyStep
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "palm.tree.fill")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(Color.riMint)

            VStack(spacing: 12) {
                Text("Welcome to\nRoatán Insider")
                    .riDisplayStyle(34)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("The only guide you need for Honduras's most beautiful island — curated by people who actually live here.")
                    .font(.riBody)
                    .foregroundStyle(Color.riLightGray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 24)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var travelerTypeStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            stepHeader(
                title: "How are you visiting?",
                subtitle: "We'll tune the app to fit your trip."
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

    private var datesStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                title: "When are you here?",
                subtitle: "We'll surface a countdown, cruise-day timing, and reminders for what to do each day."
            )

            Toggle(isOn: $hasDates.animation()) {
                Text("I know my dates")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .tint(Color.riPink)

            if hasDates {
                VStack(spacing: 14) {
                    datePickerRow(label: "Arrival", date: Binding(
                        get: { draftArrival ?? .now },
                        set: { draftArrival = $0 }
                    ))
                    datePickerRow(label: "Departure", date: Binding(
                        get: { draftDeparture ?? Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now },
                        set: { draftDeparture = $0 }
                    ))
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

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

    private var interestsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                title: "What are you into?",
                subtitle: "Pick a few. We'll prioritise these across the app."
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
        .onAppear {
            if draftInterests.isEmpty, let defaults = draftType?.defaultInterests {
                draftInterests = defaults
            }
        }
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

    private var permissionsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(
                title: "Two quick permissions",
                subtitle: "Both are optional. The app works fully without either."
            )

            permissionRow(
                icon: "location.fill",
                title: "Use your location",
                detail: "Show what's near you, sort the directory by distance, and walking directions."
            ) {
                locationManager.requestPermission()
                profileStore.profile.hasGrantedLocation = true
            }

            permissionRow(
                icon: "bell.badge.fill",
                title: "Sunset & happy-hour alerts",
                detail: "Optional reminders for sunset, live music, and places you've saved. Once a week, max."
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

    private var readyStep: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 60, weight: .light))
                .foregroundStyle(Color.riMint)

            VStack(spacing: 12) {
                Text("You're all set.")
                    .riDisplayStyle(34)
                    .foregroundStyle(.white)

                Text(readySubtitle)
                    .font(.riBody)
                    .foregroundStyle(Color.riLightGray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 24)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var readySubtitle: String {
        if let type = draftType {
            switch type {
            case .cruiser:
                return "We've put cruise-day timing at the top. Tap the Ferry banner when you're ready."
            case .vacationer, .longStay, .expat:
                if let days = arrivalDaysFromNow(), days > 0 {
                    return "\(days) days until you're on Roatán. Save what looks good — we'll remind you closer to the date."
                }
                return "Pull down on Home to see what's open right now."
            case .local:
                return "Welcome home. Tap Insider Tips to add yours — we're building this together."
            }
        }
        return "Welcome to the island. Pull down on Home to refresh."
    }

    private func arrivalDaysFromNow() -> Int? {
        guard let arrival = draftArrival else { return nil }
        return Calendar.current.dateComponents([.day], from: .now, to: arrival).day
    }

    // MARK: - Header + controls

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

    private var bottomControls: some View {
        VStack(spacing: 14) {
            Button {
                Haptics.impact()
                advance()
            } label: {
                Text(step.primaryButtonLabel)
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

    private var canAdvance: Bool {
        switch step {
        case .welcome, .dates, .permissions, .ready: return true
        case .travelerType: return draftType != nil
        case .interests: return !draftInterests.isEmpty
        }
    }

    private func advance(skip: Bool = false) {
        // Persist what we've gathered at each step.
        switch step {
        case .travelerType:
            if let t = draftType { profileStore.setTravelerType(t) }
        case .dates:
            if hasDates {
                profileStore.setTripDates(arrival: draftArrival, departure: draftDeparture)
            }
        case .interests:
            if !skip { profileStore.setInterests(draftInterests) }
        default:
            break
        }

        if let next = step.next() {
            step = next
        } else {
            profileStore.markOnboardingComplete()
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
        case travelerType
        case dates
        case interests
        case permissions
        case ready

        var id: Int { rawValue }

        var primaryButtonLabel: String {
            switch self {
            case .welcome:      return "Get started"
            case .travelerType: return "Continue"
            case .dates:        return "Continue"
            case .interests:    return "Continue"
            case .permissions:  return "Continue"
            case .ready:        return "Let's go"
            }
        }

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
