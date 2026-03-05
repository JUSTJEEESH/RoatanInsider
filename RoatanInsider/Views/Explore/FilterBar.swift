import SwiftUI

struct FilterBar: View {
    @Bindable var searchEngine: SearchEngine

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Category chips
                ForEach(Category.allCases) { category in
                    FilterChip(
                        label: category.displayName,
                        isSelected: searchEngine.selectedCategories.contains(category)
                    ) {
                        if searchEngine.selectedCategories.contains(category) {
                            searchEngine.selectedCategories.remove(category)
                        } else {
                            searchEngine.selectedCategories.insert(category)
                        }
                    }
                }

                Divider()
                    .frame(height: 24)

                // Open Now
                FilterChip(
                    label: "Open Now",
                    isSelected: searchEngine.showOpenNow
                ) {
                    searchEngine.showOpenNow.toggle()
                }

                // Price range chips
                ForEach(1...4, id: \.self) { price in
                    FilterChip(
                        label: String(repeating: "$", count: price),
                        isSelected: searchEngine.selectedPriceRanges.contains(price)
                    ) {
                        if searchEngine.selectedPriceRanges.contains(price) {
                            searchEngine.selectedPriceRanges.remove(price)
                        } else {
                            searchEngine.selectedPriceRanges.insert(price)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.riCaption(14))
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? .white : Color.riMediumGray)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.riDark : Color.riOffWhite)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
