import SwiftUI

struct HeroSection: View {
    @Binding var selectedTab: Int

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Hero photo
                Image("hero_roatan")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: 480)
                    .clipped()

                // Dark scrim for text readability
                Rectangle()
                    .fill(.black.opacity(0.55))

                // CTA content
                VStack(spacing: 14) {
                    Image("palm_logo")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(Color.riPink)
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
                            .padding(.horizontal, 36)
                            .frame(height: AppConstants.buttonHeight)
                            .background(Color.riPink)
                            .clipShape(RoundedRectangle(cornerRadius: AppConstants.buttonCornerRadius))
                    }
                    .padding(.top, 4)
                    .accessibilityLabel("Start exploring Roatán")
                }
                .padding(24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 480)
        .background(Color.riNearBlack.ignoresSafeArea(edges: .top))
    }
}
