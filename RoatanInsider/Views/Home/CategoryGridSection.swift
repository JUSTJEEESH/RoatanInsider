import SwiftUI

struct CategoryGridSection: View {
    let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 5)

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            SectionHeader(title: "Browse by Category")

            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(Category.allCases) { category in
                    NavigationLink(value: category) {
                        CategoryIcon(category: category)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}
