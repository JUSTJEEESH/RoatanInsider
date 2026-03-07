import SwiftUI

struct AnimatedLaunchView: View {
    @State private var logoOpacity: Double = 0
    @State private var swayAngle: Double = 0
    @State private var textOffset: CGFloat = 20
    @State private var textOpacity: Double = 0
    @State private var isFinished = false

    var onFinish: () -> Void

    var body: some View {
        ZStack {
            Color.riPink
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    Text("Roatán Insider")
                        .font(.system(size: 28, weight: .bold))
                        .tracking(-0.5)
                        .foregroundStyle(Color.riDark)

                    Text("Explore the island like a local.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.riDark.opacity(0.7))
                }
                .opacity(textOpacity)
                .offset(y: textOffset)
                .padding(.bottom, 60)

                // Palm tree with base pinned at bottom
                Image("palm_logo")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(Color.riDark)
                    .opacity(logoOpacity)
                    .rotationEffect(
                        .degrees(swayAngle),
                        anchor: .bottom
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 80)
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .onAppear {
            // Tree fades in
            withAnimation(.easeOut(duration: 0.5)) {
                logoOpacity = 1.0
            }

            // Gentle sway starts after tree appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(
                    .easeInOut(duration: 1.8)
                    .repeatForever(autoreverses: true)
                ) {
                    swayAngle = 2.5
                }
            }

            // Text slides up and fades in
            withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
                textOpacity = 1.0
                textOffset = 0
            }

            // Dismiss after pause
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    isFinished = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    onFinish()
                }
            }
        }
        .opacity(isFinished ? 0 : 1)
        .scaleEffect(isFinished ? 1.05 : 1.0)
    }
}
