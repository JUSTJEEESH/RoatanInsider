import SwiftUI

/// The sun's day as an arc, with a marker where it currently is.
///
/// Roatán sits near the tropics, so the day length barely moves through the
/// year and a clock time alone tells you very little. What people want here
/// is "how much light is left", and a position along an arc answers that in
/// one glance where "5:42 PM" needs arithmetic.
///
/// The arc is drawn, not decorated: no gradient fill, no glow. Elapsed
/// daylight is a solid line, the rest is faint, and the marker sits on the
/// curve. After dark the whole thing goes quiet and the label switches to
/// tomorrow's sunrise, because a sun marker parked at the horizon all night
/// is a widget pretending to be information.
struct SunArcView: View {
    var now: Date = .now

    private var sunrise: Date { SunsetCalculator.todaySunrise() }
    private var sunset: Date { SunsetCalculator.todaySunset() }

    /// 0 before dawn, 1 after dusk, position through the daylight hours
    /// between.
    private var progress: Double {
        let total = sunset.timeIntervalSince(sunrise)
        guard total > 0 else { return 0 }
        return min(1, max(0, now.timeIntervalSince(sunrise) / total))
    }

    private var isDaylight: Bool { now >= sunrise && now <= sunset }

    var body: some View {
        VStack(alignment: .leading, spacing: AppConstants.Space.snug) {
            Text("THE LIGHT")
                .riType(.label)
                .foregroundStyle(Color.riMediumGray)

            VStack(alignment: .leading, spacing: AppConstants.Space.tight) {
                Text(headline)
                    .riType(.heading)
                    .foregroundStyle(Color.riDark)

                arc
                    .frame(height: 78)
                    .padding(.top, AppConstants.Space.hair)

                HStack {
                    endpoint(label: "Sunrise", time: SunsetCalculator.todaySunrise())
                    Spacer()
                    endpoint(label: "Sunset", time: SunsetCalculator.todaySunset(), alignment: .trailing)
                }
            }
        }
        .padding(.horizontal, AppConstants.Space.gutter)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    // MARK: - The curve

    private var arc: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let baseline = h - 10

            ZStack(alignment: .topLeading) {
                // The whole day, faint.
                SunPath()
                    .stroke(Color.riDark.opacity(0.12), style: .init(lineWidth: 1.5, lineCap: .round))

                // Daylight already spent, solid.
                SunPath()
                    .trim(from: 0, to: isDaylight ? progress : (now > sunset ? 1 : 0))
                    .stroke(Color.riDark.opacity(0.5), style: .init(lineWidth: 1.5, lineCap: .round))

                // The horizon the arc rises from and sets back to.
                Path { p in
                    p.move(to: CGPoint(x: 0, y: baseline))
                    p.addLine(to: CGPoint(x: w, y: baseline))
                }
                .stroke(Color.riDark.opacity(0.12), style: .init(lineWidth: 1, dash: [2, 3]))

                if isDaylight {
                    Circle()
                        .fill(Color.riGoldStar)
                        .frame(width: 9, height: 9)
                        .position(SunPath.point(at: progress, in: geo.size))
                }
            }
        }
    }

    private func endpoint(label: String, time: Date, alignment: HorizontalAlignment = .leading) -> some View {
        VStack(alignment: alignment, spacing: 1) {
            Text(label.uppercased())
                .riType(.micro)
                .foregroundStyle(Color.riLightGray)
            Text(Self.timeLabel(time))
                .riType(.caption, weight: .semibold)
                .monospacedDigit()
                .foregroundStyle(Color.riDark)
        }
    }

    // MARK: - Copy

    private var headline: String {
        if !isDaylight {
            return now > sunset
                ? "Sun's down. Up again at \(Self.timeLabel(SunsetCalculator.tomorrowSunrise()))"
                : "Before dawn. First light at \(Self.timeLabel(sunrise))"
        }
        guard let remaining = SunsetCalculator.sunsetCountdown() else {
            return "Daylight"
        }
        return "\(remaining) of daylight left"
    }

    private var accessibilityDescription: String {
        "\(headline). Sunrise \(Self.timeLabel(sunrise)), sunset \(Self.timeLabel(sunset))."
    }

    static func timeLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        formatter.timeZone = TimeZone(identifier: "America/Tegucigalpa")
        return formatter.string(from: date)
    }
}

/// A half-ellipse from the horizon at the left, over the top, back down to
/// the horizon at the right. Kept as its own shape so the marker and the
/// stroke can't drift apart — both read the same curve.
private struct SunPath: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let steps = 60
        for step in 0...steps {
            let point = Self.point(at: Double(step) / Double(steps), in: rect.size)
            step == 0 ? path.move(to: point) : path.addLine(to: point)
        }
        return path
    }

    /// `t` runs 0 at sunrise to 1 at sunset.
    static func point(at t: Double, in size: CGSize) -> CGPoint {
        let baseline = size.height - 10
        let inset: CGFloat = 6
        let width = max(1, size.width - inset * 2)
        let x = inset + width * t
        // sin() gives a natural rise and fall, peaking at solar noon.
        let y = baseline - CGFloat(sin(t * .pi)) * (baseline - 6)
        return CGPoint(x: x, y: y)
    }
}
