import SwiftUI
import Combine

/// What's on now and what's next — the question a visitor opens this app to
/// answer after dark.
///
/// Shape shifts with the clock: today's lineup in the morning, tonight's
/// after four, whatever is still going late, and a peek at tomorrow once the
/// night is played out. Cruise-day-only events hide when no ship is in port.
/// A once-a-minute tick keeps it honest while the app stays open.
///
/// Set as a timetable, because that is what it is. Every row used to be a
/// filled card carrying its category glyph in a tinted mint circle, with the
/// start time pushed to the far right — so the one thing you scan for was
/// the last thing you read, and eight identical circles did the work of a
/// column rule. Time now leads each row and the rows are separated by
/// hairlines, which is how every departure board and listings page ever
/// printed has solved this.
struct TonightSection: View {
    @Environment(EventsService.self) private var events
    @Environment(CruiseArrivalsService.self) private var cruise

    @State private var now: Date = .now
    private let clock = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private static let liveLimit = 4
    private static let upNextLimit = 4

    var body: some View {
        // Only trust "no ships" when the schedule actually covers today.
        let shipsIn = cruise.hasCurrentData ? !cruise.arrivalsToday().isEmpty : true
        let live = events.happeningNow(now: now, cruiseShipInPort: shipsIn)
        let upNext = events.upNextToday(now: now, cruiseShipInPort: shipsIn)
        let tomorrow = (live.isEmpty && upNext.isEmpty) ? events.tomorrowPreview(now: now) : []

        VStack(alignment: .leading, spacing: AppConstants.Space.gutter) {
            header(liveCount: live.count, showingTomorrow: !tomorrow.isEmpty)

            if live.isEmpty && upNext.isEmpty && tomorrow.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    listing(live, label: nil)
                    listing(upNext, label: live.isEmpty ? nil : "Later")
                    listing(tomorrow, label: nil)
                }
                .padding(.horizontal, AppConstants.Space.gutter)

                seeAllLink(totalCount: live.count + upNext.count)
            }
        }
        .padding(.vertical, AppConstants.Space.section)
        .frame(maxWidth: .infinity)
        .background(Color.riFixedDark)
        .onReceive(clock) { now = $0 }
        .onAppear { Analytics.track(.homeSectionViewed(name: "tonight")) }
    }

    /// A run of rows under an optional quiet divider label. Returns nothing
    /// at all for an empty run, so no stray rule is drawn.
    @ViewBuilder
    private func listing(_ list: [Event], label: String?) -> some View {
        let shown = Array(list.prefix(label == nil ? Self.liveLimit : Self.upNextLimit))
        if !shown.isEmpty {
            if let label {
                Text(label)
                    .riType(.label)
                    .foregroundStyle(Color.white.opacity(0.45))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, AppConstants.Space.gutter)
                    .padding(.bottom, AppConstants.Space.tight)
            }
            ForEach(Array(shown.enumerated()), id: \.element.id) { index, event in
                if index > 0 || label != nil {
                    Divider().overlay(Color.white.opacity(0.12))
                }
                EventRow(event: event, onDark: true, now: now)
            }
        }
    }

    // MARK: - Daypart

    private enum Daypart {
        case morning, afternoon, evening, lateNight

        init(hour: Int) {
            switch hour {
            case 5..<12:  self = .morning
            case 12..<16: self = .afternoon
            case 16..<22: self = .evening
            default:      self = .lateNight
            }
        }
    }

    private var daypart: Daypart {
        Daypart(hour: Calendar.current.component(.hour, from: now))
    }

    // MARK: - Header

    private func header(liveCount: Int, showingTomorrow: Bool) -> some View {
        VStack(alignment: .leading, spacing: AppConstants.Space.hair) {
            Text(kicker)
                .riType(.label)
                .foregroundStyle(Color.riMint)

            Text(headline(liveCount: liveCount, showingTomorrow: showingTomorrow))
                .riType(.title)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text(subtitle(liveCount: liveCount, showingTomorrow: showingTomorrow))
                .riType(.caption)
                .foregroundStyle(Color.white.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, AppConstants.Space.gutter)
    }

    private var kicker: String {
        switch daypart {
        case .morning, .afternoon: return "TODAY ON THE ISLAND"
        case .evening, .lateNight: return "TONIGHT ON THE ISLAND"
        }
    }

    private func headline(liveCount: Int, showingTomorrow: Bool) -> String {
        if showingTomorrow { return "Coming up tomorrow" }
        if liveCount > 0 {
            return liveCount == 1 ? "1 spot is live right now" : "\(liveCount) spots are live right now"
        }
        switch daypart {
        case .morning:   return "What's on today"
        case .afternoon: return "This afternoon & tonight"
        case .evening:
            switch Weekday.today {
            case .friday:    return "Friday night line-up"
            case .saturday:  return "Saturday night line-up"
            case .sunday:    return "Sunday on the island"
            default:         return "What's on tonight"
            }
        case .lateNight: return "Still going"
        }
    }

    private func subtitle(liveCount: Int, showingTomorrow: Bool) -> String {
        if showingTomorrow {
            return "Tonight's played out — here's an early look at tomorrow."
        }
        if liveCount > 0 {
            return "Walk in now, or line up your next stop below."
        }
        switch daypart {
        case .morning, .afternoon:
            return "Live music, DJs, and trivia — daytime sets through tonight's lineup."
        case .evening, .lateNight:
            return "Live music, DJs, trivia, and the spots locals are at right now."
        }
    }

    private var emptyState: some View {
        Text("Quiet stretch on the island. Pull up the week to see what's coming.")
            .riType(.caption)
            .foregroundStyle(Color.white.opacity(0.6))
            .padding(.horizontal, AppConstants.Space.gutter)
    }

    private func seeAllLink(totalCount: Int) -> some View {
        NavigationLink(value: EventsListDestination()) {
            HStack(spacing: AppConstants.Space.hair + 2) {
                Text(linkLabel(totalCount: totalCount))
                    .riType(.body, weight: .semibold)
                Image(systemName: "arrow.right")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(.white)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, AppConstants.Space.gutter)
    }

    private func linkLabel(totalCount: Int) -> String {
        if totalCount > Self.liveLimit + Self.upNextLimit {
            return "See all \(totalCount) today"
        }
        return "Browse the whole week"
    }
}

/// One line of the timetable: when, who, where, and whether it's on right
/// now. Used on the dark Home section and in the full-week list.
///
/// The time leads because it's what people scan. Live beats featured in the
/// trailing slot — a set that's actually playing is more urgent than one
/// Josh flagged, and showing both markers on one row is two claims fighting
/// for the same corner.
struct EventRow: View {
    let event: Event
    var onDark: Bool = false
    var now: Date = .now

    private var primary: Color { onDark ? .white : Color.riDark }
    private var secondary: Color { onDark ? Color.white.opacity(0.55) : Color.riMediumGray }

    var body: some View {
        NavigationLink(value: event) {
            HStack(alignment: .firstTextBaseline, spacing: AppConstants.Space.snug) {
                Text(event.displayTime)
                    .riType(.caption, weight: .semibold)
                    .monospacedDigit()
                    .foregroundStyle(secondary)
                    .frame(width: 66, alignment: .leading)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Text(event.performer)
                            .riType(.body, weight: .semibold)
                            .foregroundStyle(primary)
                            .lineLimit(1)
                        if event.isFeatured {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color.riPink)
                        }
                    }

                    Text("\(event.venue) · \(event.area)")
                        .riType(.caption)
                        .foregroundStyle(secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: AppConstants.Space.tight)

                marker
            }
            .padding(.vertical, AppConstants.Space.snug)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    @ViewBuilder
    private var marker: some View {
        if event.isLiveNow(now: now) {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.riMint)
                    .frame(width: 6, height: 6)
                Text("LIVE")
                    .riType(.micro)
                    .foregroundStyle(Color.riMint)
            }
        } else if event.isFeatured {
            Text("DON'T MISS")
                .riType(.micro)
                .foregroundStyle(Color.riPink)
        }
    }

    private var accessibilityDescription: String {
        var parts = [event.performer, "at \(event.venue), \(event.area)", event.displayTime]
        if event.isLiveNow(now: now) { parts.insert("Playing now", at: 0) }
        else if event.isFeatured { parts.append("Don't miss") }
        return parts.joined(separator: ", ")
    }
}

/// Marker type for the events list deep-dive. Lives here because only
/// the events views push to it.
struct EventsListDestination: Hashable {}
