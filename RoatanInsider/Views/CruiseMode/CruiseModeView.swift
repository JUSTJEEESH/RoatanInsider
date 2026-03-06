import SwiftUI

struct CruiseModeView: View {
    @Bindable var viewModel: CruiseViewModel
    @Environment(DataManager.self) private var dataManager
    @State private var selectedCategory: Category?
    @State private var timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Countdown header
                    countdownHeader
                        .padding(.bottom, 24)

                    // Port selector
                    portSelector
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)

                    // Quick categories
                    categoryFilter
                        .padding(.bottom, 16)

                    // Nearby businesses
                    businessList
                }
            }
            .background(Color.riWhite)
            .navigationTitle("Cruise Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Haptics.tap()
                        viewModel.isActive = false
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
                // Force view update for countdown
            }
        }
    }

    // MARK: - Countdown Header

    private var countdownHeader: some View {
        VStack(spacing: 12) {
            // Urgency banner
            HStack(spacing: 8) {
                Image(systemName: viewModel.isUrgent ? "exclamationmark.triangle.fill" : "clock.fill")
                    .font(.system(size: 14, weight: .medium))

                Text(viewModel.urgencyMessage)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(viewModel.isExpired ? Color.riPink : (viewModel.isUrgent ? Color.orange : Color.riMint))

            // Time display
            VStack(spacing: 4) {
                Text("BACK ON BOARD BY")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.riLightGray)
                    .tracking(1.5)

                // Boarding time picker
                DatePicker("", selection: $viewModel.boardingTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .scaleEffect(1.2)
                    .onChange(of: viewModel.boardingTime) { _, _ in
                        Haptics.select()
                    }

                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.system(size: 18, weight: .medium))
                    Text(viewModel.timeRemainingFormatted)
                        .font(.system(size: 36, weight: .bold))
                        .tracking(-1)
                }
                .foregroundStyle(viewModel.isUrgent ? Color.riPink : Color.riDark)

                Text("remaining")
                    .font(.riCaption(13))
                    .foregroundStyle(Color.riLightGray)
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Port Selector

    private var portSelector: some View {
        VStack(spacing: 12) {
            Text("YOUR PORT")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.riLightGray)
                .tracking(1.5)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 10) {
                ForEach(CruiseViewModel.CruisePort.allCases) { port in
                    Button {
                        Haptics.select()
                        viewModel.selectedPort = port
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "ferry")
                                .font(.system(size: 18, weight: .medium))
                            Text(port.displayName)
                                .font(.system(size: 14, weight: .semibold))
                            Text(port.subtitle)
                                .font(.riCaption(11))
                                .lineLimit(1)
                        }
                        .foregroundStyle(viewModel.selectedPort == port ? .white : Color.riDark)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(viewModel.selectedPort == port ? Color.riDark : Color.riOffWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
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

                ForEach([Category.eat, .drink, .beaches, .dive, .shop, .tours], id: \.self) { category in
                    FilterChip(label: category.displayName, isSelected: selectedCategory == category) {
                        selectedCategory = selectedCategory == category ? nil : category
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Business List

    private var businessList: some View {
        let businesses = viewModel.filteredBusinesses(dataManager.businesses)
        let filtered = selectedCategory == nil ? businesses : businesses.filter { $0.category == selectedCategory }

        return LazyVStack(spacing: 0) {
            ForEach(filtered.prefix(30)) { business in
                CruiseBusinessRow(
                    business: business,
                    distance: viewModel.distanceFromPort(business),
                    travelTime: viewModel.travelTime(business),
                    canVisit: viewModel.canVisitAndReturn(business)
                )
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Business Row

private struct CruiseBusinessRow: View {
    let business: Business
    let distance: String
    let travelTime: String
    let canVisit: Bool

    var body: some View {
        NavigationLink(value: business) {
            HStack(spacing: 14) {
                // Thumbnail
                BusinessImageView(business: business, aspectRatio: 1)
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(business.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.riDark)
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Text(business.category.displayName)
                        Text("·")
                        Text(business.area.displayName)
                    }
                    .font(.riCaption(13))
                    .foregroundStyle(Color.riLightGray)

                    HStack(spacing: 8) {
                        Label(distance, systemImage: "location")
                        Label(travelTime, systemImage: "car")
                    }
                    .font(.riCaption(12))
                    .foregroundStyle(Color.riMediumGray)
                }

                Spacer()

                // Status
                VStack(spacing: 4) {
                    if business.isOpenNow() {
                        Text("Open")
                            .font(.riCaption(11))
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.riMint)
                    }

                    if !canVisit {
                        Image(systemName: "clock.badge.xmark")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.riPink.opacity(0.6))
                    }
                }
            }
            .padding(.vertical, 14)
            .overlay(alignment: .bottom) {
                Divider()
            }
            .opacity(canVisit ? 1 : 0.5)
        }
        .buttonStyle(.plain)
    }
}
