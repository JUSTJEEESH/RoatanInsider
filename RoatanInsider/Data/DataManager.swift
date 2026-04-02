import Foundation

@Observable
final class DataManager {
    var businesses: [Business] = []
    var cruiseGuides: [CruiseGuide] = []
    var areaGuides: [AreaGuide] = []
    var essentials: EssentialsGuide?
    var askALocalQuestions: [LocalQA] = []
    var categoryInfos: [CategoryInfo] = CategoryInfo.defaults

    init() {
        loadAll()
    }

    private func loadAll() {
        // Categories
        if let data: [CategoryInfo] = RemoteDataService.loadCachedOrBundled(
            filename: "categories.json", bundleName: "categories", type: [CategoryInfo].self
        ) {
            categoryInfos = data.sorted { $0.sortOrder < $1.sortOrder }
        }
        // Businesses
        if let data: [Business] = RemoteDataService.loadCachedOrBundled(
            filename: "businesses.json", bundleName: "businesses", type: [Business].self
        ) {
            businesses = data
        }

        // Area guides
        if let data: [AreaGuide] = RemoteDataService.loadCachedOrBundled(
            filename: "areas.json", bundleName: "areas", type: [AreaGuide].self
        ) {
            areaGuides = data
        }

        // Essentials
        if let data: EssentialsGuide = RemoteDataService.loadCachedOrBundled(
            filename: "essentials.json", bundleName: "essentials", type: EssentialsGuide.self
        ) {
            essentials = data
        }

        // Cruise guides
        for filename in ["cruise-mahogany-bay", "cruise-coxen-hole"] {
            if let guide: CruiseGuide = RemoteDataService.loadCachedOrBundled(
                filename: "\(filename).json", bundleName: filename, type: CruiseGuide.self
            ) {
                cruiseGuides.append(guide)
            }
        }

        // Ask a Local
        if let data: [LocalQA] = RemoteDataService.loadCachedOrBundled(
            filename: "ask-a-local.json", bundleName: "ask-a-local", type: [LocalQA].self
        ) {
            askALocalQuestions = data
        }
    }

    /// Checks Supabase for updated data across all content types.
    func checkForUpdates() async {
        guard let manifest = await RemoteDataService.fetchUpdates() else { return }

        // Categories
        if let v = manifest.categories?.version,
           let updated: [CategoryInfo] = await RemoteDataService.fetchIfNewer(
            filename: manifest.categories!.file, remoteVersion: v, type: [CategoryInfo].self
           ) {
            await MainActor.run { self.categoryInfos = updated.sorted { $0.sortOrder < $1.sortOrder } }
        }

        // Businesses
        let bizVersion = manifest.businessVersion
        if bizVersion > 0,
           let updated: [Business] = await RemoteDataService.fetchIfNewer(
            filename: "businesses.json", remoteVersion: bizVersion, type: [Business].self
           ), updated.count >= 10 {
            await MainActor.run { self.businesses = updated }
        }

        // Areas
        if let v = manifest.areas?.version,
           let updated: [AreaGuide] = await RemoteDataService.fetchIfNewer(
            filename: manifest.areas!.file, remoteVersion: v, type: [AreaGuide].self
           ) {
            await MainActor.run { self.areaGuides = updated }
        }

        // Essentials
        if let v = manifest.essentials?.version,
           let updated: EssentialsGuide = await RemoteDataService.fetchIfNewer(
            filename: manifest.essentials!.file, remoteVersion: v, type: EssentialsGuide.self
           ) {
            await MainActor.run { self.essentials = updated }
        }

        // Cruise guides
        if let v = manifest.cruiseMahoganyBay?.version,
           let updated: CruiseGuide = await RemoteDataService.fetchIfNewer(
            filename: manifest.cruiseMahoganyBay!.file, remoteVersion: v, type: CruiseGuide.self
           ) {
            await MainActor.run {
                self.cruiseGuides.removeAll { $0.id == updated.id }
                self.cruiseGuides.append(updated)
            }
        }

        if let v = manifest.cruiseCoxenHole?.version,
           let updated: CruiseGuide = await RemoteDataService.fetchIfNewer(
            filename: manifest.cruiseCoxenHole!.file, remoteVersion: v, type: CruiseGuide.self
           ) {
            await MainActor.run {
                self.cruiseGuides.removeAll { $0.id == updated.id }
                self.cruiseGuides.append(updated)
            }
        }

        // Ask a Local
        if let v = manifest.askALocal?.version,
           let updated: [LocalQA] = await RemoteDataService.fetchIfNewer(
            filename: manifest.askALocal!.file, remoteVersion: v, type: [LocalQA].self
           ) {
            await MainActor.run { self.askALocalQuestions = updated }
        }
    }

    // MARK: - Queries

    var featuredBusinesses: [Business] {
        businesses.filter { $0.isFeatured && $0.isActive }
    }

    var activeBusinesses: [Business] {
        businesses.filter { $0.isActive }
    }

    func businesses(for category: Category) -> [Business] {
        activeBusinesses.filter { $0.hasCategory(category) }.smartSorted()
    }

    func businesses(forCategoryId id: String) -> [Business] {
        activeBusinesses.filter { $0.hasCategory(id) }.smartSorted()
    }

    func categoryInfo(for id: String) -> CategoryInfo? {
        categoryInfos.first { $0.id == id }
    }

    func businesses(for area: Area) -> [Business] {
        activeBusinesses.filter { $0.isInArea(area) }.smartSorted()
    }

    func businesses(forAreaId areaId: String) -> [Business] {
        activeBusinesses.filter { $0.isInArea(areaId) }.smartSorted()
    }

    func business(withId id: String) -> Business? {
        businesses.first { $0.id == id }
    }

    func insiderPicks(limit: Int = 6) -> [Business] {
        activeBusinesses
            .filter { $0.isInsiderPick }
            .smartSorted()
            .prefix(limit)
            .map { $0 }
    }

    var bestOfBusinesses: [Business] {
        businesses.filter { $0.isBestOf && $0.isActive }
    }
}
