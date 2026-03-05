import SwiftUI

struct SectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var action: (() -> Void)? = nil
    var actionLabel: String = "See All"
    var lightText: Bool = false

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .riHeadlineStyle(24)
                    .foregroundStyle(lightText ? Color.riWhite : Color.riDark)

                if let subtitle {
                    Text(subtitle)
                        .font(.riBody)
                        .foregroundStyle(lightText ? Color.riLightGray : Color.riMediumGray)
                }
            }

            Spacer()

            if let action {
                Button(actionLabel, action: action)
                    .font(.riButton)
                    .foregroundStyle(Color.riPink)
            }
        }
        .padding(.horizontal, 20)
    }
}
