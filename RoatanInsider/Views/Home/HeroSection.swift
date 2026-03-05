import SwiftUI

struct HeroSection: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image("hero_placeholder")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 420)
                .clipped()
                .overlay {
                    // Subtle dark overlay at bottom for text readability
                    LinearGradient(
                        colors: [.clear, .clear, Color.black.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

            VStack(alignment: .leading, spacing: 8) {
                Text("Roatán\nInsider")
                    .riDisplayStyle(40)
                    .foregroundStyle(.white)

                Text("Explore the island like a local.")
                    .font(.riBody)
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(24)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity)
    }
}
