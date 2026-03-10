import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: Int
    @Environment(DataManager.self) private var dataManager
    @State private var viewModel = HomeViewModel()
    @State private var cruiseViewModel = CruiseViewModel()
    @State private var showCruiseMode = false

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    HeroSection(selectedTab: $selectedTab)

                    // Cruise banner
                    CruiseBanner(showCruiseMode: $showCruiseMode)
                        .padding(.top, 24)

                    // Right Now — white background (time-aware picks)
                    RightNowSection(businesses: dataManager.activeBusinesses)
                        .padding(.vertical, AppConstants.sectionPadding)

                    // Featured — dark background
                    FeaturedSection(businesses: dataManager.featuredBusinesses)
                        .padding(.vertical, AppConstants.sectionPadding)
                        .frame(maxWidth: .infinity)
                        .background(Color.riFixedDark)

                    // Best of Roatán — curated collections (white background)
                    CollectionsSection(businesses: dataManager.activeBusinesses)
                        .padding(.vertical, AppConstants.sectionPadding)

                    // Categories — dark background
                    CategoryGridSection()
                        .padding(.vertical, AppConstants.sectionPadding)
                        .frame(maxWidth: .infinity)
                        .background(Color.riFixedDark)

                    // Insider Picks — white background
                    InsiderPicksSection(businesses: dataManager.insiderPicks())
                        .padding(.vertical, AppConstants.sectionPadding)

                    // Local Secrets (tips feed) — dark background
                    InsiderTipsFeedSection(businesses: dataManager.activeBusinesses)
                        .padding(.vertical, AppConstants.sectionPadding)
                        .frame(maxWidth: .infinity)
                        .background(Color.riFixedDark)

                    // Quick Guides — white background
                    QuickGuidesSection()
                        .padding(.vertical, AppConstants.sectionPadding)

                    // Business Owner CTA — dark background
                    BusinessCTASection()
                        .padding(.vertical, AppConstants.sectionPadding)
                        .frame(maxWidth: .infinity)
                        .background(Color.riFixedDark)
                }
                .environment(\.colorScheme, .light)
            }
            .palmRefresh {
                try? await Task.sleep(for: .milliseconds(800))
            }
            .ignoresSafeArea(edges: .top)
            .background(.white)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Business.self) { business in
                BusinessDetailView(business: business)
            }
            .navigationDestination(for: Category.self) { category in
                CategoryListView(category: category)
            }
            .fullScreenCover(isPresented: $showCruiseMode) {
                CruiseModeView(viewModel: cruiseViewModel)
            }
        }
    }


}

struct CategoryListView: View {
    let category: Category
    @Environment(DataManager.self) private var dataManager

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(dataManager.businesses(for: category)) { business in
                    NavigationLink(value: business) {
                        BusinessCard(business: business)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
        .navigationTitle(category.displayName)
        .background(Color.riWhite)
    }
}
