import SwiftUI

struct AreaGuideView: View {
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Area.allCases) { area in
                    NavigationLink {
                        AreaGuideDetailView(area: area)
                    } label: {
                        AreaCard(area: area)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
        }
        .background(Color.riWhite)
        .navigationTitle("Area Guides")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct AreaCard: View {
    let area: Area

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "2D2D2D"))
                    .frame(height: 120)

                VStack(alignment: .leading, spacing: 2) {
                    Text(area.displayName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(12)
            }

            Text(area.bestFor)
                .font(.riCaption(12))
                .foregroundStyle(Color.riLightGray)
                .lineLimit(2)
        }
    }
}
