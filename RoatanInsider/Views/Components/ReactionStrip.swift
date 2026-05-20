import SwiftUI

/// Three-button reaction row for business detail pages. Tap to toggle. Counts
/// live-update optimistically; aggregate counts from the backend (when an
/// anon key is configured) refresh on appear.
///
/// Design rules:
///   - Pill background; mint when the user has tapped that reaction, otherwise
///     light-gray.
///   - Counts hidden until at least one user has reacted (avoids "0" noise).
///   - Subtle scale-bounce when toggling on — adds the small dopamine bump
///     that makes reactions stick.
struct ReactionStrip: View {
    let businessId: String
    @Environment(ReactionsService.self) private var reactions

    @State private var animatedReaction: ReactionsService.Reaction?

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ReactionsService.Reaction.allCases) { reaction in
                button(for: reaction)
            }
            Spacer(minLength: 0)
        }
        .task {
            reactions.refreshCounts(for: businessId)
        }
    }

    @ViewBuilder
    private func button(for reaction: ReactionsService.Reaction) -> some View {
        let isOn = reactions.reactions(for: businessId).contains(reaction)
        let count = reactions.count(for: businessId, reaction: reaction)
        let tint = tintColor(for: reaction, isOn: isOn)

        Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.6)) {
                animatedReaction = reaction
                reactions.toggle(reaction, on: businessId)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                animatedReaction = nil
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: reaction.symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .scaleEffect(animatedReaction == reaction ? 1.25 : 1.0)
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 13, weight: .semibold))
                        .monospacedDigit()
                }
            }
            .foregroundStyle(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isOn ? tint.opacity(0.15) : Color.riOffWhite)
            .overlay(
                Capsule()
                    .stroke(isOn ? tint.opacity(0.4) : Color.clear, lineWidth: 1)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel(for: reaction, isOn: isOn, count: count))
    }

    private func tintColor(for reaction: ReactionsService.Reaction, isOn: Bool) -> Color {
        guard isOn else { return Color.riMediumGray }
        switch reaction {
        case .heart:  return Color.riPink
        case .fire:   return .orange
        case .thumbs: return Color.riMint
        }
    }

    private func accessibilityLabel(for reaction: ReactionsService.Reaction, isOn: Bool, count: Int) -> String {
        let verb = isOn ? "Selected" : "Tap to react"
        let noun: String
        switch reaction {
        case .heart:  noun = "Love"
        case .fire:   noun = "Fire"
        case .thumbs: noun = "Recommend"
        }
        if count > 0 {
            return "\(noun), \(count) reaction\(count == 1 ? "" : "s"). \(verb)."
        }
        return "\(noun). \(verb)."
    }
}
