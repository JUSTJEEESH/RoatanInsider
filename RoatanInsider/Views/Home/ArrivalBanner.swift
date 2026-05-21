import SwiftUI

/// Soft "Welcome to Roatán" banner that shows when the user opens the app
/// while on the island AND hasn't set up a trip. Tap → opens Cruise Mode.
/// Dismissable for the session.
///
/// Renders nothing when `ArrivalDetector.shouldShow(...)` returns false,
/// so HomeView can include it unconditionally without worrying about
/// layout reservation.
struct ArrivalBanner: View {
    @Environment(ArrivalDetector.self) private var arrival
    @Environment(LocationManager.self) private var location
    @Environment(UserProfileStore.self) private var profile
    @Binding var showCruiseMode: Bool

    var body: some View {
        if arrival.shouldShow(location: location.userLocation, profile: profile.profile) {
            HStack(spacing: 14) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Color.riPink)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("Welcome to Roatán")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.riDark)
                    Text("Looks like a cruise day — open your itinerary.")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.riMediumGray)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                Button {
                    Haptics.impact()
                    showCruiseMode = true
                } label: {
                    Text("Open")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.riPink)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Button {
                    Haptics.tap()
                    arrival.dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.riLightGray)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss")
            }
            .padding(14)
            .background(Color.riOffWhite)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .transition(.move(edge: .top).combined(with: .opacity))
            .onAppear {
                Analytics.track(.toolUsed(name: "arrival_banner_shown"))
            }
        }
    }
}
