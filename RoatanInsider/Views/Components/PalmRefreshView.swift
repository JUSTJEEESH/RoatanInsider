import SwiftUI

struct PalmRefreshHeader: View {
    @State private var swayAngle: Double = -3
    @State private var isAnimating = false

    var body: some View {
        Image("palm_logo")
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 32, height: 32)
            .foregroundStyle(Color.riPink)
            .rotationEffect(
                .degrees(swayAngle),
                anchor: .init(x: 0.5, y: 0.85)
            )
            .onAppear {
                guard !isAnimating else { return }
                isAnimating = true
                withAnimation(
                    .easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true)
                ) {
                    swayAngle = 3
                }
            }
            .onDisappear {
                isAnimating = false
                swayAngle = -3
            }
    }
}

struct PalmRefreshModifier: ViewModifier {
    let onRefresh: () async -> Void

    func body(content: Content) -> some View {
        content
            .refreshable {
                Haptics.tap()
                await onRefresh()
            }
    }
}

extension View {
    func palmRefresh(onRefresh: @escaping () async -> Void) -> some View {
        modifier(PalmRefreshModifier(onRefresh: onRefresh))
    }
}
