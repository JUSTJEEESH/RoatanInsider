import SwiftUI
import MapKit

struct MapTabView: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(LocationManager.self) private var locationManager
    @Environment(NetworkMonitor.self) private var networkMonitor
    @State private var viewModel = MapViewModel()

    private var isOffline: Bool { !networkMonitor.isConnected }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Map(position: $viewModel.cameraPosition) {
                    if !isOffline && viewModel.isShowingAppleResults {
                        // Online: Apple Maps search results
                        ForEach(viewModel.searchResults, id: \.self) { item in
                            Annotation(item.name ?? "", coordinate: item.placemark.coordinate) {
                                AppleResultPinView(
                                    iconName: viewModel.selectedCategory?.iconName ?? "mappin",
                                    isSelected: viewModel.selectedMapItem == item
                                )
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        viewModel.selectedMapItem = item
                                    }
                                }
                            }
                        }
                    } else if isOffline {
                        // Offline fallback: our bundled business pins
                        let businesses = viewModel.filteredBusinesses(from: dataManager.businesses)
                        ForEach(businesses) { business in
                            Annotation(business.name, coordinate: business.coordinate) {
                                MapPinView(
                                    business: business,
                                    isSelected: viewModel.selectedBusiness?.id == business.id
                                )
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        viewModel.selectedBusiness = business
                                        viewModel.selectedMapItem = nil
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

                // Search bar + category filters
                VStack(spacing: 0) {
                    if !isOffline {
                        MapSearchBar(
                            query: $viewModel.searchQuery,
                            isSearching: viewModel.isSearching
                        ) {
                            viewModel.submitSearch()
                        } onClear: {
                            viewModel.clearSearch()
                            viewModel.selectedCategory = nil
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(
                                label: "All",
                                isSelected: viewModel.selectedCategory == nil && !viewModel.isShowingAppleResults
                            ) {
                                viewModel.selectCategory(nil)
                            }

                            ForEach(Category.allCases) { category in
                                FilterChip(
                                    label: category.displayName,
                                    isSelected: viewModel.selectedCategory == category
                                ) {
                                    if isOffline {
                                        viewModel.selectedCategory = category
                                    } else {
                                        viewModel.selectCategory(category)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
                .background(.ultraThinMaterial)
            }
            .overlay(alignment: .bottom) {
                if isOffline {
                    // Offline: show bundled business popup
                    if let business = viewModel.selectedBusiness {
                        MapPopupCard(business: business) {
                            viewModel.selectedBusiness = nil
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                } else if let item = viewModel.selectedMapItem {
                    // Online: show Apple Maps result popup
                    MapItemPopupCard(mapItem: item) {
                        viewModel.selectedMapItem = nil
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .overlay(alignment: .top) {
                if isOffline {
                    HStack(spacing: 6) {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 12, weight: .medium))
                        Text("Offline — showing saved locations")
                            .font(.riCaption(13))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.riDark.opacity(0.85))
                    .clipShape(Capsule())
                    .padding(.top, 100)
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
            .navigationDestination(for: Business.self) { business in
                BusinessDetailView(business: business)
            }
            .onAppear {
                locationManager.requestPermission()
            }
        }
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

            TextField("Search businesses, keywords...", text: $query)
                .font(.riBody(15))
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
