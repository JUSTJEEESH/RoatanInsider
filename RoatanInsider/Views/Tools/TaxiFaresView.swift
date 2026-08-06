import SwiftUI

/// What a taxi should cost, so nobody has to guess at the roadside.
///
/// Reads `taxi_fares.json`, which ships with routes but no numbers until
/// they're filled in. Everything here renders only what it actually holds: a
/// route with no fare never appears, a column with no fares anywhere never
/// draws, and if the file has nothing at all the whole screen becomes a note
/// saying so. There is no state in which this invents a price.
///
/// It names its source and the date it was checked, and admits when that
/// date is over a year old. Fares drift; a number with no provenance is
/// worth less than one you can go and verify.
struct TaxiFaresView: View {
    @State private var guide: TaxiFareGuide = .empty

    private var fares: [TaxiFare] { guide.publishedFares }
    private var showsColectivo: Bool { fares.contains { $0.colectivoUSD != nil } }
    private var showsPrivate: Bool { fares.contains { $0.privateUSD != nil } }

    var body: some View {
        VStack(spacing: 0) {
            ToolHeader(
                icon: "car",
                title: "Taxi Fares",
                subtitle: "Agree the price before you get in — every time."
            )

            VStack(alignment: .leading, spacing: AppConstants.Space.block) {
                if fares.isEmpty {
                    unavailable
                } else {
                    rulesBlock
                    table
                    provenance
                }
            }
            .padding(.horizontal, AppConstants.Space.gutter)
            .padding(.bottom, AppConstants.Space.block)
        }
        .task {
            guide = Self.load()
            if let fresh = await Self.refresh() { guide = fresh }
        }
    }

    // MARK: - Rules

    @ViewBuilder
    private var rulesBlock: some View {
        if !guide.rules.isEmpty {
            VStack(alignment: .leading, spacing: AppConstants.Space.snug) {
                Text("HOW IT WORKS")
                    .riType(.label)
                    .foregroundStyle(Color.riMediumGray)

                VStack(alignment: .leading, spacing: AppConstants.Space.snug) {
                    ForEach(guide.rules, id: \.self) { rule in
                        HStack(alignment: .top, spacing: AppConstants.Space.snug) {
                            Circle()
                                .fill(Color.riMint)
                                .frame(width: 5, height: 5)
                                .padding(.top, 7)
                            Text(rule)
                                .riType(.caption)
                                .foregroundStyle(Color.riMediumGray)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    // MARK: - The table

    private var table: some View {
        VStack(alignment: .leading, spacing: AppConstants.Space.snug) {
            HStack(spacing: AppConstants.Space.snug) {
                Text("ROUTE")
                    .riType(.label)
                    .foregroundStyle(Color.riMediumGray)
                Spacer(minLength: 0)
                if showsColectivo {
                    Text("SHARED")
                        .riType(.micro)
                        .foregroundStyle(Color.riMediumGray)
                        .frame(width: 62, alignment: .trailing)
                }
                if showsPrivate {
                    Text("PRIVATE")
                        .riType(.micro)
                        .foregroundStyle(Color.riMediumGray)
                        .frame(width: 62, alignment: .trailing)
                }
            }

            VStack(spacing: 0) {
                ForEach(Array(fares.enumerated()), id: \.element.id) { index, fare in
                    if index > 0 {
                        Divider().overlay(Color.riDark.opacity(0.08))
                    }
                    row(fare)
                }
            }

            if showsColectivo && showsPrivate {
                Text("Shared is per person. Private is the whole car.")
                    .riType(.caption)
                    .foregroundStyle(Color.riLightGray)
                    .padding(.top, AppConstants.Space.hair)
            }
        }
    }

    private func row(_ fare: TaxiFare) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppConstants.Space.snug) {
            VStack(alignment: .leading, spacing: 2) {
                Text(fare.routeLabel)
                    .riType(.body, weight: .medium)
                    .foregroundStyle(Color.riDark)
                    .fixedSize(horizontal: false, vertical: true)
                if let note = fare.note, !note.isEmpty {
                    Text(note)
                        .riType(.caption)
                        .foregroundStyle(Color.riLightGray)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: AppConstants.Space.tight)

            if showsColectivo {
                amount(fare.colectivoUSD)
            }
            if showsPrivate {
                amount(fare.privateUSD, emphasised: !showsColectivo)
            }
        }
        .padding(.vertical, AppConstants.Space.snug)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel(fare))
    }

    /// An em dash where a fare is missing, so the column stays aligned and
    /// the gap reads as "we don't know" rather than "free".
    private func amount(_ value: Double?, emphasised: Bool = false) -> some View {
        Text(value.map(TaxiFare.formatted) ?? "—")
            .riType(.body, weight: value == nil ? .regular : .semibold)
            .monospacedDigit()
            .foregroundStyle(value == nil ? Color.riLightGray : Color.riDark)
            .frame(width: 62, alignment: .trailing)
    }

    private func accessibilityLabel(_ fare: TaxiFare) -> String {
        var parts = [fare.routeLabel]
        if let shared = fare.colectivoUSD {
            parts.append("shared \(TaxiFare.formatted(shared)) per person")
        }
        if let priv = fare.privateUSD {
            parts.append("private \(TaxiFare.formatted(priv))")
        }
        if let note = fare.note, !note.isEmpty { parts.append(note) }
        return parts.joined(separator: ", ")
    }

    // MARK: - Provenance

    private var provenance: some View {
        VStack(alignment: .leading, spacing: 3) {
            if !guide.source.isEmpty {
                Text("Fares from \(guide.source)\(guide.updated.isEmpty ? "" : ", checked \(guide.updated)").")
                    .riType(.caption)
                    .foregroundStyle(Color.riLightGray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if guide.isStale {
                Text("These haven't been checked in a while — treat them as a guide, not a quote.")
                    .riType(.caption)
                    .foregroundStyle(Color.riMediumGray)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Drivers can charge more after dark or off the main road. This is what the run usually costs, not a fixed price.")
                    .riType(.caption)
                    .foregroundStyle(Color.riLightGray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var unavailable: some View {
        EmptyStateView(
            symbol: "car",
            title: "No fares yet",
            message: "We'd rather show nothing than a number that's wrong. Ask your hotel what a run should cost, and always agree it before you get in."
        )
    }

    // MARK: - Loading

    /// Remote-first, like every other data file, with the bundled copy as
    /// the offline fallback.
    ///
    /// This was bundle-only on the reasoning that fares are editorial rather
    /// than live. That held right up until the file shipped with every price
    /// null: gathering the numbers is the remaining work, and tying each
    /// batch of them to an App Store release is the difference between a
    /// screen that fills in over a week and one that fills in whenever the
    /// next build happens to go out.
    static func load() -> TaxiFareGuide {
        RemoteDataService.loadCachedOrBundled(
            filename: "taxi_fares.json", bundleName: "taxi_fares", type: TaxiFareGuide.self
        ) ?? .empty
    }

    /// Fares change slowly, so this is a day — same reasoning as dive sites.
    static func refresh() async -> TaxiFareGuide? {
        await RemoteDataService.fetchLatest(
            filename: "taxi_fares.json", maxAge: 24 * 3600, type: TaxiFareGuide.self
        )
    }
}
