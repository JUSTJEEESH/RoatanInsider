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
            VStack(spacing: 0) {
                // Custom header matching other tabs
                VStack(alignment: .leading, spacing: 2) {
                    Text("Map")
                        .riDisplayStyle(34)
                        .foregroundStyle(Color.riDark)
                    Text("See what's around you")
                        .font(.riCaption(15))
                        .foregroundStyle(Color.riLightGray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 12)
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

                        ForEach(Category.allCases) { category in
                            FilterChip(
                                label: category.displayName,
                                isSelected: viewModel.selectedCategory == category
                            ) {
                                viewModel.selectCategory(category)
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
            .navigationDestination(for: Business.self) { business in
                BusinessDetailView(business: business)
            }
            .onAppear {
                locationManager.requestPermission()
            }
        }
    }

    private func pinIcon(for category: Category?) -> String {
        category?.iconName ?? "mappin"
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
                .font(.system(size: 15, weight: .regular))
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
