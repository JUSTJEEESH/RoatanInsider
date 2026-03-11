import SwiftUI

struct HeroSection: View {
    @Binding var selectedTab: Int

    var body: some View {
        GeometryReader { geo in
            let topInset = geo.safeAreaInsets.top

            ZStack(alignment: .bottom) {
                // Hero photo
                Image("hero_roatan")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: 480)
                    .clipped()

                // Dark scrim at bottom for text readability
                Rectangle()
                    .fill(
                        .linearGradient(
                            colors: [.clear, .black.opacity(0.3), .black.opacity(0.75)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // CTA content
                VStack(spacing: 14) {
                    Spacer()

                    Image("palm_logo")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(.white.opacity(0.15))
                        .frame(height: 60)

                    Text("Explore the island\nlike a local.")
                        .riDisplayStyle(32)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("Curated by people who live here.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)

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
                .padding(.top, topInset)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 480)
        .background(Color.riNearBlack.ignoresSafeArea(edges: .top))
    }
}
