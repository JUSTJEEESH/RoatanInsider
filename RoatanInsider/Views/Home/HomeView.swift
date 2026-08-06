import SwiftUI

/// Home, in six blocks.
///
/// This screen previously stacked seventeen sections, roughly 1,900 lines,
/// in which five surfaces answered "what should I do right now?" and seven
/// answered "which places should I look at?" — including two that both used
/// the kicker "RIGHT NOW". Nothing had rank because everything claimed the
/// same rank.
///
/// The six that remain, in the order a visitor needs them:
///   1. HomeHeader     — who you are, and the conditions, on two lines
///   2. TodaySection   — one ranked list of what's true today (adapts to you)
///   3. TonightSection — what's on now and next
///   4. InsiderPickSection — the single editorial moment
///   5. BrowseSection  — the handoff to Explore
///   6. QuickGuides    — the deeper reading
///
/// Sections that moved rather than died: the time-of-day business scoring
/// in `RightNowSection`, `TrendingSection` and `ContinueBrowsingSection`
/// belong in Explore, where they work across all 94 places instead of six;
/// they're wired up in the Explore pass and their files stay put until
/// then. `BusinessCTASection` moved to Settings, where an owner will
/// actually look for it.
struct HomeView: View {
    @Binding var selectedTab: Int
    @Environment(DataManager.self) private var dataManager
    @State private var cruiseViewModel = CruiseViewModel()
    @State private var showCruiseMode = false
    @Namespace private var zoomNS

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    HomeHeader()

                    TodaySection(showCruiseMode: $showCruiseMode)
                        .padding(.top, AppConstants.Space.block)

                    TonightSection()
                        .padding(.top, AppConstants.Space.section)

                    InsiderPickSection()
                        .padding(.vertical, AppConstants.Space.section)

                    BrowseSection(businesses: dataManager.activeBusinesses)
                        .padding(.vertical, AppConstants.Space.section)
                        .frame(maxWidth: .infinity)
                        .background(Color.riFixedDark)

                    QuickGuidesSection()
                        .padding(.vertical, AppConstants.Space.section)
                }
                .environment(\.colorScheme, .light)
            }
            .palmRefresh {
                try? await Task.sleep(for: .milliseconds(800))
            }
            .background(Color.white.ignoresSafeArea(edges: .top))
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Business.self) { business in
                BusinessDetailView(business: business)
            }
            .navigationDestination(for: CategoryNavID.self) { navID in
                CategoryListView(categoryId: navID.id)
            }
            .navigationDestination(for: CuratedCollection.self) { collection in
                CollectionDetailView(
                    collection: collection,
                    businesses: dataManager.activeBusinesses.filter(collection.filter).smartSorted()
                )
            }
            .navigationDestination(for: EventsListDestination.self) { _ in
                EventsListView()
            }
            .navigationDestination(for: HappyHourDestination.self) { _ in
                HappyHourListView()
            }
            .navigationDestination(for: Event.self) { event in
                EventDetailView(event: event)
            }
            .fullScreenCover(isPresented: $showCruiseMode) {
                CruiseModeView(viewModel: cruiseViewModel)
            }
        }
        // Applied on the NavigationStack (not its content) so navigationDestination
        // children inherit the namespace.
        .environment(\.zoomNamespace, zoomNS)
    }


}

struct CategoryListView: View {
    let categoryId: String
    @Environment(DataManager.self) private var dataManager

    private var displayName: String {
        dataManager.categoryInfo(for: categoryId)?.displayName
            ?? Category(rawValue: categoryId)?.displayName
            ?? categoryId.replacingOccurrences(of: "_", with: " ").capitalized
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(dataManager.businesses(forCategoryId: categoryId)) { business in
                    NavigationLink(value: business) {
                        BusinessCard(business: business)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
        .navigationTitle(displayName)
        .background(Color.riWhite)
    }
}
