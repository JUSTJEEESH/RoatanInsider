import SwiftUI

struct CruiseDayGuideView: View {
    @Environment(DataManager.self) private var dataManager
    @State private var selectedPortIndex = 0
    @State private var selectedItineraryIndex = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Port selector
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Your Port")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.riDark)

                    if !dataManager.cruiseGuides.isEmpty {
                        Picker("Port", selection: $selectedPortIndex) {
                            ForEach(Array(dataManager.cruiseGuides.enumerated()), id: \.offset) { index, guide in
                                Text(guide.portName).tag(index)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                if let guide = currentGuide {
                    Text(guide.portDescription)
                        .font(.riBody)
                        .foregroundStyle(Color.riMediumGray)
                        .lineSpacing(4)

                    // Time selector
                    if !guide.itineraries.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How Much Time Do You Have?")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.riDark)

                            HStack(spacing: 10) {
                                ForEach(Array(guide.itineraries.enumerated()), id: \.offset) { index, itinerary in
                                    Button {
                                        selectedItineraryIndex = index
                                    } label: {
                                        Text(itinerary.duration)
                                            .font(.riButton)
                                            .foregroundStyle(selectedItineraryIndex == index ? .white : Color.riDark)
                                            .padding(.horizontal, 16)
                                            .frame(height: 40)
                                            .background(selectedItineraryIndex == index ? Color.riFixedDark : Color.riOffWhite)
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        if let itinerary = currentItinerary {
                            // Itinerary steps
                            VStack(alignment: .leading, spacing: 0) {
                                Text(itinerary.title)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(Color.riDark)
                                    .padding(.bottom, 16)

                                ForEach(Array(itinerary.steps.enumerated()), id: \.offset) { index, step in
                                    ItineraryStepView(step: step, isLast: index == itinerary.steps.count - 1)
                                }
                            }
                        }
                    }

                    // Safety tips
                    if !guide.safetyTips.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Safety Tips")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Color.riDark)

                            ForEach(guide.safetyTips, id: \.self) { tip in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "checkmark.circle")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Color.riMint)
                                        .padding(.top, 2)

                                    Text(tip)
                                        .font(.riCaption(14))
                                        .foregroundStyle(Color.riMediumGray)
                                }
                            }
                        }
                    }

                    // Return reminder
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.riPink)
                            .frame(width: 3)

                        Text(guide.returnReminder)
                            .font(.riCaption(14))
                            .foregroundStyle(Color.riMediumGray)
                            .fontWeight(.medium)
                            .padding(.leading, 12)
                            .padding(.vertical, 8)
                    }
                }
            }
            .padding(20)
        }
        .background(Color.riWhite)
        .navigationTitle("Cruise Day Guide")
        .navigationBarTitleDisplayMode(.large)
    }

    private var currentGuide: CruiseGuide? {
        guard dataManager.cruiseGuides.indices.contains(selectedPortIndex) else { return nil }
        return dataManager.cruiseGuides[selectedPortIndex]
    }

    private var currentItinerary: Itinerary? {
        guard let guide = currentGuide,
              guide.itineraries.indices.contains(selectedItineraryIndex) else { return nil }
        return guide.itineraries[selectedItineraryIndex]
    }
}

struct ItineraryStepView: View {
    let step: ItineraryStep
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline
            VStack(spacing: 0) {
                Circle()
                    .fill(Color.riMint)
                    .frame(width: 10, height: 10)

                if !isLast {
                    Rectangle()
                        .fill(Color.riOffWhite)
                        .frame(width: 2)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(step.time)
                    .font(.riCaption(12))
                    .foregroundStyle(Color.riMint)
                    .fontWeight(.semibold)

                Text(step.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.riDark)

                Text(step.description)
                    .font(.riCaption(14))
                    .foregroundStyle(Color.riMediumGray)
                    .lineSpacing(3)

                if let cost = step.estimatedCost {
                    Text("Est. cost: \(cost)")
                        .font(.riCaption(12))
                        .foregroundStyle(Color.riLightGray)
                }

                if let tip = step.tip {
                    Text(tip)
                        .font(.riCaption(12))
                        .foregroundStyle(Color.riMint)
                        .italic()
                }
            }
            .padding(.bottom, isLast ? 0 : 20)
        }
    }
}
