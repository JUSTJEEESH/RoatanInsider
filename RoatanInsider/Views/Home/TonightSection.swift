import SwiftUI

/// "Tonight on Roatán" — the highest-priority answer to the question every
/// tourist asks. Shows the next 5 events starting from now (or already
/// in progress within the last hour) and a See-all link to the full
/// week's list.
struct TonightSection: View {
    @Environment(EventsService.self) private var events

    private static let previewLimit = 5

    var body: some View {
        let tonight = events.eventsTonight()

        VStack(alignment: .leading, spacing: 14) {
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

                if tonight.count > Self.previewLimit {
                    NavigationLink(value: EventsListDestination()) {
                        HStack(spacing: 6) {
                            Text("See all \(tonight.count) tonight")
                                .font(.system(size: 14, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundStyle(Color.riPink)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                }
            }
        }
    }

    private func header(count: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("TONIGHT ON ROATÁN")
                .font(.system(size: 12, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(Color.riMint)

            HStack(alignment: .firstTextBaseline) {
                Text(headlineForToday)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Color.riDark)
                Spacer()
                NavigationLink(value: EventsListDestination()) {
                    Text("This week")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.riPink)
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private var headlineForToday: String {
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
        Text("Quiet night on the island. Pull up the week to plan ahead.")
            .font(.system(size: 14))
            .foregroundStyle(Color.riLightGray)
            .padding(.horizontal, 20)
    }
}

/// Compact single-line event row used in TonightSection and the
/// full-week list. Three columns — performer/event, venue+area, time.
struct EventRow: View {
    let event: Event

    var body: some View {
        NavigationLink(value: event) {
            HStack(spacing: 14) {
                Image(systemName: event.category.iconName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.riMint)
                    .frame(width: 32, height: 32)
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
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.riOffWhite)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

/// Marker type for the events list deep-dive. Lives here because only
/// the events views push to it.
struct EventsListDestination: Hashable {}
