import SwiftUI

struct HeroSection: View {
    @Binding var selectedTab: Int
    @Environment(DataManager.self) private var dataManager
    @State private var currentIndex = 0
    @State private var hasAppeared = false

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

                // Radial gradient overlay — darker at center, lighter at edges
                RadialGradient(
                    colors: [
                        .black.opacity(0.55),
                        .black.opacity(0.3)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 400
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // CTA overlay with entrance animation
                VStack(spacing: 16) {
                    Text("Explore the island\nlike a local.")
                        .riDisplayStyle(30)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : 15)

                    Text("Discover the best of Roatán — curated by people who live here.")
                        .font(.riBody)
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .opacity(hasAppeared ? 1 : 0)
                        .offset(y: hasAppeared ? 0 : 15)

                    Button {
                        Haptics.impact()
                        selectedTab = 1
                    } label: {
                        Text("Start Exploring")
                            .font(.riButton)
                            .tracking(0.8)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: AppConstants.buttonHeight)
                            .background(Color.riPink)
                            .clipShape(RoundedRectangle(cornerRadius: AppConstants.buttonCornerRadius))
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 4)
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 15)
                    .accessibilityLabel("Start exploring Roatán")
                }
                .padding(24)
            }
            .offset(y: parallaxOffset)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 460)
        .clipped()
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                hasAppeared = true
            }
        }
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
