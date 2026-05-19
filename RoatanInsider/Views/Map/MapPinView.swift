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

struct AppleResultPinView: View {
    let iconName: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(Color.riPink)
                    .frame(width: isSelected ? 36 : 28, height: isSelected ? 36 : 28)

                Image(systemName: iconName)
                    .font(.system(size: isSelected ? 16 : 12, weight: .medium))
                    .foregroundStyle(.white)
            }

            Triangle()
                .fill(Color.riPink)
                .frame(width: 12, height: 6)
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
                .font(.system(size: count >= 100 ? 14 : 16, weight: .bold))
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
