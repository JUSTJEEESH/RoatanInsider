import Foundation

@Observable
final class ToolsViewModel {
    enum ToolTab: String, CaseIterable {
        case currency = "Currency"
        case tips = "Tips"
        case safety = "Safety"
    }

    var selectedTool: ToolTab = .currency

    // Exchange rate
    let exchangeRateService = ExchangeRateService()

    var rate: Double {
        exchangeRateService.currentRate
    }

    // Currency
    var usdAmount: String = ""
    var isUsdToHnl: Bool = true

    var convertedAmount: Double {
        let amount = Double(usdAmount) ?? 0
        return isUsdToHnl
            ? amount * rate
            : amount / rate
    }

    var convertedDisplay: String {
        let code = isUsdToHnl ? "HNL" : "USD"
        return convertedAmount.formattedCurrency(code: code)
    }

    func setQuickAmount(_ amount: Int) {
        usdAmount = "\(amount)"
    }

    // Tip Calculator
    var billAmount: String = ""
    var tipPercentage: Int = 18
    var splitCount: Int = 1

    var tipAmount: Double {
        let bill = Double(billAmount) ?? 0
        return bill * Double(tipPercentage) / 100
    }

    var totalWithTip: Double {
        let bill = Double(billAmount) ?? 0
        return bill + tipAmount
    }

    var perPerson: Double {
        guard splitCount > 0 else { return totalWithTip }
        return totalWithTip / Double(splitCount)
    }

    var perPersonHNL: Double {
        perPerson * rate
    }
}
