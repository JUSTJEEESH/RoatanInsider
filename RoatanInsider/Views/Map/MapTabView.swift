import SwiftUI
import MapKit

/// The island, with the guide on it.
///
/// This screen used to show Apple Maps results whenever it could reach the
/// network, and the app's own 94 places only when offline — so the guide's
/// curation, the entire reason the app exists, appeared exclusively when the
/// phone had no signal. Tapping "Eat" ran an Apple Maps search for
/// "restaurants" instead of filtering the twenty-three places written up in
/// the guide, and with no search running the map rendered nothing at all.
///
/// The directory is the map now, online and off. Category chips filter the
/// guide. Dive sites are a second layer. Apple's results appear only when a
/// text search finds nothing in the guide — drawn grey and labelled, so a
/// pharmacy Apple happens to know about never reads as something we picked.
struct MapTabView: View {
    @Environment(DataManager.self) private var dataManager
    @Environment(DiveSitesService.self) private var diveSites
    @Environment(LocationManager.self) private var locationManager
    @Environment(PurchaseManager.self) private var purchases
    @State private var viewModel = MapViewModel()
    @State private var showNearby = false
    @State private var showInView = false

    private var businesses: [Business] {
        viewModel.filteredBusinesses(from: dataManager.businesses)
    }

    private var sites: [DiveSite] {
        viewModel.filteredDiveSites(from: diveSites.sites)
    }

