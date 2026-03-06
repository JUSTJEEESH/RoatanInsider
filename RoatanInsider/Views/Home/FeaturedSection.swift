import SwiftUI

struct FeaturedSection: View {
    let businesses: [Business]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            SectionHeader(title: "Featured", lightText: true)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(businesses.prefix(10)) { business in
                        BusinessCardCompact(business: business)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}
