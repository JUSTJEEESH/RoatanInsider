import SwiftUI

struct ToolsView: View {
    @State private var viewModel = ToolsViewModel()
    @Environment(UnitPreference.self) private var unitPreference

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom header for reliable display on all devices
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tools")
                            .riDisplayStyle(34)
                            .foregroundStyle(Color.riDark)
                        Text("Everything you need on the go")
                            .font(.riCaption(15))
                            .foregroundStyle(Color.riLightGray)
                    }
                    Spacer()
                    Button {
                        Haptics.select()
                        unitPreference.useMetric.toggle()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "ruler")
                                .font(.system(size: 14, weight: .medium))
                            Text(unitPreference.useMetric ? "km" : "mi")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundStyle(Color.riMint)
                    }
                    .padding(.bottom, 4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)

                // Custom segmented control with better visibility
                HStack(spacing: 0) {
                    ForEach(ToolsViewModel.ToolTab.allCases, id: \.self) { tab in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectedTool = tab
                            }
                            Haptics.select()
                        } label: {
                            Text(tab.rawValue)
                                .font(.system(size: 14, weight: viewModel.selectedTool == tab ? .bold : .medium))
                                .foregroundStyle(viewModel.selectedTool == tab ? .white : Color.riMediumGray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    viewModel.selectedTool == tab
                                        ? Color.riFixedDark
                                        : Color.riOffWhite
                                )
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

                ScrollView {
                    switch viewModel.selectedTool {
                    case .currency:
                        CurrencyConverterView(viewModel: viewModel)
                    case .tips:
                        TipCalculatorView(viewModel: viewModel)
                    case .phrases:
                        PhrasesView()
                    case .safety:
                        SafetyCardView()
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .background(Color.riWhite)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .navigationBarHidden(true)
            .task {
                await viewModel.exchangeRateService.fetchLatestRate()
            }
        }
    }
}
