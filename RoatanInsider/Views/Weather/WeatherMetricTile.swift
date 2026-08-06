import SwiftUI

/// One tile in the metrics grid: a small labelled panel carrying a single
/// reading and, underneath it, the sentence that says what to do about it.
///
/// The shape is lifted from iOS Weather, which gets this right: a label you
/// can find by scanning, one large value, and a plain-language line that
/// turns the number into advice. The styling is this app's — flat off-white
/// surfaces, no glass, no gradients — so the screen still belongs to the
/// same product as everything around it.
struct WeatherMetricTile<Content: View>: View {
    let icon: String
    let label: String
    /// Optional line under the content. Skip it and the content fills.
    var footnote: String?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.Space.snug) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(label.uppercased())
                    .riType(.micro)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(Color.riMediumGray)

            content
                .frame(maxWidth: .infinity, alignment: .leading)

            if let footnote {
                Spacer(minLength: 0)
                Text(footnote)
                    .riType(.caption)
                    .foregroundStyle(Color.riMediumGray)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(AppConstants.Space.snug + 2)
        .frame(maxWidth: .infinity, minHeight: 148, alignment: .topLeading)
        .background(Color.riOffWhite)
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.card, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// The big number most tiles lead with.
struct WeatherMetricValue: View {
    let value: String
    var caption: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .riType(.display, weight: .bold)
                .monospacedDigit()
                .foregroundStyle(Color.riDark)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if let caption {
                Text(caption)
                    .riType(.body, weight: .semibold)
                    .foregroundStyle(Color.riDark)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }
}

// MARK: - UV scale

/// The UV band as discrete stops with a marker, rather than the rainbow
/// gradient iOS uses.
///
/// Same information, and it survives this app's no-gradients rule — but it's
/// also just more honest: UV bands *are* discrete (low, moderate, high, very
/// high, extreme), and a continuous smear implies a precision the index
/// doesn't have.
struct UVScaleBar: View {
    let index: Int

    private static let bands: [(upper: Int, color: Color)] = [
        (2, Color(hex: "4CAF50")),
        (5, Color(hex: "F5A623")),
        (7, Color(hex: "F57C00")),
        (10, Color(hex: "E31B4E")),
        (13, Color(hex: "8E24AA")),
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                HStack(spacing: 2) {
                    ForEach(Array(Self.bands.enumerated()), id: \.offset) { _, band in
                        Rectangle().fill(band.color)
                    }
                }
                .frame(height: 4)
                .clipShape(Capsule())

                Circle()
                    .fill(Color.riDark)
                    .frame(width: 8, height: 8)
                    .overlay(Circle().stroke(Color.riOffWhite, lineWidth: 2))
                    .offset(x: markerOffset(in: geo.size.width))
            }
            .frame(height: 8)
        }
        .frame(height: 8)
        .accessibilityHidden(true)
    }

    private func markerOffset(in width: CGFloat) -> CGFloat {
        let clamped = min(13, max(0, Double(index)))
        return CGFloat(clamped / 13) * (width - 8)
    }
}

// MARK: - Wind compass

/// A dial with the needle pointing the way the wind is going.
///
/// Meteorological wind direction names where it comes *from*, which is the
/// convention every forecast uses and also the one that confuses everyone.
/// The needle points downwind — the way it will push a boat — and the label
/// names the origin, which is how sailors and dive masters actually talk.
struct WindCompass: View {
    /// Direction the wind blows FROM, in degrees.
    let degrees: Double
    let speed: String

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                Circle()
                    .stroke(Color.riDark.opacity(0.12), lineWidth: 1)

                ForEach(["N", "E", "S", "W"], id: \.self) { point in
                    Text(point)
                        .riType(.micro, weight: .semibold)
                        .foregroundStyle(Color.riLightGray)
                        .offset(y: -side / 2 - 1)
                        .rotationEffect(.degrees(rotation(for: point)))
                }

                Text(speed)
                    .riType(.caption, weight: .semibold)
                    .monospacedDigit()
                    .foregroundStyle(Color.riDark)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Image(systemName: "arrowtriangle.up.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(Color.riPink)
                    .offset(y: -side / 2 + 5)
                    .rotationEffect(.degrees(degrees + 180))
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityHidden(true)
    }

    private func rotation(for point: String) -> Double {
        switch point {
        case "N": return 0
        case "E": return 90
        case "S": return 180
        default:  return 270
        }
    }

    /// "ENE" for 67°. The sixteen-point compass, which is how every marine
    /// forecast on this island states it.
    static func cardinal(_ degrees: Double) -> String {
        let points = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                      "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let normalised = degrees.truncatingRemainder(dividingBy: 360)
        let positive = normalised < 0 ? normalised + 360 : normalised
        let index = Int((positive / 22.5).rounded()) % 16
        return points[index]
    }
}

// MARK: - Moon

/// The lit portion of the disc, drawn rather than illustrated.
struct MoonPhaseDisc: View {
    let phase: MoonPhase

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                Circle().fill(Color.riDark.opacity(0.10))
                Circle()
                    .fill(Color.riLightGray.opacity(0.9))
                    .mask(alignment: .center) { litMask(side: side) }
                Circle().stroke(Color.riDark.opacity(0.12), lineWidth: 1)
            }
            .frame(width: side, height: side)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityHidden(true)
    }

    /// A circle with an ellipse carved out of it — the terminator is an
    /// ellipse whose width tracks illumination, which is what actually makes
    /// a drawn moon read as the right phase.
    private func litMask(side: CGFloat) -> some View {
        let illum = phase.illumination
        let terminator = abs(1 - 2 * illum) * side

        return ZStack {
            // The lit half.
            Rectangle()
                .frame(width: side / 2, height: side)
                .offset(x: phase.isWaxing ? side / 4 : -side / 4)

            // Then push the terminator across it.
            Ellipse()
                .frame(width: terminator, height: side)
                .blendMode(illum < 0.5 ? .destinationOut : .normal)
        }
        .compositingGroup()
        .frame(width: side, height: side)
    }
}
