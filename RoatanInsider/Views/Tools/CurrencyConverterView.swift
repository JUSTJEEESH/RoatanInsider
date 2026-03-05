import SwiftUI

struct CurrencyConverterView: View {
    @Bindable var viewModel: ToolsViewModel

    var body: some View {
        VStack(spacing: 32) {
            // Currency display
            VStack(spacing: 20) {
                // From
                VStack(spacing: 8) {
                    Text(viewModel.isUsdToHnl ? "USD" : "HNL")
                        .font(.riCaption(14))
                        .foregroundStyle(Color.riLightGray)

                    TextField("0", text: $viewModel.usdAmount)
                        .font(.system(size: 48, weight: .bold, design: .default))
                        .foregroundStyle(Color.riDark)
                        .multilineTextAlignment(.center)
                        .keyboardType(.decimalPad)
                        .tracking(-1)
                }

                // Swap button
                Button {
                    viewModel.isUsdToHnl.toggle()
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color.riMint)
                        .frame(width: AppConstants.minTapTarget, height: AppConstants.minTapTarget)
                        .background(Color.riOffWhite)
                        .clipShape(Circle())
                }

                // To
                VStack(spacing: 8) {
                    Text(viewModel.isUsdToHnl ? "HNL" : "USD")
                        .font(.riCaption(14))
                        .foregroundStyle(Color.riLightGray)

                    Text(viewModel.convertedDisplay)
                        .font(.system(size: 48, weight: .bold, design: .default))
                        .foregroundStyle(Color.riMint)
                        .tracking(-1)
                }
            }

            // Rate info
            Text("1 USD = \(AppConstants.usdToHnlRate, specifier: "%.2f") HNL")
                .font(.riCaption(13))
                .foregroundStyle(Color.riLightGray)

            // Quick amount buttons
            VStack(spacing: 12) {
                Text("Quick Convert")
                    .font(.riCaption(14))
                    .foregroundStyle(Color.riLightGray)

                HStack(spacing: 10) {
                    ForEach(AppConstants.quickAmounts, id: \.self) { amount in
                        Button {
                            viewModel.isUsdToHnl = true
                            viewModel.setQuickAmount(amount)
                        } label: {
                            Text("$\(amount)")
                                .font(.riButton)
                                .foregroundStyle(Color.riDark)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(Color.riOffWhite)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(24)
        .padding(.top, 20)
    }
}
