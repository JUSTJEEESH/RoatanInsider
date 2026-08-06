import SwiftUI

/// Section title, optional supporting line, optional trailing action.
///
/// The action used to be pink. Pink is reserved for primary CTAs, the active
/// tab and a saved heart — a "See all" link on six different sections spends
/// the loudest colour in the palette on the least important control on the
/// screen, and once it's everywhere it stops meaning anything. It's set as
/// dark text with a chevron instead, which is what it is: navigation.
struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var action: (() -> Void)? = nil
    var actionLabel: String = "See all"
    var lightText: Bool = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: AppConstants.Space.snug) {
            VStack(alignment: .leading, spacing: AppConstants.Space.hair) {
                Text(title)
                    .riType(.title)
                    .foregroundStyle(lightText ? Color.white : Color.riDark)
                    .fixedSize(horizontal: false, vertical: true)

                if let subtitle {
                    Text(subtitle)
                        .riType(.caption)
                        .foregroundStyle(lightText ? Color.white.opacity(0.6) : Color.riMediumGray)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: AppConstants.Space.tight)

            if let action {
                Button {
                    Haptics.tap()
                    action()
                } label: {
                    HStack(spacing: 3) {
                        Text(actionLabel)
                            .riType(.caption, weight: .semibold)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(lightText ? Color.white.opacity(0.75) : Color.riMediumGray)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppConstants.Space.gutter)
    }
}
