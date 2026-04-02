import SwiftUI

struct CruiseModeView: View {
    @Bindable var viewModel: CruiseViewModel
    @Environment(DataManager.self) private var dataManager
    @Environment(UnitPreference.self) private var unitPreference
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: String?
    @State private var tick = 0
    private let timer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    countdownHeader

                    portSelector
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 20)

                    categoryFilter
                        .padding(.bottom, 20)

                    businessList
                        .padding(.bottom, 40)
                }
            }
            .background(Color.riWhite)
            .navigationTitle("Cruise Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Haptics.select()
                        unitPreference.useMetric.toggle()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "ruler")
                                .font(.system(size: 13, weight: .medium))
                            Text(unitPreference.useMetric ? "km" : "mi")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundStyle(Color.riMint)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        viewModel.isActive = false
                        dismiss()
                    } label: {
                        Text("Exit")
                            .font(.riCaption(15))
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.riPink)
                    }
                }
            }
            .navigationDestination(for: Business.self) { business in
                BusinessDetailView(business: business)
            }
            .onReceive(timer) { _ in
                tick += 1
            }
        }
    }

    // MARK: - Countdown Header

    private var countdownHeader: some View {
        let urgency = viewModel.urgencyLevel

        return VStack(spacing: 0) {
            // Urgency banner — full width, prominent
            HStack(spacing: 8) {
                Image(systemName: urgency.icon)
                    .font(.system(size: 15, weight: .semibold))

                Text(urgency.message)
                    .font(.system(size: 15, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(urgency.color)

            // Time display
            VStack(spacing: 6) {
                Text("BACK ON BOARD BY")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.riLightGray)
                    .tracking(1.5)

                DatePicker("", selection: $viewModel.boardingTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .scaleEffect(1.1)
                    .onChange(of: viewModel.boardingTime) { _, _ in
                        Haptics.select()
                    }

                // Large countdown
                let _ = tick
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .font(.system(size: 22, weight: .medium))
                    Text(viewModel.timeRemainingFormatted)
                        .font(.system(size: 44, weight: .bold))
                        .tracking(-1.5)
                        .monospacedDigit()
                }
                .foregroundStyle(countdownColor)

                Text("remaining")
                    .font(.riCaption(13))
                    .foregroundStyle(Color.riLightGray)
            }
            .padding(.vertical, 16)
        }
    }

    private var countdownColor: Color {
        switch viewModel.urgencyLevel {
        case .expired, .critical: return .riPink
        case .urgent: return .orange
        case .moderate, .relaxed: return .riDark
        }
    }

    // MARK: - Port Selector

    private var portSelector: some View {
        HStack(spacing: 10) {
            ForEach(CruiseViewModel.CruisePort.allCases) { port in
                let isSelected = viewModel.selectedPort == port
                Button {
                    Haptics.select()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedPort = port
                        selectedCategory = nil
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "ferry")
                            .font(.system(size: 18, weight: .medium))
                        Text(port.displayName)
                            .font(.system(size: 14, weight: .bold))
                        Text(port.subtitle)
                            .font(.riCaption(11))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                    .foregroundStyle(isSelected ? .white : Color.riDark)
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 8)
                    .background(isSelected ? Color.riFixedDark : Color.riOffWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.riMint, lineWidth: isSelected ? 2 : 0)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }

                ForEach(["eat", "drink", "beaches", "dive", "shop", "tours"], id: \.self) { catId in
                    let displayName = Category(rawValue: catId)?.displayName ?? catId.capitalized
                    FilterChip(label: displayName, isSelected: selectedCategory == catId) {
                        selectedCategory = selectedCategory == catId ? nil : catId
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Business List

    private var businessList: some View {
        let portId = viewModel.selectedPort == .mahoganyBay ? "mahogany_bay" : "coxen_hole"
        let remoteAreaIds = dataManager.areaIds(nearPort: portId)
        let allFiltered = viewModel.filteredBusinesses(dataManager.businesses, nearbyAreaIds: remoteAreaIds.isEmpty ? nil : remoteAreaIds)
        let businesses = selectedCategory == nil
            ? allFiltered
            : allFiltered.filter { $0.hasCategory(selectedCategory!) }
        let visitable = businesses.filter { viewModel.canVisitAndReturn($0) }
        let tooFar = businesses.filter { !viewModel.canVisitAndReturn($0) }

        return VStack(spacing: 0) {
            if businesses.isEmpty {
                emptyState
            } else {
                // Visitable businesses
                if !visitable.isEmpty {
                    sectionLabel(
                        visitable.count == businesses.count ? "Nearby" : "You have time for",
                        icon: "checkmark.circle.fill",
                        color: .riMint
                    )

                    ForEach(visitable) { business in
                        CruiseBusinessRow(
                            business: business,
                            distance: viewModel.distanceFromPort(business, useMetric: unitPreference.useMetric),
                            travelTime: viewModel.travelTime(business),
                            canVisit: true,
                            isOpen: business.isOpenNow()
                        )
                    }
                }

                // Not enough time
                if !tooFar.isEmpty && !viewModel.isExpired {
                    sectionLabel(
                        "Not enough time",
                        icon: "clock.badge.xmark",
                        color: .riLightGray
                    )
                    .padding(.top, visitable.isEmpty ? 0 : 8)

                    ForEach(tooFar) { business in
                        CruiseBusinessRow(
                            business: business,
                            distance: viewModel.distanceFromPort(business, useMetric: unitPreference.useMetric),
                            travelTime: viewModel.travelTime(business),
                            canVisit: false,
                            isOpen: business.isOpenNow()
                        )
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    private func sectionLabel(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
            Text(title.uppercased())
                .font(.system(size: 12, weight: .bold))
                .tracking(1)
        }
        .foregroundStyle(color)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 12)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "ferry")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(Color.riLightGray)

            Text(viewModel.isExpired
                 ? "Time's up — head to the port!"
                 : "No matching businesses nearby")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.riMediumGray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

// MARK: - Business Row

private struct CruiseBusinessRow: View {
    let business: Business
    let distance: String
    let travelTime: String
    let canVisit: Bool
    let isOpen: Bool

    var body: some View {
        NavigationLink(value: business) {
            HStack(spacing: 14) {
                BusinessImageView(business: business, aspectRatio: 1)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 3) {
                    Text(business.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.riDark)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Text(business.categoryDisplayName)
                        Text("·")
                        Text(business.areaDisplayName)
                    }
                    .font(.riCaption(13))
                    .foregroundStyle(Color.riLightGray)

                    HStack(spacing: 10) {
                        Label(distance, systemImage: "location.fill")
                        Label(travelTime, systemImage: "car.fill")
                    }
                    .font(.riCaption(12))
                    .foregroundStyle(Color.riMediumGray)
                }

                Spacer(minLength: 4)

                // Right side status
                VStack(alignment: .trailing, spacing: 4) {
                    if isOpen {
                        Text("Open")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.riMint)
                    }

                    if !canVisit {
                        Text("Too far")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.riLightGray)
                    }
                }
            }
            .padding(.vertical, 12)
            .opacity(canVisit ? 1 : 0.4)
        }
        .buttonStyle(.plain)
    }
}
