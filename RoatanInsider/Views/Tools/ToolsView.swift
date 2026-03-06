import SwiftUI

struct ToolsView: View {
    @State private var viewModel = ToolsViewModel()

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
        }
    }
}
