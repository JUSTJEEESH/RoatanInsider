import SwiftUI

/// "This week's pick" — the screen's one editorial moment.
///
/// Replaces `InsiderPicksSection` (a rail of four cards) and
/// `InsiderTipsFeedSection` (a rail of tips). Both were rails of business
/// cards among six such rails, so neither read as special. One pick,
/// stated once, does.
///
/// The tip is the hero and the photo is evidence, not the other way round.
/// That's a deliberate inversion of the original photo-led spec: the
/// library is 269 mostly-workmanlike shots, and a workmanlike photo blown
/// up reads as louder, not better. The writing is the thing competitors
/// don't have, so the writing gets the large type and the photo gets a
/// tight 4:3 crop where "workmanlike" reads as fine.
///
/// Rotation is weekly and deterministic — derived from the ISO week, so
/// every user sees the same pick, it changes on Monday, and nothing needs
/// to be stored. Weekly rather than daily so 94 places last a year and a
/// half instead of three months.
struct ThisWeeksPick: View {
    @Environment(DataManager.self) private var dataManager

    var body: some View {
        if let business = pick, let tip = business.insiderTip, !tip.isEmpty {
            VStack(alignment: .leading, spacing: AppConstants.Space.gutter) {
                Text("THIS WEEK'S PICK")
                    .riType(.label)
                    .foregroundStyle(Color.riMediumGray)

                // The tip, set large, with the mint rule this app already
                // uses to mark insider voice.
                HStack(alignment: .top, spacing: AppConstants.Space.snug) {
                    Rectangle()
                        .fill(Color.riMint)
                        .frame(width: 3)
                    Text(tip)
                        .riType(.title)
                        .foregroundStyle(Color.riDark)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .fixedSize(horizontal: false, vertical: true)

                NavigationLink(value: business) {
                    HStack(spacing: AppConstants.Space.snug) {
                        BusinessImageView(business: business, aspectRatio: 4/3)
                            .frame(width: 84, height: 63)
                            .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.small))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(business.name)
                                .riType(.heading)
                                .foregroundStyle(Color.riDark)
                                .lineLimit(1)
                            Text("\(business.categoryDisplayName) · \(business.areaDisplayName)")
                                .riType(.caption)
                                .foregroundStyle(Color.riMediumGray)
                                .lineLimit(1)
                        }

                        Spacer(minLength: AppConstants.Space.tight)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.riLightGray)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppConstants.Space.gutter)
            .onAppear { Analytics.track(.homeSectionViewed(name: "weekly_pick")) }
        }
    }

    /// Deterministic by ISO week. Sorted by id first so the choice doesn't
    /// shift when the remote data file reorders.
    private var pick: Business? {
        let eligible = dataManager.activeBusinesses
            .filter { $0.isInsiderPick && !($0.insiderTip ?? "").isEmpty }
            .sorted { $0.id < $1.id }
        guard !eligible.isEmpty else { return nil }

        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(identifier: "America/Tegucigalpa") ?? .current
        let week = calendar.component(.weekOfYear, from: .now)
        let year = calendar.component(.yearForWeekOfYear, from: .now)
        let index = abs(year &* 53 &+ week) % eligible.count
        return eligible[index]
    }
}
