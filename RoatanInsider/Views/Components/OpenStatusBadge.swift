import SwiftUI

/// Open/closed as plain text, not a coloured pill.
///
/// The spec is explicit that status is "shown as subtle text", and it's the
/// right call: a green pill on every card turns a whole screen into traffic
/// lights. Mint carries "open" quietly; closed is simply grey.
///
/// Says nothing at all when we don't know the hours, rather than guessing
/// "Closed" — 12 of 94 places have incomplete hours, and telling someone a
/// place is shut when it isn't costs them the walk.
struct OpenStatusBadge: View {
    let business: Business

    var body: some View {
        if business.hasKnownHours {
            let isOpen = business.isOpenNow()
            Text(isOpen ? "Open now" : "Closed")
                .riType(.caption, weight: .semibold)
                .foregroundStyle(isOpen ? Color.riMint : Color.riLightGray)
        }
    }
}