    /// Dive sites are Insider+, and the layer control only appears when
    /// there are sites to show at all.
    private var showsDiveLayer: Bool { diveSites.hasSites && purchases.hasPremium }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                searchBar
                controls
                mapBody
            }
            .background(Color.riWhite)
            .navigationBarHidden(true)
            .navigationDestination(for: Business.self) { BusinessDetailView(business: $0) }
            .navigationDestination(for: DiveSite.self) { DiveSiteDetailView(site: $0) }
            .sheet(isPresented: $showNearby) {
                NearbySheet(businesses: dataManager.businesses)
            }
            .sheet(isPresented: $showInView) {
                MapResultsSheet(
                    businesses: viewModel.layer == .places
                        ? viewModel.itemsInView(businesses, coordinate: { $0.coordinate }) : [],
                    diveSites: viewModel.layer == .diveSites
                        ? viewModel.itemsInView(sites, coordinate: { $0.coordinate }) : []
                )
            }
        }
    }

    // MARK: - Chrome

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Map")
                    .riType(.display)
                    .foregroundStyle(Color.riDark)
                Text(subtitle)
                    .riType(.caption)
                    .foregroundStyle(Color.riMediumGray)
            }

            Spacer()

            // The island has no street addresses, so "what's within walking
            // distance" is the question people actually have standing on a
            // road here.
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
    }

    private var subtitle: String {
        switch viewModel.layer {
        case .places:    return "\(businesses.count) places from the guide"
        case .diveSites: return "\(sites.count) dive sites on the reef"
        }
    }

    private var searchBar: some View {
        MapSearchBar(
            query: $viewModel.searchQuery,
            isSearching: viewModel.isSearching
        ) {
            viewModel.submitSearch(directoryMatches: businesses.count + sites.count)
        } onClear: {
            viewModel.clearSearch()
        }
        .padding(.horizontal, AppConstants.Space.gutter)
        .padding(.bottom, AppConstants.Space.hair)
    }

    @ViewBuilder
    private var controls: some View {
        if showsDiveLayer {
            HStack(spacing: AppConstants.Space.tight) {
                ForEach(MapViewModel.Layer.allCases) { option in
                    FilterChip(label: option.title, isSelected: viewModel.layer == option) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            viewModel.layer = option
                            viewModel.clearSelection()
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppConstants.Space.gutter)
            .padding(.top, AppConstants.Space.hair)
        }

        if viewModel.layer == .places {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppConstants.Space.tight) {
                    FilterChip(label: "All", isSelected: viewModel.selectedCategory == nil) {
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
                .padding(.horizontal, AppConstants.Space.gutter)
                .padding(.vertical, AppConstants.Space.tight)
            }
        }
    }

    // MARK: - The map

    private var mapBody: some View {
        Map(position: $viewModel.cameraPosition, interactionModes: .all) {
            if viewModel.layer == .places {
                placePins
            } else {
                divePins
            }

            // Apple's results, only when the guide came up empty on a text
            // search. Grey and outlined so they never read as a pick.
            ForEach(viewModel.searchResults, id: \.self) { item in
                Annotation(item.name ?? "", coordinate: item.placemark.coordinate) {
                    AppleResultPinView(isSelected: viewModel.selectedMapItem == item)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.clearSelection()
                                viewModel.selectedMapItem = item
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
            viewModel.visibleRegion = context.region
        }
        .overlay(alignment: .top) { inViewButton }
        .overlay(alignment: .bottom) { popup }
        .overlay(alignment: .center) {
            if viewModel.isSearching {
                ProgressView()
                    .padding(AppConstants.Space.gutter)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: AppConstants.Radius.small, style: .continuous))
            }
        }
    }

    @MapContentBuilder
    private var placePins: some MapContent {
        let clusters = MapClusterer.cluster(businesses, span: viewModel.visibleSpan)
        ForEach(clusters) { pin in
            Annotation(
                pin.isCluster ? "\(pin.count) places" : pin.representative.name,
                coordinate: pin.coordinate
            ) {
                Group {
                    if pin.isCluster {
                        ClusterPinView(count: pin.count)
                            .onTapGesture {
                                Haptics.tap()
                                withAnimation(.easeInOut(duration: 0.35)) {
                                    viewModel.zoom(to: MapClusterer.zoomInRegion(
                                        for: pin, currentSpan: viewModel.visibleSpan
                                    ))
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
                                viewModel.clearSelection()
                                viewModel.selectedBusiness = pin.representative
                            }
                        }
                    }
                }
            }
        }
    }

    @MapContentBuilder
    private var divePins: some MapContent {
        ForEach(sites) { site in
            Annotation(site.name, coordinate: site.coordinate) {
                DiveSitePinView(site: site, isSelected: viewModel.selectedDiveSite?.id == site.id)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.clearSelection()
                            viewModel.selectedDiveSite = site
                        }
                    }
            }
        }
    }

    // MARK: - Overlays

    /// Pan somewhere and this says what's under you, then hands you the
    /// list. More useful than "search this area" when the whole directory
    /// already fits on one screen.
    @ViewBuilder
    private var inViewButton: some View {
        let total = viewModel.layer == .places ? businesses.count : sites.count
        let count = viewModel.layer == .places
            ? viewModel.countInView(businesses, coordinate: { $0.coordinate })
            : viewModel.countInView(sites, coordinate: { $0.coordinate })

        if count > 0 && count < total {
            Button {
                Haptics.tap()
                showInView = true
            } label: {
                Text(count == 1 ? "1 here" : "\(count) here")
                    .riType(.caption, weight: .semibold)
                    .foregroundStyle(Color.riDark)
                    .padding(.horizontal, AppConstants.Space.snug + 2)
                    .padding(.vertical, AppConstants.Space.tight)
                    .background(.regularMaterial)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, AppConstants.Space.snug)
        }
    }

    @ViewBuilder
    private var popup: some View {
        Group {
            if let mapItem = viewModel.selectedMapItem {
                MapItemPopupCard(mapItem: mapItem) { viewModel.selectedMapItem = nil }
            } else if let site = viewModel.selectedDiveSite {
                DiveSitePopupCard(site: site)
            } else if let business = viewModel.selectedBusiness {
                MapPopupCard(business: business, userLocation: locationManager.userLocation) {
                    viewModel.selectedBusiness = nil
                }
            }
        }
        .padding(.horizontal, AppConstants.Space.snug + 4)
        .padding(.bottom, AppConstants.Space.snug + 4)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

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
