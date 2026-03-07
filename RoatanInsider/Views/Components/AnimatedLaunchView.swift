import SwiftUI

struct AnimatedLaunchView: View {
    @State private var logoOpacity: Double = 0
    @State private var swayAngle: Double = 0
    @State private var isFinished = false

    var onFinish: () -> Void

    var body: some View {
        ZStack {
            Color.riPink
                .ignoresSafeArea()

            // Palm tree centered, base anchored so only leaves sway
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
                .padding(.horizontal, 80)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                logoOpacity = 1.0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(
                    .easeInOut(duration: 1.8)
                    .repeatForever(autoreverses: true)
                ) {
                    swayAngle = 2.5
                }
            }

            // Dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
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
