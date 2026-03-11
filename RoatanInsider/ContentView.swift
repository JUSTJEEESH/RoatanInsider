import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var dataManager = DataManager()
    @State private var locationManager = LocationManager()
    @State private var networkMonitor = NetworkMonitor()
    @State private var unitPreference = UnitPreference()
    @State private var selectedTab = 0
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
        .onChange(of: selectedTab) { _, _ in
            Haptics.select()
        }
        .environment(dataManager)
        .environment(locationManager)
        .environment(networkMonitor)
        .environment(favoritesStore)
        .environment(unitPreference)
        .onAppear {
            configureTabBarAppearance()
        }
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
