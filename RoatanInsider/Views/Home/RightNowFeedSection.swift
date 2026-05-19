import SwiftUI

/// Vertical timeline of contextually relevant alerts derived from current
/// app state. Sits above the existing RightNowSection on Home as the
/// "brand-defining" surface — the answer to "why open this app today?"
struct RightNowFeedSection: View {
    @Environment(WeatherService.self) private var weather
    @Environment(UserProfileStore.self) private var profileStore
    @Environment(DataManager.self) private var dataManager

    private var items: [FeedItem] {
        FeedComposer.compose(
            weather: weather.conditions,
            reefScore: weather.reefScore,
            snorkelLabel: weather.snorkelLabel,
            profile: profileStore.profile,
            businesses: dataManager.activeBusinesses
        )
    }

    var body: some View {
        let composed = items
        if !composed.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                header

                VStack(spacing: 10) {
                    ForEach(composed) { item in
                        feedCard(for: item)
                    }
                }
                .padding(.horizontal, 20)
            }
            .onAppear {
                Analytics.track(.homeSectionViewed(name: "right_now_feed"))
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("RIGHT NOW")
                .font(.system(size: 12, weight: .bold))
                .tracking(1.5)
                .foregroundStyle(Color.riMint)
            Text("Happening on the island")
                .riHeadlineStyle(22)
                .foregroundStyle(Color.riDark)
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func feedCard(for item: FeedItem) -> some View {
        switch item {
        case .sunsetCountdown(let remaining, let time):
            card(
                icon: "sunset.fill",
                tint: .orange,
                title: "Sunset in \(remaining)",
                detail: "Today's golden hour at \(time). Grab a west-facing seat."
            )

        case .reefConditions(let label, let score):
            card(
                icon: "water.waves",
                tint: Color.riMint,
                title: "Reef conditions: \(label)",
                detail: scoreCommentary(score: score)
            )

        case .weatherAlert(let message):
            card(
                icon: "exclamationmark.circle.fill",
                tint: Color.riPink,
                title: "Heads up",
                detail: message
            )

        case .happyHourNow(let count, _):
            card(
                icon: "wineglass",
                tint: Color.riMint,
                title: "Happy hour now",
                detail: "\(count) place\(count == 1 ? "" : "s") within reach."
            )

        case .liveMusicTonight(let count, _):
            card(
                icon: "music.note",
                tint: .purple,
                title: "Live music tonight",
                detail: "\(count) spot\(count == 1 ? "" : "s") with a band playing."
            )

        case .tripCountdown(let days):
            card(
                icon: "airplane",
                tint: Color.riPink,
                title: "\(days) day\(days == 1 ? "" : "s") until you land",
                detail: "Start saving favorites — we'll build your itinerary."
            )

        case .lastDay(let daysLeft):
            card(
                icon: "calendar.badge.clock",
                tint: Color.riPink,
                title: daysLeft == 0 ? "Last day on the island" : "Final \(daysLeft) day\(daysLeft == 1 ? "" : "s")",
                detail: "Make it count. The good places stay open late."
            )
        }
    }

    private func card(icon: String, tint: Color, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.riDark)
                Text(detail)
                    .font(.riCaption(13))
                    .foregroundStyle(Color.riMediumGray)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(14)
        .background(Color.riOffWhite)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func scoreCommentary(score: Int) -> String {
        switch score {
        case 80...100: return "Calm water, great visibility. Snorkel anywhere."
        case 60..<80:  return "Solid conditions — west side is best."
        case 40..<60:  return "Some chop. Pick a protected cove."
        case 20..<40:  return "Choppy day. Wait for the wind to drop."
        default:       return "Rough water. Stay shore-side."
        }
    }
}
