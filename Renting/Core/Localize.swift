//
//  Localize.swift
//  Renting
//
//  Lookups for strings built outside SwiftUI views (PDF, notifications, formatting).
//

import Foundation
import SwiftUI

/// Localised string in the in-app language, with optional `String(format:)` arguments.
func L(_ key: String, _ args: CVarArg...) -> String {
    let format = NSLocalizedString(key, bundle: AppLanguage.shared.bundle, comment: "")
    return args.isEmpty ? format : String(format: format, locale: AppLanguage.shared.locale, arguments: args)
}

/// Currency chosen in Settings (defaults to EUR: the app is built for Spanish landlords).
@Observable
final class AppCurrency {
    static let shared = AppCurrency()
    static let supported = ["EUR", "USD", "GBP", "MXN", "ARS", "COP", "CLP", "BRL", "CHF"]
    private static let key = "app_currency"

    var code: String { didSet { UserDefaults.standard.set(code, forKey: Self.key) } }

    private init() { code = UserDefaults.standard.string(forKey: Self.key) ?? "EUR" }
}

extension Double {
    /// Whole-unit currency string in the app's currency and language.
    var money: String {
        formatted(.currency(code: AppCurrency.shared.code).locale(AppLanguage.shared.locale).precision(.fractionLength(0)))
    }

    /// Currency string with cents, for single payments.
    var moneyExact: String {
        formatted(.currency(code: AppCurrency.shared.code).locale(AppLanguage.shared.locale).precision(.fractionLength(0...2)))
    }

    /// "+1,200 €" / "−300 €": explicit sign for balances.
    var signedMoney: String {
        formatted(.currency(code: AppCurrency.shared.code).locale(AppLanguage.shared.locale).precision(.fractionLength(0)).sign(strategy: .always(showZero: false)))
    }
}

extension Date {
    var short: String { formatted(.dateTime.locale(AppLanguage.shared.locale).day().month(.abbreviated).year()) }
}
