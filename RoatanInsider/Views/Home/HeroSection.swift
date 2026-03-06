import SwiftUI

struct HeroSection: View {
    @Environment(DataManager.self) private var dataManager
    @State private var currentIndex = 0

    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    private var heroBusinesses: [Business] {
        Array(dataManager.featuredBusinesses.prefix(5))
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
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

            // Dark overlay for text
            VStack {} .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(
                        colors: [.clear, .clear, Color.black.opacity(0.65)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Text overlay
            VStack(alignment: .leading, spacing: 8) {
                Text("Roatán\nInsider")
                    .riDisplayStyle(40)
                    .foregroundStyle(.white)

                Text(AppConstants.tagline)
                    .font(.riBody)
                    .foregroundStyle(.white.opacity(0.9))

                // Page dots
                if heroBusinesses.count > 1 {
                    HStack(spacing: 6) {
                        ForEach(0..<heroBusinesses.count, id: \.self) { i in
                            Circle()
                                .fill(i == currentIndex ? Color.white : Color.white.opacity(0.4))
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding(24)
            .padding(.bottom, 16)
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
