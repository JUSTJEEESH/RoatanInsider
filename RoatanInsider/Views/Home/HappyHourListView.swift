import SwiftUI

/// Marker type for the happy-hour list. Pushed from the Today row.
struct HappyHourDestination: Hashable {}

/// Where happy hour is on right now, and what's coming later today.
///
/// Two sections, because "on now" and "starts at five" are different
/// answers to different questions, and merging them is how a list stops
/// being actionable. Only places with a stated window appear at all — the
/// app knows of no others, and says so rather than padding the list with
/// bars that merely serve drinks.
struct HappyHourListView: View {
    @Environment(DataManager.self) private var dataManager

    @State private var now: Date = .now
    private let clock = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: AppConstants.Space.section) {
                header

                if onNow.isEmpty && laterToday.isEmpty {
                    EmptyStateView(
                        symbol: "clock",
                        title: "Nothing on right now",
                        message: "No happy hour we know the times for is running at the moment. Check back this afternoon."
                    )
                } else {
                    group("ON NOW", places: onNow, showsCountdown: true)
                    group("LATER TODAY", places: laterToday, showsCountdown: false)
                }

                footer
            }
            .padding(.bottom, AppConstants.Space.block)
        }
        .navigationTitle("Happy hour")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.riWhite)
        .onReceive(clock) { now = $0 }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: AppConstants.Space.tight) {
            Text("Happy hour")
                .riType(.display)
                .foregroundStyle(Color.riDark)
            Text("Only places whose times we've confirmed. If a bar you know isn't here, we don't have its hours yet.")
                .riType(.caption)
                .foregroundStyle(Color.riMediumGray)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, AppConstants.Space.gutter)
        .padding(.top, AppConstants.Space.snug)
    }

    @ViewBuilder
    private func group(_ label: String, places: [Business], showsCountdown: Bool) -> some View {
        if !places.isEmpty {
            VStack(alignment: .leading, spacing: AppConstants.Space.snug) {
                Text(label)
                    .riType(.label)
                    .foregroundStyle(showsCountdown ? Color.riMint : Color.riMediumGray)

                VStack(spacing: 0) {
                    ForEach(Array(places.enumerated()), id: \.element.id) { index, business in
                        if index > 0 {
                            Divider().overlay(Color.riDark.opacity(0.08))
                        }
                        NavigationLink(value: business) {
                            row(business, showsCountdown: showsCountdown)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, AppConstants.Space.gutter)
        }
    }

    private func row(_ business: Business, showsCountdown: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppConstants.Space.snug) {
            VStack(alignment: .leading, spacing: 3) {
                Text(business.name)
                    .riType(.heading)
                    .foregroundStyle(Color.riDark)
                    .lineLimit(1)

                Text(detailLine(business))
                    .riType(.caption)
                    .foregroundStyle(Color.riMediumGray)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: AppConstants.Space.tight)

            if showsCountdown, let hh = business.happyHour {
                Text(hh.untilLabel)
                    .riType(.caption, weight: .semibold)
                    .foregroundStyle(Color.riMint)
                    .layoutPriority(1)
            } else if let hh = business.happyHour {
                Text(HappyHour.displayTime(hh.start))
                    .riType(.caption, weight: .semibold)
                    .monospacedDigit()
                    .foregroundStyle(Color.riMediumGray)
                    .layoutPriority(1)
            }
        }
        .padding(.vertical, AppConstants.Space.snug)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private func detailLine(_ business: Business) -> String {
        var parts = [business.areaDisplayName]
        if let hh = business.happyHour {
            parts.append(hh.fullLabel)
            if let note = hh.note, !note.isEmpty { parts.append(note) }
        }
        return parts.joined(separator: " · ")
    }

    private var footer: some View {
        Text("Times change and specials come and go — worth a quick call before you walk over.")
            .riType(.caption)
            .foregroundStyle(Color.riLightGray)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AppConstants.Space.gutter)
    }

    // MARK: - Data

    private var withWindows: [Business] {
        dataManager.activeBusinesses.filter { $0.happyHour != nil }
    }

    private var onNow: [Business] {
        withWindows
            .filter { $0.isHappyHourNow(now: now) }
            .sorted { ($0.happyHour?.end ?? "") < ($1.happyHour?.end ?? "") }
    }

    /// Starts later today, on a day it actually runs. Deliberately not
    /// "tomorrow onwards" — this screen is opened by someone deciding where
    /// to walk in the next few hours.
    private var laterToday: [Business] {
        let calendar = Calendar.current
        let today = Weekday.from(calendarWeekday: calendar.component(.weekday, from: now))?.rawValue ?? ""
        let nowMinutes = calendar.component(.hour, from: now) * 60 + calendar.component(.minute, from: now)

        return withWindows
            .filter { business in
                guard let hh = business.happyHour, !business.isHappyHourNow(now: now) else { return false }
                guard hh.runs(on: today) else { return false }
                let parts = hh.start.split(separator: ":")
                guard parts.count == 2, let h = Int(parts[0]), let m = Int(parts[1]) else { return false }
                return h * 60 + m > nowMinutes
            }
            .sorted { ($0.happyHour?.start ?? "") < ($1.happyHour?.start ?? "") }
    }
}
