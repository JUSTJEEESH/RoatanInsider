import SwiftUI

/// Compact live-conditions row shown high on the Home tab. Designed to be
/// glanceable in under one second — five chips, no chrome, no headers.
/// Each chip is decisive ("Snorkel: Good") rather than data-dumpy ("0.4m
/// wave height, 18kph wind") because cruise passengers have 6 hours and
/// zero patience.
struct LiveConditionsStrip: View {
    @Environment(WeatherService.self) private var weather

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                chip(symbol: weather.weatherSymbol, label: weather.temperatureLabel, sub: weather.weatherLabel)
                chip(symbol: "sunset.fill", label: SunsetCalculator.sunsetTimeString(), sub: sunsetSubtitle)
                chip(symbol: "water.waves", label: weather.snorkelLabel, sub: "Snorkel")
                chip(symbol: "sun.max.trianglebadge.exclamationmark.fill", label: weather.uvLabel, sub: nil, compact: false)
            }
            .padding(.horizontal, 20)
        }
        .task {
            await weather.refreshIfNeeded()
        }
    }

    private var sunsetSubtitle: String {
        if let countdown = SunsetCalculator.sunsetCountdown() {
            return "in \(countdown)"
        }
        return "Tomorrow"
    }

    private func chip(symbol: String, label: String, sub: String?, compact: Bool = false) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.riMint)

            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.riDark)
                if let sub {
                    Text(sub)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color.riLightGray)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.riOffWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}
