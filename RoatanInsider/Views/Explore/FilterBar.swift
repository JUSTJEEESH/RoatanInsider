import SwiftUI

struct FilterBar: View {
    @Bindable var searchEngine: SearchEngine
    var allFeatures: [String] = []
    @State private var showAreaSheet = false
    @State private var showFeatureSheet = false

    private static let popularFeatures = [
        "Family Friendly", "Beachfront", "PADI Certified",
        "Live Music", "Romantic", "Eco Friendly",
        "WiFi", "Pool", "Ocean View", "Budget Friendly"
    ]

    private var activeFilterCount: Int {
        searchEngine.selectedAreas.count + searchEngine.selectedFeatures.count
    }

    var body: some View {
        VStack(spacing: 8) {
            // Primary row: Categories + Open Now + Price
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
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

                    FilterChip(
                        label: "Open Now",
                        isSelected: searchEngine.showOpenNow
                    ) {
                        searchEngine.showOpenNow.toggle()
                    }

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

            // Secondary row: Area + Features + Clear
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Area dropdown chip
                    FilterChipDropdown(
                        label: "Area",
                        count: searchEngine.selectedAreas.count
                    ) {
                        showAreaSheet = true
                    }

                    // Feature dropdown chip
                    FilterChipDropdown(
                        label: "Features",
                        count: searchEngine.selectedFeatures.count
                    ) {
                        showFeatureSheet = true
                    }

                    Divider()
                        .frame(height: 24)

                    // Popular feature quick chips
                    ForEach(Self.popularFeatures, id: \.self) { feature in
                        FilterChip(
                            label: feature,
                            isSelected: searchEngine.selectedFeatures.contains(feature)
                        ) {
                            if searchEngine.selectedFeatures.contains(feature) {
                                searchEngine.selectedFeatures.remove(feature)
                            } else {
                                searchEngine.selectedFeatures.insert(feature)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            // Clear all button (only when filters are active)
            if searchEngine.hasActiveFilters {
                HStack {
                    Button {
                        Haptics.tap()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            searchEngine.clearFilters()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                            Text("Clear all filters")
                                .font(.riCaption(13))
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(Color.riPink)
                    }
                    .padding(.leading, 20)

                    Spacer()
                }
            }
        }
        .sheet(isPresented: $showAreaSheet) {
            AreaFilterSheet(searchEngine: searchEngine)
        }
        .sheet(isPresented: $showFeatureSheet) {
            FeatureFilterSheet(
                searchEngine: searchEngine,
                allFeatures: allFeatures
            )
        }
    }
}

// MARK: - Area Selection Sheet

struct AreaFilterSheet: View {
    @Bindable var searchEngine: SearchEngine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(Area.allCases) { area in
                    Button {
                        Haptics.tap()
                        if searchEngine.selectedAreas.contains(area) {
                            searchEngine.selectedAreas.remove(area)
                        } else {
                            searchEngine.selectedAreas.insert(area)
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(area.displayName)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(Color.riDark)

                                Text(area.bestFor)
                                    .font(.riCaption(13))
                                    .foregroundStyle(Color.riLightGray)
                                    .lineLimit(1)
                            }

                            Spacer()

                            if searchEngine.selectedAreas.contains(area) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.riMint)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Filter by Area")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.riPink)
                }
                ToolbarItem(placement: .topBarLeading) {
                    if !searchEngine.selectedAreas.isEmpty {
                        Button("Clear") {
                            searchEngine.selectedAreas.removeAll()
                        }
                        .foregroundStyle(Color.riLightGray)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Feature Selection Sheet

struct FeatureFilterSheet: View {
    @Bindable var searchEngine: SearchEngine
    let allFeatures: [String]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(allFeatures, id: \.self) { feature in
                    Button {
                        Haptics.tap()
                        if searchEngine.selectedFeatures.contains(feature) {
                            searchEngine.selectedFeatures.remove(feature)
                        } else {
                            searchEngine.selectedFeatures.insert(feature)
                        }
                    } label: {
                        HStack {
                            Text(feature)
                                .font(.system(size: 16, weight: .regular))
                                .foregroundStyle(Color.riDark)

                            Spacer()

                            if searchEngine.selectedFeatures.contains(feature) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.riMint)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Filter by Feature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.riPink)
                }
                ToolbarItem(placement: .topBarLeading) {
                    if !searchEngine.selectedFeatures.isEmpty {
                        Button("Clear") {
                            searchEngine.selectedFeatures.removeAll()
                        }
                        .foregroundStyle(Color.riLightGray)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Chip Components

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: { Haptics.tap(); action() }) {
            Text(label)
                .font(.riCaption(14))
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? .white : Color.riMediumGray)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.riPink : Color.riOffWhite)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct FilterChipDropdown: View {
    let label: String
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: { Haptics.tap(); action() }) {
            HStack(spacing: 4) {
                Text(label)
                if count > 0 {
                    Text("\(count)")
                        .font(.riCaption(11))
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(Color.riMint)
                        .clipShape(Circle())
                }
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
            }
            .font(.riCaption(14))
            .fontWeight(.medium)
            .foregroundStyle(count > 0 ? .white : Color.riMediumGray)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(count > 0 ? Color.riPink : Color.riOffWhite)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
