import SwiftUI

struct IslandEssentialsView: View {
    @Environment(DataManager.self) private var dataManager

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let essentials = dataManager.essentials {
                    ForEach(essentials.topics) { topic in
                        EssentialTopicCard(topic: topic)
                    }
                } else {
                    Text("Loading essentials...")
                        .font(.riBody)
                        .foregroundStyle(Color.riLightGray)
                }
            }
            .padding(20)
        }
        .background(Color.riWhite)
        .navigationTitle("Island Essentials")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct EssentialTopicCard: View {
    let topic: EssentialTopic
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: topic.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color.riMint)
                        .frame(width: 36)

                    Text(topic.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.riDark)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.riLightGray)
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Text(topic.content)
                        .font(.riCaption(14))
                        .foregroundStyle(Color.riMediumGray)
                        .lineSpacing(4)

                    if !topic.tips.isEmpty {
                        ForEach(topic.tips, id: \.self) { tip in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "lightbulb")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.riMint)
                                    .padding(.top, 2)

                                Text(tip)
                                    .font(.riCaption(13))
                                    .foregroundStyle(Color.riMediumGray)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(Color.riOffWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
