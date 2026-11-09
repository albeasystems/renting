//
//  RentingApp.swift
//  Renting
//

import SwiftUI

@main
struct RentingApp: App {
    @State private var store = RentalStore.shared
    @State private var ui = AppUI()
    @State private var appLanguage = AppLanguage.shared
    @State private var currency = AppCurrency.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(ui)
                .environment(appLanguage)
                .environment(currency)
                .environment(\.locale, appLanguage.locale)
                .environment(\.layoutDirection, appLanguage.isRightToLeft ? .rightToLeft : .leftToRight)
                .tint(Color.brand)
        }
    }
}
