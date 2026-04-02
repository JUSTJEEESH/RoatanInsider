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
