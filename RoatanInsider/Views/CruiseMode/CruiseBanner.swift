import SwiftUI

struct CruiseBanner: View {
    @Binding var showCruiseMode: Bool

    var body: some View {
        Button {
            Haptics.impact()
            showCruiseMode = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "ferry.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.riMint)

                VStack(alignment: .leading, spacing: 2) {
                    Text("On a cruise ship today?")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("Activate Cruise Day Mode")
                        .font(.riCaption(13))
                        .foregroundStyle(Color.riLightGray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.riMediumGray)
            }
            .padding(16)
            .background(Color.riNearBlack)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
    }
}
