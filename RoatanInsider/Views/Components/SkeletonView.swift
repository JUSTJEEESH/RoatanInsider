import SwiftUI

struct SkeletonView: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16

    @State private var opacity: Double = 0.3

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.riLightGray)
            .opacity(opacity)
            .frame(width: width, height: height)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    opacity = 0.1
                }
            }
    }
}
