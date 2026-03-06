import SwiftUI
import MapKit

struct BusinessDetailView: View {
    let business: Business
    @Environment(FavoritesStore.self) private var favoritesStore

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Hero image
                PhotoGallery(images: business.images, category: business.category, slug: business.slug)

                VStack(alignment: .leading, spacing: 20) {
                    // Title section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(business.name)
                                .riHeadlineStyle(26)
                                .foregroundStyle(Color.riDark)

                            Spacer()

                            FavoriteButton(businessId: business.id, onPhoto: false)
                        }

                        HStack(spacing: 6) {
                            Text(business.category.displayName)
                            Text("·")
                            Text(business.subcategory)
                            Text("·")
                            Text(business.area.displayName)
                        }
                        .font(.riCaption(14))
                        .foregroundStyle(Color.riLightGray)

                        HStack(spacing: 12) {
                            PriceRangeView(priceRange: business.priceRange)
                            OpenStatusBadge(business: business)
                        }
                    }

                    // Description
                    Text(business.description)
                        .font(.riBody)
                        .foregroundStyle(Color.riMediumGray)
                        .lineSpacing(6)

                    // Insider Tip
                    if let tip = business.insiderTip {
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.riMint)
                                .frame(width: 3)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Insider Tip")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color.riMint)

                                Text(tip)
                                    .font(.riCaption(14))
                                    .foregroundStyle(Color.riMediumGray)
                                    .italic()
                            }
                            .padding(.leading, 12)
                        }
                    }

                    // Features
                    if !business.features.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Features")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.riDark)

                            FlowLayout(spacing: 8) {
                                ForEach(business.features, id: \.self) { feature in
                                    Text(feature)
                                        .font(.riCaption(13))
                                        .foregroundStyle(Color.riMediumGray)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.riOffWhite)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    // Contact actions
                    ContactActions(business: business)

                    // Hours
                    if !business.hours.isEmpty {
                        hoursSection
                    }

                    // Location
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Location")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.riDark)

                        Text(business.addressDescription)
                            .font(.riCaption(14))
                            .foregroundStyle(Color.riMediumGray)

                        MiniMapView(coordinate: business.coordinate, name: business.name)
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(20)
            }
        }
        .background(Color.riWhite)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.impact()
                    shareBusiness()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.riDark)
                }
                .accessibilityLabel("Share \(business.name)")
            }
        }
    }

    private func shareBusiness() {
        let shareText = "\(business.name) — \(business.category.displayName) in \(business.area.displayName). \(business.insiderTip ?? business.description.prefix(100).description)"

        var items: [Any] = [shareText]

        if let image = ShareHelper.shareImage(for: business) {
            items.insert(image, at: 0)
        }

        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

    private var hoursSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Hours")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.riDark)

            let days = ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"]
            let today = Date().currentDayKey

            ForEach(days, id: \.self) { day in
                if let hours = business.hours[day] ?? nil {
                    HStack {
                        Text(day.capitalized)
                            .font(.riCaption(14))
                            .fontWeight(day == today ? .semibold : .regular)
                            .foregroundStyle(day == today ? Color.riDark : Color.riMediumGray)
                            .frame(width: 100, alignment: .leading)

                        Text("\(hours.open) – \(hours.close)")
                            .font(.riCaption(14))
                            .foregroundStyle(day == today ? Color.riDark : Color.riLightGray)
                    }
                }
            }
        }
    }
}

// Simple flow layout for feature tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
