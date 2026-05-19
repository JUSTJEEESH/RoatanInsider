import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var dataManager = DataManager()
    @State private var networkMonitor = NetworkMonitor()
    @State private var unitPreference = UnitPreference()
    @State private var router = DeepLinkRouter()
    @State private var selectedTab = 0
    @State private var deepLinkedBusiness: Business?
    @Environment(\.scenePhase) private var scenePhase
    @Environment(LocationManager.self) private var locationManager
    @Environment(WeatherService.self) private var weatherService
    let favoritesStore: FavoritesStore

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            ExploreView()
                .tabItem {
                    Label("Explore", systemImage: "magnifyingglass")
                }
                .tag(1)

            MapTabView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
                .tag(2)

            ToolsView()
                .tabItem {
                    Label("Tools", systemImage: "wrench.and.screwdriver.fill")
                }
                .tag(3)

            SavedView()
                .tabItem {
                    Label("Saved", systemImage: "heart.fill")
                }
                .tag(4)
        }
        .tint(.riPink)
        .onChange(of: selectedTab) { _, newTab in
            Haptics.select()
            Analytics.track(.tabSelected(name: tabName(newTab)))
        }
        .environment(dataManager)
        .environment(networkMonitor)
        .environment(favoritesStore)
        .environment(unitPreference)
        .environment(router)
        .onOpenURL { url in
            router.handle(url)
        }
        .onChange(of: router.pendingRoute) { _, route in
            guard let route else { return }
            handle(route: route)
        }
        .sheet(item: $deepLinkedBusiness) { business in
            NavigationStack {
                BusinessDetailView(business: business)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Done") { deepLinkedBusiness = nil }
                                .foregroundStyle(Color.riPink)
                        }
                    }
            }
        }
        .onAppear {
            configureTabBarAppearance()
        }
        .task {
            Analytics.track(.appLaunched)
            await dataManager.checkForUpdates()
            prewarmFeaturedImages()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    await dataManager.checkForUpdates()
                    await weatherService.refreshIfNeeded()
                }
            }
        }
    }

    private func tabName(_ index: Int) -> String {
        let names = ["home", "explore", "map", "tools", "saved"]
        return (0..<names.count).contains(index) ? names[index] : "tab_\(index)"
    }

    private func handle(route: DeepLinkRouter.Route) {
        switch route {
        case .business(let slug):
            // Match by slug or id — slug is the share-friendly canonical form.
            if let match = dataManager.businesses.first(where: { $0.slug == slug || $0.id == slug }) {
                deepLinkedBusiness = match
            } else {
                AppLog.app.warning("Deep link: no business found for slug=\(slug, privacy: .public)")
            }
        case .category:
            selectedTab = 1 // Explore
        case .area:
            selectedTab = 2 // Map
        case .collection:
            selectedTab = 0 // Home
        case .openTab(let idx):
            if (0...4).contains(idx) { selectedTab = idx }
        }
        router.pendingRoute = nil
    }

    private func prewarmFeaturedImages() {
        let urls: [URL] = dataManager.featuredBusinesses.prefix(12).compactMap { business in
            let first = business.images.first ?? ""
            if UIImage(named: first) != nil { return nil }
            if first.contains(".") && first != "business_placeholder" {
                return URL(string: AppConstants.supabaseStorageBaseURL + first)
            }
            guard !business.slug.isEmpty else { return nil }
            return URL(string: AppConstants.supabaseStorageBaseURL + business.slug + ".jpg")
        }
        Task { await ImageCache.shared.prefetch(urls) }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.riNearBlack)

        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(Color.riMediumGray)
        ]
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(Color.riPink)
        ]

        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.riMediumGray)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttributes
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.riPink)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
