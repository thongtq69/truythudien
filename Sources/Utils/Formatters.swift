import Foundation

struct NumberFormatters {
    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.currencyCode = "VND"
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        return formatter
    }()
    
    static let decimal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    static func formatCurrency(_ value: Double) -> String {
        currency.string(from: NSNumber(value: value)) ?? "\(Int(value)) đ"
    }
    
    static func formatDecimal(_ value: Double) -> String {
        decimal.string(from: NSNumber(value: value)) ?? "\(value)"
    }
}
