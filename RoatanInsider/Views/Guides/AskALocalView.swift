import SwiftUI

struct AskALocalView: View {
    @State private var expandedId: String?
    @Environment(DataManager.self) private var dataManager

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.text.bubble.right")
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(Color.riMint)

                    Text("Ask a Local")
                        .riDisplayStyle(30)
                        .foregroundStyle(Color.riDark)

                    Text("Honest answers from someone who actually lives here.")
                        .font(.riBody)
                        .foregroundStyle(Color.riMediumGray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.vertical, 32)

                // Q&A List
                LazyVStack(spacing: 0) {
                    ForEach(dataManager.askALocalQuestions) { qa in
                        QARow(qa: qa, isExpanded: expandedId == qa.id) {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                expandedId = expandedId == qa.id ? nil : qa.id
                            }
                            Haptics.tap()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Color.riWhite)
        .navigationTitle("Ask a Local")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - QA Row

private struct QARow: View {
    let qa: LocalQA
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Question
            Button(action: onTap) {
                HStack(alignment: .top, spacing: 12) {
                    Text("Q")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.riPink)
                        .frame(width: 24)

                    Text(qa.question)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.riDark)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.riLightGray)
                        .padding(.top, 3)
                }
                .padding(.vertical, 18)
            }
            .buttonStyle(.plain)

            // Answer
            if isExpanded {
                HStack(alignment: .top, spacing: 12) {
                    Rectangle()
                        .fill(Color.riMint)
                        .frame(width: 3)
                        .clipShape(RoundedRectangle(cornerRadius: 2))

                    Text(qa.answer)
                        .font(.riBody)
                        .foregroundStyle(Color.riMediumGray)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.leading, 36)
                .padding(.bottom, 18)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Divider()
        }
    }
}

// MARK: - Data

struct LocalQA: Identifiable, Codable {
    let id: String
    let question: String
    let answer: String
}
