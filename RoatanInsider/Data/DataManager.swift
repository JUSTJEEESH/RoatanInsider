import Foundation

@Observable
final class DataManager {
    var businesses: [Business] = []
    var cruiseGuides: [CruiseGuide] = []
    var areaGuides: [AreaGuide] = []
    var essentials: EssentialsGuide?

    init() {
        loadBusinesses()
        loadGuides()
    }

    private func loadBusinesses() {
        guard let url = Bundle.main.url(forResource: "businesses", withExtension: "json") else {
            print("⚠️ DataManager: businesses.json not found in bundle")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            businesses = try JSONDecoder().decode([Business].self, from: data)
            print("✅ Loaded \(businesses.count) businesses")
        } catch {
            print("⚠️ DataManager: Failed to decode businesses.json: \(error)")
        }
    }

    private func loadGuides() {
        // Cruise guides
        for filename in ["cruise-mahogany-bay", "cruise-coxen-hole"] {
            if let url = Bundle.main.url(forResource: filename, withExtension: "json") {
                do {
                    let data = try Data(contentsOf: url)
                    let guide = try JSONDecoder().decode(CruiseGuide.self, from: data)
                    cruiseGuides.append(guide)
                    print("✅ Loaded cruise guide: \(filename)")
                } catch {
                    print("⚠️ Failed to decode \(filename): \(error)")
                }
            } else {
                print("⚠️ \(filename).json not found in bundle")
            }
        }

        // Area guides
        if let url = Bundle.main.url(forResource: "areas", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                areaGuides = try JSONDecoder().decode([AreaGuide].self, from: data)
                print("✅ Loaded \(areaGuides.count) area guides")
            } catch {
                print("⚠️ Failed to decode areas.json: \(error)")
            }
        }

        // Essentials
        if let url = Bundle.main.url(forResource: "essentials", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                essentials = try JSONDecoder().decode(EssentialsGuide.self, from: data)
                print("✅ Loaded essentials guide")
            } catch {
                print("⚠️ Failed to decode essentials.json: \(error)")
            }
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
        activeBusinesses.filter { $0.category == category }
    }

    func businesses(for area: Area) -> [Business] {
        activeBusinesses.filter { $0.area == area }
    }

    func business(withId id: String) -> Business? {
        businesses.first { $0.id == id }
    }

    func insiderPicks(limit: Int = 6) -> [Business] {
        activeBusinesses
            .filter { $0.insiderTip != nil && $0.isFeatured }
            .prefix(limit)
            .map { $0 }
    }
}
