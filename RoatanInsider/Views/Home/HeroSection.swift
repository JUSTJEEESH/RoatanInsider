import SwiftUI

struct HeroSection: View {
    @Binding var selectedTab: Int
    @Environment(DataManager.self) private var dataManager
    @State private var currentIndex = 0

    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    private var heroBusinesses: [Business] {
        Array(dataManager.featuredBusinesses.prefix(5))
    }

    var body: some View {
        GeometryReader { outerGeo in
            let minY = outerGeo.frame(in: .global).minY
            let parallaxOffset = minY > 0 ? -minY : -minY * 0.35

            ZStack {
                if heroBusinesses.isEmpty {
                    staticHero
                } else {
                    TabView(selection: $currentIndex) {
                        ForEach(Array(heroBusinesses.enumerated()), id: \.element.id) { index, business in
                            BusinessImageView(business: business, aspectRatio: 16/9, contentMode: .fill)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .clipped()
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .onReceive(timer) { _ in
                        guard !heroBusinesses.isEmpty else { return }
                        withAnimation(.easeInOut(duration: 0.6)) {
                            currentIndex = (currentIndex + 1) % heroBusinesses.count
                        }
                    }
                }

                // Dark overlay for text readability
                Color.black.opacity(0.45)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // CTA overlay
                VStack(spacing: 16) {
                    Text("Explore the island\nlike a local.")
                        .riDisplayStyle(30)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("Discover the best of Roatán — curated by people who live here.")
                        .font(.riBody)
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)

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
                    .padding(.top, 4)
                    .accessibilityLabel("Start exploring Roatán")
                }
                .padding(24)
            }
            .offset(y: parallaxOffset)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 420)
        .clipped()
    }

    private var staticHero: some View {
        ZStack {
            let heroImage = UIImage(named: "hero_placeholder") != nil

            if heroImage {
                Image("hero_placeholder")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.riDark
                Image(systemName: "palm.tree")
                    .font(.system(size: 60, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.15))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
