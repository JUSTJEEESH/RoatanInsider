import Foundation

extension Double {
    func formattedCurrency(code: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }
}

extension String {
    var displayArea: String {
        self.replacingOccurrences(of: "_", with: " ").capitalized
    }
}

extension Array where Element == Business {
    /// Smart sort: Featured first, then Insider Picks, then by rating/reviews.
    func smartSorted() -> [Business] {
        sorted { lhs, rhs in
            let lhsTier = lhs.isFeatured ? 0 : (lhs.isInsiderPick ? 1 : 2)
            let rhsTier = rhs.isFeatured ? 0 : (rhs.isInsiderPick ? 1 : 2)
            if lhsTier != rhsTier { return lhsTier < rhsTier }
            let lhsRating = lhs.rating ?? 0
            let rhsRating = rhs.rating ?? 0
            if lhsRating != rhsRating { return lhsRating > rhsRating }
            let lhsReviews = lhs.reviewCount ?? 0
            let rhsReviews = rhs.reviewCount ?? 0
            return lhsReviews > rhsReviews
        }
    }
}

extension Date {
    var currentDayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self).lowercased()
    }

    var currentTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }
}
