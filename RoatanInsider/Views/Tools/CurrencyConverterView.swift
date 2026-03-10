import SwiftUI

struct CurrencyConverterView: View {
    @Bindable var viewModel: ToolsViewModel
    @FocusState private var focusedField: CurrencyField?

    private enum CurrencyField {
        case main, home
    }

    var body: some View {
        VStack(spacing: 32) {
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
                        .focused($focusedField, equals: .main)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    focusedField = nil
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

            // Home Currency section
            VStack(spacing: 16) {
                Rectangle()
                    .fill(Color.riOffWhite)
                    .frame(height: 1)

                Text("Your Currency")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.riDark)
                    .tracking(0.5)

                // Currency picker
                HStack(spacing: 10) {
                    ForEach(HomeCurrency.allCases) { currency in
                        Button {
                            Haptics.select()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if viewModel.selectedHomeCurrency == currency {
                                    viewModel.selectedHomeCurrency = nil
                                    viewModel.homeAmount = ""
                                } else {
                                    viewModel.selectedHomeCurrency = currency
                                }
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Text(currency.flag)
                                    .font(.system(size: 16))
                                Text(currency.rawValue)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundStyle(
                                viewModel.selectedHomeCurrency == currency
                                    ? Color.white : Color.riDark
                            )
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                viewModel.selectedHomeCurrency == currency
                                    ? Color.riDark : Color.riOffWhite
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Conversion display
                if let currency = viewModel.selectedHomeCurrency {
                    VStack(spacing: 16) {
                        VStack(spacing: 6) {
                            Text(currency.rawValue)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Color.riDark)
                                .tracking(1)

                            TextField("0", text: $viewModel.homeAmount)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(Color.riDark)
                                .multilineTextAlignment(.center)
                                .keyboardType(.decimalPad)
                                .tracking(-0.5)
                                .focused($focusedField, equals: .home)
                        }

                        // Results
                        if let amount = Double(viewModel.homeAmount), amount > 0 {
                            HStack(spacing: 24) {
                                VStack(spacing: 4) {
                                    Text("USD")
                                        .font(.riCaption(11))
                                        .foregroundStyle(Color.riLightGray)
                                        .tracking(0.5)
                                    Text(viewModel.homeToUsd.formattedCurrency(code: "USD"))
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundStyle(Color.riDark)
                                }
                                VStack(spacing: 4) {
                                    Text("HNL")
                                        .font(.riCaption(11))
                                        .foregroundStyle(Color.riLightGray)
                                        .tracking(0.5)
                                    Text(viewModel.homeToHnl.formattedCurrency(code: "HNL"))
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundStyle(Color.riDark)
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        // Rate reference
                        let rateToUsd = viewModel.exchangeRateService.toUsd(from: currency)
                        Text("1 \(currency.rawValue) = \(rateToUsd, specifier: "%.2f") USD")
                            .font(.riCaption(12))
                            .foregroundStyle(Color.riLightGray)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(24)
        .padding(.top, 20)
        .animation(.easeInOut(duration: 0.2), value: viewModel.selectedHomeCurrency)
    }
}
