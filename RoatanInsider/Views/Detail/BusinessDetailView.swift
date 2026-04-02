import SwiftUI
import MapKit

struct BusinessDetailView: View {
    let business: Business
    @Environment(FavoritesStore.self) private var favoritesStore
    @Environment(DataManager.self) private var dataManager

    /// Always use the latest version from DataManager (picks up remote updates)
    private var b: Business {
        dataManager.business(withId: business.id) ?? business
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Hero image
                PhotoGallery(images: b.images, categoryIconName: b.categoryIconName, categoryDisplayName: b.categoryDisplayName, slug: b.slug)
                    .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 20) {
                    // Title section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(b.name)
                                .riHeadlineStyle(26)
                                .foregroundStyle(Color.riDark)

                            Spacer()

                            FavoriteButton(businessId: b.id, onPhoto: false)
                        }

                        HStack(spacing: 6) {
                            Text(b.allCategories.map { $0.categoryDisplayName }.joined(separator: " · "))
                            Text("·")
                            Text(b.allAreaStrings.map { $0.replacingOccurrences(of: "_", with: " ").capitalized }.joined(separator: " · "))
                        }
                        .font(.riCaption(14))
                        .foregroundStyle(Color.riLightGray)

                        if b.allCategories.count > 1 {
                            FlowLayout(spacing: 6) {
                                ForEach(b.allCategories, id: \.self) { entry in
                                    HStack(spacing: 4) {
                                        Image(systemName: entry.categoryIconName)
                                            .font(.system(size: 11))
                                        Text(entry.subcategory)
                                    }
                                    .font(.riCaption(12))
                                    .foregroundStyle(Color.riMediumGray)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.riOffWhite)
                                    .clipShape(Capsule())
                                }
                            }
                        }

                        HStack(spacing: 12) {
                            if let rating = b.rating {
                                HStack(spacing: 4) {
                                    RatingView(rating: rating, size: 14)

                                    if let count = b.reviewCount, count > 0 {
                                        Text("(\(count))")
                                            .font(.riCaption(13))
                                            .foregroundStyle(Color.riLightGray)
                                    }
                                }
                            }
                            PriceRangeView(priceRange: b.priceRange)
                            OpenStatusBadge(business: b)
                        }
                    }

                    // Description
                    Text(b.description)
                        .font(.riBody)
                        .foregroundStyle(Color.riMediumGray)
                        .lineSpacing(6)

                    // Insider Tip
                    if let tip = b.insiderTip {
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
                    if !b.features.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Features")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.riDark)

                            FlowLayout(spacing: 8) {
                                ForEach(b.features, id: \.self) { feature in
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
                    ContactActions(business: b)

                    // Hours
                    if !b.hours.isEmpty {
                        hoursSection
                    } else if let hoursText = b.hoursText {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Hours")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.riDark)

                            Text(hoursText)
                                .font(.riCaption(14))
                                .foregroundStyle(Color.riMediumGray)
                        }
                    }

                    // Location(s)
                    VStack(alignment: .leading, spacing: 12) {
                        Text(b.allLocations.count > 1 ? "Locations" : "Location")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.riDark)

                        ForEach(b.allLocations, id: \.self) { location in
                            VStack(alignment: .leading, spacing: 8) {
                                if b.allLocations.count > 1 {
                                    Text(location.area.displayName)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(Color.riDark)
                                }

                                Text(location.addressDescription)
                                    .font(.riCaption(14))
                                    .foregroundStyle(Color.riMediumGray)

                                MiniMapView(coordinate: location.coordinate, name: b.name)
                                    .frame(height: 180)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .frame(maxWidth: .infinity)
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
                .accessibilityLabel("Share \(b.name)")
            }
        }
    }

    private func shareBusiness() {
        let shareText = "\(b.name) — \(b.categoryDisplayName) in \(b.areaDisplayName). \(b.insiderTip ?? b.description.prefix(100).description)"

        var items: [Any] = [shareText]

        if let image = ShareHelper.shareImage(for: b) {
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
                HStack {
                    Text(day.capitalized)
                        .font(.riCaption(14))
                        .fontWeight(day == today ? .semibold : .regular)
                        .foregroundStyle(day == today ? Color.riDark : Color.riMediumGray)
                        .frame(width: 100, alignment: .leading)

                    if let hours = b.hours[day] ?? nil {
                        Text("\(formatTime(hours.open)) – \(formatTime(hours.close))")
                            .font(.riCaption(14))
                            .foregroundStyle(day == today ? Color.riDark : Color.riLightGray)
                    } else {
                        Text("Closed")
                            .font(.riCaption(14))
                            .foregroundStyle(Color.riLightGray)
                    }
                }
            }
        }
    }

    /// Converts "14:00" to "2:00 PM", "08:00" to "8:00 AM"
    private func formatTime(_ time: String) -> String {
        let parts = time.split(separator: ":")
        guard parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]) else { return time }

        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        if minute == 0 {
            return "\(displayHour) \(period)"
        }
        return "\(displayHour):\(String(format: "%02d", minute)) \(period)"
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
