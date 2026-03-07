import SwiftUI

struct HeroSection: View {
    @Binding var selectedTab: Int

    var body: some View {
        GeometryReader { geo in
            let topInset = geo.safeAreaInsets.top

            ZStack {
                // Palm tree watermark
                Image("palm_logo")
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.white.opacity(0.04))
                    .frame(height: 320)

                // CTA content — pushed down to clear status bar
                VStack(spacing: 16) {
                    Text("Explore the island\nlike a local.")
                        .riDisplayStyle(30)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("Discover the best of Roatán — curated by people who live here.")
                        .font(.riBody)
                        .foregroundStyle(.white.opacity(0.7))
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
                .padding(.top, topInset)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 420)
        .background(Color.riNearBlack.ignoresSafeArea(edges: .top))
    }
}
