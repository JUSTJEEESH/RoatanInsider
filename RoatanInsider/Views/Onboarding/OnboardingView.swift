import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0

    var body: some View {
        ZStack {
            Color.riNearBlack
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Pages
                TabView(selection: $currentPage) {
                    ForEach(Array(Self.pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPage(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .onChange(of: currentPage) { _, _ in
                    Haptics.select()
                }

                // Bottom controls
                VStack(spacing: 24) {
                    // Custom page indicator
                    HStack(spacing: 8) {
                        ForEach(0..<Self.pages.count, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPage ? Color.riPink : Color.riMediumGray.opacity(0.4))
                                .frame(width: index == currentPage ? 24 : 8, height: 8)
                                .animation(.easeInOut(duration: 0.2), value: currentPage)
                        }
                    }

                    // Button
                    Button {
                        Haptics.impact()
                        if currentPage < Self.pages.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                hasCompletedOnboarding = true
                            }
                        }
                    } label: {
                        Text(currentPage == Self.pages.count - 1 ? "Let's Go" : "Next")
                            .font(.riButton)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: AppConstants.buttonHeight)
                            .background(Color.riPink)
                            .clipShape(RoundedRectangle(cornerRadius: AppConstants.buttonCornerRadius))
                    }
                    .padding(.horizontal, 40)

                    // Skip
                    if currentPage < Self.pages.count - 1 {
                        Button {
                            Haptics.tap()
                            withAnimation(.easeInOut(duration: 0.3)) {
                                hasCompletedOnboarding = true
                            }
                        } label: {
                            Text("Skip")
                                .font(.riCaption(15))
                                .fontWeight(.medium)
                                .foregroundStyle(Color.riLightGray)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Page View

private struct OnboardingPage: View {
    let page: OnboardingPageData

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: page.icon)
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(Color.riMint)
                .padding(.bottom, 8)

            // Title
            Text(page.title)
                .riDisplayStyle(30)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Subtitle
            Text(page.subtitle)
                .font(.riBody)
                .foregroundStyle(Color.riLightGray)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Data

struct OnboardingPageData {
    let icon: String
    let title: String
    let subtitle: String
}

extension OnboardingView {
    static let pages: [OnboardingPageData] = [
        OnboardingPageData(
            icon: "palm.tree",
            title: "Welcome to\nRoatán Insider",
            subtitle: "The only guide you need for Honduras's most beautiful island — curated by people who actually live here."
        ),
        OnboardingPageData(
            icon: "map.fill",
            title: "200+ places.\nZero tourist traps.",
            subtitle: "Every restaurant, bar, dive shop, and beach — hand-picked and verified. With real insider tips you won't find anywhere else."
        ),
        OnboardingPageData(
            icon: "wifi.slash",
            title: "Works offline.\nBecause Roatán.",
            subtitle: "No signal in Oak Ridge? No problem. The full directory, guides, and tools work without internet. As it should."
        ),
    ]
}
