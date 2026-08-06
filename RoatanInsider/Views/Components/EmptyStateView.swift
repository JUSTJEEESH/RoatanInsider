import SwiftUI

/// Unified empty-state for any list, grid or search result: symbol,
/// headline, supporting copy, optional CTA.
///
/// The symbol is set light and grey rather than large and solid — an empty
/// state should feel like a quiet room, not an error.
struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    var ctaLabel: String?
    var ctaAction: (() -> Void)?

    var body: some View {
        VStack(spacing: AppConstants.Space.gutter) {
            Image(systemName: symbol)
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundStyle(Color.riLightGray)

            VStack(spacing: AppConstants.Space.tight) {
                Text(title)
                    .riType(.heading)
                    .foregroundStyle(Color.riDark)
                    .multilineTextAlignment(.center)

                Text(message)
                    .riType(.caption)
                    .foregroundStyle(Color.riMediumGray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .frame(maxWidth: 320)
            }

            if let ctaLabel, let ctaAction {
                Button {
                    Haptics.impact()
                    ctaAction()
                } label: {
                    Text(ctaLabel)
                        .riType(.body, weight: .semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, AppConstants.Space.gutter + 4)
                        .frame(height: AppConstants.buttonHeight)
                        .background(Color.riPink)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.card, style: .continuous))
                }
                .padding(.top, AppConstants.Space.hair)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, AppConstants.Space.gutter)
    }
}
