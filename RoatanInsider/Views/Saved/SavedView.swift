import SwiftUI

struct SavedView: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(FavoritesStore.self) private var favoritesStore
    @Environment(EventsService.self) private var events
    @Environment(EventFavoritesStore.self) private var eventFavorites
    @State private var viewModel = FavoritesViewModel()

    private var favoritedEvents: [Event] {
        events.events
            .filter { eventFavorites.isFavorited($0) }
            .sorted { $0.startTime < $1.startTime }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                header

                let businesses = viewModel.favoriteBusinesses(from: dataManager, favoritesStore: favoritesStore)
                let savedEvents = favoritedEvents

                if businesses.isEmpty && savedEvents.isEmpty {
                    EmptyFavoritesView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 24, pinnedViews: []) {
                            if !savedEvents.isEmpty {
                                eventsSection(savedEvents)
                            }
                            if !businesses.isEmpty {
                                businessesSection(businesses)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .background(Color.riWhite)
            .navigationBarHidden(true)
            .navigationDestination(for: Business.self) { business in
                BusinessDetailView(business: business)
            }
            .navigationDestination(for: Event.self) { event in
                EventDetailView(event: event)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Saved")
                .riDisplayStyle(34)
                .foregroundStyle(Color.riDark)
            Text("Your personal island shortlist")
                .font(.riCaption(15))
                .foregroundStyle(Color.riLightGray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private func eventsSection(_ savedEvents: [Event]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("EVENTS", count: savedEvents.count)
            VStack(spacing: 8) {
                ForEach(savedEvents) { event in
                    EventRow(event: event)
                        .contextMenu {
                            Button(role: .destructive) {
                                eventFavorites.remove(id: event.id)
                            } label: {
                                Label("Remove from Saved", systemImage: "heart.slash")
                            }
                        }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func businessesSection(_ businesses: [Business]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("PLACES", count: businesses.count)
            LazyVStack(spacing: 16) {
                ForEach(businesses) { business in
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
        }
    }

    private func sectionLabel(_ title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(Color.riMint)
            Spacer()
            Text("\(count)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.riLightGray)
        }
        .padding(.horizontal, 24)
    }
}
