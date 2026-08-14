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
///   1b. ConditionsBand — the next ten hours, where the header can't show change
///   2. TodaySection   — one ranked list of what's true today (adapts to you)
///   3. TonightSection — what's on now and next
///   4. InsiderPickSection — the single editorial moment
///   5. BrowseSection  — the handoff to Explore
///   6. QuickGuides    — the deeper reading
///
/// Sections that moved rather than died: the time-of-day business scoring in
/// `RightNowSection`, `TrendingSection` and `ContinueBrowsingSection` now
/// open Explore, where they work across all 94 places instead of six.
/// `BusinessCTASection` moved to Settings, where an owner will actually look
/// for it.
struct HomeView: View {
    @Binding var selectedTab: Int
    @Environment(DataManager.self) private var dataManager
    @Environment(WeatherService.self) private var weather
    @Environment(LocationManager.self) private var location
    @State private var cruiseViewModel = CruiseViewModel()
    @State private var showCruiseMode = false
    @Namespace private var zoomNS

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    HomeHeader()

                    ConditionsBand()
                        .padding(.top, AppConstants.Space.gutter)

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
            .navigationDestination(for: WeatherDestination.self) { _ in
                WeatherDetailView()
            }
            .navigationDestination(for: GuideDestination.self) { $0.view }
            .navigationDestination(for: DiveSite.self) { site in
                DiveSiteDetailView(site: site)
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
        .onAppear(perform: publishWidgetSnapshot)
        .onChange(of: weather.conditions) { _, _ in publishWidgetSnapshot() }
    }

    /// Hands the home screen's two headline facts to the widget.
    ///
    /// Home is the right place for this because it is the one screen that
    /// already resolves both of them, and the widget shows exactly what it
    /// shows. Publishing from here also means the widget's empty state —
    /// "Open the app to set today's pick" — is true: opening the app is
    /// literally what fills it.
    private func publishWidgetSnapshot() {
        let selection = InsiderPickSection.pick(
            from: dataManager.activeBusinesses,
            userLocation: location.userLocation
        )
        WidgetSharedData.publish(
            temperatureLabel: weather.conditions.map { "\(Int($0.temperatureF.rounded()))°" },
            pickName: selection?.business.name,
            pickArea: selection?.business.areaDisplayName,
            pickId: selection?.business.id
        )
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
        let results = dataManager.businesses(forCategoryId: categoryId)

        ScrollView {
            // No outer NavigationLink — BusinessCard already is one.
            LazyVStack(spacing: AppConstants.Space.gutter) {
                if results.isEmpty {
                    // Home, Explore and the Map all hide categories with
                    // nothing in them, so this should be unreachable. It
                    // exists because a deep link or a stale cached
                    // categories.json can still land someone here, and a
                    // blank white page reads as a crash.
                    EmptyStateView(
                        symbol: "magnifyingglass",
                        title: "Nothing here yet",
                        message: "We haven't written up anywhere in \(displayName) so far. It's on the list."
                    )
                } else {
                    ForEach(results) { business in
                        BusinessCard(business: business)
                    }
                }
            }
            .padding(AppConstants.Space.gutter)
        }
        .navigationTitle(displayName)
        .background(Color.riWhite)
    }
}
