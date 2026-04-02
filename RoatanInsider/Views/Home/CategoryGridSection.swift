import SwiftUI

struct CategoryGridSection: View {
    @Environment(DataManager.self) private var dataManager
    let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 5)

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SectionHeader(title: "Browse by Category", lightText: true)

            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(dataManager.categoryInfos) { info in
                    NavigationLink(value: CategoryNavID(id: info.id)) {
                        CategoryIcon(categoryInfo: info, lightText: true)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(info.displayName)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}
