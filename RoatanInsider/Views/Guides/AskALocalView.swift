import SwiftUI

struct AskALocalView: View {
    @State private var expandedId: String?

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
                    ForEach(Self.questions) { qa in
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

struct LocalQA: Identifiable {
    let id: String
    let question: String
    let answer: String
}

extension AskALocalView {
    static let questions: [LocalQA] = [
        LocalQA(
            id: "safe",
            question: "Is Roatán safe?",
            answer: "The tourist areas — West Bay, West End, Sandy Bay — are very safe. I walk around at night, eat at street carts, take water taxis. Use common sense like you would anywhere: don't flash expensive jewelry, don't walk alone on empty dark roads, and keep an eye on your stuff at the beach. Coxen Hole requires more awareness, especially near the market. Overall, Roatán is significantly safer than mainland Honduras."
        ),
        LocalQA(
            id: "money",
            question: "Do I need Lempiras or can I use US dollars?",
            answer: "USD is accepted almost everywhere in the tourist zones. Restaurants, dive shops, bars, taxis — they all take dollars. You'll get change in a mix of USD and Lempiras though. ATMs on the island dispense Lempiras. Pro tip: carry small bills ($1s and $5s). If you pay for a $3 water taxi with a $20, you might not get change."
        ),
        LocalQA(
            id: "snorkel",
            question: "Where's the best snorkeling without a boat?",
            answer: "West Bay Beach, hands down. Walk in from the south end of the beach near Infinity Bay and you're on the reef in 30 seconds. The coral starts in about 4 feet of water and drops off to a wall. You'll see parrotfish, sergeant majors, brain coral, and if you're lucky, a sea turtle. Bring your own gear or rent it from the beach vendors for about $10. Half Moon Bay in West End is another great walk-in spot — smaller beach, fewer people."
        ),
        LocalQA(
            id: "baleada",
            question: "What's a baleada and where do I get the best one?",
            answer: "A baleada is Honduras's national street food — a thick flour tortilla folded over refried beans, crema (sour cream), and crumbly cheese. The 'sencilla' (simple) version is just that. A 'con todo' adds scrambled eggs, avocado, and sometimes meat. They cost $1-3. The best ones are from street vendors and small local shops, not resort restaurants. Look for places where locals are lined up — that's your sign."
        ),
        LocalQA(
            id: "cruise-time",
            question: "I have 6 hours from my cruise ship — what should I do?",
            answer: "Skip the overpriced excursions sold on the ship. Here's what I'd do: grab a taxi to West Bay Beach ($5-8 per person from Mahogany Bay). Spend 3 hours swimming, snorkeling, and having a couple beers at a beach bar. Eat fresh fish tacos for lunch. Then head back with an hour buffer — you do NOT want to miss the ship. If you're at Coxen Hole port, it's a bit farther to West Bay (20 min taxi, ~$10-15) but still totally doable."
        ),
        LocalQA(
            id: "water",
            question: "Can I drink the tap water?",
            answer: "No. Drink bottled or filtered water only. Every restaurant and hotel provides purified water, and you can buy gallon jugs at any grocery store for about $1.50. Ice in restaurants is almost always made from purified water, so that's fine. Most locals drink purified water too — it's not a tourist-only thing."
        ),
        LocalQA(
            id: "taxi",
            question: "How do taxis work? Will I get ripped off?",
            answer: "There are no meters. Always agree on the price before you get in. Typical fares: West Bay to West End is $5, Mahogany Bay port to West Bay is $5-8 per person, Coxen Hole to West End is $10-15. Shared colectivo minibuses run the main road for about $1-2 per person — they're totally fine to use. Water taxis between West End and West Bay are $3 per person and run constantly during the day. Ask your hotel or a restaurant to call you a taxi — they'll get you a fair price."
        ),
        LocalQA(
            id: "diving",
            question: "I've never scuba dived — can I try it here?",
            answer: "Roatán is one of the best places in the world to learn. A Discover Scuba (intro dive) costs about $85-100 and takes half a day — you'll do a pool session then a real reef dive. Full PADI Open Water certification is $300-400 for 3-4 days, which is roughly half the price of most Caribbean destinations. The water is warm, calm, and visibility is usually 80-100+ feet. West End has the highest concentration of dive shops. Book directly with the shop, not through your hotel — you'll save 20-30%."
        ),
        LocalQA(
            id: "sunscreen",
            question: "Any tips about sunscreen?",
            answer: "The sun here is no joke — you're 16 degrees from the equator. Wear reef-safe sunscreen (no oxybenzone or octinoxate). Regular sunscreen kills the coral reef, and this reef is the second largest barrier reef in the world. Apply it 30 minutes before getting in the water. Re-apply constantly. I've seen people get second-degree burns on day one. Bring a rash guard if you're snorkeling — it's the best protection and means less sunscreen in the water."
        ),
        LocalQA(
            id: "internet",
            question: "Will my phone work? Is there WiFi?",
            answer: "Most US carriers work here with international roaming, but it's expensive ($10/day for some plans). Buy a local Tigo SIM card at the airport or in Coxen Hole for about $10 — you'll get data that works across most of the island. WiFi is available at hotels, restaurants, and bars in the tourist areas but can be slow and unreliable. In the eastern part of the island (Oak Ridge, Punta Gorda), connectivity gets spotty. Download offline maps before you go."
        ),
        LocalQA(
            id: "rain",
            question: "What if it rains during my trip?",
            answer: "Tropical rain is usually short and intense — 20-40 minutes, then sunshine. Don't cancel your plans because of a morning shower. The rainy season (October-January) means more frequent rain but rarely all-day downpours. Diving and snorkeling are fine in light rain — the underwater visibility doesn't change. If it's a heavy storm day, hit a restaurant, explore the shops in West End, or get a massage. The rain makes everything even greener and more beautiful."
        ),
        LocalQA(
            id: "tipping",
            question: "How much should I tip?",
            answer: "Restaurants: 15-18% if not already included (check the bill — some add 'propina' automatically). Dive instructors: $10-20 per day is appreciated. Taxi drivers: not expected but rounding up is nice. Tour guides: $5-10 per person. Hotel housekeeping: $2-3 per day. Beach chair attendants: $1-2. Tip in USD — it's preferred over Lempiras."
        ),
        LocalQA(
            id: "food-cost",
            question: "How expensive is Roatán?",
            answer: "It depends where you go. A local baleada: $1-2. Beach bar burger: $8-12. Nice restaurant dinner: $15-25 per person. Beers: $2-4. A dive: $35-50 for certified divers. West Bay Beach chair rental: $5-10. Taxi across the island: $25-30. You can absolutely do Roatán on a budget if you eat where locals eat and skip the resort restaurants. A comfortable mid-range day costs about $50-80 per person including food, drinks, and an activity."
        ),
        LocalQA(
            id: "wildlife",
            question: "What wildlife will I see?",
            answer: "Underwater: sea turtles, eagle rays, moray eels, barracuda, nurse sharks, parrotfish, and hundreds of coral species. On land: iguanas everywhere (they're harmless), tropical birds, and if you visit the Gumbalimba Park, you can meet monkeys and macaws. At night, you might see hermit crabs on the beach. Between November and March, whale sharks occasionally pass through. No dangerous wildlife to worry about — no poisonous snakes on the island."
        ),
        LocalQA(
            id: "best-time",
            question: "When's the best time to visit?",
            answer: "February through June is peak season — dry, sunny, calm seas, perfect visibility for diving. March and April are the best months overall. July-September is hot and humid but less crowded and cheaper. October-January is rainy season — still beautiful, but expect afternoon showers and occasionally rough seas. Cruise ship days (check the port schedule) make West Bay much more crowded. If you're staying on the island, plan your beach days for non-cruise days."
        ),
    ]
}
