import SwiftUI

struct ToolsView: View {
    @State private var viewModel = ToolsViewModel()
    @Environment(PurchaseManager.self) private var purchases
    @State private var showPaywall = false

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

                    insiderPlusChip
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
                                        ? Color.riPink
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
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    @ViewBuilder
    private var insiderPlusChip: some View {
        Button {
            Haptics.tap()
            showPaywall = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: purchases.hasPremium ? "checkmark.seal.fill" : "sparkles")
                    .font(.system(size: 11, weight: .bold))
                Text(purchases.hasPremium ? "Insider+" : "Try Insider+")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(0.3)
            }
            .foregroundStyle(purchases.hasPremium ? Color.riMint : Color.riPink)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background((purchases.hasPremium ? Color.riMint : Color.riPink).opacity(0.12))
            .clipShape(Capsule())
        }
        .accessibilityLabel(purchases.hasPremium ? "Insider+ member" : "Try Insider+")
    }
}
