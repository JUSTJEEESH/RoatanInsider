import SwiftUI
import Combine

/// "On the island" — the time-aware answer to the question every visitor
/// asks when they open the app: what's happening RIGHT NOW, and what's
/// next? Lives in its own dark section on Home.
///
/// Shape shifts with the clock:
///   - Morning/afternoon: "Today on the island" — daytime sets through
///     tonight's lineup.
///   - Evening: "Tonight on the island" — the classic night framing.
///   - Late night: whatever is still going, then a peek at tomorrow.
/// Events in progress lead the list with a LIVE NOW pulse; the rest follow
/// in start-time order. Cruise-day-only events hide when no ship is in
/// port. A once-a-minute tick keeps it honest while the app stays open.
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

        VStack(alignment: .leading, spacing: 18) {
            header(liveCount: live.count, upNextCount: upNext.count, showingTomorrow: !tomorrow.isEmpty)

            if live.isEmpty && upNext.isEmpty && tomorrow.isEmpty {
                emptyState
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    if !live.isEmpty {
                        groupLabel("HAPPENING NOW", color: .green)
                        ForEach(live.prefix(Self.liveLimit)) { EventRow(event: $0) }
                    }
                    if !upNext.isEmpty {
                        if !live.isEmpty { groupLabel("UP NEXT", color: Color.riMint).padding(.top, 8) }
                        ForEach(upNext.prefix(Self.upNextLimit)) { EventRow(event: $0) }
                    }
                    if !tomorrow.isEmpty {
                        ForEach(tomorrow) { EventRow(event: $0) }
                    }
                }
                .padding(.horizontal, 20)

                seeAllLink(totalCount: live.count + upNext.count)
            }
        }
        .padding(.vertical, AppConstants.sectionPadding)
        .frame(maxWidth: .infinity)
        .background(Color.riFixedDark)
        .onReceive(clock) { now = $0 }
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

    private func header(liveCount: Int, upNextCount: Int, showingTomorrow: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: kickerIcon)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.riMint)
                Text(kicker)
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(Color.riMint)
            }

            Text(headline(liveCount: liveCount, showingTomorrow: showingTomorrow))
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)

            Text(subtitle(liveCount: liveCount, showingTomorrow: showingTomorrow))
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.6))
                .lineSpacing(2)
        }
        .padding(.horizontal, 20)
    }

    private var kicker: String {
        switch daypart {
        case .morning, .afternoon: return "TODAY ON THE ISLAND"
        case .evening, .lateNight: return "TONIGHT ON THE ISLAND"
        }
    }

    private var kickerIcon: String {
        switch daypart {
        case .morning:   return "sun.max.fill"
        case .afternoon: return "sun.haze.fill"
        case .evening, .lateNight: return "moon.stars.fill"
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

    private func groupLabel(_ text: String, color: Color) -> some View {
        HStack(spacing: 6) {
            if color == .green {
                Circle().fill(Color.green).frame(width: 6, height: 6)
            }
            Text(text)
                .font(.system(size: 10, weight: .heavy))
                .tracking(1.2)
                .foregroundStyle(color)
        }
        .padding(.leading, 4)
    }

    private var emptyState: some View {
        Text("Quiet stretch on the island. Pull up the week to see what's coming.")
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
        if totalCount > Self.liveLimit + Self.upNextLimit {
            return "See all \(totalCount) today"
        }
        return "Browse the whole week"
    }
}

/// Compact single-line event row used in TonightSection and the
/// full-week list. Adapts colors to light/dark mode. Featured events
/// (the local 'don't miss' picks) get a pink star next to the performer
/// name and a small DON'T MISS pill above the venue line.
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

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        if event.isFeatured {
                            Text("DON'T MISS")
                                .font(.system(size: 9, weight: .heavy))
                                .tracking(1.0)
                                .foregroundStyle(Color.riPink)
                        }
                        if event.isLiveNow() {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                                Text("LIVE NOW")
                                    .font(.system(size: 9, weight: .heavy))
                                    .tracking(1.0)
                                    .foregroundStyle(Color.green)
                            }
                        }
                    }
                    HStack(spacing: 5) {
                        Text(event.performer)
                            .font(.system(size: 15, weight: event.isFeatured ? .bold : .semibold))
                            .foregroundStyle(Color.riDark)
                            .lineLimit(1)
                        if event.isFeatured {
                            Image(systemName: "star.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color.riPink)
                        }
                    }
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
            .background(Color.riOffWhite)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

/// Marker type for the events list deep-dive. Lives here because only
/// the events views push to it.
struct EventsListDestination: Hashable {}
