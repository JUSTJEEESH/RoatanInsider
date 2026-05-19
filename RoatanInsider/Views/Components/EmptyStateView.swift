import SwiftUI

/// Unified empty-state for any list/grid/search result. Three-line UI:
/// SF Symbol, headline, supporting copy, optional CTA. Replaces the
/// one-off empty states currently sprinkled across views, each of which
/// uses slightly different paddings and colours.
struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String
    var ctaLabel: String?
    var ctaAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Color.riLightGray)

            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.riDark)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.riBody)
                    .foregroundStyle(Color.riLightGray)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 24)
            }

            if let ctaLabel, let ctaAction {
                Button {
                    Haptics.impact()
                    ctaAction()
                } label: {
                    Text(ctaLabel)
                        .font(.riButton)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .frame(height: AppConstants.buttonHeight)
                        .background(Color.riPink)
                        .clipShape(RoundedRectangle(cornerRadius: AppConstants.buttonCornerRadius))
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .padding(.horizontal, 20)
    }
}
