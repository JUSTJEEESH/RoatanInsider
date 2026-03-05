import SwiftUI

struct BusinessListView: View {
    let businesses: [Business]

    var body: some View {
        LazyVStack(spacing: 16) {
            ForEach(businesses) { business in
                BusinessCard(business: business)
            }
        }
    }
}
