import SwiftUI

/// Compact live-conditions block shown high on the Home tab. Designed to be
/// glanceable in under one second — four chips in a 2×2 grid, no chrome, no
/// headers. Each chip is decisive ("Snorkel: Good") rather than data-dumpy
/// ("0.4m wave height, 18kph wind") because cruise passengers have 6 hours
/// and zero patience.
struct LiveConditionsStrip: View {
    @Environment(WeatherService.self) private var weather

    var body: some View {
        Grid(horizontalSpacing: 10, verticalSpacing: 10) {
            GridRow {
                chip(symbol: weather.weatherSymbol, label: weather.temperatureLabel, sub: weather.weatherLabel)
                horizonChip
            }
            GridRow {
                chip(symbol: "water.waves", label: weather.snorkelLabel, sub: "Snorkel")
                chip(symbol: "sun.max.trianglebadge.exclamationmark.fill", label: weather.uvLabel, sub: "UV")
            }
        }
        .padding(.horizontal, 20)
        .task {
            await weather.refreshIfNeeded()
        }
    }

    private var horizonChip: some View {
        let event = SunsetCalculator.nextHorizonEvent()
        return chip(
            symbol: event.symbol,
            label: event.timeString,
            sub: event.countdown.map { "in \($0)" } ?? event.label
        )
    }

    private func chip(symbol: String, label: String, sub: String?) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.riMint)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.riDark)
                    .lineLimit(1)
                if let sub {
                    Text(sub)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color.riLightGray)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.riOffWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}
