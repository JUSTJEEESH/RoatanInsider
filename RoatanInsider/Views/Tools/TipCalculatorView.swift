import SwiftUI

struct TipCalculatorView: View {
    @Bindable var viewModel: ToolsViewModel

    var body: some View {
        VStack(spacing: 28) {
            // Bill amount
            VStack(spacing: 8) {
                Text("Bill Amount (USD)")
                    .font(.riCaption(14))
                    .foregroundStyle(Color.riLightGray)

                TextField("0.00", text: $viewModel.billAmount)
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(Color.riDark)
                    .multilineTextAlignment(.center)
                    .keyboardType(.decimalPad)
                    .tracking(-1)
            }

            // Tip percentage buttons
            VStack(spacing: 12) {
                Text("Tip Percentage")
                    .font(.riCaption(14))
                    .foregroundStyle(Color.riLightGray)

                HStack(spacing: 10) {
                    ForEach(AppConstants.tipPercentages, id: \.self) { pct in
                        Button {
                            viewModel.tipPercentage = pct
                        } label: {
                            Text("\(pct)%")
                                .font(.riButton)
                                .foregroundStyle(viewModel.tipPercentage == pct ? .white : Color.riDark)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(viewModel.tipPercentage == pct ? Color.riDark : Color.riOffWhite)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Split
            VStack(spacing: 12) {
                Text("Split Between")
                    .font(.riCaption(14))
                    .foregroundStyle(Color.riLightGray)

                HStack(spacing: 16) {
                    Button {
                        if viewModel.splitCount > 1 { viewModel.splitCount -= 1 }
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 16, weight: .medium))
                            .frame(width: AppConstants.minTapTarget, height: AppConstants.minTapTarget)
                            .foregroundStyle(Color.riDark)
                            .background(Color.riOffWhite)
                            .clipShape(Circle())
                    }

                    Text("\(viewModel.splitCount)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(Color.riDark)
                        .frame(width: 60)

                    Button {
                        viewModel.splitCount += 1
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                            .frame(width: AppConstants.minTapTarget, height: AppConstants.minTapTarget)
                            .foregroundStyle(Color.riDark)
                            .background(Color.riOffWhite)
                            .clipShape(Circle())
                    }
                }
            }

            // Results
            VStack(spacing: 16) {
                Divider()

                resultRow(label: "Tip", value: viewModel.tipAmount.formattedCurrency())
                resultRow(label: "Total", value: viewModel.totalWithTip.formattedCurrency())

                if viewModel.splitCount > 1 {
                    resultRow(label: "Per Person", value: viewModel.perPerson.formattedCurrency(), highlight: true)
                }

                resultRow(
                    label: viewModel.splitCount > 1 ? "Per Person (HNL)" : "Total (HNL)",
                    value: (viewModel.splitCount > 1 ? viewModel.perPersonHNL : viewModel.totalWithTip * AppConstants.usdToHnlRate)
                        .formattedCurrency(code: "HNL")
                )
            }
        }
        .padding(24)
        .padding(.top, 20)
    }

    private func resultRow(label: String, value: String, highlight: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.riBody)
                .foregroundStyle(Color.riMediumGray)

            Spacer()

            Text(value)
                .font(.system(size: highlight ? 22 : 18, weight: .bold))
                .foregroundStyle(highlight ? Color.riMint : Color.riDark)
        }
    }
}
