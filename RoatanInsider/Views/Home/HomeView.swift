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
                    HeroSection()

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
                        .background(Color.riDark)

                    // Best of Roatán — curated collections (white background)
                    CollectionsSection(businesses: dataManager.activeBusinesses)
                        .padding(.vertical, AppConstants.sectionPadding)

                    // Categories — dark background
                    CategoryGridSection()
                        .padding(.vertical, AppConstants.sectionPadding)
                        .frame(maxWidth: .infinity)
                        .background(Color.riDark)

                    // Insider Picks — white background
                    InsiderPicksSection(businesses: dataManager.insiderPicks())
                        .padding(.vertical, AppConstants.sectionPadding)

                    // Local Secrets (tips feed) — dark background
                    InsiderTipsFeedSection(businesses: dataManager.activeBusinesses)
                        .padding(.vertical, AppConstants.sectionPadding)
                        .frame(maxWidth: .infinity)
                        .background(Color.riDark)

                    // Quick Guides — white background
                    QuickGuidesSection()
                        .padding(.vertical, AppConstants.sectionPadding)

                    // Business Owner CTA — dark background
                    BusinessCTASection()
                        .padding(.vertical, AppConstants.sectionPadding)
                        .frame(maxWidth: .infinity)
                        .background(Color.riDark)

                    // CTA — white background
                    ctaSection
                        .padding(.vertical, AppConstants.sectionPadding)
                }
            }
            .palmRefresh {
                try? await Task.sleep(for: .milliseconds(800))
            }
            .background(Color.riWhite)
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

    private var ctaSection: some View {
        VStack(spacing: 20) {
            Text("Explore the island\nlike a local.")
                .riDisplayStyle(30)
                .foregroundStyle(Color.riDark)
                .multilineTextAlignment(.center)

            Text("Discover the best of Roatán — curated by people who live here.")
                .font(.riBody)
                .foregroundStyle(Color.riMediumGray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                Haptics.impact()
                selectedTab = 1
            } label: {
                Text("Start Exploring")
                    .font(.riButton)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppConstants.buttonHeight)
                    .background(Color.riPink)
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.buttonCornerRadius))
            }
            .padding(.horizontal, 40)
            .accessibilityLabel("Start exploring Roatán")
        }
        .padding(.horizontal, 20)
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
