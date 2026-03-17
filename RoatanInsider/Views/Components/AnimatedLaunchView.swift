import SwiftUI

struct AnimatedLaunchView: View {
    @State private var isFinished = false

    var onFinish: () -> Void

    var body: some View {
        GeometryReader { geo in
            Image("LaunchImage")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .ignoresSafeArea()
        }
        .ignoresSafeArea()
        .opacity(isFinished ? 0 : 1)
        .scaleEffect(isFinished ? 1.02 : 1.0)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    isFinished = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    onFinish()
                }
            }
        }
    }
}
