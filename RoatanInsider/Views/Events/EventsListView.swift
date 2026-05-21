import SwiftUI

/// Full weekly events list with day-of-week tabs. Pushed onto the
/// NavigationStack from TonightSection's See-all / This-week links.
///
/// V1 keeps this deliberately minimal: a day selector and a sectioned
/// list. Category + area filters land in a later phase.
struct EventsListView: View {
    @Environment(EventsService.self) private var events
    @State private var selectedDay: Weekday = Weekday.today ?? .friday

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                pageHeader

                Section(header: daySelector) {
                    let dayEvents = events.events(for: selectedDay)
                    if dayEvents.isEmpty {
                        Text("Nothing scheduled for \(selectedDay.displayName).")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.riLightGray)
                            .padding(.top, 60)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(dayEvents) { event in
                                EventRow(event: event)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.riWhite)
    }

    private var pageHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "music.note.list")
                    .font(.system(size: 12, weight: .bold))
                Text("EVENTS THIS WEEK")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1.4)
            }
            .foregroundStyle(Color.riMint)

            Text("What's on, every night")
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(Color.riDark)

            Text("Live music, DJs, karaoke, trivia, fire shows — every spot worth being at, sorted by day.")
                .font(.system(size: 15))
                .foregroundStyle(Color.riLightGray)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 20)
    }

    private var daySelector: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Weekday.allCases) { day in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedDay = day
                            }
                            Haptics.tap()
                        } label: {
                            Text(day.displayName)
                                .font(.system(size: 14, weight: selectedDay == day ? .bold : .medium))
                                .foregroundStyle(selectedDay == day ? .white : Color.riDark)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(selectedDay == day ? Color.riPink : Color.riOffWhite)
                                .clipShape(Capsule())
                        }
                        .id(day)
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
            }
            .background(Color.riWhite)
            .onAppear {
                proxy.scrollTo(selectedDay, anchor: .center)
            }
        }
    }
}
