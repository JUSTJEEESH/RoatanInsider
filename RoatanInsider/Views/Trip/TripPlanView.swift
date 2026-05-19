import SwiftUI

/// Replaces the old Saved tab. Contains two segments:
///   - Plan: day-by-day itinerary view (requires trip dates).
///   - Saved: the existing favorites grid.
///
/// The Plan segment is the differentiator vs every Roatán website.
/// Generating the schedule via AI is an Insider+ feature; manually adding
/// favorites to days is free.
struct TripPlanView: View {
    @Environment(UserProfileStore.self) private var profileStore
    @Environment(TripPlanStore.self) private var tripStore
    @Environment(DataManager.self) private var dataManager
    @Environment(FavoritesStore.self) private var favoritesStore
    @Environment(PurchaseManager.self) private var purchases

    @State private var segment: Segment = .plan
    @State private var showDatePicker = false
    @State private var showPaywall = false
    @State private var addingToDateKey: String?

    enum Segment: String, CaseIterable, Identifiable {
        case plan = "Plan"
        case saved = "Saved"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                segmentedControl
                Group {
                    switch segment {
                    case .plan:  planContent
                    case .saved: savedContent
                    }
                }
            }
            .background(Color.riWhite)
            .navigationBarHidden(true)
            .navigationDestination(for: Business.self) { business in
                BusinessDetailView(business: business)
            }
            .sheet(isPresented: $showDatePicker) {
                TripDatesEditor()
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(item: Binding(
                get: { addingToDateKey.map { TripPickerSheet(dateKey: $0) } },
                set: { _ in addingToDateKey = nil }
            )) { sheet in
                AddToDaySheet(dateKey: sheet.dateKey)
            }
            .onAppear {
                tripStore.sync(with: profileStore.profile)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("My Trip")
                .riDisplayStyle(34)
                .foregroundStyle(Color.riDark)

            if let plan = tripStore.plan {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12, weight: .medium))
                    Text(dateRangeLabel(plan: plan))
                        .font(.riCaption(14))
                        .fontWeight(.medium)
                    if let countdown = countdownLabel(plan: plan) {
                        Text("·")
                        Text(countdown)
                            .font(.riCaption(14))
                            .foregroundStyle(Color.riPink)
                    }
                    Spacer()
                    Button {
                        Haptics.tap()
                        showDatePicker = true
                    } label: {
                        Text("Edit")
                            .font(.riCaption(13))
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.riMint)
                    }
                }
                .foregroundStyle(Color.riMediumGray)
            } else {
                Text("Plan your day-by-day, save your shortlist.")
                    .font(.riCaption(15))
                    .foregroundStyle(Color.riLightGray)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var segmentedControl: some View {
        HStack(spacing: 0) {
            ForEach(Segment.allCases) { s in
                Button {
                    Haptics.select()
                    withAnimation(.easeInOut(duration: 0.2)) { segment = s }
                } label: {
                    Text(s.rawValue)
                        .font(.system(size: 14, weight: segment == s ? .bold : .medium))
                        .foregroundStyle(segment == s ? .white : Color.riMediumGray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(segment == s ? Color.riPink : Color.riOffWhite)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Plan tab

    @ViewBuilder
    private var planContent: some View {
        if tripStore.plan == nil {
            ScrollView {
                EmptyStateView(
                    symbol: "calendar.badge.plus",
                    title: "Add your trip dates",
                    message: "We'll build a day-by-day plan around what you love. You can always edit later.",
                    ctaLabel: "Set trip dates",
                    ctaAction: { showDatePicker = true }
                )
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    generatorBar
                    ForEach(tripStore.plan!.days) { day in
                        dayCard(for: day)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
    }

    private var generatorBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Color.riMint)

            VStack(alignment: .leading, spacing: 2) {
                Text(generatorPrimary)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.riDark)
                Text(generatorSecondary)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.riLightGray)
            }

            Spacer()

            Button {
                Haptics.impact()
                runGenerator()
            } label: {
                HStack(spacing: 5) {
                    if !purchases.hasPremium {
                        Image(systemName: "lock.fill").font(.system(size: 11, weight: .bold))
                    }
                    Text(purchases.hasPremium ? "Generate" : "Insider+")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.riPink)
                .clipShape(Capsule())
            }
        }
        .padding(14)
        .background(Color.riOffWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var generatorPrimary: String {
        let count = tripStore.plan?.totalItems ?? 0
        if count == 0 { return "Build my itinerary" }
        return "Regenerate itinerary"
    }

    private var generatorSecondary: String {
        if tripStore.plan?.lastGenerated == nil {
            return "Tailored to your dates and interests."
        }
        return "Refresh based on your latest favorites."
    }

    private func dayCard(for day: ItineraryDay) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("DAY \(day.dayNumber)")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(Color.riMint)
                Text(day.dayLabel)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.riDark)
                Spacer()
                Text("\(day.itemIds.count) places")
                    .font(.riCaption(12))
                    .foregroundStyle(Color.riLightGray)
            }

            if day.itemIds.isEmpty {
                Text("Nothing planned yet.")
                    .font(.riCaption(13))
                    .foregroundStyle(Color.riLightGray)
                    .padding(.vertical, 4)
            } else {
                ForEach(day.itemIds, id: \.self) { id in
                    if let biz = dataManager.businesses.first(where: { $0.id == id }) {
                        NavigationLink(value: biz) {
                            itemRow(business: biz, dateKey: day.dateKey)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Button {
                Haptics.tap()
                addingToDateKey = day.dateKey
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                    Text("Add a place")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(Color.riMint)
            }
        }
        .padding(16)
        .background(Color.riOffWhite)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func itemRow(business: Business, dateKey: String) -> some View {
        HStack(spacing: 12) {
            BusinessImageView(business: business, aspectRatio: 1)
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(business.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.riDark)
                    .lineLimit(1)
                Text("\(business.categoryDisplayName) · \(business.areaDisplayName)")
                    .font(.riCaption(12))
                    .foregroundStyle(Color.riLightGray)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            Button {
                Haptics.tap()
                tripStore.removeItem(business.id, from: dateKey)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.riLightGray.opacity(0.6))
            }
            .accessibilityLabel("Remove \(business.name) from this day")
        }
        .padding(.vertical, 6)
    }

    // MARK: - Saved tab

    private var savedContent: some View {
        let favIds = favoritesStore.allFavoriteIds()
        let favorites = favIds.compactMap { id in dataManager.businesses.first(where: { $0.id == id }) }

        return Group {
            if favorites.isEmpty {
                ScrollView {
                    EmptyStateView(
                        symbol: "heart",
                        title: "No favorites yet",
                        message: "Tap the heart on any place to save it here — and pull it into your itinerary later."
                    )
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(favorites) { business in
                            BusinessCard(business: business)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        favoritesStore.removeFavorite(business.id)
                                    } label: {
                                        Label("Remove from Favorites", systemImage: "heart.slash")
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
    }

    // MARK: - Helpers

    private func dateRangeLabel(plan: TripPlan) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return "\(f.string(from: plan.arrivalDate)) – \(f.string(from: plan.departureDate))"
    }

    private func countdownLabel(plan: TripPlan) -> String? {
        let days = Calendar.current.dateComponents([.day], from: .now, to: plan.arrivalDate).day ?? 0
        if days > 0 { return "in \(days) day\(days == 1 ? "" : "s")" }
        let depDays = Calendar.current.dateComponents([.day], from: .now, to: plan.departureDate).day ?? 0
        if depDays >= 0 { return "on the island" }
        return nil
    }

    private func runGenerator() {
        guard purchases.hasPremium else {
            showPaywall = true
            Analytics.track(.paywallShown(source: "trip_generator"))
            return
        }
        guard let plan = tripStore.plan else { return }
        let input = TripItineraryGenerator.Input(
            plan: plan,
            profile: profileStore.profile,
            allBusinesses: dataManager.businesses,
            favoriteIds: Set(favoritesStore.allFavoriteIds())
        )
        let schedule = TripItineraryGenerator.generate(input)
        tripStore.replaceSchedule(schedule)
        Analytics.track(.toolUsed(name: "itinerary_generated"))
    }
}

private struct TripPickerSheet: Identifiable {
    let dateKey: String
    var id: String { dateKey }
}

// MARK: - Date editor sheet

private struct TripDatesEditor: View {
    @Environment(UserProfileStore.self) private var profileStore
    @Environment(TripPlanStore.self) private var tripStore
    @Environment(\.dismiss) private var dismiss

    @State private var arrival: Date = .now
    @State private var departure: Date = Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Arrival", selection: $arrival, displayedComponents: .date)
                    DatePicker("Departure", selection: $departure, in: arrival..., displayedComponents: .date)
                } footer: {
                    Text("Used for trip countdown, the cruise-day countdown, and day-by-day itinerary.")
                }
            }
            .navigationTitle("Trip dates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        profileStore.setTripDates(arrival: arrival, departure: departure)
                        tripStore.sync(with: profileStore.profile)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                arrival = profileStore.profile.arrivalDate ?? .now
                departure = profileStore.profile.departureDate ?? Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now
            }
        }
    }
}

// MARK: - Add-to-day sheet

private struct AddToDaySheet: View {
    let dateKey: String
    @Environment(DataManager.self) private var dataManager
    @Environment(FavoritesStore.self) private var favoritesStore
    @Environment(TripPlanStore.self) private var tripStore
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""

    private var candidates: [Business] {
        let favIds = Set(favoritesStore.allFavoriteIds())
        let alreadyOnThisDay = Set(tripStore.plan?.itemsByDate[dateKey] ?? [])

        let pool = dataManager.activeBusinesses.filter { !alreadyOnThisDay.contains($0.id) }

        let query = searchText.trimmingCharacters(in: .whitespaces)
        let filtered: [Business]
        if query.isEmpty {
            // Show favorites first, then featured.
            let favs = pool.filter { favIds.contains($0.id) }
            let featured = pool.filter { !favIds.contains($0.id) && $0.isFeatured }.prefix(20)
            filtered = favs + featured
        } else {
            let tokens = SearchSynonyms.expand(query)
            filtered = pool.filter { biz in
                let hay = biz.searchHaystack
                return tokens.contains { hay.contains($0) }
            }.prefix(40).map { $0 }
        }
        return filtered
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                SearchBar(text: $searchText)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(candidates) { business in
                            Button {
                                Haptics.tap()
                                tripStore.addItem(business.id, to: dateKey)
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    BusinessImageView(business: business, aspectRatio: 1)
                                        .frame(width: 48, height: 48)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(business.name)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(Color.riDark)
                                        Text("\(business.categoryDisplayName) · \(business.areaDisplayName)")
                                            .font(.riCaption(12))
                                            .foregroundStyle(Color.riLightGray)
                                    }

                                    Spacer()

                                    Image(systemName: "plus")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(Color.riPink)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                            .buttonStyle(.plain)
                            Divider().padding(.leading, 76)
                        }
                    }
                }
            }
            .navigationTitle("Add a place")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
