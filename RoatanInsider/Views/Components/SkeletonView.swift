import SwiftUI

struct SkeletonView: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16

    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.riLightGray.opacity(0.15))
            .frame(width: width, height: height)
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.riLightGray.opacity(0.08))
                    .mask {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, .white, .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 120)
                            .offset(x: shimmerOffset)
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    shimmerOffset = 400
                }
            }
    }
}

/// Skeleton placeholder that mimics BusinessCard layout
struct SkeletonBusinessCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SkeletonView(height: 180)

            VStack(alignment: .leading, spacing: 8) {
                SkeletonView(width: 160, height: 16)
                SkeletonView(width: 120, height: 12)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .background(Color.riOffWhite)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius))
        .accessibilityLabel("Loading")
    }
}

/// Skeleton for compact horizontal cards
struct SkeletonCardCompact: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SkeletonView(height: 180)
                .frame(width: 260)

            VStack(alignment: .leading, spacing: 6) {
                SkeletonView(width: 140, height: 14)
                SkeletonView(width: 100, height: 11)
            }
            .padding(10)
        }
        .frame(width: 260)
        .background(Color.riOffWhite)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius))
        .accessibilityLabel("Loading")
    }
}
