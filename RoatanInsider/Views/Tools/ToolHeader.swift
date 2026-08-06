import SwiftUI

/// Shared header for the four Tools screens.
///
/// Each screen used to build this block itself — same icon size, same
/// title weight, same subtitle style — but with the gap underneath set
/// independently: 32pt in Currency, 28pt in Tips, 24pt in Phrases and
/// Safety. Switching tools shifted the content, and because none of them
/// pinned to the full width, each header centred against a different box.
///
/// One component, one set of numbers, so the four screens sit still.
struct ToolHeader: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: AppConstants.Space.tight) {
            Image(systemName: icon)
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(Color.riMint)

            Text(title)
                .riType(.title)
                .foregroundStyle(Color.riDark)

            Text(subtitle)
                .riType(.caption)
                .foregroundStyle(Color.riMediumGray)
                .multilineTextAlignment(.center)
        }
        // Pinning to full width is what actually fixes the alignment: the
        // subtitle lengths differ enough that content-sized headers centred
        // against four different widths.
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppConstants.Space.gutter)
        .padding(.top, 28)
        .padding(.bottom, AppConstants.Space.gutter + 4)
        .accessibilityElement(children: .combine)
    }
}
