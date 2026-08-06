import SwiftUI

struct MapPinView: View {
    let business: Business
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color.riPink)
                    .frame(width: isSelected ? 36 : 28, height: isSelected ? 36 : 28)

                Image(systemName: business.categoryIconName)
                    .font(.system(size: isSelected ? 16 : 12, weight: .medium))
                    .foregroundStyle(.white)
            }

            // Pin tail
            Triangle()
                .fill(Color.riPink)
                .frame(width: 12, height: 6)
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

/// An Apple Maps result, drawn deliberately unlike ours.
///
/// It used to be the same pink circle as a guide pin, which meant a visitor
/// couldn't tell whose recommendation they were looking at. These are
/// outlined and grey: useful, but not something we vouch for.
struct AppleResultPinView: View {
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color.riWhite)
                    .frame(width: isSelected ? 30 : 24, height: isSelected ? 30 : 24)
                Circle()
                    .stroke(Color.riMediumGray, lineWidth: 1.5)
                    .frame(width: isSelected ? 30 : 24, height: isSelected ? 30 : 24)
                Image(systemName: "mappin")
                    .font(.system(size: isSelected ? 13 : 11, weight: .semibold))
                    .foregroundStyle(Color.riMediumGray)
            }
            Triangle()
                .fill(Color.riMediumGray)
                .frame(width: 8, height: 5)
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

/// A dive site. Mint rather than pink, because it's a different kind of
/// thing from a business and the map should say so before you tap it.
struct DiveSitePinView: View {
    let site: DiveSite
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color.riMint)
                    .frame(width: isSelected ? 34 : 26, height: isSelected ? 34 : 26)
                Image(systemName: site.kind?.iconName ?? "water.waves")
                    .font(.system(size: isSelected ? 15 : 11, weight: .medium))
                    .foregroundStyle(.white)
            }
            Triangle()
                .fill(Color.riMint)
                .frame(width: 11, height: 6)
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

struct ClusterPinView: View {
    let count: Int

    var body: some View {
        let size: CGFloat = count >= 30 ? 52 : (count >= 10 ? 46 : 40)

        ZStack {
            Circle()
                .fill(Color.riPink)
                .frame(width: size, height: size)
            Circle()
                .stroke(Color.white, lineWidth: 3)
                .frame(width: size, height: size)
            Text("\(count)")
                .riType(count >= 100 ? .caption : .body, weight: .bold)
                .foregroundStyle(.white)
                .monospacedDigit()
        }
        .shadow(color: .black.opacity(0.25), radius: 4, x: 0, y: 2)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}
