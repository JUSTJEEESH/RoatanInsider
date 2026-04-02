import SwiftUI

struct CurrencyConverterView: View {
    @Bindable var viewModel: ToolsViewModel
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "coloncurrencysign.arrow.circlepath")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(Color.riMint)

                Text("Currency Converter")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.riDark)

                Text("USD and Honduran Lempira — updated daily")
                    .font(.riCaption(14))
                    .foregroundStyle(Color.riMediumGray)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 28)

            // Currency display
            VStack(spacing: 20) {
                // From
                VStack(spacing: 8) {
                    Text(viewModel.isUsdToHnl ? "USD" : "HNL")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.riDark)
                        .tracking(1)

                    TextField("0", text: $viewModel.usdAmount)
                        .font(.system(size: 48, weight: .bold, design: .default))
                        .foregroundStyle(Color.riDark)
                        .multilineTextAlignment(.center)
                        .keyboardType(.decimalPad)
                        .tracking(-1)
                        .focused($isInputFocused)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    isInputFocused = false
                                }
                                .fontWeight(.semibold)
                            }
                        }
                }

                // Swap button
                Button {
                    Haptics.tap()
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
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.riDark)
                        .tracking(1)

                    Text(viewModel.convertedDisplay)
                        .font(.system(size: 48, weight: .bold, design: .default))
                        .foregroundStyle(Color.riDark)
                        .tracking(-1)
                }
            }

            // Rate info
            VStack(spacing: 4) {
                Text("1 USD = \(viewModel.rate, specifier: "%.2f") HNL")
                    .font(.riCaption(13))
                    .foregroundStyle(Color.riLightGray)

                HStack(spacing: 4) {
                    let service = viewModel.exchangeRateService
                    Circle()
                        .fill(service.isLive ? Color.riMint : Color.riLightGray)
                        .frame(width: 6, height: 6)

                    Text(service.rateSourceLabel)
                        .font(.riCaption(11))
                        .foregroundStyle(Color.riLightGray)
                }
            }

            // Quick amount buttons
            VStack(spacing: 12) {
                Text("Quick Convert")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.riDark)
                    .tracking(0.5)

                HStack(spacing: 10) {
                    ForEach(AppConstants.quickAmounts, id: \.self) { amount in
                        Button {
                            Haptics.select()
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

            // In Your Currency — read-only reference
            if viewModel.currentUsdValue > 0 {
                VStack(spacing: 14) {
                    Rectangle()
                        .fill(Color.riOffWhite)
                        .frame(height: 1)

                    Text("In Your Currency")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.riDark)
                        .tracking(0.5)

                    HStack(spacing: 0) {
                        ForEach(HomeCurrency.allCases) { currency in
                            let amount = viewModel.usdInHomeCurrency(currency)
                            VStack(spacing: 6) {
                                Text(currency.displayLabel)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color.riLightGray)
                                    .tracking(0.5)

                                Text("\(currency.symbol)\(amount, specifier: "%.2f")")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(Color.riDark)
                                    .tracking(-0.3)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .transition(.opacity.combined(with: .offset(y: 8)))
            }
        }
        .padding(24)
        .padding(.top, 20)
        .animation(.easeOut(duration: 0.25), value: viewModel.currentUsdValue > 0)
    }
}
