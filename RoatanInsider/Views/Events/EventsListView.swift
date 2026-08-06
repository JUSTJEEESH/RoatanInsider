import SwiftUI

/// Full weekly events list with search, category filter chips, and a
/// day-of-week selector. When a search query or category is active the
/// day picker hides and results span the whole week.
struct EventsListView: View {
    @Environment(EventsService.self) private var events
    @State private var selectedDay: Weekday = Weekday.today ?? .friday
    @State private var searchText: String = ""
    @State private var selectedCategory: EventCategory?
    @FocusState private var searchFocused: Bool

    private var hasFilter: Bool {
        !searchText.isEmpty || selectedCategory != nil
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                pageHeader

                searchBar
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                categoryChips
                    .padding(.bottom, hasFilter ? 8 : 4)

                if !hasFilter {
                    Section(header: daySelector) {
                        resultsList
                    }
                } else {
                    resultsList
                }

                freshnessFooter
            }
        }
        .refreshable {
            await events.refreshNow()
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.riWhite)
    }

    /// Says plainly where the schedule came from and how old it is. Keith
    /// updates the source through the day, so a week-old copy is a real
    /// possibility offline — better to admit it than to let the reader
    /// assume every line is confirmed.
    private var freshnessFooter: some View {
        VStack(spacing: 4) {
            Text("Schedule from Blue Wave Radio's Roatán Music Scene")
                .riType(.caption)
                .foregroundStyle(Color.riLightGray)

            Text(freshnessLine)
                .riType(.caption)
                .foregroundStyle(Color.riLightGray)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.bottom, 28)
    }

    private var freshnessLine: String {
        guard let updated = events.lastRefreshed else {
            return "Offline copy — pull down to update."
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Updated \(formatter.localizedString(for: updated, relativeTo: .now)) · pull down to refresh"
    }

    @ViewBuilder
    private var resultsList: some View {
        let results = events.filtered(
            query: searchText,
            category: selectedCategory,
            day: hasFilter ? nil : selectedDay
        )

        if results.isEmpty {
            emptyState
        } else if hasFilter {
            groupedResults(results)
        } else {
            hairlineList(results)
                .padding(.horizontal, AppConstants.Space.gutter)
                .padding(.bottom, AppConstants.Space.block)
        }
    }

    /// Rows separated by rules rather than gaps between filled cards — the
    /// same timetable treatment Home uses, so an event looks like the same
    /// object on both screens.
    private func hairlineList(_ list: [Event]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(list.enumerated()), id: \.element.id) { index, event in
                if index > 0 {
                    Divider().overlay(Color.riDark.opacity(0.08))
                }
                EventRow(event: event)
            }
        }
    }

    @ViewBuilder
    private func groupedResults(_ matches: [Event]) -> some View {
        let groups = Self.groupByDay(matches)
        VStack(alignment: .leading, spacing: AppConstants.Space.block) {
            ForEach(groups) { group in
                VStack(alignment: .leading, spacing: AppConstants.Space.tight) {
                    HStack(spacing: 6) {
                        Text(dayLabel(for: group))
                            .riType(.label)
                            .foregroundStyle(Color.riMint)
                        Spacer()
                        Text("\(group.events.count) \(group.events.count == 1 ? "spot" : "spots")")
                            .riType(.caption)
                            .foregroundStyle(Color.riLightGray)
                    }

                    hairlineList(group.events)
                }
            }
        }
        .padding(.horizontal, AppConstants.Space.gutter)
        .padding(.bottom, AppConstants.Space.block)
    }

    private func dayLabel(for group: DayGroup) -> String {
        let name = group.day.displayName.uppercased()
        if group.day == Weekday.today { return "\(name) · TODAY" }
        if group.isTomorrow { return "\(name) · TOMORROW" }
        return name
    }

    /// Groups events by weekday, ordered starting from today and wrapping
    /// forward through the week. Empty days are dropped.
    private static func groupByDay(_ events: [Event]) -> [DayGroup] {
        let buckets = Dictionary(grouping: events) { $0.day ?? .monday }
        let today = Weekday.today ?? .monday
        return Weekday.allCases
            .sorted { a, b in
                let aOffset = (a.calendarWeekday - today.calendarWeekday + 7) % 7
                let bOffset = (b.calendarWeekday - today.calendarWeekday + 7) % 7
                return aOffset < bOffset
            }
            .compactMap { day -> DayGroup? in
                guard let dayEvents = buckets[day], !dayEvents.isEmpty else { return nil }
                return DayGroup(day: day, events: dayEvents)
            }
    }

    private struct DayGroup: Identifiable {
        let day: Weekday
        let events: [Event]
        var id: Weekday { day }

        var isTomorrow: Bool {
            let today = Weekday.today ?? .monday
            let tomorrowWD = (today.calendarWeekday % 7) + 1
            return day.calendarWeekday == tomorrowWD
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Text(hasFilter ? "No matches." : "Nothing scheduled for \(selectedDay.displayName).")
                .riType(.heading)
                .foregroundStyle(Color.riDark)
            if hasFilter {
                Text("Try a different word, or drop the category filter.")
                    .riType(.caption)
                    .foregroundStyle(Color.riMediumGray)
            }
        }
        .padding(.top, 60)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity)
    }

    private var pageHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("EVENTS THIS WEEK")
                .riType(.label)
                .foregroundStyle(Color.riMint)

            Text("What's on, every night")
                .riType(.display)
                .foregroundStyle(Color.riDark)
                .fixedSize(horizontal: false, vertical: true)

            Text("Live music, DJs, karaoke, trivia and fire shows — sorted by day.")
                .riType(.caption)
                .foregroundStyle(Color.riMediumGray)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.riLightGray)
            TextField(
                "",
                text: $searchText,
                prompt: Text("Search venue, performer, area…").foregroundStyle(Color.riLightGray)
            )
            .focused($searchFocused)
            .riType(.body)
            .foregroundStyle(Color.riDark)
            .submitLabel(.search)
            .autocorrectionDisabled(true)
            .textInputAutocapitalization(.never)

            if !searchText.isEmpty {
                Button {
                    Haptics.tap()
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.riLightGray)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppConstants.Space.snug)
        .padding(.vertical, AppConstants.Space.snug)
        .background(Color.riOffWhite)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.small, style: .continuous))
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chipButton(label: "All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(events.availableCategories()) { category in
                    chipButton(
                        label: category.rawValue,
                        icon: category.iconName,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = selectedCategory == category ? nil : category
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func chipButton(label: String, icon: String? = nil, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                action()
            }
            Haptics.tap()
        } label: {
            HStack(spacing: 5) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                }
                Text(label)
                    .riType(.caption, weight: isSelected ? .bold : .medium)
            }
            .foregroundStyle(isSelected ? .white : Color.riDark)
            .padding(.horizontal, AppConstants.Space.snug)
            .padding(.vertical, 7)
            .background(isSelected ? Color.riPink : Color.riOffWhite)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
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
                                .riType(.caption, weight: selectedDay == day ? .bold : .medium)
                                .foregroundStyle(selectedDay == day ? .white : Color.riDark)
                                .padding(.horizontal, AppConstants.Space.snug + 2)
                                .padding(.vertical, AppConstants.Space.tight)
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
