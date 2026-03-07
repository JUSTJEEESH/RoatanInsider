import SwiftUI

struct AnimatedLaunchView: View {
    @State private var logoScale: CGFloat = 0.6
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

            VStack(spacing: 28) {
                Image("palm_logo")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150)
                    .foregroundStyle(Color.riDark)
                    .scaleEffect(logoScale)
                    .rotationEffect(
                        .degrees(swayAngle),
                        anchor: .init(x: 0.5, y: 0.85)
                    )
                    .opacity(logoOpacity)

                VStack(spacing: 6) {
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
            }
        }
        .onAppear {
            // Palm tree appears with spring
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }

            // Start gentle sway after tree appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(
                    .easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: true)
                ) {
                    swayAngle = 3.5
                }
            }

            // Text slides up and fades in
            withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
                textOpacity = 1.0
                textOffset = 0
            }

            // Dismiss after pause
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
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
