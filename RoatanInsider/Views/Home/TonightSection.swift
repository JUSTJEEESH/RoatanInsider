import SwiftUI

/// "Tonight on the island" — the highest-priority answer to the question
/// every tourist asks. Lives in its own dark section on Home, framed as
/// live music + DJs + trivia + more so it doesn't feel like a hidden
/// directory.
struct TonightSection: View {
    @Environment(EventsService.self) private var events

    private static let previewLimit = 5

    var body: some View {
        let tonight = events.eventsTonight()

        VStack(alignment: .leading, spacing: 18) {
            header(count: tonight.count)

            if tonight.isEmpty {
                emptyState
            } else {
                VStack(spacing: 8) {
                    ForEach(tonight.prefix(Self.previewLimit)) { event in
                        EventRow(event: event)
                    }
                }
                .padding(.horizontal, 20)

                seeAllLink(totalCount: tonight.count)
            }
        }
        .padding(.vertical, AppConstants.sectionPadding)
        .frame(maxWidth: .infinity)
        .background(Color.riFixedDark)
    }

    private func header(count: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.riMint)
                Text("TONIGHT ON THE ISLAND")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(Color.riMint)
            }

            Text(headline)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)

            Text("Live music, DJs, trivia, and the spots locals are at right now.")
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.6))
                .lineSpacing(2)
        }
        .padding(.horizontal, 20)
    }

    private var headline: String {
        switch Weekday.today {
        case .friday:    return "Friday night line-up"
        case .saturday:  return "Saturday night line-up"
        case .sunday:    return "Sunday on the island"
        case .monday:    return "Monday picks"
        case .tuesday:   return "Tuesday picks"
        case .wednesday: return "Wednesday picks"
        case .thursday:  return "Thursday picks"
        case .none:      return "What's on tonight"
        }
    }

    private var emptyState: some View {
        Text("Quiet night. Pull up the week to see what's coming.")
            .font(.system(size: 14))
            .foregroundStyle(Color.white.opacity(0.6))
            .padding(.horizontal, 20)
    }

    private func seeAllLink(totalCount: Int) -> some View {
        NavigationLink(value: EventsListDestination()) {
            HStack(spacing: 8) {
                Text(linkLabel(totalCount: totalCount))
                    .font(.system(size: 14, weight: .bold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color.riPink)
            .clipShape(Capsule())
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }

    private func linkLabel(totalCount: Int) -> String {
        if totalCount > Self.previewLimit {
            return "See all \(totalCount) tonight"
        }
        return "Browse the whole week"
    }
}

/// Compact single-line event row used in TonightSection and the
/// full-week list. Three columns — performer/event, venue+area, time.
/// White card on whatever background — works on light or dark sections.
struct EventRow: View {
    let event: Event

    var body: some View {
        NavigationLink(value: event) {
            HStack(spacing: 14) {
                Image(systemName: event.category.iconName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.riMint)
                    .frame(width: 34, height: 34)
                    .background(Color.riMint.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.performer)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.riDark)
                        .lineLimit(1)
                    Text("\(event.venue) · \(event.area)")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.riLightGray)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Text(event.displayTime)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.riDark)
                    .monospacedDigit()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

/// Marker type for the events list deep-dive. Lives here because only
/// the events views push to it.
struct EventsListDestination: Hashable {}
