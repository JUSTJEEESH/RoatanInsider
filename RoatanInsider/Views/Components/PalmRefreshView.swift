import SwiftUI

struct PalmRefreshModifier: ViewModifier {
    @State private var refreshOffset: CGFloat = 0
    @State private var isRefreshing = false
    @State private var swayAngle: Double = 0
    let onRefresh: () async -> Void

    private let threshold: CGFloat = 80
    private let logoSize: CGFloat = 36

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if refreshOffset > 10 || isRefreshing {
                    palmIndicator
                        .offset(y: max(0, min(refreshOffset - 20, 60)))
                }
            }
            .onScrollGeometryChange(for: CGFloat.self) { geo in
                geo.contentOffset.y
            } action: { _, newValue in
                let offset = -newValue
                refreshOffset = max(0, offset)

                if offset > threshold && !isRefreshing {
                    isRefreshing = true
                    Haptics.impact()
                    Task {
                        await onRefresh()
                        try? await Task.sleep(for: .milliseconds(600))
                        withAnimation(.easeOut(duration: 0.3)) {
                            isRefreshing = false
                            refreshOffset = 0
                        }
                    }
                }
            }
    }

    private var palmIndicator: some View {
        Image("palm_logo")
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: logoSize, height: logoSize)
            .foregroundStyle(Color.riPink)
            .rotationEffect(.degrees(isRefreshing ? swayAngle : pullRotation))
            .scaleEffect(isRefreshing ? 1.0 : pullScale)
            .opacity(pullOpacity)
            .onAppear {
                if isRefreshing {
                    startSway()
                }
            }
            .onChange(of: isRefreshing) { _, refreshing in
                if refreshing {
                    startSway()
                } else {
                    swayAngle = 0
                }
            }
    }

    private var pullScale: CGFloat {
        let progress = min(refreshOffset / threshold, 1.0)
        return 0.5 + (progress * 0.5)
    }

    private var pullRotation: Double {
        let progress = min(refreshOffset / threshold, 1.0)
        return progress * 15
    }

    private var pullOpacity: Double {
        let progress = min(refreshOffset / threshold, 1.0)
        return Double(progress)
    }

    private func startSway() {
        withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
            swayAngle = 12
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            if isRefreshing {
                withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                    swayAngle = -12
                }
            }
        }
    }
}

extension View {
    func palmRefresh(onRefresh: @escaping () async -> Void) -> some View {
        modifier(PalmRefreshModifier(onRefresh: onRefresh))
    }
}
