import SwiftUI
import MapKit

struct MapTabView: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(LocationManager.self) private var locationManager
    @State private var viewModel = MapViewModel()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Map(position: $viewModel.cameraPosition) {
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

                // Category filter bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(
                            label: "All",
                            isSelected: viewModel.selectedCategory == nil
                        ) {
                            viewModel.selectedCategory = nil
                        }

                        ForEach(Category.allCases) { category in
                            FilterChip(
                                label: category.displayName,
                                isSelected: viewModel.selectedCategory == category
                            ) {
                                viewModel.selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .background(.ultraThinMaterial)
            }
            .overlay(alignment: .bottom) {
                if let business = viewModel.selectedBusiness {
                    MapPopupCard(business: business) {
                        viewModel.selectedBusiness = nil
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
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
