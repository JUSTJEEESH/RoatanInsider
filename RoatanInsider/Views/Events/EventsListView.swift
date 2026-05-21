import SwiftUI

/// Full weekly events list with day-of-week tabs. Pushed onto the
/// NavigationStack from TonightSection's See-all / This-week links.
///
/// V1 keeps this deliberately minimal: a day selector at the top and
/// a sectioned list below. Category + area filters land in a later phase.
struct EventsListView: View {
    @Environment(EventsService.self) private var events
    @State private var selectedDay: Weekday = Weekday.today ?? .friday

    var body: some View {
        VStack(spacing: 0) {
            daySelector

            ScrollView {
                LazyVStack(spacing: 8) {
                    let dayEvents = events.events(for: selectedDay)
                    if dayEvents.isEmpty {
                        Text("Nothing scheduled for \(selectedDay.displayName).")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.riLightGray)
                            .padding(.top, 60)
                    } else {
                        ForEach(dayEvents) { event in
                            EventRow(event: event)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("This week")
        .navigationBarTitleDisplayMode(.large)
        .background(Color.white)
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
            .onAppear {
                proxy.scrollTo(selectedDay, anchor: .center)
            }
        }
    }
}
