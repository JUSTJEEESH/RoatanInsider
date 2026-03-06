import SwiftUI

struct ToolsView: View {
    @State private var viewModel = ToolsViewModel()
    @Environment(UnitPreference.self) private var unitPreference

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Tool", selection: $viewModel.selectedTool) {
                    ForEach(ToolsViewModel.ToolTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .onChange(of: viewModel.selectedTool) { _, _ in
                    Haptics.select()
                }

                ScrollView {
                    switch viewModel.selectedTool {
                    case .currency:
                        CurrencyConverterView(viewModel: viewModel)
                    case .tips:
                        TipCalculatorView(viewModel: viewModel)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .background(Color.riWhite)
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
            .navigationTitle("Tools")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
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
                }
            }
        }
    }
}
