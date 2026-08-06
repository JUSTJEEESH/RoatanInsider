import SwiftUI
import MapKit

struct MapTabView: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(LocationManager.self) private var locationManager
    @Environment(NetworkMonitor.self) private var networkMonitor
    @State private var viewModel = MapViewModel()
    @State private var showNearby = false

    private var isOffline: Bool { !networkMonitor.isConnected }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom header matching other tabs
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Map")
                            .riType(.display)
                            .foregroundStyle(Color.riDark)
                        Text("See what's around you")
                            .riType(.caption)
                            .foregroundStyle(Color.riMediumGray)
                    }

                    Spacer()

                    // The island has no street addresses, so "what's within
                    // walking distance" is the question people actually have
                    // standing on a road here.
                    Button {
                        Haptics.tap()
                        showNearby = true
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Near me")
                                .riType(.caption, weight: .semibold)
                        }
                        .foregroundStyle(Color.riDark)
                        .padding(.horizontal, AppConstants.Space.snug + 2)
                        .padding(.vertical, AppConstants.Space.tight)
                        .background(Color.riOffWhite)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("What's near me")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppConstants.Space.gutter)
                .padding(.top, AppConstants.Space.snug)
                .padding(.bottom, 6)

                MapSearchBar(
                    query: $viewModel.searchQuery,
                    isSearching: viewModel.isSearching
                ) {
                    viewModel.submitSearch()
                } onClear: {
                    viewModel.clearSearch()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 4)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(
                            label: "All",
                            isSelected: viewModel.selectedCategory == nil
                        ) {
                            viewModel.selectCategory(nil)
                        }

                        ForEach(dataManager.categoryInfos) { info in
                            FilterChip(
                                label: info.displayName,
                                isSelected: viewModel.selectedCategory == info.id
                            ) {
                                viewModel.selectCategory(info.id)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }

                // Map fills remaining space
                ZStack {
                    Map(position: $viewModel.cameraPosition, interactionModes: .all) {
                        if !isOffline && viewModel.isShowingAppleResults {
                            ForEach(viewModel.searchResults, id: \.self) { item in
                                Annotation(item.name ?? "", coordinate: item.placemark.coordinate) {
                                    AppleResultPinView(
                                        iconName: pinIcon(for: viewModel.selectedCategory),
                                        isSelected: viewModel.selectedMapItem == item
                                    )
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            viewModel.selectedMapItem = item
                                            viewModel.selectedBusiness = nil
                                        }
                                    }
                                }
                            }
                        } else if isOffline {
                            let businesses = viewModel.filteredBusinesses(from: dataManager.businesses)
                            let clusters = MapClusterer.cluster(businesses, span: viewModel.visibleSpan)
                            ForEach(clusters) { pin in
                                Annotation(pin.isCluster ? "\(pin.count) places" : pin.representative.name, coordinate: pin.coordinate) {
                                    Group {
                                        if pin.isCluster {
                                            ClusterPinView(count: pin.count)
                                                .onTapGesture {
                                                    Haptics.tap()
                                                    withAnimation(.easeInOut(duration: 0.35)) {
                                                        viewModel.zoom(to: MapClusterer.zoomInRegion(for: pin, currentSpan: viewModel.visibleSpan))
                                                    }
                                                }
                                        } else {
                                            MapPinView(
                                                business: pin.representative,
                                                isSelected: viewModel.selectedBusiness?.id == pin.representative.id
                                            )
                                            .onTapGesture {
                                                Analytics.track(.mapPinTapped(id: pin.representative.id))
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    viewModel.selectedBusiness = pin.representative
                                                    viewModel.selectedMapItem = nil
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        UserAnnotation()
                    }
                    .mapStyle(.standard)
                    .mapControls {
                        MapUserLocationButton()
                        MapCompass()
                        MapScaleView()
                    }
                    .onMapCameraChange(frequency: .onEnd) { context in
                        viewModel.visibleSpan = context.region.span
                    }
                }
                .overlay(alignment: .bottom) {
                    if let mapItem = viewModel.selectedMapItem {
                        MapItemPopupCard(mapItem: mapItem) {
                            viewModel.selectedMapItem = nil
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if let business = viewModel.selectedBusiness {
                        MapPopupCard(business: business) {
                            viewModel.selectedBusiness = nil
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .overlay(alignment: .center) {
                    if viewModel.isSearching {
                        ProgressView()
                            .padding(16)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .background(Color.riWhite)
            .navigationBarHidden(true)
            .sheet(isPresented: $showNearby) {
                NearbySheet(businesses: dataManager.businesses)
            }
            .navigationDestination(for: Business.self) { business in
                BusinessDetailView(business: business)
            }
            .onAppear {
                locationManager.requestPermission()
            }
        }
    }

    private func pinIcon(for categoryId: String?) -> String {
        guard let id = categoryId else { return "mappin" }
        return dataManager.categoryInfo(for: id)?.iconName
            ?? Category(rawValue: id)?.iconName
            ?? "mappin"
    }
}

// MARK: - Search Bar

struct MapSearchBar: View {
    @Binding var query: String
    let isSearching: Bool
    let onSubmit: () -> Void
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.riLightGray)
                .font(.system(size: 15, weight: .medium))

            TextField("Search places on Roatán...", text: $query)
                .riType(.body)
                .submitLabel(.search)
                .onSubmit(onSubmit)

            if !query.isEmpty {
                Button {
                    onClear()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.riLightGray)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
