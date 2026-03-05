import SwiftUI

struct OpenStatusBadge: View {
    let business: Business

    private var isOpen: Bool {
        business.isOpenNow()
    }

    var body: some View {
        Text(isOpen ? "Open Now" : "Closed")
            .font(.riCaption(12))
            .fontWeight(.medium)
            .foregroundStyle(isOpen ? Color.riMint : Color.riLightGray)
    }
}
