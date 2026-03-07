import SwiftUI

struct AnimatedLaunchView: View {
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var isFinished = false

    var onFinish: () -> Void

    var body: some View {
        ZStack {
            Color.riPink
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Image("palm_logo")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 140, height: 140)
                    .foregroundStyle(Color.riDark)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                VStack(spacing: 6) {
                    Text("Roatán Insider")
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .tracking(-0.5)
                        .foregroundStyle(Color.riDark)

                    Text("Explore the island like a local.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.riDark.opacity(0.7))
                }
                .opacity(textOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.65)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }

            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                textOpacity = 1.0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation(.easeOut(duration: 0.3)) {
                    isFinished = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onFinish()
                }
            }
        }
        .opacity(isFinished ? 0 : 1)
    }
}
