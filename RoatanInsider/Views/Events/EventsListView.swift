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
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.riWhite)
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
        } else {
            VStack(spacing: 8) {
                ForEach(results) { event in
                    EventRow(event: event)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 32)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Text(hasFilter ? "No matches." : "Nothing scheduled for \(selectedDay.displayName).")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.riDark)
            if hasFilter {
                Text("Try a different search or category.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.riLightGray)
            }
        }
        .padding(.top, 60)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity)
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
        .padding(.bottom, 16)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.riLightGray)
            TextField(
                "",
                text: $searchText,
                prompt: Text("Search venue, performer, area…").foregroundStyle(Color.riLightGray)
            )
            .focused($searchFocused)
            .font(.system(size: 14))
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
                        .font(.system(size: 14))
                        .foregroundStyle(Color.riLightGray)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.riOffWhite)
        .clipShape(RoundedRectangle(cornerRadius: 10))
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
                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
            }
            .foregroundStyle(isSelected ? .white : Color.riDark)
            .padding(.horizontal, 12)
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
