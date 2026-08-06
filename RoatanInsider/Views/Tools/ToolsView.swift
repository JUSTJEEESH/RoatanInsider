import SwiftUI

struct ToolsView: View {
    @State private var viewModel = ToolsViewModel()
    @Environment(PurchaseManager.self) private var purchases
    @State private var showPaywall = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom header for reliable display on all devices
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tools")
                            .riType(.display)
                            .foregroundStyle(Color.riDark)
                        Text("Money, taxis, Spanish, safety — quick references.")
                            .riType(.body)
                            .foregroundStyle(Color.riLightGray)
                    }
                    Spacer()

                    insiderPlusChip

                    Button {
                        Haptics.tap()
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color.riMediumGray)
                            .frame(width: 32, height: 32)
                    }
                    .accessibilityLabel("Settings")
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
                                .riType(.caption, weight: viewModel.selectedTool == tab ? .bold : .medium)
                                .foregroundStyle(viewModel.selectedTool == tab ? .white : Color.riMediumGray)
                                // Five tabs into a phone's width: "Currency"
                                // is the longest and only just fits on the
                                // narrowest devices.
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
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
                    case .taxis:
                        TaxiFaresView()
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
            .sheet(isPresented: $showSettings) {
                SettingsView()
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
                    .riType(.label, weight: .bold)
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
