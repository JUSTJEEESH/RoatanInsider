import SwiftUI

struct SkeletonView: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16
    var cornerRadius: CGFloat = AppConstants.Radius.small

    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(Color.riLightGray.opacity(0.15))
            .frame(width: width, height: height)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
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
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    shimmerOffset = 400
                }
            }
    }
}

/// Skeleton standing in for a BusinessCard. Mirrors the real card's shape —
/// photo, then two text lines directly on the page with no panel behind them
/// — so the layout doesn't shift when content arrives.
struct SkeletonBusinessCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.Space.snug) {
            SkeletonView(height: 180, cornerRadius: AppConstants.Radius.card)
            SkeletonView(width: 160, height: 16)
            SkeletonView(width: 120, height: 12)
        }
        .accessibilityLabel("Loading")
    }
}

/// Skeleton for compact horizontal cards
struct SkeletonCardCompact: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.Space.snug) {
            SkeletonView(height: 195, cornerRadius: AppConstants.Radius.card)
                .frame(width: 260)
            SkeletonView(width: 140, height: 16)
            SkeletonView(width: 100, height: 12)
        }
        .frame(width: 260)
        .accessibilityLabel("Loading")
    }
}
