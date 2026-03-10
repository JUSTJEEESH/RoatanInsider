import SwiftUI

struct PhrasesView: View {
    @State private var speechService = SpeechService()
    @State private var expandedCategory: PhraseCategory? = .basics

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "text.bubble")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(Color.riMint)

                Text("Spanish Phrases")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.riDark)

                Text("A little Spanish goes a long way — locals appreciate the effort")
                    .font(.riCaption(14))
                    .foregroundStyle(Color.riMediumGray)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 28)
            .padding(.bottom, 24)

            // Categories
            VStack(spacing: 12) {
                ForEach(PhraseCategory.allCases) { category in
                    CategoryPhraseSection(
                        category: category,
                        isExpanded: expandedCategory == category,
                        speechService: speechService,
                        onToggle: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                if expandedCategory == category {
                                    expandedCategory = nil
                                } else {
                                    expandedCategory = category
                                }
                            }
                            Haptics.select()
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .onDisappear {
            speechService.stop()
        }
    }
}

// MARK: - Category Section

private struct CategoryPhraseSection: View {
    let category: PhraseCategory
    let isExpanded: Bool
    let speechService: SpeechService
    let onToggle: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Category header
            Button(action: onToggle) {
                HStack(spacing: 14) {
                    Image(systemName: category.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.riMint)
                        .frame(width: 36, height: 36)
                        .background(Color.riMint.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    Text(category.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.riDark)

                    Spacer()

                    Text("\(category.phrases.count)")
                        .font(.riCaption(13))
                        .foregroundStyle(Color.riLightGray)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.riLightGray)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            // Expanded phrases
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(category.phrases) { phrase in
                        PhraseRow(phrase: phrase, speechService: speechService)

                        if phrase.id != category.phrases.last?.id {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.riOffWhite)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Phrase Row

private struct PhraseRow: View {
    let phrase: Phrase
    let speechService: SpeechService

    private var isPlaying: Bool {
        speechService.currentlyPlayingID == phrase.id
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(phrase.english)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.riMediumGray)

                Text(phrase.spanish)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.riDark)

                Text(phrase.phonetic)
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.riMint)
            }

            Spacer()

            Button {
                Haptics.tap()
                speechService.speak(phrase.spanish, id: phrase.id)
            } label: {
                Image(systemName: isPlaying ? "speaker.wave.2.fill" : "play.circle.fill")
                    .font(.system(size: 32, weight: .regular))
                    .foregroundStyle(isPlaying ? Color.riPink : Color.riMint)
            }
            .buttonStyle(.plain)
            .frame(width: 44, height: 44)
            .accessibilityLabel("Play \(phrase.spanish)")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
